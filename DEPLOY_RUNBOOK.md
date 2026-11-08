# Upajo (उपजो) - Production Deployment Runbook

This runbook provides the step-by-step procedure for deploying the Upajo production environment across Supabase, Render/Railway, Vercel, and Google Play Console.

---

## 1. Prerequisites & Required Secrets

Ensure the following accounts and credentials are available before commencing deployment:

| Service | Required Keys / Secrets | Where Stored |
| :--- | :--- | :--- |
| **Supabase** | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET` | Backend, FastAPI, Vercel |
| **Google Cloud**| `GEMINI_API_KEY` (Gemini 1.5 Flash) | Render Environment Secrets |
| **Razorpay** | `RAZORPAY_KEY_ID` (Public), `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET` | Supabase Edge Functions, Flutter |
| **SMS Gateway** | India DLT Principal Entity ID, Sender Header (`UPAJOP`), Template IDs | Supabase Auth SMS Provider |
| **Android** | `upload-keystore.jks`, `key.properties` (`storePassword`, `keyPassword`, `keyAlias`) | CI/CD Secrets / Local Build Machine |
| **Admin Web** | `ADMIN_TOTP_SECRET` (Base32 secret for 2FA TOTP authentication) | Vercel Environment Variables |

---

## 2. Step 1: Supabase Production Deployment

### 2.1 Database Migrations
Run the migrations in exact chronological sequence using the Supabase CLI:

```bash
# 1. Login and link to your remote production Supabase project
supabase login
supabase link --project-ref <YOUR_SUPABASE_PROJECT_ID>

# 2. Push database migrations in order
supabase db push

# The migrations applied will be:
# - 20250101000000_init_upajo_schema.sql (Core schema, 20 tables, RLS, triggers)
# - 20250215000000_recommendations_and_feedback.sql (ML recommendations & farmer feedback tables)
# - 20250216000000_account_deletion_and_compliance.sql (Support tickets & DPDP Act deletion RPC)
```

### 2.2 Seed Admin Account
Create the initial administrator account (never accessible via client sign-up):

```sql
-- Execute in Supabase SQL Editor:
INSERT INTO public.profiles (id, phone, full_name, role)
VALUES ('<SUPABASE_AUTH_ADMIN_UUID>', '+919999999999', 'Platform Super Admin', 'admin')
ON CONFLICT (id) DO UPDATE SET role = 'admin';
```

### 2.3 Storage Buckets Configuration
Verify the 4 storage buckets in the Supabase Dashboard:
* `kyc-docs`: **Private** (Signed URL access only, 10MB max).
* `product-images`: **Public** (5MB max).
* `avatars`: **Public** (2MB max).
* `disease-scans`: **Private** (10MB max).

### 2.4 Deploy Edge Functions
Deploy server-side payment and messaging handlers:

```bash
supabase functions deploy create-razorpay-order --project-ref <YOUR_SUPABASE_PROJECT_ID>
supabase functions deploy verify-razorpay-payment --project-ref <YOUR_SUPABASE_PROJECT_ID>
supabase functions deploy send-push-notification --project-ref <YOUR_SUPABASE_PROJECT_ID>

# Set Edge Function Secrets
supabase secrets set RAZORPAY_KEY_ID="rzp_live_xxx" RAZORPAY_KEY_SECRET="your_secret_here"
```

---

## 3. Step 2: FastAPI ML Service Deployment (Render / Railway)

### 3.1 Deploying via Render
1. In the Render Dashboard, select **New** > **Blueprint**.
2. Connect your Git repository. Render will automatically parse `render.yaml`.
3. Set the service plan to **Starter (Paid)** to guarantee 24x7 zero spin-down latency.
4. Add the required production environment variables:
   * `ENVIRONMENT`: `production`
   * `ML_SERVICE_API_KEY`: Generate a secure 32-character random token.
   * `GEMINI_API_KEY`: Your Google AI Studio API key.
   * `SUPABASE_URL`: Your Supabase project URL.
   * `SUPABASE_SERVICE_ROLE_KEY`: Service role key.
   * `SUPABASE_JWT_SECRET`: JWT secret for bearer validation.
   * `ALLOWED_ORIGINS`: `https://admin.upajo.com,https://upajo.com,capacitor://localhost`

### 3.2 Verification
Verify the service is live and healthy:

```bash
curl -f https://<YOUR_RENDER_SERVICE_URL>/health
# Expected Output: {"status":"healthy","version":"1.0.0",...}
```

---

## 4. Step 3: Admin Web Portal Deployment (Vercel)

### 4.1 Deploying via Vercel
1. In Vercel, click **Add New** > **Project** and select this repository.
2. Set **Root Directory** to `admin_web`.
3. Framework Preset: **Next.js**.
4. Configure Environment Variables:
   * `NEXT_PUBLIC_SUPABASE_URL`: `https://<YOUR_PROJECT>.supabase.co`
   * `NEXT_PUBLIC_SUPABASE_ANON_KEY`: `<YOUR_ANON_KEY>`
   * `SUPABASE_SERVICE_ROLE_KEY`: `<YOUR_SERVICE_ROLE_KEY>`
   * `ADMIN_TOTP_SECRET`: Base32 secret string (e.g. `JBSWY3DPEHPK3PXP`) for Google Authenticator.
5. Deploy.

---

## 5. Step 4: Flutter Android App Release (Google Play)

### 5.1 Keystore Preparation
Ensure `android/key.properties` is configured on the release build runner:

```properties
storePassword=<YOUR_KEYSTORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=<YOUR_KEY_ALIAS>
storeFile=upload-keystore.jks
```

### 5.2 Build Production App Bundle
Execute the production flavor build:

```bash
flutter build appbundle --release --flavor prod
```

The resulting signed artifact will be generated at:  
`build/app/outputs/bundle/prodRelease/app-prod-release.aab`

### 5.3 Upload to Google Play Console
1. Upload `.aab` to the **Internal Testing Track**.
2. Verify Google Play Pre-Launch Report:
   * 0 crashes.
   * Target SDK: 34 (Android 14).
   * 0 privacy or permission policy violations.
3. Promote to Closed Beta > Open Production.

---

## 6. Rollback Procedures

* **Database Rollback**: In the event of an unintended migration regression, apply a down-migration script or revert via Supabase Dashboard backup restore point.
* **FastAPI Service Rollback**: In Render, select **Deploys** > Click previous stable commit > Click **Rollback to this deploy**.
* **Admin Web Rollback**: In Vercel, select **Deployments** > Instant Rollback to previous deployment.
* **Mobile App Rollback**: If a critical bug is reported in production, halt roll-out in Google Play Console and release an emergency patch build incrementing `versionCode`.

