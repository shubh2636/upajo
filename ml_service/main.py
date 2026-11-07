import os
from fastapi import FastAPI, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
from routers.crop_advisor import router as crop_advisor_router
from routers.disease_detection import router as disease_detection_router
from routers.krishi_sahayak import router as krishi_sahayak_router
from routers.mandi import router as mandi_router
from routers.yield_prediction import router as yield_prediction_router

app = FastAPI(
    title="Upajo ML & AI Farming Service",
    description="Microservice providing AI crop advisory, on-device/cloud plant disease detection, Claude-powered Krishi Sahayak chat, Agmarknet Mandi rates, and crop yield forecasting.",
    version="1.0.0",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_SECRET = os.getenv("ML_SERVICE_API_KEY", "upajo_internal_ml_secret_key")

def verify_api_key(x_api_key: Optional[str] = Header(None)):
    # Allow open access in local dev, enforce in production
    if os.getenv("ENVIRONMENT") == "production" and x_api_key != API_SECRET:
        raise HTTPException(status_code=401, detail="Unauthorized: Invalid internal API key")
    return True

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "Upajo ML Microservice",
        "version": "1.0.0",
        "endpoints": [
            "/api/v1/crop-advisor/recommend",
            "/api/v1/crop-advisor/seed-data",
            "/api/v1/disease/predict",
            "/api/v1/krishi-sahayak/chat",
            "/api/v1/mandi/prices",
            "/api/v1/mandi/price-suggestion",
            "/api/v1/analytics/yield-prediction",
        ]
    }

# Mount Feature Routers
app.include_router(crop_advisor_router)
app.include_router(disease_detection_router)
app.include_router(krishi_sahayak_router)
app.include_router(mandi_router)
app.include_router(yield_prediction_router)
