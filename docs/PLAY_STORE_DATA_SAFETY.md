# Upajo (उपजो) - Google Play Console Data Safety Declaration
### Official Production Answers for Google Play Store Listing & Data Safety Audit

---

## 1. Overview & Data Collection Summary

| Question | Official Answer |
|---|---|
| **Does your app collect or share any of the required user data types?** | **Yes** |
| **Is all of the user data collected by your app encrypted in transit?** | **Yes** (Strict TLS 1.3 / HTTPS on all endpoints) |
| **Do you provide a way for users to request that their data be deleted?** | **Yes** (In-app Profile Deletion & dedicated Web portal) |

---

## 2. Detailed Data Types Collected & Purpose

### A. Location (Approximate & Precise)
- **Data Collected**: Approximate location and Precise location (GPS coordinates).
- **Is it shared?**: **Yes** (Shared with matched delivery drivers strictly during active order transit).
- **Is it ephemeral?**: **No** (Stored in database to calculate distance to mandi and farm pickup pins).
- **Purpose**:
  - *App functionality*: Farmer farm location pin, local APMC Mandi price discovery, delivery distance computation.
  - *Personalization*: Hyperlocal Open-Meteo weather forecasts and disease outbreak alerts.

### B. Personal Information
- **Name**: Collected for profile setup, invoice generation, and farmer KYC verification.
- **Phone Number**: Collected for passwordless OTP authentication (SMS), order tracking SMS alerts, and buyer-seller contact.
- **Address / Village / District**: Collected for delivery route dispatch and mandi price matching.
- **Is it shared?**: Shared between transacting buyer and seller for delivery execution. Never shared with data brokers or advertisers.

### C. Financial Info
- **Payment Info / UPI Transaction IDs**: Processed securely via Razorpay PCI-DSS Level 1 compliant SDK.
- **Raw Credit Card / Debit Card Numbers**: **Not Collected / Not Stored** (Razorpay tokenized).
- **Bank Account Details (Farmers Only)**: Account Number and IFSC code stored for direct farmer payouts.

### D. Photos and Videos
- **Photos**: Captured leaf/plant images for AI Crop Disease Detection and produce photos for marketplace listings.
- **Purpose**: App functionality (Machine learning inference and catalog display).

### E. Audio (Speech Data)
- **Audio Recordings / Speech-to-Text**: Voice inputs captured when interacting with the Hindi AI assistant "Krishi Sahayak".
- **Purpose**: App functionality. Audio is processed ephemerally and transcribed; raw voice recordings are not stored permanently.

### F. App Performance & Diagnostics
- **Crash Logs & Performance Diagnostics**: Captured via Firebase Crashlytics & Sentry for stability and bug tracking.
- **PII Scrubbing**: All logs automatically redact phone numbers, tokens, and bank details before transmission.

---

## 3. Security Practices & User Rights
1. **Encryption in Transit**: All communications with Supabase, Open-Meteo, and FastAPI ML microservices enforce **HTTPS / TLS 1.3** with modern cipher suites.
2. **Encryption at Rest**: PostgreSQL database storage, object storage buckets (produce images), and local SQLite caches employ **AES-256** encryption.
3. **Data Deletion Mechanism**:
   - In-app: `Profile -> Delete Account & All Data`.
   - Web deletion request URL: `https://upajo.in/delete-account`
   - Policy: Deletes all personal records, active listings, and un-archived chat logs within 30 days in compliance with the Digital Personal Data Protection (DPDP) Act.

