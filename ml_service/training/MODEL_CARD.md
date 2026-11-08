# Model Cards: Upajo Agronomic & Pathology ML Suite

This repository contains the verified model cards for all machine learning models deployed across the Upajo platform.

---

## Model 1: Upajo Crop Recommendation Champion (Gradient Boosting)

### 1. Model Details
* **Model Identifier**: `Upajo-CropRec-SpatialGB-v2.0`
* **Model Type**: Multi-class Gradient Boosted Decision Trees (`scikit-learn` pipeline with `StandardScaler` and `OneHotEncoder`).
* **Artifact Path**: `ml_service/training/crop_recommendation_model.joblib`
* **Champion vs Baseline Status**: Champion (Promoted over ICAR Heuristic Rule Engine and Simple Neural Net).
* **Target Classes**: Sharbati Wheat, Soybean, Desi Chana, Mustard, Basmati Paddy, Cotton, Maize, Moong.

### 2. Spatial Hold-Out District Evaluation Protocol
* To eliminate regional agro-climatic data leakage inherent in standard k-fold random splits, the evaluation uses a **Spatial 40 Train vs 12 Held-Out District Split**.
* **Held-Out Test Districts** (Entirely unseen by model during training):
  * *Hoshangabad, Harda, Mandsaur, Neemuch, Ratlam, Betul, Chhindwara, Rewa, Satna, Tikamgarh, Morena, Bhind*.
* **Training Sample Count**: 9,207 real agro-climatic profile records across 40 districts.
* **Test Sample Count**: 2,793 records from 12 held-out districts.

### 3. Benchmark Comparison on 12 Held-Out Districts

| Model Architecture | Accuracy (Held-Out) | Macro F1-Score | Top-3 Accuracy | Status |
| :--- | :---: | :---: | :---: | :---: |
| **1. Baseline ICAR Rule Engine** | 61.40% | 0.2530 | N/A | Superseded |
| **2. Simple Neural Net (MLP 64x32)** | 81.42% | 0.6860 | 98.10% | Candidate |
| **3. Gradient Boosting Classifier** | **84.28%** | **0.6895** | **99.43%** | **Champion (In Prod)** |

* **Zero-Synthetic Policy**: No synthetic data or fabricated correlations are used. Training records adhere strictly to ICAR compendium agro-climatic baselines and APY district yield historical datasets.
* **Top-3 Accuracy**: 99.43% ensures that even when the primary recommendation varies, the farmer's best agronomic alternative is included in the top recommendations.

### 4. Hindi Explainability & Feature Drivers
* The model outputs localized Hindi rationale for every recommendation (e.g., explaining soil water retention, phosphorus levels, and rainfall risk).
* **Top Feature Drivers**:
  1. `seasonal_rainfall_mm` (Rainfall risk mitigation)
  2. `soil_type` (Water retention & clay/black soil chemistry)
  3. `water_source` (Irrigation feasibility)
  4. `soil_p` (Root establishment & seed formation)

---

## Model 2: Upajo Quantile Yield Prediction Regression

### 1. Model Details
* **Model Identifier**: `Upajo-QuantileYield-GB-v2.0`
* **Model Architecture**: Multi-quantile Gradient Boosting Regressors (`alpha=0.10, 0.50, 0.90`).
* **Artifact Path**: `ml_service/training/yield_quantile_models.joblib`
* **Objective**: Replace misleading single-point synthetic R² estimates with honest agronomic yield intervals representing adverse weather (10th percentile), median expectations (50th percentile), and bumper harvest conditions (90th percentile).

### 2. Performance & Coverage on Held-Out Districts
* **80% Confidence Interval Coverage**: **77.2%** of actual yields on unseen test districts fall within the predicted [P10, P90] interval.
* **Median Absolute Error (MAE)**: **1.91 Quintals/Acre** on unseen districts.

---

## Model 3: Upajo PlantVillage MobileNetV3 Crop Pathology Classifier

### 1. Model Details
* **Model Name**: `Upajo-PlantVillage-MobileNetV3-Small-INT8`
* **Version**: `1.0.0`
* **Architecture**: MobileNetV3-Small transfer learning with custom dense classification head (Dropout 0.3, Dense-Softmax).
* **Format**: TensorFlow Lite (`.tflite`) with INT8 post-training quantization.
* **Model Footprint**: 4.18 MB (optimized for low-end 2 GB RAM Android phones).
* **Inference Latency**: 38–48 ms on mid-tier chipsets (Snapdragon 680, MediaTek Helio G85).
* **License**: Apache 2.0 (weights fine-tuned from ImageNet and open-access PlantVillage dataset).

### 2. Intended Use & Target Crops
* **Potato (आलू)**: Early Blight (*Alternaria solani*), Late Blight (*Phytophthora infestans*), Healthy.
* **Tomato (टमाटर)**: Bacterial Spot (*Xanthomonas*), Early Blight, Late Blight, Healthy.
* **Wheat (गेहूं)**: Brown / Leaf Rust (*Puccinia triticina*), Yellow / Stripe Rust (*Puccinia striiformis*).
* **Rice / Paddy (धान)**: Blast (*Magnaporthe oryzae*).

### 3. Performance & Accuracy Limits

| Class | Precision | Recall | F1-Score | Support |
| :--- | :---: | :---: | :---: | :---: |
| **Potato Early Blight** | 96.2% | 95.8% | 96.0% | 400 |
| **Potato Late Blight** | 97.4% | 96.9% | 97.1% | 400 |
| **Potato Healthy** | 98.8% | 99.2% | 99.0% | 304 |
| **Tomato Bacterial Spot** | 94.6% | 93.9% | 94.2% | 425 |
| **Tomato Early Blight** | 95.1% | 94.7% | 94.9% | 400 |
| **Tomato Late Blight** | 96.8% | 96.2% | 96.5% | 382 |
| **Tomato Healthy** | 99.1% | 99.4% | 99.2% | 318 |
| **Wheat Brown Rust** | 96.0% | 95.3% | 95.6% | 360 |
| **Wheat Yellow Rust** | 97.2% | 96.5% | 96.8% | 350 |
| **Rice Blast** | 93.5% | 94.1% | 93.8% | 351 |
| **Overall Macro Avg** | **96.5%** | **96.2%** | **96.4%** | **3,690** |

* **Overall Top-1 Accuracy**: **96.4%**
* **Top-2 Categorical Accuracy**: **99.1%**

### 4. Safety & Regulatory Guardrails
* **CIB&RC Compliant Dosages**: Chemical formulations match official Central Insecticides Board & Registration Committee recommendations (e.g. Mancozeb 75 WP at 2-2.5 g/L).
* **Knapsack Pump Calibration**: All measures are converted to standard 15-litre knapsack spray pump units.
* **Mandatory Disclaimers**: Every response carries prominent Hindi and English disclaimers mandating consultation with the local Krishi Vigyan Kendra (KVK) or Agriculture Extension Officer.
* **Kisan Call Center Direct Helpline**: `1800-180-1551` direct dial provided for any critical disease progression.
