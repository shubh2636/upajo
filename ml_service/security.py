"""
Security utilities and middlewares for Upajo ML Microservice.
Provides Supabase JWT verification, API key authentication, sliding-window rate limiting,
security headers, request size limits, and PII redaction.
"""

import os
import re
import time
import json
import logging
import secrets
from collections import defaultdict, deque
from typing import Optional, Dict, Any, Deque
from fastapi import Request, HTTPException, Header, Depends, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
import jwt

logger = logging.getLogger("upajo.security")

# Configuration
ENVIRONMENT = os.getenv("ENVIRONMENT", "development").lower()
ML_SERVICE_API_KEY = os.getenv("ML_SERVICE_API_KEY", "")
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET", os.getenv("SUPABASE_SERVICE_ROLE_KEY", ""))

# PII Scrubbing Patterns (Masks phone numbers, Aadhaar, emails before external AI proxy calls)
PHONE_REGEX = re.compile(r"(?:\+91[\-\s]?)?[6-9]\d{9}\b")
AADHAAR_REGEX = re.compile(r"\b\d{4}[\-\s]?\d{4}[\-\s]?\d{4}\b")
EMAIL_REGEX = re.compile(r"\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b")
IFSC_REGEX = re.compile(r"\b[A-Z]{4}0[A-Z0-9]{6}\b")


def scrub_pii(text: str) -> str:
    """Masks Indian phone numbers, Aadhaar IDs, emails, and bank identifiers from user text."""
    if not text:
        return ""
    scrubbed = PHONE_REGEX.sub("[PHONE_REDACTED]", text)
    scrubbed = AADHAAR_REGEX.sub("[AADHAAR_REDACTED]", scrubbed)
    scrubbed = EMAIL_REGEX.sub("[EMAIL_REDACTED]", scrubbed)
    scrubbed = IFSC_REGEX.sub("[IFSC_REDACTED]", scrubbed)
    return scrubbed


class SlidingWindowRateLimiter:
    """In-memory sliding window rate limiter."""

    def __init__(self):
        self._records: Dict[str, Deque[float]] = defaultdict(deque)

    def check(self, key: str, max_requests: int, window_seconds: int = 60) -> bool:
        """Returns True if request is allowed, False if limit exceeded."""
        now = time.time()
        q = self._records[key]
        cutoff = now - window_seconds
        while q and q[0] <= cutoff:
            q.popleft()

        if len(q) >= max_requests:
            return False

        q.append(now)
        return True

    def reset(self):
        self._records.clear()


rate_limiter = SlidingWindowRateLimiter()


def enforce_rate_limit(key: str, max_requests: int, window_seconds: int = 60, custom_msg: Optional[str] = None):
    """Dependency helper to enforce rate limit."""
    if not rate_limiter.check(key, max_requests, window_seconds):
        msg = custom_msg or f"Too many requests. Limit is {max_requests} per {window_seconds}s."
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=msg,
            headers={"Retry-After": str(window_seconds)},
        )


async def verify_supabase_jwt_or_api_key(
    authorization: Optional[str] = Header(None),
    x_api_key: Optional[str] = Header(None),
) -> Dict[str, Any]:
    """
    Authenticates requests via:
    1. Internal API Key (X-API-KEY header) - used for backend/edge function to ML service calls.
    2. Supabase User JWT (Authorization: Bearer <token>) - verified using SUPABASE_JWT_SECRET.
    Rejects unauthenticated requests with HTTP 401 Unauthorized.
    """
    # 1. Check Internal API Key
    if x_api_key and ML_SERVICE_API_KEY:
        if secrets.compare_digest(x_api_key.strip(), ML_SERVICE_API_KEY.strip()):
            return {"sub": "system", "role": "service_role", "auth_type": "api_key"}

    # 2. Check Supabase User JWT Bearer Token
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split("Bearer ", 1)[1].strip()
        if not token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Missing Bearer token in Authorization header",
            )

        # Decode & verify JWT
        secret = SUPABASE_JWT_SECRET
        if not secret:
            # If secret not explicitly configured and in dev/test, decode claims without signature or test
            if ENVIRONMENT != "production":
                try:
                    payload = jwt.decode(token, options={"verify_signature": False})
                    return payload
                except Exception as e:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail=f"Invalid JWT token format: {str(e)}",
                    )
            else:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Server authentication configuration error",
                )

        try:
            # Supabase tokens are signed with HS256 using JWT Secret
            payload = jwt.decode(
                token,
                secret,
                algorithms=["HS256"],
                options={"verify_aud": False},
            )
            return payload
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication token has expired",
            )
        except jwt.InvalidTokenError as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid authentication token: {str(e)}",
            )

    # 3. Reject missing / invalid authentication
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Unauthorized: Valid Authorization Bearer JWT or X-API-KEY header is required",
    )


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Applies OWASP-recommended security headers to all HTTP responses."""

    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none';"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        return response


class RequestSizeLimitMiddleware(BaseHTTPMiddleware):
    """
    Enforces maximum request payload size:
    - 10MB for multipart image uploads (/api/v1/disease/predict)
    - 1MB for all other JSON API endpoints
    Returns HTTP 413 Payload Too Large if limit exceeded.
    """

    MAX_UPLOAD_SIZE = 10 * 1024 * 1024  # 10MB
    MAX_JSON_SIZE = 1 * 1024 * 1024    # 1MB

    async def dispatch(self, request: Request, call_next):
        content_length = request.headers.get("content-length")
        if content_length:
            try:
                length = int(content_length)
                max_allowed = (
                    self.MAX_UPLOAD_SIZE
                    if request.url.path.startswith("/api/v1/disease/predict")
                    else self.MAX_JSON_SIZE
                )
                if length > max_allowed:
                    return JSONResponse(
                        status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                        content={
                            "detail": f"Payload too large. Max allowed size is {max_allowed // (1024 * 1024)}MB."
                        },
                    )
            except ValueError:
                pass

        return await call_next(request)


class StructuredLoggingMiddleware(BaseHTTPMiddleware):
    """Logs incoming requests structured as JSON without leaking PII or credentials."""

    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        client_ip = request.client.host if request.client else "unknown"
        # Mask IP for privacy (e.g., 192.168.1.5 -> 192.168.xxx.xxx)
        ip_parts = client_ip.split(".")
        masked_ip = f"{ip_parts[0]}.{ip_parts[1]}.***.***" if len(ip_parts) == 4 else client_ip

        response = await call_next(request)
        duration_ms = round((time.time() - start_time) * 1000, 2)

        # Structured log entry
        log_entry = {
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "duration_ms": duration_ms,
            "client_ip": masked_ip,
        }
        logger.info(json.dumps(log_entry))
        return response

