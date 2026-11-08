# Upajo (उपजो) - Comprehensive Baseline Verification & Security Audit Report (STEP 1)

Date: 2026-11-08  
Auditor: Principal Full-Stack & Security Engineer  
Repository: Upajo (उपजो) - Direct Farmer-to-Consumer Marketplace & AI Farming Assistant  

---

## 1. Clean Clone Verification & Build Audit

### A. Real Verification Commands & Outputs

| Command | Status | Real Output Summary |
| :--- | :--- | :--- |
| `flutter pub get` | **PASS (Exit 0)** | "Got dependencies! 53 packages have newer versions incompatible with constraints." |
| `flutter analyze` | **FAIL (Exit 1)** | 1 Error: `Undefined class 'OrderModel' - lib/features/consumer/presentation/screens/checkout_screen.dart:33:3`. (154 informational lints). |
| `flutter test` | **PASS (Exit 0)** | `19 passed` (Authentication invariants, core flows, role selection, touch targets). |
| `build_runner build` | **FAIL (Exit 1)** | `Missing implementation of visitDotShorthandPropertyAccess` in `riverpod_generator` due to newer Dart analyzer AST visitor. |
| `flutter build apk --release --flavor prod` | **FAIL (Exit 1)** | Failed at `:app:compileFlutterBuildProdRelease` kernel snapshot: `Type 'OrderModel' not found in checkout_screen.dart:33:3`. |
| `python test_parts_0_to_2.py` | **PASS (Exit 0)** | `41 passed` (Schema, foundation, auth, crop engine, store, logistics, security). |
| `python test_step5_payments_security.py` | **PASS (Exit 0)** | `6 passed` (Server-side order computation, signature verification, stock lock). |
| `python -m pytest test_step6_backend_security.py -v` | **PASS (Exit 0)** | `15 passed` (JWT auth, CORS allow-list, OWASP headers, image validation, EXIF strip). |
| `python supabase/tests/run_rls_security_validation.py` | **PASS (Exit 0)** | `11 passed` (RLS enabled on all 20 tables, PII column protection, anti-escalation). |

---

## 2. Complete Inventory

### A. Database Schema: Exactly 20 Tables in Supabase Public Schema
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
*Directory: `supabase/functions/`*
1. `create-razorpay-order`: Authoritative server-side amount calculation from DB records; prevents client price tampering.
2. `verify-razorpay-payment`: Cryptographic HMAC-SHA256 signature verification, idempotency deduplication, atomic stock deduction via DB stored procedure.
3. `razorpay-webhook`: Server-to-server webhook handler verifying `x-razorpay-signature` over raw payload.
4. `send-push-notification`: FCM notification dispatcher with recipient profile verification.

### C. FastAPI ML Microservice Routes (7 Endpoints)
*Directory: `ml_service/`*
1. `GET /health`: Microservice health check (public).
2. `POST /api/v1/crop-advisor/recommend`: ICAR rule engine agronomic crop recommendation (JWT/API key protected).
3. `GET /api/v1/crop-advisor/seed-data`: ICAR agronomic seed compendium (JWT/API key protected).
4. `POST /api/v1/disease/predict`: Plant pathology detection with content-based MIME validation, EXIF stripping, and KVK disclaimers (JWT/API key protected).
5. `POST /api/v1/krishi-sahayak/chat`: AI voice assistant with prompt injection firewall, PII scrubbing, and token budget cap (JWT/API key protected).
6. `GET /api/v1/mandi/prices`: Daily APMC benchmark mandi rates (public).
7. `GET /api/v1/mandi/price-suggestion`: Direct fair pricing vs APMC commission calculator (JWT/API key protected).
8. `POST /api/v1/analytics/yield-prediction`: Crop yield forecasting engine (JWT/API key protected).

### D. Flutter Screens (31 Screens)
*Directory: `lib/features/`*
* **Auth & Onboarding (6)**: `splash_screen.dart`, `onboarding_screen.dart`, `language_select_screen.dart`, `login_screen.dart`, `verify_otp_screen.dart`, `role_selection_screen.dart`.
* **Consumer Portal (7)**: `consumer_home_screen.dart`, `product_detail_screen.dart`, `cart_screen.dart`, `checkout_screen.dart`, `consumer_orders_screen.dart`, `order_tracking_screen.dart`, `order_rating_sheet.dart`.
* **Farmer Portal (5)**: `farmer_dashboard_screen.dart`, `my_products_screen.dart`, `add_product_screen.dart`, `farmer_orders_screen.dart`, `farmer_earnings_screen.dart`.
* **Agronomy & AI Services (5)**: `crop_advisor_screen.dart`, `crop_calendar_screen.dart`, `disease_detection_screen.dart`, `krishi_sahayak_screen.dart`, `mandi_prices_screen.dart`.
* **Machinery & Input Store (5)**: `machinery_browse_screen.dart`, `machinery_detail_screen.dart`, `list_machinery_screen.dart`, `my_rentals_screen.dart`, `store_catalog_screen.dart`.
* **Logistics & Admin (3)**: `live_tracking_screen.dart`, `farmer_analytics_screen.dart`, `admin_verification_screen.dart`.

---

## 3. Findings: Mock, Fake, Simulated, and Vulnerable Behaviors

| ID | Category | Component | Current State | Risk / Reality | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **F-01** | **Build Failure** | `checkout_screen.dart` | Missing `import '.../order_model.dart'` | Causes `flutter analyze` and `flutter build` failure. | **CRITICAL** |
| **F-02** | **ML / Model** | Disease Detection | No `.tflite` model exists; uses filename substring checks | Entire scanner is fake in code; no actual model running. Must be honest or disabled. | **CRITICAL** |
| **F-03** | **ML / Model** | Yield Prediction | Trained on `np.random` synthetic data | R2 / accuracy metrics are meaningless. Must be labeled indicative estimate. | **HIGH** |
| **F-04** | **Auth / Security** | Login / Demo OTP | Hardcoded "123456" OTP & "9876543210" phone | Reviewer demo credentials must be completely removed from production flavor. | **CRITICAL** |
| **F-05** | **Architecture** | Portals & Roles | Single combined navigation shell | Lacks dedicated Farmer vs Customer portals with route guards; no Next.js admin panel. | **HIGH** |
| **F-06** | **Third-Party API** | Weather Provider | Open-Meteo free tier | Non-commercial license limitation; needs abstraction with fallback. | **MEDIUM** |
| **F-07** | **Third-Party API** | Mandi Rates | Static hardcoded JSON catalog | Not connected to live data.gov.in Agmarknet API. | **HIGH** |
| **F-08** | **Third-Party API** | Maps / Tile Server | Public `tile.openstreetmap.org` | Unsuitable for production traffic; violates OSM tile usage policy. | **MEDIUM** |
| **F-09** | **Logistics** | Live Tracking | Timer-based lat/long simulation | Fake GPS movement in `live_tracking_screen.dart`; 3PL adapter is a mock. | **HIGH** |
| **F-10** | **Marketing Claims** | Store & Dashboard | "100% ICAR certified", "+30-45% margin" | Hardcoded marketing text without backing verification. | **MEDIUM** |
| **F-11** | **Admin / Governance** | Admin Panel | Single mobile screen `admin_verification_screen.dart` | Missing dedicated `/admin_web` Next.js management portal with mandatory 2FA. | **CRITICAL** |
| **F-12** | **AI Microservice** | Krishi Sahayak LLM | Hardcoded Claude dependency | User requested Gemini LLM provider proxy with server-side API key. | **HIGH** |
| **F-13** | **ML Self-Learning** | Crop Recommendation | Hardcoded rule compendium | Missing ML model with train/eval pipeline, feedback loop tables, and shadow deployment. | **HIGH** |

---

## 4. Git History & Secrets Scan

- Full regex scan of repository and commit history for API keys, AWS credentials, Google service accounts, private keys, `.jks`, `.keystore`, `.env`.
- **Finding**: Zero production secrets found in git history. All environment templates use dummy placeholders.
- Verified `.gitignore` covers `*.jks`, `*.keystore`, `key.properties`, `.env*`.

---

## 5. Next Steps Plan
1. **STEP 2**: Implement real Phone + SMS OTP + Password auth, role selection, `flutter_secure_storage`, and route guards.
2. **STEP 3**: Build dedicated Farmer Portal with KYC-lite, product & order management.
3. **STEP 4**: Build dedicated Customer Portal with browse, cart, checkout, tracking.
4. **STEP 5**: Construct `/admin_web` Next.js management panel with mandatory TOTP 2FA.
5. **STEP 6**: Wire real APIs (Agmarknet, commercial WeatherProvider, Gemini LLM proxy, production Map tiles).
6. **STEP 7**: Train and integrate own Crop Recommendation ML model with self-learning feedback loop.
7. **STEP 8**: Complete Android & Database security hardening.
8. **STEP 9**: Privacy, legal, support, delete-account workflows.
9. **STEP 10**: Deployment automation & CI/CD workflows.
10. **STEP 11**: Final verification runs across all suites and delivery artifacts.

