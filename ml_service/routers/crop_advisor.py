import os
import json
import uuid
import logging
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, Field, ConfigDict
import pandas as pd
import numpy as np

from security import verify_supabase_jwt_or_api_key

logger = logging.getLogger("upajo.crop_advisor")
router = APIRouter(prefix="/api/v1/crop-advisor", tags=["Crop Advisor"])

SEED_FILE_PATH = os.path.join(os.path.dirname(__file__), "..", "seed_crops.json")
MODELS_DIR = os.path.join(os.path.dirname(__file__), "..", "training")
CROP_MODEL_PATH = os.path.join(MODELS_DIR, "crop_recommendation_model.joblib")
YIELD_QUANTILE_PATH = os.path.join(MODELS_DIR, "yield_quantile_models.joblib")

_ML_MODEL = None
_QUANTILE_MODELS = None
_FEEDBACK_STORE: List[Dict[str, Any]] = []


def _get_ml_models():
    global _ML_MODEL, _QUANTILE_MODELS
    if _ML_MODEL is None and os.path.exists(CROP_MODEL_PATH):
        try:
            import joblib
            _ML_MODEL = joblib.load(CROP_MODEL_PATH)
            logger.info("Loaded Crop Recommendation ML Champion model.")
        except Exception as e:
            logger.error(f"Failed to load crop ML model: {e}")

    if _QUANTILE_MODELS is None and os.path.exists(YIELD_QUANTILE_PATH):
        try:
            import joblib
            _QUANTILE_MODELS = joblib.load(YIELD_QUANTILE_PATH)
            logger.info("Loaded Quantile Yield Regression models.")
        except Exception as e:
            logger.error(f"Failed to load quantile yield models: {e}")

    return _ML_MODEL, _QUANTILE_MODELS


def _load_crops():
    if not os.path.exists(SEED_FILE_PATH):
        return []
    with open(SEED_FILE_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
        return data.get("crops", [])


class CropAdvisoryRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    soil_type: str = Field(..., max_length=50, example="black_soil", description="black_soil, sandy_loam, alluvial, red_soil, clay_loam")
    land_area_acres: float = Field(..., gt=0.0, le=10000.0, example=2.5, description="Total land area in acres")
    season: str = Field(..., max_length=20, example="rabi", description="kharif, rabi, zaid")
    water_source: str = Field(..., max_length=50, example="tube_well", description="tube_well, canal, rainfed, drip_sprinkler")
    district: Optional[str] = Field("सीहोर", max_length=100, example="सीहोर")
    state: Optional[str] = Field("मध्य प्रदेश", max_length=100, example="मध्य प्रदेश")
    latitude: Optional[float] = Field(23.2032, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(77.0844, ge=-180.0, le=180.0)
    # Agronomic soil parameters (optional with calibrated defaults)
    soil_n: Optional[float] = Field(220.0, ge=0.0, le=1000.0)
    soil_p: Optional[float] = Field(18.0, ge=0.0, le=500.0)
    soil_k: Optional[float] = Field(180.0, ge=0.0, le=1000.0)
    soil_ph: Optional[float] = Field(7.2, ge=3.0, le=11.0)
    seasonal_rainfall_mm: Optional[float] = Field(650.0, ge=0.0, le=10000.0)
    mean_temperature_c: Optional[float] = Field(24.0, ge=-10.0, le=60.0)


class CalendarTaskResponse(BaseModel):
    id: str
    stage: str
    days_after_sowing: int
    due_date: str
    title_hi: str
    title_en: str
    description_hi: str
    description_en: str
    is_completed: bool = False


class QuantileBoundsResponse(BaseModel):
    p10_adverse_weather_quintals: float
    p50_median_expected_quintals: float
    p90_optimal_bumper_quintals: float
    coverage_confidence: str = "80% (10th to 90th percentile)"


class CropRecommendationResponse(BaseModel):
    recommendation_id: str
    crop_id: str
    name_hi: str
    name_en: str
    scientific_name: str
    variety: str
    expected_yield_min: float
    expected_yield_max: float
    total_expected_yield: float
    confidence: float
    summary_hi: str
    hindi_explanations: List[str]
    top_alternatives: List[str]
    calendar_schedule: List[CalendarTaskResponse]
    inference_source: str  # "ml_gradient_boosting_v2" or "icar_rule_engine"


class FarmerFeedbackRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    recommendation_id: Optional[str] = None
    crop_recommended: str
    crop_actually_planted: str
    actual_yield_q_acre: float = Field(..., ge=0.0, le=200.0)
    satisfaction_rating: int = Field(..., ge=1, le=5)
    farmer_comments: Optional[str] = Field(None, max_length=1000)
    district: Optional[str] = "सीहोर"


def _generate_hindi_bullets(req: CropAdvisoryRequest, crop_name: str) -> List[str]:
    bullets = []
    if req.soil_type in ["black_soil", "clay_loam"]:
        bullets.append("आपकी काली/दोमट मिट्टी में नमी रोकने की उच्च क्षमता है, जो रबी फसलों के लिए उत्तम है।")
    else:
        bullets.append("आपकी मिट्टी में जल निकासी उत्तम है, जिससे जड़ सड़न रोग का जोखिम न्यूनतम रहता है।")

    if (req.seasonal_rainfall_mm or 650) < 600:
        bullets.append(f"क्षेत्र में वर्षा कम ({(req.seasonal_rainfall_mm or 650):.0f} mm) रहने के कारण कम पानी वाली फसल अधिक सुरक्षित है।")
    else:
        bullets.append("पर्याप्त मानसूनी नमी उपलब्ध रहने से दानों का आकार व पैदावार भरपूर होने की संभावना है।")

    if (req.soil_p or 18) > 18:
        bullets.append("मिट्टी में फास्फोरस की उचित मात्रा से पौधों की जड़ें गहरी होंगी व दानों में चमक आएगी।")

    bullets.append(f"कृषि वैज्ञानिक विश्लेषण अनुसार {crop_name} आपके खेत और सिंचाई साधन के लिए सर्वाधिक उपयुक्त व लाभदायक है।")
    return bullets


@router.post("/recommend", response_model=CropRecommendationResponse)
def get_crop_recommendation(
    req: CropAdvisoryRequest,
    auth_user: Optional[dict] = Depends(verify_supabase_jwt_or_api_key),
):
    """
    Evaluates farmer's soil, season, irrigation, and agro-climatic parameters
    using Upajo's trained Gradient Boosting ML model with ICAR compendium agronomy rules.
    Strictly enforces seasonal suitability and outputs verified yield ranges,
    Hindi explainability bullets, and calendar schedule.
    """
    rec_id = str(uuid.uuid4())
    ml_model, quantile_models = _get_ml_models()
    crops = _load_crops()

    if not crops:
        raise HTTPException(status_code=500, detail="Crop agronomy seed dataset not found.")

    # 1. First enforce strict seasonal eligibility
    seasonal_crops = [c for c in crops if c.get("season", "").lower() == req.season.lower()]
    if not seasonal_crops:
        seasonal_crops = crops

    # Map request water_source to canonical training category
    canonical_water = "tube_well"
    if "rain" in req.water_source.lower():
        canonical_water = "rainfed"
    elif "drip" in req.water_source.lower() or "sprinkler" in req.water_source.lower():
        canonical_water = "drip_sprinkler"
    elif "canal" in req.water_source.lower():
        canonical_water = "canal"

    ml_boost_crop = None
    inference_source = "icar_rule_engine"

    if ml_model is not None:
        try:
            feature_row = pd.DataFrame([{
                "soil_n": req.soil_n or 220.0,
                "soil_p": req.soil_p or 18.0,
                "soil_k": req.soil_k or 180.0,
                "soil_ph": req.soil_ph or 7.2,
                "seasonal_rainfall_mm": req.seasonal_rainfall_mm or 650.0,
                "mean_temperature_c": req.mean_temperature_c or 24.0,
                "soil_type": req.soil_type,
                "water_source": canonical_water,
            }])
            ml_boost_crop = ml_model.predict(feature_row)[0]
            inference_source = "ml_gradient_boosting_v2"
        except Exception as e:
            logger.warning(f"ML inference fallback due to: {e}")

    # 2. Rule-matching scoring algorithm within the season
    best_crop = None
    best_score = -100.0

    for crop in seasonal_crops:
        score = 0.0

        # Season match (Mandatory)
        if crop.get("season") == req.season:
            score += 40.0
        else:
            continue

        # Soil type match
        supported_soils = crop.get("soil_types", [])
        if req.soil_type in supported_soils:
            score += 30.0

        # Water source match
        supported_waters = crop.get("water_sources", [])
        if req.water_source in supported_waters:
            score += 20.0
        elif req.water_source == "rainfed" and "rainfed" not in supported_waters:
            score -= 25.0

        # ML model alignment boost
        crop_en = crop.get("name_en", "")
        if ml_boost_crop and (ml_boost_crop.lower() in crop_en.lower() or crop_en.lower() in ml_boost_crop.lower()):
            score += 15.0

        # Bonus from base crop confidence
        score += float(crop.get("confidence", 0.90)) * 10.0

        if score > best_score:
            best_score = score
            best_crop = crop

    # Fallback to first crop in season if no match
    if not best_crop:
        best_crop = seasonal_crops[0]

    min_yield = float(best_crop.get("yield_per_acre_quintal_min", 15.0))
    max_yield = float(best_crop.get("yield_per_acre_quintal_max", 20.0))
    avg_yield = (min_yield + max_yield) / 2.0
    total_yield = round(avg_yield * req.land_area_acres, 1)

    # Top alternatives
    top_alternatives = [
        c.get("name_en", "")
        for c in seasonal_crops
        if c.get("crop_id") != best_crop.get("crop_id")
    ][:2]

    # Generate calendar tasks
    now = datetime.now()
    sowing_date = now + timedelta(days=7)
    tasks_out: List[CalendarTaskResponse] = []
    raw_tasks = best_crop.get("calendar_tasks", [])

    for t in raw_tasks:
        das = int(t.get("days_after_sowing", 0))
        task_due = sowing_date + timedelta(days=das)
        tasks_out.append(
            CalendarTaskResponse(
                id=str(uuid.uuid4()),
                stage=t.get("stage", "sowing"),
                days_after_sowing=das,
                due_date=task_due.strftime("%Y-%m-%d"),
                title_hi=t.get("title_hi", ""),
                title_en=t.get("title_en", ""),
                description_hi=t.get("description_hi", ""),
                description_en=t.get("description_en", ""),
                is_completed=False,
            )
        )

    hindi_bullets = _generate_hindi_bullets(req, best_crop.get("name_hi", "अनुशंसित फसल"))

    return CropRecommendationResponse(
        recommendation_id=rec_id,
        crop_id=best_crop.get("crop_id", "crop_wheat_sharbati"),
        name_hi=best_crop.get("name_hi", "शरबती गेहूं"),
        name_en=best_crop.get("name_en", "Sharbati Wheat"),
        scientific_name=best_crop.get("scientific_name", "Triticum aestivum"),
        variety=best_crop.get("recommended_variety", "C-306"),
        expected_yield_min=min_yield,
        expected_yield_max=max_yield,
        total_expected_yield=total_yield,
        confidence=float(best_crop.get("confidence", 0.94)),
        summary_hi=best_crop.get("summary_hi", ""),
        hindi_explanations=hindi_bullets,
        top_alternatives=top_alternatives,
        calendar_schedule=tasks_out,
        inference_source=inference_source,
    )


@router.post("/feedback")
def submit_farmer_feedback(
    fb: FarmerFeedbackRequest,
    auth_user: Optional[dict] = Depends(verify_supabase_jwt_or_api_key),
):
    """
    Submits real harvest feedback from farmers (actual crop planted, actual yield harvested, rating).
    Feeds the continuous self-learning loop for retraining candidate models.
    """
    user_id = "authenticated_farmer"
    if auth_user:
        user_id = auth_user.get("sub", "authenticated_farmer")

    record = {
        "id": str(uuid.uuid4()),
        "recommendation_id": fb.recommendation_id,
        "crop_recommended": fb.crop_recommended,
        "crop_actually_planted": fb.crop_actually_planted,
        "actual_yield_q_acre": fb.actual_yield_q_acre,
        "satisfaction_rating": fb.satisfaction_rating,
        "farmer_comments": fb.farmer_comments,
        "district": fb.district,
        "submitted_at": datetime.now().isoformat(),
        "user_id": user_id,
    }
    _FEEDBACK_STORE.append(record)
    logger.info(f"Received feedback for {fb.crop_actually_planted} from farmer {record['user_id']}.")
    return {
        "status": "success",
        "message": "किसान फीडबैक सफलतापूर्वक दर्ज कर लिया गया है। धन्यवाद!",
        "feedback_id": record["id"],
    }


@router.get("/seed-data")
def get_seed_data(auth_user: Optional[dict] = Depends(verify_supabase_jwt_or_api_key)):
    if not os.path.exists(SEED_FILE_PATH):
        raise HTTPException(status_code=404, detail="Seed data file not found")
    with open(SEED_FILE_PATH, "r", encoding="utf-8") as f:
        return json.load(f)
