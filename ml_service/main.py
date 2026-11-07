import os
from fastapi import FastAPI, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional

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

class CropAdvisoryRequest(BaseModel):
    soil_type: str = Field(..., example="black_soil")
    land_area_acres: float = Field(..., gt=0, example=2.5)
    season: str = Field(..., example="rabi")
    water_source: str = Field(..., example="tube_well")
    district: Optional[str] = Field("Sehore", example="Sehore")
    state: Optional[str] = Field("Madhya Pradesh", example="Madhya Pradesh")

@app.post("/api/v1/crop-advisor", dependencies=[Depends(verify_api_key)])
def recommend_crop(req: CropAdvisoryRequest):
    # Foundation rule-based endpoint (expanded in Part 2)
    return {
        "recommended_crop_hi": "शरबती गेहूं (C-306)",
        "recommended_crop_en": "Sharbati Wheat",
        "variety": "C-306 / Sujata",
        "expected_yield_per_acre_quintal": 18.5,
        "total_expected_yield_quintal": round(req.land_area_acres * 18.5, 2),
        "confidence": 0.94,
        "calendar_summary": "सप्ताह 1: खेत की जुताई व पाटा लगाना; सप्ताह 3: बीज बोआई; सप्ताह 6: पहली सिंचाई (CRI चरण)"
    }

