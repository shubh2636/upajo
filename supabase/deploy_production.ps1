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
    # Fail loudly if required production secrets are absent
    if (-not $env:RAZORPAY_KEY_SECRET -or -not $env:ML_SERVICE_API_KEY) {
        Write-Error "❌ FATAL: Production secrets missing! Set RAZORPAY_KEY_SECRET and ML_SERVICE_API_KEY in your environment or provide supabase/.env.production"
        exit 1
    }
    supabase secrets set `
        RAZORPAY_KEY_ID="$($env:RAZORPAY_KEY_ID)" `
        RAZORPAY_KEY_SECRET="$($env:RAZORPAY_KEY_SECRET)" `
        FCM_SERVER_KEY="$($env:FCM_SERVER_KEY)" `
        CLAUDE_API_KEY="$($env:CLAUDE_API_KEY)" `
        ML_SERVICE_URL="$($env:ML_SERVICE_URL)" `
        ML_SERVICE_API_KEY="$($env:ML_SERVICE_API_KEY)"
}

Write-Host "🚀 Deploying Edge Functions..." -ForegroundColor Green
supabase functions deploy create-razorpay-order --no-verify-jwt
supabase functions deploy verify-razorpay-payment --no-verify-jwt
supabase functions deploy send-push-notification

Write-Host "✅ Supabase Production Deployment Complete!" -ForegroundColor Green

