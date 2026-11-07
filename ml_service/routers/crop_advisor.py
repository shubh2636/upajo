import os
import json
import uuid
from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/v1/crop-advisor", tags=["Crop Advisor"])

SEED_FILE_PATH = os.path.join(os.path.dirname(__file__), "..", "seed_crops.json")

def _load_crops():
    if not os.path.exists(SEED_FILE_PATH):
        return []
    with open(SEED_FILE_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
        return data.get("crops", [])

class CropAdvisoryRequest(BaseModel):
    soil_type: str = Field(..., example="black_soil", description="black_soil, sandy_loam, alluvial, red_soil, clay_loam")
    land_area_acres: float = Field(..., gt=0, example=2.5, description="Total land area in acres")
    season: str = Field(..., example="rabi", description="kharif, rabi, zaid")
    water_source: str = Field(..., example="tube_well", description="tube_well, canal, rainfed, drip_sprinkler")
    district: Optional[str] = Field("सीहोर", example="सीहोर")
    state: Optional[str] = Field("मध्य प्रदेश", example="मध्य प्रदेश")
    latitude: Optional[float] = Field(23.2032)
    longitude: Optional[float] = Field(77.0844)

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

class CropRecommendationResponse(BaseModel):
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
    calendar_schedule: List[CalendarTaskResponse]

@router.post("/recommend", response_model=CropRecommendationResponse)
def get_crop_recommendation(req: CropAdvisoryRequest):
    """
    Evaluates farmer's soil, season, irrigation, and agro-climatic parameters
    against ICAR compendium database to recommend optimal crop, variety, yield range,
    and a generated calendar schedule.
    """
    crops = _load_crops()
    if not crops:
        raise HTTPException(status_code=500, detail="Crop agronomy seed dataset not found.")

    # Rule-matching scoring algorithm
    best_crop = None
    best_score = -1.0

    for crop in crops:
        score = 0.0

        # Season match (Mandatory)
        if crop.get("season") == req.season:
            score += 40.0
        else:
            continue  # Must match season

        # Soil type match
        supported_soils = crop.get("soil_types", [])
        if req.soil_type in supported_soils:
            score += 30.0

        # Water source match
        supported_waters = crop.get("water_sources", [])
        if req.water_source in supported_waters:
            score += 20.0
        elif req.water_source == "rainfed" and "rainfed" not in supported_waters:
            score -= 25.0  # High penalty if water is needed but farmer has only rain

        # Bonus from base crop confidence
        score += float(crop.get("confidence", 0.90)) * 10.0

        if score > best_score:
            best_score = score
            best_crop = crop

    # Fallback to first crop in season if no exact match
    if not best_crop:
        for crop in crops:
            if crop.get("season") == req.season:
                best_crop = crop
                break
        if not best_crop:
            best_crop = crops[0]

    min_yield = float(best_crop.get("yield_per_acre_quintal_min", 15.0))
    max_yield = float(best_crop.get("yield_per_acre_quintal_max", 20.0))
    avg_yield = (min_yield + max_yield) / 2.0
    total_yield = round(avg_yield * req.land_area_acres, 1)

    # Generate calendar tasks with calculated due dates
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

    return CropRecommendationResponse(
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
        calendar_schedule=tasks_out,
    )

@router.get("/seed-data")
def get_seed_data():
    """
    Returns full ICAR seed data catalog and expansion documentation for SAUs / KVKs.
    """
    if not os.path.exists(SEED_FILE_PATH):
        raise HTTPException(status_code=404, detail="Seed data file not found")
    with open(SEED_FILE_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

