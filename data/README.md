# Upajo (उपजो) - Agricultural Data Plan & Data Collection Protocol

## 1. Overview & Regulatory Framework
This document specifies the data sourcing, ingestion standards, and validation protocols for the **Upajo Crop Recommendation and Quantile Yield Prediction Engine**.

In accordance with Indian agricultural reality and the **Digital Agriculture Mission (AgriStack)** guidelines, model training strictly uses authenticated ground-truth agronomic datasets from recognized public agricultural universities and government portals.

---

## 2. Authenticated Data Sources
The training datasets are sourced from:

1. **ICAR Package of Practices for Madhya Pradesh (Central Zone)**:
   - **JNKVV (Jawaharlal Nehru Krishi Vishwavidyalaya, Jabalpur)**: Crop variety yield potentials, irrigation schedules, and nutrient response curves for Malwa, Nimar, Bundelkhand, and Vindhyan plateau.
   - **RVSKVV (Rajmata Vijayaraje Scindia Krishi Vishwa Vidyalaya, Gwalior)**: Soil-crop suitability matrices and drought-tolerant cultivars.
2. **Ministry of Agriculture & Farmers Welfare (MoAFW)**:
   - **DAC&FW Crop Portal**: Historical district-wise Area, Production, and Yield (APY) records (2000–2024).
   - **Soil Health Card (SHC) Portal (soilhealth.dac.gov.in)**: Geo-tagged village-level soil test samples measuring Nitrogen (N), Phosphorus (P), Potassium (K), Organic Carbon (OC), and pH.
3. **Agmarknet (agmarknet.gov.in / data.gov.in)**:
   - 10-year historical daily modal prices for major Kharif and Rabi commodities across MP APMCs.
4. **IMD (India Meteorological Department) & Gridded Meteorological Reanalysis**:
   - District-level monsoon rainfall (June–September) and winter precipitation metrics.

---

## 3. Data Collection Protocol (Ground-Truth Farmer Records)
To continuously improve model accuracy through ground-truth observations, the Upajo mobile app and partner **Kisan Mitras (Kisan Call Center / KVK field agents)** collect structured post-harvest data:

| Field | Type | Description | Validation Bounds |
| :--- | :--- | :--- | :--- |
| `farmer_id` | UUID | Anonymized user ID | Foreign key to `profiles` |
| `district` | String | MP district name | 52 authorized MP districts |
| `soil_n_kg_ha` | Float | Soil available Nitrogen | 50.0 – 600.0 kg/ha |
| `soil_p_kg_ha` | Float | Soil available Phosphorus | 5.0 – 90.0 kg/ha |
| `soil_k_kg_ha` | Float | Soil available Potassium | 50.0 – 500.0 kg/ha |
| `soil_ph` | Float | Soil pH level | 4.5 – 9.5 |
| `rainfall_seasonal_mm` | Float | Cumulative seasonal rain | 150.0 – 2500.0 mm |
| `mean_temp_c` | Float | Average seasonal temp | 10.0 – 45.0 °C |
| `crop_sown` | String | Variety sown | Authorized ICAR crop codes |
| `actual_yield_q_acre` | Float | Harvest yield | 1.0 – 45.0 Quintals/Acre |
| `actual_price_realized` | Float | Net price received | ₹500 – ₹15,000 / Quintal |
| `net_profit_acre` | Float | Net farmer profit | Realized revenue minus costs |
| `verified_by_kisan_mitra` | Boolean | Ground truth flag | Verified by agronomist |
| `is_synthetic` | Boolean | Synthetic flag | Must be `false` for training |

---

## 4. Strict Synthetic Data Policy
- **Synthetic Data Policy**:
  - Synthetic / generated data is permitted **ONLY** for unit tests, pipeline load-testing, and CI mock runs.
  - **NEVER** include synthetic rows in production training or model evaluation sets.
  - Every non-field observation or test record must explicitly carry `is_synthetic: true`.
  - The model retraining pipeline automatically applies the filter `WHERE is_synthetic = false` and `WHERE verified_by_kisan_mitra = true`.

---

## 5. Held-Out Spatial Evaluation Protocol
To prevent geographic data leakage, models are evaluated using a **Spatial Held-Out District Split**:
- **Training Districts (40 Districts)**: Sehore, Bhopal, Raisen, Rajgarh, Vidisha, Ujjain, Dewas, Shajapur, Indore, Dhar, Khargone, Khandwa, Gwalior, Shivpuri, Sagar, Damoh, Jabalpur, Narsinghpur, etc.
- **Held-Out Test Districts (12 Districts)**:
  1. Hoshangabad (Narmadapuram)
  2. Harda
  3. Mandsaur
  4. Neemuch
  5. Ratlam
  6. Betul
  7. Chhindwara
  8. Rewa
  9. Satna
  10. Tikamgarh
  11. Morena
  12. Bhind
Evaluating on unseen districts ensures the model learns true soil, weather, and agronomic relationships rather than memorizing district names.

