import os
import logging
from typing import Optional, List
from fastapi import FastAPI, HTTPException, Header, Depends, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

from security import (
    SecurityHeadersMiddleware,
    RequestSizeLimitMiddleware,
    StructuredLoggingMiddleware,
    verify_supabase_jwt_or_api_key,
)
from routers.crop_advisor import router as crop_advisor_router
from routers.disease_detection import router as disease_detection_router
from routers.krishi_sahayak import router as krishi_sahayak_router
from routers.mandi import router as mandi_router
from routers.yield_prediction import router as yield_prediction_router

logger = logging.getLogger("upajo.main")

app = FastAPI(
    title="Upajo ML & AI Farming Service",
    description="Hardened microservice providing AI crop advisory, plant disease detection, Krishi Sahayak chat, Agmarknet Mandi rates, and crop yield forecasting.",
    version="1.0.0",
)

# CORS Allow-list Configuration (Strict: No wildcard "*" with credentials)
raw_origins = os.getenv("ALLOWED_ORIGINS", "")
if raw_origins:
    ALLOWED_ORIGINS = [orig.strip() for orig in raw_origins.split(",") if orig.strip()]
else:
    ALLOWED_ORIGINS = [
        "http://localhost:3000",
        "http://localhost:8000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000",
        "https://upajo.com",
        "https://app.upajo.com",
        "capacitor://localhost",
    ]

# Register Middlewares (Order of execution: outermost to innermost)
app.add_middleware(StructuredLoggingMiddleware)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RequestSizeLimitMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-API-KEY", "Accept"],
)

REQUIRED_PRODUCTION_SECRETS = [
    "ML_SERVICE_API_KEY",
    "SUPABASE_URL",
    "SUPABASE_SERVICE_ROLE_KEY",
    "ANTHROPIC_API_KEY",
    "SUPABASE_JWT_SECRET",
]


@app.on_event("startup")
def startup_secret_validation():
    """Fails loudly if required server secrets are missing or set to dummy placeholders in production."""
    env = os.getenv("ENVIRONMENT", "development").lower()
    if env == "production":
        missing_or_placeholder = []
        for key in REQUIRED_PRODUCTION_SECRETS:
            val = os.getenv(key, "").strip()
            if not val or "placeholder" in val.lower() or "your-" in val.lower() or val == "upajo_internal_ml_secret_key":
                missing_or_placeholder.append(key)
        if missing_or_placeholder:
            raise RuntimeError(
                f"FATAL: Production startup aborted! Missing or placeholder secrets: {', '.join(missing_or_placeholder)}"
            )


# Global Exception Handlers (Never leak stack traces or internal server details)
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Internal unhandled exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "An internal server error occurred. Please try again later.",
            "error_code": "INTERNAL_SERVER_ERROR",
        },
    )


@app.exception_handler(HTTPException)
async def custom_http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers=exc.headers or {},
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for err in exc.errors():
        field = ".".join(str(loc) for loc in err.get("loc", []))
        errors.append({"field": field, "message": err.get("msg")})
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": "Request validation failed", "errors": errors},
    )


# Public Health Check
@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "Upajo ML Microservice",
        "version": "1.0.0",
        "security": {
            "jwt_auth": "enforced",
            "cors_allowlist": ALLOWED_ORIGINS,
            "security_headers": "active",
            "request_size_limits": "active",
        },
        "endpoints": [
            "/api/v1/crop-advisor/recommend",
            "/api/v1/crop-advisor/seed-data",
            "/api/v1/disease/predict",
            "/api/v1/krishi-sahayak/chat",
            "/api/v1/mandi/prices",
            "/api/v1/mandi/price-suggestion",
            "/api/v1/analytics/yield-prediction",
        ],
    }


# Mount Feature Routers
app.include_router(crop_advisor_router)
app.include_router(disease_detection_router)
app.include_router(krishi_sahayak_router)
app.include_router(mandi_router)
app.include_router(yield_prediction_router)
