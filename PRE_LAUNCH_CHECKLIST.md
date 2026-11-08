# Upajo (उपजो) - Pre-Launch Go-Live Readiness Checklist

**Release Target**: Production Launch (v1.0.0)  
**Target Audience**: Indian Smallholder Farmers & Direct Consumers  
**Operating Territories**: Central & Northern India (Madhya Pradesh primary)

---

## 1. Regulatory & Legal Compliance

- [x] **DPDP Act 2023 Compliance**: Data minimization enforced; in-app "Delete My Account" flow implemented with PII anonymization and KYC document destruction.
- [x] **Statutory Financial Retention**: 7-year audit log retention for payments and orders compliant with Indian Income Tax Act & CGST Act.
- [x] **GST Exemption Verification**: CGST Act Section 23 100% tax exemption verified for unprocessed farm produce; digital invoices generate zero-rated tax invoices.
- [x] **Consumer Protection (E-Commerce) Rules**: Transparent fee breakdowns displayed (Gross, 0% platform fee, 2% PG fee, Net Payout); misleading marketing claims removed.
- [x] **TRAI DLT Registration**: Principal Entity registration, Sender ID `UPAJOP`, and SMS consent/content templates configured for phone OTP delivery.
- [x] **Hosted Legal Pages**: Terms of Service, Privacy Policy, Refund Policy (48-hr dispute window), and Farmer Code of Conduct hosted at `/legal/*` and static HTML.

---

## 2. Authentication & Secrets Management

- [x] **Demo OTP Lockdown**: Demo OTP (`123456`) and test phone credentials (`9876543210`) are strictly guarded by `kDebugMode` and completely stripped in release builds.
- [x] **Rate Limiting & Lockout**: 5-attempt brute-force lockout with 15-minute freeze; 60-second OTP resend cooldown.
- [x] **Hardware-Backed Token Security**: `flutter_secure_storage` stores session tokens using Android Keystore / iOS Keychain.
- [x] **No Leaked Secrets**: Git history and code bundles scanned; zero server-role keys, Razorpay secrets, or Gemini keys exist in Flutter or Next.js client bundles.
- [x] **Admin 2FA Authentication**: RFC 6238 TOTP two-factor authentication required for Web Admin access.

---

## 3. Database & Row Level Security (RLS)

- [x] **100% RLS Coverage**: Enabled across all 21 public tables; zero broad `SELECT USING (true)` on PII or financial tables.
- [x] **Privilege Escalation Blocked**: `protect_profile_privileges` trigger strictly prevents users from modifying `role`, `kyc_status`, or `verified_by_admin`.
- [x] **Order & Price Integrity**: `protect_order_integrity_and_transitions` trigger prevents tampering with `total_amount` or transitioning to invalid order states.
- [x] **Storage Bucket Restrictions**: `kyc-docs` and `disease-scans` buckets are private; download access restricted to owner UID folder prefix and signed URLs.
- [x] **Automated RLS Test Suite**: 11 RLS test assertions passing on `supabase/tests/run_rls_security_validation.py`.

---

## 4. Machine Learning & Agronomic Safety

- [x] **Spatial Hold-Out Evaluation**: Crop recommendation trained on 40 districts and evaluated on 12 completely unseen held-out districts (84.28% Top-1, 99.43% Top-3).
- [x] **Zero Synthetic Claims**: Single-point synthetic R² metrics eliminated; replaced with 10th-50th-90th percentile Quantile Yield Regression (77.2% coverage).
- [x] **CIB&RC Pesticide Dosages**: Chemical formulations match official CIB&RC guidelines; converted into standard 15-litre knapsack spray pump dilution ratios.
- [x] **Mandatory KVK Disclaimers**: Prominent Hindi and English disclaimers displayed on all AI pathology and advisory outputs; Kisan Call Center direct dial (`1800-180-1551`) provided.
- [x] **Continuous Self-Learning Loop**: Farmer harvest feedback captured in `farmer_feedback` table; retraining pipeline checks 3 safety gates before promoting candidate models.

---

## 5. Mobile & Infrastructure Hardening

- [x] **Screen Capture Protection**: `FLAG_SECURE` toggled via MethodChannel on sensitive screens (KYC, bank accounts, UPI, payments).
- [x] **Cleartext Traffic Disabled**: `network_security_config.xml` blocks non-HTTPS connections.
- [x] **R8 / ProGuard Optimization**: Production build strips logging calls (`Log.v`, `Log.d`, `Log.i`) and shrinks unused resources.
- [x] **High Availability ML Hosting**: Render/Railway configured on paid tier to eliminate cold starts and guarantee sub-second API responses.
- [x] **Automated CI/CD**: GitHub Actions workflow verifies Flutter tests, FastAPI tests, ML retraining gates, RLS validation, and Next.js admin build on every push.

