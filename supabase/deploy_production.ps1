# ==============================================================================
# Upajo (उपजो) - Supabase Production Deployment Script (PowerShell)
# ==============================================================================
param (
    [string]$ProjectId = $env:SUPABASE_PROJECT_ID
)

if (-not $ProjectId) {
    $ProjectId = Read-Host "Enter your Supabase Project ID (Reference ID)"
}

Write-Host "🌾 [Upajo Deployment] Linking to Supabase Project: $ProjectId..." -ForegroundColor Green
supabase link --project-ref $ProjectId

Write-Host "📦 Applying database migrations..." -ForegroundColor Green
supabase db push

Write-Host "🔐 Configuring secrets for Edge Functions..." -ForegroundColor Green
if (Test-Path "supabase/.env.production") {
    supabase secrets set --env-file "supabase/.env.production"
} else {
    Write-Host "⚠️ Setting fallback environment variables..." -ForegroundColor Yellow
    supabase secrets set `
        RAZORPAY_KEY_ID="$($env:RAZORPAY_KEY_ID)" `
        RAZORPAY_KEY_SECRET="$($env:RAZORPAY_KEY_SECRET)" `
        FCM_SERVER_KEY="$($env:FCM_SERVER_KEY)" `
        CLAUDE_API_KEY="$($env:CLAUDE_API_KEY)" `
        ML_SERVICE_URL="https://upajo-ml-service.onrender.com" `
        ML_SERVICE_API_KEY="upajo_internal_ml_secret_key"
}

Write-Host "🚀 Deploying Edge Functions..." -ForegroundColor Green
supabase functions deploy create-razorpay-order --no-verify-jwt
supabase functions deploy verify-razorpay-payment --no-verify-jwt
supabase functions deploy send-push-notification

Write-Host "✅ Supabase Production Deployment Complete!" -ForegroundColor Green
