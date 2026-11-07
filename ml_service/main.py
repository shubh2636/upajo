import os
from fastapi import FastAPI, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
from routers.crop_advisor import router as crop_advisor_router

app = FastAPI(
    title="Upajo ML & AI Farming Service",
    description="Microservice providing AI crop advisory, on-device/cloud plant disease detection, and Claude-powered Krishi Sahayak chat.",
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
        "version": "1.0.0"
    }

# Mount Feature Routers
app.include_router(crop_advisor_router)
