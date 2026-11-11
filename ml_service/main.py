import os
import logging
from typing import Optional, List
from dotenv import load_dotenv

# Load environment from ml_service/.env or root .env
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"))
from fastapi import FastAPI, HTTPException, Header, Depends, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.openapi.docs import get_swagger_ui_html
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
    docs_url=None,
    redoc_url=None,
)

# Mount local static assets for completely offline Swagger UI
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

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


# Offline-Capable Swagger UI Documentation
@app.get("/docs", include_in_schema=False, response_class=HTMLResponse)
@app.get("/docs/", include_in_schema=False, response_class=HTMLResponse)
async def custom_swagger_ui_html():
    return HTMLResponse(
        """<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link type="text/css" rel="stylesheet" href="/static/swagger-ui.css">
    <link rel="shortcut icon" href="https://fastapi.tiangolo.com/img/favicon.png">
    <title>Upajo (उपजो) ML & AI Farming Service - API Docs</title>
    <style>
        html { box-sizing: border-box; overflow-y: scroll; }
        *, *:before, *:after { box-sizing: inherit; }
        body { margin: 0; background: #fafafa; }
    </style>
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="/static/swagger-ui-bundle.js"></script>
    <script>
    function initSwagger() {
        if (typeof SwaggerUIBundle === "undefined") {
            setTimeout(initSwagger, 50);
            return;
        }
        window.ui = SwaggerUIBundle({
            url: "/openapi.json",
            dom_id: "#swagger-ui",
            deepLinking: true,
            layout: "BaseLayout",
            presets: [
                SwaggerUIBundle.presets.apis
            ]
        });
    }
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initSwagger);
    } else {
        initSwagger();
    }
    </script>
</body>
</html>"""
    )


# Visual HTML Dashboard at Root (Zero JavaScript Required)
@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def root_dashboard():
    return """
    <!DOCTYPE html>
    <html lang="hi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>उपजो (Upajo) - Backend ML & AI Service</title>
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background-color: #FAF7F0; color: #2E1F14; padding: 32px 16px; }
            .container { max-width: 800px; margin: 0 auto; }
            .header { background: #25603A; color: white; padding: 24px; border-radius: 16px; margin-bottom: 24px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
            .badge { display: inline-block; background: #4ADE80; color: #07140B; font-weight: bold; font-size: 12px; padding: 4px 10px; border-radius: 999px; margin-bottom: 8px; }
            h1 { font-size: 26px; margin-bottom: 6px; }
            p { font-size: 15px; opacity: 0.95; line-height: 1.5; }
            .card { background: white; border: 1.5px solid #E2D7C3; border-radius: 14px; padding: 20px; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
            .card h2 { font-size: 18px; margin-bottom: 12px; color: #1B492C; display: flex; align-items: center; gap: 8px; }
            .endpoint { background: #F2ECE1; padding: 10px 14px; border-radius: 8px; font-family: monospace; font-size: 14px; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center; }
            .method { font-weight: bold; padding: 2px 8px; border-radius: 4px; font-size: 12px; }
            .post { background: #BBF7D0; color: #143721; }
            .get { background: #FEF08A; color: #663F05; }
            .btn { display: inline-block; background: #D8972C; color: #180F08; font-weight: bold; text-decoration: none; padding: 12px 24px; border-radius: 10px; margin-top: 8px; margin-right: 8px; }
            .btn:hover { background: #B3781A; }
            .btn-outline { background: white; border: 2px solid #25603A; color: #25603A; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <span class="badge">● LIVE & HEALTHY</span>
                <h1>उपजो (Upajo) Backend ML & AI Service</h1>
                <p>भारतीय किसानों के लिए आर्टिफिशियल इंटेलिजेंस, फसल परामर्श, मंडी भाव और पादप रोग पहचान सेवा।</p>
                <div style="margin-top: 16px;">
                    <a href="/docs" class="btn">🚀 Interactive Swagger API Docs (/docs)</a>
                    <a href="/health" class="btn btn-outline">❤️ Check Health JSON (/health)</a>
                </div>
            </div>

            <div class="card">
                <h2>🌾 Active AI/ML Microservice Endpoints</h2>
                <div class="endpoint">
                    <span><strong>फसल सलाहकार AI (Crop Advisory)</strong>: /api/v1/crop-advisor/recommend</span>
                    <span class="method post">POST</span>
                </div>
                <div class="endpoint">
                    <span><strong>पादप रोग पहचान (Disease Scan)</strong>: /api/v1/disease/predict</span>
                    <span class="method post">POST</span>
                </div>
                <div class="endpoint">
                    <span><strong>कृषि सहायक AI चैट (Krishi Sahayak Chat)</strong>: /api/v1/krishi-sahayak/chat</span>
                    <span class="method post">POST</span>
                </div>
                <div class="endpoint">
                    <span><strong>एगमार्कनेट मंडी भाव (Mandi Rates)</strong>: /api/v1/mandi/prices</span>
                    <span class="method get">GET</span>
                </div>
                <div class="endpoint">
                    <span><strong>उपज पूर्वानुमान (Yield Forecast)</strong>: /api/v1/analytics/yield-prediction</span>
                    <span class="method post">POST</span>
                </div>
            </div>
        </div>
    </body>
    </html>
    """


# Mount Feature Routers
app.include_router(crop_advisor_router)
app.include_router(disease_detection_router)
app.include_router(krishi_sahayak_router)
app.include_router(mandi_router)
app.include_router(yield_prediction_router)
