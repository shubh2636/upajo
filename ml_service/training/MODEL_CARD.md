# Model Card: Upajo PlantVillage MobileNetV3 Crop Pathology Classifier

## 1. Model Details
* **Model Name**: `Upajo-PlantVillage-MobileNetV3-Small-INT8`
* **Version**: `1.0.0`
* **Architecture**: MobileNetV3-Small transfer learning with custom dense classification head (Dropout 0.3, Dense-Softmax).
* **Format**: TensorFlow Lite (`.tflite`) with INT8 post-training quantization.
* **Model Footprint**: 4.18 MB (optimized for low-end 2 GB RAM Android phones).
* **Inference Latency**: 38–48 ms on mid-tier chipsets (Snapdragon 680, MediaTek Helio G85).
* **License**: Apache 2.0 (weights fine-tuned from ImageNet and open-access PlantVillage dataset).

---

## 2. Intended Use & Users
* **Primary Use Case**: Rapid on-device leaf disease detection for Indian smallholder farmers without requiring continuous 4G/5G mobile connectivity.
* **Target Crops**:
  1. **Potato (आलू)**: Early Blight (*Alternaria solani*), Late Blight (*Phytophthora infestans*), Healthy.
  2. **Tomato (टमाटर)**: Bacterial Spot (*Xanthomonas*), Early Blight, Late Blight, Healthy.
  3. **Wheat (गेहूं)**: Brown / Leaf Rust (*Puccinia triticina*), Yellow / Stripe Rust (*Puccinia striiformis*).
  4. **Rice / Paddy (धान)**: Blast (*Magnaporthe oryzae*).
* **Out-of-Scope**: Soil-borne nematode infections, root rots (Rhizoctonia), whole-field aerial drone surveys, and post-harvest grain storage pests.

---

## 3. Dataset & Training Methodology
* **Base Dataset**: PlantVillage crop pathology dataset augmented with ICAR (Indian Council of Agricultural Research) field photographs.
* **Sample Count**: 18,450 annotated leaf images across 10 target classes.
* **Split**: 80% Training (14,760 images), 20% Validation (3,690 images).
* **Data Augmentations**:
  * Random 360-degree rotation and horizontal/vertical flips.
  * Contrast and brightness jittering to simulate bright sun and overcast monsoon lighting.
  * Zoom and crop to simulate camera distance variability in the field.
* **Training Hardware**: 1x NVIDIA A100 (40GB), total training time: 28 minutes.

---

## 4. Performance & Accuracy Limits

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

---

## 5. Known Failure Modes & Limitations
1. **Multiple Co-infections**: If a leaf exhibits both late blight and spider mite damage simultaneously, the model classifies the dominant visual symptom.
2. **Severe Overexposure / Motion Blur**: Direct harsh sunlight glare on wet leaves can cause misclassification between Bacterial Spot and Early Blight.
3. **Nutrient Deficiency Confusion**: Severe Nitrogen chlorosis (general leaf yellowing) can mimic early fungal yellowing.
4. **Offline Heuristics**: When ran in extreme low-memory environments, the app engages the rule-based agronomy fallback with exact safe chemical dosages.

---

## 6. Safety & Regulatory Guardrails
* **No Hazardous Pesticides**: Output remedies strictly exclude all banned WHO Class Ia/Ib and CIB&RC prohibited molecules (e.g., Endosulfan, Monocrotophos, Paraquat).
* **Standard Pump Dosages**: All chemical formulations are converted into standard 15-litre knapsack pump dilution ratios (e.g., 30g Mancozeb / 15L water).
* **Escalation**: Any scan marked as `severe` features a one-click direct dial to the **Government Kisan Call Center toll-free helpline: `1800-180-1551`**.
