# Upajo (उपजो) - Third-Party Integrations & DLT Setup Guide

This document details all external services, configuration parameters, and the mandatory regulatory compliance workflows required to operate Upajo in production across India.

---

## 1. SMS Gateway & India DLT Compliance (TRAI Mandate)

Under Telecom Regulatory Authority of India (TRAI) TCCCPR 2018 regulations, commercial and transactional SMS messages cannot be delivered to Indian mobile numbers without registration on an authorized Distributed Ledger Technology (DLT) portal.

### 1.1 DLT Registration Workflow
1. **Entity Registration (Principal Entity)**:
   * Register Upajo Technologies Pvt Ltd on any major operator DLT portal (e.g., [Jio DLT](https://trueconnect.jio.com/), [Airtel DLT](https://www.airtel.in/business/commercial-communication), or [Vilpower DLT](https://www.vilpower.in/)).
   * Submit Company PAN, GST Certificate, and Authorized Signatory Aadhaar.
   * Receive unique **Principal Entity ID (PE ID)**.

2. **Header (Sender ID) Registration**:
   * Type: **Transactional / Service Implicit**.
   * Header: `UPAJOP` (or `UPAJIN` - 6 alpha characters).
   * Associated with your PE ID.

3. **Content Template Registration (Strict Format)**:
   * *Template Name*: `Upajo_Phone_Login_OTP`
   * *Template Type*: Service Implicit
   * *Message Text*:
     ```text
     प्रिय किसान साथी, उपजो (Upajo) में लॉगिन करने हेतु आपका OTP {#var#} है। यह 10 मिनट के लिए मान्य है। किसी के साथ साझा न करें। - Upajo
     ```
   * *Template ID*: Copy the generated 19-digit Template ID into your SMS provider console.

### 1.2 Supabase Phone Auth SMS Provider Setup
1. In the Supabase Dashboard, navigate to **Authentication** > **Providers** > **Phone**.
2. Select your SMS Gateway (Twilio, MessageBird, or custom webhook to Indian aggregators like Fast2SMS, Textlocal, or Gupshup).
3. If using Twilio:
   * **Account SID** & **Auth Token**.
   * Configure sender phone number or alphanumeric Sender ID.
4. If using Indian aggregators via Edge Function / Webhook:
   * Set custom SMS hook URL in Supabase Auth configuration.

---

## 2. Supabase Backend & Database

### 2.1 Project Configuration
* **Environment Variables**:
  * `SUPABASE_URL`: e.g. `https://your-project.supabase.co`
  * `SUPABASE_ANON_KEY`: Public client-safe key (configured in Flutter & Next.js client).
  * `SUPABASE_SERVICE_ROLE_KEY`: Server-side only (Edge Functions & FastAPI ML service).
  * `SUPABASE_JWT_SECRET`: Used by FastAPI to cryptographically verify user bearer tokens.

### 2.2 Storage Buckets Matrix

| Bucket Name | Access Level | Allowed MIME Types | Max Size | Purpose |
| :--- | :---: | :---: | :---: | :--- |
| `kyc-docs` | **Private** | `image/jpeg, image/png, application/pdf` | 10 MB | Farmer Aadhaar/Khasra/Passbook verification documents |
| `product-images`| **Public** | `image/jpeg, image/png, image/webp` | 5 MB | Farmer harvest and crop listing photos |
| `avatars` | **Public** | `image/jpeg, image/png` | 2 MB | User profile avatars |
| `disease-scans` | **Private** | `image/jpeg, image/png` | 10 MB | Sanitized crop pathology scans |

### 2.3 Edge Functions Deployment
* `create-razorpay-order`: Authenticated RPC creating PG order with exact server-calculated amount.
* `verify-razorpay-payment`: Server-side HMAC-SHA256 signature verification and order state transition.
* `send-push-notification`: Firebase Cloud Messaging (FCM) v1 server-side broadcast.

---

## 3. Razorpay Payment Gateway

### 3.1 Credentials & Modes
* **Razorpay Key ID**: Public (injected into Flutter app via build flavor or `env_config.dart`).
* **Razorpay Key Secret**: Server-side only (stored as Supabase Edge Function secret `RAZORPAY_KEY_SECRET`).
* **Webhook Secret**: Stored in Edge Function `RAZORPAY_WEBHOOK_SECRET` for async payment callbacks.

### 3.2 Payment Verification Security Invariant
* Clients are never permitted to update order status to `confirmed` or `paid`.
* Razorpay passes signature `razorpay_signature = HMAC_SHA256(order_id + "|" + payment_id, secret)`.
* Only upon cryptographic match in `verify-razorpay-payment` is the payment recorded in `public.payments` and order status transitioned.

---

## 4. Google Gemini 1.5 Flash LLM (Krishi Sahayak)

### 4.1 Architecture
* The Flutter Android app **never** calls Google Gemini directly.
* All AI chat queries route through the FastAPI ML service (`/api/v1/krishi-sahayak/chat`).
* **Security & Privacy Guardrails**:
  1. *PII Scrubbing*: All Indian phone numbers, Aadhaar IDs, emails, and IFSC codes are stripped prior to forwarding.
  2. *Agricultural Topic Firewall*: Queries unrelated to farming, agronomy, crops, or livestock are rejected with a helpful message.
  3. *KVK Disclaimer*: Prominently appended advising consultation with local agricultural authorities for chemical usage.
  4. *Offline / Quota Fallback*: When the API is unavailable, the service automatically falls back to the ICAR compendium agronomy rules.

---

## 5. Weather & Mandi Real-Time APIs

### 5.1 Weather (Open-Meteo)
* Endpoint: `https://api.open-meteo.com/v1/forecast`
* Fallback: If network is offline, the app displays the last cached forecast with an explicit **"ऑफ़लाइन कैश डेटा" (Offline Cached Data)** badge and timestamp.

### 5.2 Mandi Prices (Agmarknet / data.gov.in)
* Proxy Route: `ml_service/routers/mandi.py`
* Caching: In-memory 30-minute sliding cache to protect public rate limits and prevent app slowdowns.
* Disclosures: Fallback rates are clearly labeled with the date and source APMC market.

