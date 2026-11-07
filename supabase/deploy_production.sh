#!/usr/bin/env bash
# ==============================================================================
# Upajo (उपजो) - Supabase Production Deployment Script
# ==============================================================================
set -euo pipefail

echo "🌾 [Upajo Deployment] Starting Supabase Production Deployment..."

if [ -z "${SUPABASE_PROJECT_ID:-}" ]; then
  read -rp "Enter your Supabase Project ID (Reference ID): " SUPABASE_PROJECT_ID
fi

# 1. Link to Supabase Production Project
echo "🔗 Linking to Supabase Project: $SUPABASE_PROJECT_ID..."
supabase link --project-ref "$SUPABASE_PROJECT_ID"

# 2. Push Database Migrations (All 20 tables + RLS policies + Indexes)
echo "📦 Applying database migrations..."
supabase db push

# 3. Configure Production Secrets for Edge Functions
echo "🔐 Setting production secrets..."
if [ -f "supabase/.env.production" ]; then
  supabase secrets set --env-file "supabase/.env.production"
else
  if [ -z "$RAZORPAY_KEY_SECRET" ] || [ -z "$ML_SERVICE_API_KEY" ]; then
    echo "❌ FATAL: Production secrets missing! Please export RAZORPAY_KEY_SECRET and ML_SERVICE_API_KEY or provide supabase/.env.production" >&2
    exit 1
  fi
  supabase secrets set \
    RAZORPAY_KEY_ID="${RAZORPAY_KEY_ID}" \
    RAZORPAY_KEY_SECRET="${RAZORPAY_KEY_SECRET}" \
    FCM_SERVER_KEY="${FCM_SERVER_KEY}" \
    CLAUDE_API_KEY="${CLAUDE_API_KEY}" \
    ML_SERVICE_URL="${ML_SERVICE_URL:-https://upajo-ml-service.onrender.com}" \
    ML_SERVICE_API_KEY="${ML_SERVICE_API_KEY}"
fi

# 4. Deploy Edge Functions
echo "🚀 Deploying Edge Functions..."
supabase functions deploy create-razorpay-order --no-verify-jwt
supabase functions deploy verify-razorpay-payment --no-verify-jwt
supabase functions deploy send-push-notification

echo "✅ [Upajo Deployment] Supabase Production Deployment Complete!"

