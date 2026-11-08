"""
Upajo: Automated ML Retraining Pipeline with Candidate vs Champion Evaluation.
Implements spatial holdout testing, safety gating, shadow mode, and rollback prevention.
"""

import os
import json
import logging
from datetime import datetime
import numpy as np
import pandas as pd
import joblib
from sklearn.metrics import accuracy_score, f1_score, classification_report
from sklearn.ensemble import GradientBoostingClassifier, GradientBoostingRegressor

from train_crop_recommendation_and_quantile_yield import (
    generate_ground_truth_agronomic_dataset,
    HELD_OUT_DISTRICTS,
)

logger = logging.getLogger("upajo.ml.retraining")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

MODELS_DIR = os.path.dirname(os.path.abspath(__file__))
CHAMPION_MODEL_PATH = os.path.join(MODELS_DIR, "crop_recommendation_model.joblib")
CANDIDATE_MODEL_PATH = os.path.join(MODELS_DIR, "candidate_crop_recommendation_model.joblib")
METRICS_PATH = os.path.join(MODELS_DIR, "metrics_summary.json")


def load_champion_metrics() -> dict:
    if os.path.exists(METRICS_PATH):
        with open(METRICS_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {
        "models": {
            "gradient_boosting_champion": {"accuracy": 0.8428, "macro_f1": 0.6895}
        }
    }


def evaluate_model_on_held_out(model, X_test, y_test):
    preds = model.predict(X_test)
    probs = model.predict_proba(X_test)
    acc = accuracy_score(y_test, preds)
    macro_f1 = f1_score(y_test, preds, average="macro")

    # Per-crop F1
    report = classification_report(y_test, preds, output_dict=True, zero_division=0)
    per_crop_f1 = {crop: metrics["f1-score"] for crop, metrics in report.items() if crop in model.classes_}

    # Top-3 Accuracy
    classes = model.classes_
    top3_correct = 0
    for i, true_label in enumerate(y_test):
        top3_indices = np.argsort(probs[i])[-3:]
        top3_crops = [classes[idx] for idx in top3_indices]
        if true_label in top3_crops:
            top3_correct += 1
    top3_acc = top3_correct / len(y_test)

    return {
        "accuracy": float(acc),
        "macro_f1": float(macro_f1),
        "top3_accuracy": float(top3_acc),
        "per_crop_f1": per_crop_f1,
    }


def run_retraining_and_evaluation(feedback_df: pd.DataFrame = None, shadow_mode: bool = False):
    """
    Executes automated retraining workflow:
    1. Loads base agronomic dataset + farmer feedback.
    2. Trains Candidate model.
    3. Evaluates Candidate vs Champion on 12 held-out districts.
    4. Evaluates Safety Gates:
       - Gate 1: Candidate Macro F1 >= Champion Macro F1 - 0.01 (no overall regression)
       - Gate 2: No single crop F1 drops by > 0.03 (no individual crop sacrificed)
       - Gate 3: Top-3 Accuracy >= 0.95
    5. Decides promotion / shadow-mode / rollback.
    """
    logger.info("Starting ML Retraining Pipeline...")

    # Load baseline dataset
    base_df = generate_ground_truth_agronomic_dataset(n_samples=12000, seed=2026)
    
    # Merge feedback data if available
    if feedback_df is not None and not feedback_df.empty:
        logger.info(f"Incorporating {len(feedback_df)} farmer feedback records into training set.")
        train_pool = pd.concat([base_df[~base_df["is_held_out"]], feedback_df], ignore_index=True)
    else:
        logger.info("No external feedback records provided; evaluating candidate hyperparameter tuning.")
        train_pool = base_df[~base_df["is_held_out"]].copy()

    test_pool = base_df[base_df["is_held_out"]].copy()

    feature_cols = [
        "soil_n", "soil_p", "soil_k", "soil_ph",
        "seasonal_rainfall_mm", "mean_temperature_c",
        "soil_type", "water_source"
    ]

    X_train = train_pool[feature_cols]
    y_train = train_pool["recommended_crop"]
    X_test = test_pool[feature_cols]
    y_test = test_pool["recommended_crop"]

    # Load current Champion
    if not os.path.exists(CHAMPION_MODEL_PATH):
        raise FileNotFoundError(f"Champion model not found at {CHAMPION_MODEL_PATH}")

    champion_model = joblib.load(CHAMPION_MODEL_PATH)
    champion_eval = evaluate_model_on_held_out(champion_model, X_test, y_test)
    logger.info(f"Current Champion Evaluation: Acc={champion_eval['accuracy']:.4f}, Macro F1={champion_eval['macro_f1']:.4f}, Top-3={champion_eval['top3_accuracy']:.4f}")

    # Train Candidate Model (e.g. improved learning rate and regularization)
    from sklearn.compose import ColumnTransformer
    from sklearn.preprocessing import StandardScaler, OneHotEncoder
    from sklearn.pipeline import Pipeline

    preprocessor = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), ["soil_n", "soil_p", "soil_k", "soil_ph", "seasonal_rainfall_mm", "mean_temperature_c"]),
            ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), ["soil_type", "water_source"]),
        ]
    )

    candidate_model = Pipeline([
        ("preprocessor", preprocessor),
        ("classifier", GradientBoostingClassifier(n_estimators=110, max_depth=5, learning_rate=0.09, random_state=42))
    ])
    candidate_model.fit(X_train, y_train)

    candidate_eval = evaluate_model_on_held_out(candidate_model, X_test, y_test)
    logger.info(f"Candidate Evaluation: Acc={candidate_eval['accuracy']:.4f}, Macro F1={candidate_eval['macro_f1']:.4f}, Top-3={candidate_eval['top3_accuracy']:.4f}")

    # Safety Gating Checks
    passed_all_gates = True
    failure_reasons = []

    # Gate 1: Macro F1 >= Champion - 0.005
    if candidate_eval["macro_f1"] < champion_eval["macro_f1"] - 0.005:
        passed_all_gates = False
        failure_reasons.append(f"Gate 1 Failed: Candidate Macro F1 ({candidate_eval['macro_f1']:.4f}) is lower than Champion ({champion_eval['macro_f1']:.4f})")

    # Gate 2: No single crop F1 drops by > 3.0% (0.03)
    for crop, champ_f1 in champion_eval["per_crop_f1"].items():
        cand_f1 = candidate_eval["per_crop_f1"].get(crop, 0.0)
        if cand_f1 < champ_f1 - 0.03:
            passed_all_gates = False
            failure_reasons.append(f"Gate 2 Failed: Crop '{crop}' F1 regressed from {champ_f1:.4f} to {cand_f1:.4f} (drop > 0.03)")

    # Gate 3: Top-3 Accuracy >= 98%
    if candidate_eval["top3_accuracy"] < 0.98:
        passed_all_gates = False
        failure_reasons.append(f"Gate 3 Failed: Candidate Top-3 Accuracy {candidate_eval['top3_accuracy']:.4f} < 0.98")

    result = {
        "timestamp": datetime.utcnow().isoformat(),
        "passed_all_gates": passed_all_gates,
        "failure_reasons": failure_reasons,
        "champion_eval": champion_eval,
        "candidate_eval": candidate_eval,
        "action_taken": None,
    }

    if passed_all_gates:
        if shadow_mode:
            logger.info("Safety gates PASSED. Running Candidate in SHADOW MODE (logging predictions alongside Champion).")
            joblib.dump(candidate_model, CANDIDATE_MODEL_PATH)
            result["action_taken"] = "DEPLOYED_SHADOW_MODE"
        else:
            logger.info("Safety gates PASSED. PROMOTING Candidate to CHAMPION!")
            joblib.dump(candidate_model, CHAMPION_MODEL_PATH)
            result["action_taken"] = "PROMOTED_TO_CHAMPION"

            # Update metrics
            champion_metrics = load_champion_metrics()
            champion_metrics["models"]["gradient_boosting_champion"] = {
                "accuracy": candidate_eval["accuracy"],
                "macro_f1": candidate_eval["macro_f1"],
                "top3_accuracy": candidate_eval["top3_accuracy"],
            }
            champion_metrics["last_retrained"] = datetime.utcnow().isoformat()
            with open(METRICS_PATH, "w", encoding="utf-8") as f:
                json.dump(champion_metrics, f, indent=2, ensure_ascii=False)
    else:
        logger.warning(f"Safety gates FAILED. Candidate rejected. Retaining Champion.\nReasons:\n" + "\n".join(failure_reasons))
        result["action_taken"] = "REJECTED_RETAINED_CHAMPION"

    return result


if __name__ == "__main__":
    res = run_retraining_and_evaluation(shadow_mode=False)
    print("\nRetraining Pipeline Execution Result:")
    print(json.dumps(res, indent=2))

