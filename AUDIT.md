# Upajo (उपजो) - Comprehensive Baseline Verification & Security Audit Report (STEP 1 / PHASE 1)

Date: 2026-11-11  
Auditor: Principal Full-Stack & Security Engineer  
Repository: Upajo (उपजो) - Direct Farmer-to-Consumer Marketplace & AI Farming Assistant  

---

## 1. Repository Directory Tree
```
E:\new\
├── admin_web\                # Next.js admin management portal
├── android\                  # Android native project & Gradle config
├── assets\                   # Fonts, icons, images, translation JSONs, models
├── brand\                    # Brand identity assets
├── data\                     # Seed data & static JSON datasets
├── docs\                     # Architecture and deployment documentation
├── lib\                      # Flutter app source code (features, models, services, providers)
├── ml_service\               # FastAPI ML & AI microservice
├── scripts\                  # Automation & validation scripts
├── supabase\                 # Supabase migrations, Edge Functions, RLS security tests
├── test\                     # Flutter unit & widget tests
├── tool\                     # Build & audit tools
├── .env / .env.example       # Environment configuration templates
├── Dockerfile                # Container definition for backend services
├── pubspec.yaml              # Flutter dependency manifest
└── railway.json / render.yaml # Deployment configurations
```

---

## 2. Real Verification Commands & Outputs (No Claim Without Proof)

| Command | Status | Real Output Summary |
| :--- | :--- | :--- |
| `flutter pub get` | **PASS (Exit 0)** | Got dependencies! 53 packages have newer versions incompatible with constraints. |
| `flutter analyze` | **FAIL (Exit 1)** | 1 Error: `Undefined class 'OrderModel' - lib/features/consumer/presentation/screens/checkout_screen.dart:33:3`. (154 informational lints). |
| `flutter test` | **PASS (Exit 0)** | `19 passed` (Authentication invariants, core flows, role selection, touch targets). |
| `flutter build apk --release --flavor dev` | **FAIL (Exit 1)** | Failed at compile time due to missing `OrderModel` definition in checkout screen. |
| `python test_parts_0_to_2.py` | **PASS (Exit 0)** | `41 passed` (Schema, foundation, auth, crop engine, store, logistics, security). |
| `python test_step5_payments_security.py` | **PASS (Exit 0)** | `6 passed` (Server-side order computation, signature verification, stock lock). |
| `python -m pytest test_step6_backend_security.py -v` | **PASS (Exit 0)** | `15 passed` (JWT auth, CORS allow-list, OWASP headers, image validation, EXIF strip). |
| `python supabase/tests/run_rls_security_validation.py` | **PASS (Exit 0)** | `11 passed` (RLS enabled on all 20 tables, PII column protection, anti-escalation). |

---

## 3. Complete Architecture & Component Inventory

### A. Database Schema (20 Tables in Supabase Public Schema)
*File: `supabase/migrations/20250101000000_init_upajo_schema.sql`*
1. `profiles`: User account details, phone, full name, role (`farmer`, `consumer`, `admin`), KYC verification status.
2. `farmer_profiles`: PII & banking details (village, district, land size, bank account, IFSC, UPI VPA, Aadhaar last-4, KCC).
3. `categories`: Produce categories (grains, pulses, oilseeds, vegetables, fruits, spices).
4. `products`: Direct produce listings with base price per kg, harvest date, active status.
5. `pack_options`: Standardized pack sizes (10kg, 20kg, 50kg) with packaging & volume discount multipliers.
6. `orders`: Authoritative order state machine (`pending_payment`, `confirmed`, `harvesting_packed`, `out_for_delivery`, `ready_for_pickup`, `delivered`, `cancelled`).
7. `order_items`: Line items tied to products, pack sizes, quantities, and prices.
8. `payments`: Payment records, Razorpay order/payment IDs, status (`pending`, `captured`, `failed`, `refunded`).
9. `ratings`: Verified customer reviews with 1-5 star ratings for farmers and products.
10. `delivery`: Delivery coordinates, driver assignment, delivery modes (`pickup`, `farm_direct_dispatch`).
11. `crops`: Supported crop compendium with ICAR agronomic baselines.
12. `crop_plans`: Farmer active crop planning entries linked to land area and sowing date.
13. `tasks`: Chronological calendar tasks generated for crop maintenance stages.
14. `disease_scans`: Scan history records storing diagnosis, confidence, and photo references.
15. `chat_sessions`: Krishi Sahayak conversation threads.
16. `chat_messages`: Structured dialogue history between farmer and AI assistant.
17. `machinery`: Farm equipment listed for rent (tractors, harvesters, rotavators, sprayers).
18. `rentals`: Equipment rental bookings, rental dates, security deposit records.
19. `store_items`: Agricultural input catalog (certified seeds, bio-fertilizers, organic pesticides, farm tools).
20. `notifications`: In-app and push notification delivery records.

### B. Supabase Edge Functions (4 Functions)
1. `create-razorpay-order`: Authoritative server-side amount calculation from DB records; prevents client price tampering.
2. `verify-razorpay-payment`: Cryptographic HMAC-SHA256 signature verification, idempotency deduplication, atomic stock deduction via DB stored procedure.
3. `razorpay-webhook`: Server-to-server webhook handler verifying `x-razorpay-signature` over raw payload.
4. `send-push-notification`: FCM notification dispatcher with recipient profile verification.

### C. FastAPI ML Microservice Routes (7 Endpoints)
1. `GET /health`, 2. `POST /api/v1/crop-advisor/recommend`, 3. `GET /api/v1/crop-advisor/seed-data`, 4. `POST /api/v1/disease/predict`, 5. `POST /api/v1/krishi-sahayak/chat`, 6. `GET /api/v1/mandi/prices`, 7. `GET /api/v1/mandi/price-suggestion`, 8. `POST /api/v1/analytics/yield-prediction`.

---

## 4. Feature Audit: Real vs Mock vs Broken

| Feature / Component | Classification | Status & Reality |
| :--- | :--- | :--- |
| **Flutter UI Screens (31 screens)** | Mixed | Navigation structure exists, but `checkout_screen.dart` fails compilation due to missing `OrderModel`. |
| **Authentication Flow** | Mock / Prototype | Uses hardcoded test credentials ("123456" OTP & "9876543210" phone) in UI prototypes. |
| **Disease Detection Scanner** | Mock / Simulated | No `.tflite` model file in `assets/models/`; checks filename substrings to return hardcoded mock diagnoses. |
| **Yield Prediction Engine** | Mock / Simulated | Trained on `np.random` synthetic data; lacks real regional historical training datasets. |
| **Mandi Prices** | Mock / Static | Returns static hardcoded JSON data instead of live APMC Agmarknet API integration. |
| **Live Order Tracking** | Mock / Simulated | GPS coordinates increment via timer simulation (`LiveTrackingScreen`). |
| **Supabase Backend & RLS** | Real & Robust | 20 tables with comprehensive SQL schema, functions, and RLS validation tests passing. |
| **FastAPI ML Backend** | Real & Structured | Routes defined with Pydantic validation, security headers, and EXIF stripping. |

---

## 5. Dead Code, Duplicate Code & Unused Packages Audit

1. **Unused Asset Inclusion**: `pubspec.yaml` includes `- .env` under `assets:`, which embeds secret configuration files into compiled binaries. **(Security Risk)**
2. **Duplicate Logic**: Multiple utility functions for date formatting and currency formatting across disparate UI feature directories.
3. **Unused Packages**: Several pub dependencies declared in `pubspec.yaml` are imported nowhere in `lib/` (e.g., certain charts or redundant state utilities).
4. **Dead Code**: Unreferenced stub screens and obsolete test harness scripts in root directory.

---

## 6. Schema vs Code Mismatches

1. **Naming Convention Discrepancies**: Database column snake_case vs Dart model camelCase mappings require rigorous adapter parsing; some models lack Null safety fallbacks for optional nullable columns (e.g., `farmer_profiles` banking details).
2. **Enum Mismatches**: Order status strings in Flutter client enums (`pending_payment`, `confirmed`, etc.) must exactly match PostgreSQL check constraints in the `orders` table.

---

## 7. Hardcoded Strings, URLs, and Keys Audit

1. **Hardcoded Fallbacks**: Default Supabase project URL and anon key fallbacks hardcoded in `lib/core/config/env_config.dart`.
2. **Hardcoded OTP / Auth**: Test phone number "9876543210" and OTP "123456" hardcoded in auth controller flows.
3. **Map Tile Server**: Uses public OpenStreetMap tile URLs (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`) without commercial usage attribution headers.

---

## 8. Workarounds in Gradle & Configuration

1. **MultiDex Enabled**: `multiDexEnabled true` configured in `android/app/build.gradle` to bypass 65k method limit due to large dependency tree (`firebase`, `supabase`, `drift`, `flutter_map`).
2. **Min/Target SDK**: `minSdkVersion flutter.minSdkVersion` and `targetSdk 34` with `compileSdk 36`.

---

## 9. What Has Never Been Run
- **End-to-End Real Phone Execution**: The app has **never** been installed and tested on a physical Android device connected via USB with real Supabase instance and FastAPI backend.
- **Real Payment Gateway Integration**: Razorpay webhooks and live transactions have only been tested via mock test scripts, never in production environment.

---

## 10. Severity-Ranked Findings & Issues

| Severity | Issue Description | Component | Remediation Plan |
| :--- | :--- | :--- | :--- |
| **CRITICAL** | `checkout_screen.dart` fails analysis (`Undefined class 'OrderModel'`) | Flutter App | Define `OrderModel` or import the correct model file. |
| **CRITICAL** | `.env` included in `pubspec.yaml` assets | Config / Build | Remove `- .env` from pubspec assets to prevent secret exposure in APK. |
| **CRITICAL** | Hardcoded demo OTP / credentials in production code paths | Auth | Restrict test credentials exclusively to debug builds/flavors. |
| **HIGH** | Disease detection scanner lacks real `.tflite` model | ML Service | Label prototype status honestly or bundle valid quantized tflite model. |
| **HIGH** | Static Mandi prices and simulated GPS tracking | Integrations | Document limitation in UI and user reports. |
| **MEDIUM** | OpenStreetMap public tiles used without commercial tier | Maps | Add proper attribution headers. |
| **LOW** | 154 informational lints in Dart analysis | Code Quality | Clean up lints during Phase 4 clean-up. |

---
*End of Phase 1 Audit Report. Awaiting user OK before proceeding to Phase 2.*
