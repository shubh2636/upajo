# Upajo (उपजो) - Post-Launch Operations, Disaster Recovery & ML Upgrade Path

---

## 1. Post-Launch Telemetry & Monitoring Architecture

### Key Health Metrics & Alert Thresholds
| Metric | Healthy Benchmark | Warning | P1 Incident (Halt Rollout) |
|---|---|---|---|
| **Crash-Free User Rate** | $\ge 99.8\%$ | $< 99.5\%$ | $< 99.0\%$ |
| **API Response Time (p95)** | $\le 250\text{ ms}$ | $> 500\text{ ms}$ | $> 1500\text{ ms}$ |
| **Payment Success Rate (UPI)** | $\ge 92.0\%$ | $< 85.0\%$ | $< 75.0\%$ |
| **Disease Scan Accuracy** | $\ge 93.0\%$ confidence | $< 80.0\%$ | Repeated false positives |

- **Error Breadcrumbs**: Captured via `UpajoCrashReporting` with automatic PII sanitization (phone numbers and UPI IDs redacted).
- **Service Uptime**: Open-Meteo weather service and FastAPI microservices monitored every 60 seconds with automated fallback to cached ICAR agro-climatic tables.

---

## 2. Backup & Point-in-Time Disaster Recovery (PITR)

### Automated Daily Snapshots
- Supabase automatically creates daily snapshots retained for 30 days.
- **Point-in-Time Recovery (PITR)**: Enabled on the production Postgres instance, allowing rollback to any microsecond in the past 7 days in case of catastrophic data corruption or human error.

### Manual Database Export Procedure
Before deploying major schema migrations, execute a point-in-time logical dump:
```bash
# Export schema + data
supabase db dump --project-ref "$SUPABASE_PROJECT_ID" -f "supabase_backup_$(date +%Y%m%d_%H%M%S).sql"

# Export data-only (for seed/audit verification)
supabase db dump --project-ref "$SUPABASE_PROJECT_ID" --data-only -f "supabase_data_$(date +%Y%m%d).sql"
```

---

## 3. Play Store Emergency Rollback Procedure

If a critical regression is discovered during a staged release:

### Immediate Action (Within 5 Minutes)
1. Navigate to **Google Play Console -> Release -> Production**.
2. Click **Halt Rollout** on the active release track. This immediately freezes distribution to new users.
3. The existing percentage of users who downloaded the update can be served a remote configuration maintenance banner or forced update prompt.

### Hotfix Rollback Deployment (Within 2 Hours)
In the Google Play Store, apps cannot be rolled back to a lower version code. To roll back:
1. Revert Git to the previous stable release commit:
   ```bash
   git checkout tags/v1.0.0-stable
   ```
2. Increment `versionCode` in `pubspec.yaml` (e.g. `versionCode 3` with `version: 1.0.1+3`).
3. Build and publish the hotfix AppBundle:
   ```bash
   flutter build appbundle --release --flavor prod
   ```
4. Upload to the Production Track at 100% rollout.

---

## 4. Machine Learning Model Lifecycle & Upgrade Path
Upajo uses a hybrid **edge-first + cloud fallback** model lifecycle:

```
[Mobile App (On-Device)]
   │
   ├── 1. Check Local Custom Directory (Documents: disease_model_v2.tflite)
   │        └── If present & hash verified -> Load in Interpreter
   │
   ├── 2. Fallback to Asset Model (Bundled: disease_model_v1.tflite)
   │        └── If local file absent -> Run bundled model
   │
   └── 3. Fallback to Cloud Inference (FastAPI: /api/v1/disease/predict)
            └── If on-device inference fails or device RAM < 1 GB
```

### Remote Model Over-The-Air (OTA) Updating
1. **Remote Config Payload**:
   ```json
   {
     "model_version": "2.1.0",
     "model_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
     "download_url": "https://storage.upajo.in/models/disease_mobilenet_v2.1.tflite"
   }
   ```
2. **Background Download**:
   - The app verifies WiFi or non-metered network availability.
   - Streams the new 4.18 MB TFLite model to temporary storage.
   - Compares SHA-256 checksum to prevent corrupted or tampered models.
   - Atomically renames the file to `disease_model_active.tflite`.
   - The next leaf scan automatically uses the upgraded model without requiring a Play Store APK update!
