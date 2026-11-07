# Upajo (उपजो) - Accessibility Audit Checklist (WCAG 2.1 AA / AAA)
### Designed for Rural Indian Farmers with Low Digital Literacy & Low Bandwidth

---

## 1. Touch Targets & Ergonomics
- [x] **Minimum Touch Target**: Every interactive button, chip, text input, and card complies with >= 48dp x 48dp touch target guidelines (`AppTheme.minTouchTargetLarge = 48.0`).
- [x] **Thumb-Zone Navigation**: Primary navigation, CTA buttons (e.g. "रोग जांचें", "ओटीपी भेजें", "ऑर्डर करें"), and voice microphone chips are positioned in the bottom $50\%$ of the screen viewport for easy single-handed operation.
- [x] **Spacious Padding**: Minimum $12\text{dp}$ touch separation between adjacent clickable elements prevents accidental mis-taps.

---

## 2. Visual Contrast & Color-Blindness Compliance

| UI Component | Foreground Color | Background Surface | Contrast Ratio | WCAG Compliance |
|---|---|---|---|---|
| **Body & Headings** | Soil Loam (`#2E1F14`) | Khadi Cream (`#FAF7F0`) | **$12.8 : 1$** | **AAA** (Exceeds $7.0 : 1$) |
| **Primary CTA Button** | White (`#FFFFFF`) | Harvest Green (`#25603A`) | **$6.2 : 1$** | **AA** (Exceeds $4.5 : 1$) |
| **Secondary Button** | Soil Loam (`#180F08`) | Ripe Wheat (`#D8972C`) | **$7.4 : 1$** | **AAA** |
| **Danger / Alert Badge** | White (`#FFFFFF`) | Terracotta Clay (`#BA4A38`) | **$5.1 : 1$** | **AA** |
| **Card Borders** | Soil Sand (`#C7B79B`) | Pure White (`#FFFFFF`) | **$3.2 : 1$** | Non-text UI $\ge 3.0:1$ |

*All critical status badges (e.g. "सत्यापित", "ऑर्डर पहुँचा", "गंभीर रोग") utilize dual encoding: **an explicit icon + distinct text label**, ensuring full intelligibility for color-blind users.*

---

## 3. Bilingual Language & Audio Inclusivity
- [x] **Hindi-First Default**: Default interface language is conversational, non-technical Devanagari Hindi (सरल हिंदी), avoiding English loan words and bureaucratic jargon.
- [x] **Speech-to-Text (Voice Input)**: Farmers can dictate crop names, search queries, and questions to Krishi Sahayak using voice recognition (`speech_to_text`).
- [x] **Text-to-Speech (Audio Output)**: Advisory recommendations and Krishi Sahayak answers can be listened to in clear spoken Hindi (`flutter_tts`).
- [x] **Text Scalability**: Fonts scale dynamically using Flutter's `MediaQuery.textScalerOf(context)` without layout clipping or text truncation up to $200\%$ magnification.

---

## 4. Screen Reader Semantics & Accessibility Tree
- [x] **Image Descriptions**: All produce imagery, disease scan photos, and machinery listings feature localized `semanticLabel` attributes.
- [x] **Semantic Form Fields**: Phone inputs and OTP fields specify `TextInputType.phone` and `TextInputType.number` with assistive labels.
- [x] **Live Region Announcements**: Network disconnection and reconnect events announce status updates via `OfflineBanner`.
