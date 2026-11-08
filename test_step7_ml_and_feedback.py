import sys
import os
import unittest

os.environ["ML_SERVICE_API_KEY"] = "upajo_internal_ml_secret_key"
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "ml_service"))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "ml_service", "training"))

import security
security.ML_SERVICE_API_KEY = "upajo_internal_ml_secret_key"

from fastapi.testclient import TestClient
from main import app
from training.retraining_pipeline import run_retraining_and_evaluation, load_champion_metrics

client = TestClient(app)
API_HEADERS = {"X-API-KEY": "upajo_internal_ml_secret_key"}


class TestStep7MLAndFeedback(unittest.TestCase):
    def test_champion_metrics_exist(self):
        metrics = load_champion_metrics()
        self.assertIn("models", metrics)
        champ = metrics["models"]["gradient_boosting_champion"]
        self.assertGreater(champ["accuracy"], 0.80)
        self.assertGreater(champ["top3_accuracy"], 0.95)

    def test_crop_recommendation_endpoint(self):
        payload = {
            "soil_type": "black_soil",
            "land_area_acres": 3.0,
            "season": "rabi",
            "water_source": "tube_well",
            "district": "सीहोर",
            "soil_n": 240.0,
            "soil_p": 22.0,
            "soil_k": 190.0,
            "soil_ph": 7.4,
            "seasonal_rainfall_mm": 600.0,
            "mean_temperature_c": 22.0,
        }
        res = client.post("/api/v1/crop-advisor/recommend", json=payload, headers=API_HEADERS)
        self.assertEqual(res.status_code, 200, res.text)
        data = res.json()
        self.assertIn("recommendation_id", data)
        self.assertIn("name_en", data)
        self.assertGreater(data["confidence"], 0.5)
        self.assertGreater(data["total_expected_yield"], 0.0)
        self.assertGreater(len(data["hindi_explanations"]), 0)
        self.assertIn(data["inference_source"], ["ml_gradient_boosting_v2", "icar_rule_engine"])
        self.assertGreater(len(data["calendar_schedule"]), 0)

    def test_farmer_feedback_endpoint(self):
        payload = {
            "crop_recommended": "Sharbati Wheat",
            "crop_actually_planted": "Sharbati Wheat",
            "actual_yield_q_acre": 17.5,
            "satisfaction_rating": 5,
            "farmer_comments": "बहुत अच्छी सलाह थी, उपज शानदार रही।",
            "district": "सीहोर",
        }
        res = client.post("/api/v1/crop-advisor/feedback", json=payload, headers=API_HEADERS)
        self.assertEqual(res.status_code, 200, res.text)
        data = res.json()
        self.assertEqual(data["status"], "success")
        self.assertIn("feedback_id", data)

    def test_quantile_yield_prediction_endpoint(self):
        payload = {
            "crop_name": "Wheat (शरबती)",
            "soil_type": "black_soil",
            "land_area_acres": 4.0,
            "irrigation_type": "drip_irrigation",
            "rainfall_mm": 520.0,
            "fertilizer_n_kg_per_acre": 55.0,
            "fertilizer_p_kg_per_acre": 25.0,
            "fertilizer_k_kg_per_acre": 20.0,
            "organic_farming": False,
        }
        res = client.post("/api/v1/analytics/yield-prediction", json=payload, headers=API_HEADERS)
        self.assertEqual(res.status_code, 200, res.text)
        data = res.json()
        self.assertIn("quantile_bounds", data)
        qb = data["quantile_bounds"]
        self.assertGreater(qb["p50_median_expected_quintals"], 0.0)
        self.assertGreaterEqual(qb["p90_optimal_bumper_quintals"], qb["p10_adverse_weather_quintals"])
        self.assertEqual(qb["confidence_interval_coverage"], "80% (10th to 90th percentile)")


if __name__ == "__main__":
    unittest.main()
