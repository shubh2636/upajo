# Upajo (उपजो) — UI Polish, Localization Rebuild & Branding Overhaul Report

## Executive Summary
This report documents the end-to-end transformation of the **Upajo** mobile application (Flutter, Riverpod, go_router, easy_localization) and companion Python ML Microservice. The overhaul eliminated all mixed bilingual strings (e.g. "खाता बनाएं (Sign Up)"), established 3 pure-script locales (`en`, `hi`, `hi-Latn`), created an earthy Farmland Design System with authentic visual motifs, generated complete vector branding assets, verified small-device (360dp) and accessibility (1.5x font scale) responsiveness, and passed full automated test suites.

---

## 1. Localization Rebuild (3 Pure Locales)

### Core Rules & Architecture
1. **Zero Mixed Script Strings**: Screens show ONLY the chosen language. No "Hindi (English)" or mixed Latin/Devanagari strings except the brand name ("Upajo" / "उपजो") and language picker switcher previews.
2. **Three First-Class Locales**:
   - `hi` (हिन्दी): Pure Devanagari Hindi (e.g. "खाता बनाएं", "मोबाइल नंबर", "पासवर्ड दर्ज करें").
   - `hi-Latn` (Hinglish): Conversational Hindi in Roman/Latin script (e.g. "Khaata banayein", "Mobile number", "Password daalein").
   - `en` (English): Clean, modern English (e.g. "Create Account", "Mobile Number", "Enter Password").
3. **Bundled Typography**: Bundled Google `NotoSansDevanagari-Regular.ttf` and `NotoSansDevanagari-Bold.ttf` in `assets/fonts/` and registered in `pubspec.yaml` and `AppTheme`. Conjuncts render correctly offline without runtime font downloads.
4. **Formatting per Locale**: `lib/core/utils/formatters.dart` formats Indian currency (`₹`), weight units (`kg` vs. `किग्रा`), and land areas (`acres` vs. `एकड़`) dynamically based on active locale.
5. **Key Parity & Integrity Enforcement**: Automated test `test/unit/localization_parity_test.dart` asserts:
   - Identical key count and identical key sets across `en.json`, `hi.json`, and `hi-Latn.json` (~490+ keys each).
   - Zero missing keys in any locale file.
   - Zero Devanagari characters in `en.json` or `hi-Latn.json`.
   - Pure Devanagari in `hi.json` (Latin text strictly restricted to technical acronyms, units, and brand name).

---

## 2. Dynamic Language Switcher

1. **First-Launch Onboarding (`LanguageSelectScreen`)**:
   - 3 clean interactive cards (हिन्दी, English, Hinglish) displaying script badges (`अ`, `A`, `Aa`) and localized sample lines ("सीधे खेत से थाली तक, सच्चा मंच").
   - Selection persists to `SharedPreferences` and synchronizes with user profile.
2. **Persistent Global Switcher (`LanguageSwitcherButton`)**:
   - Globe icon + current locale pill with >=48dp touch target.
   - Embedded in `WelcomeScreen`, `LoginScreen`, `SignupScreen`, and `ProfileScreen`.
   - Bottom sheet modal applies locale instantly (`context.setLocale(...)`) with zero app restart.
3. **Automated Verification**:
   - `test/widget/language_switch_test.dart` dynamically tests language switching across 10 core screens:
     1. `LanguageSelectScreen`
     2. `WelcomeScreen`
     3. `LoginScreen`
     4. `SignupScreen`
     5. `ForgotPasswordScreen`
     6. `VerifyOtpScreen`
     7. `RoleSelectionScreen`
     8. `DeleteAccountScreen`
     9. `EmptyStateView`
     10. `ErrorView`

---

## 3. Farmland Design System & Responsiveness

### Color Tokens (`AppColors`)
| Token | Hex | Role |
| :--- | :--- | :--- |
| `primary` / `harvestGreen` | `#25603A` | Deep crop green, primary buttons, active tabs |
| `primaryDark` / `forestCanopy` | `#1B492C` | Deep forest green for app bars, headers, contrast |
| `accent` / `wheatGold` | `#D8972C` | Ripe wheat gold for secondary highlights, CTA badges |
| `terracottaClay` | `#BA4A38` | Warm clay terracotta for alerts, badges, warnings |
| `surfaceCream` / `khadiCream` | `#FAF7F0` | Warm Indian khadi cream background |
| `textPrimary` / `darkLoam` | `#2E1F14` | High contrast dark loam soil tone for crisp typography |
| `surfaceCard` | `#FFFFFF` | Crisp card background with warm subtle border |

### Signature Motifs
- `SeedSproutMotif` (`lib/core/widgets/brand_motifs.dart`): Custom geometric vector painter featuring twin leaves and root node, used on splash screen, auth hero banners, loaders, and empty states.
- `FurrowHeaderPattern`: Subtle agricultural soil furrow line pattern used in `AppAppBar` and screen headers.

### Standard Components
- `AppButton`: Minimum 48dp height, accessible high-contrast text, flexible content layout, loading spinner.
- `AppTextField`: Clear label, hint, helper/error text, accessibility semantics, earth-toned borders.
- `AppCard`: Subtle border `#E2D7C3`, rounded radius (12-16dp), elevation-free flat elevation design.
- `AppAppBar`: Earthy styling, brand wordmark, integrated `LanguageSwitcherButton`.
- `AppSkeleton`: Shimmer placeholder loaders matching card layouts during data fetches.

### Small Device & Large Font Scale Responsiveness
- All 38 screens tested on **360dp width** (budget Android smartphones) and **1.5x accessibility text scale**.
- Verified zero `RenderFlex` overflows via `test/widget/design_system_responsiveness_test.dart` (16 tests passing).

---

## 4. Branding & Visual Assets

All assets generated and located in `/brand`:
1. **Brand Guidelines**: `brand/brand_guidelines.md` (vision, tone, palette, typography, logo rules).
2. **Vector Logos**:
   - `brand/logo/logo_symbol.svg` (Signature seed & furrow mark)
   - `brand/logo/logo_wordmark.svg` (Full symbol + Upajo wordmark)
   - `brand/logo/logo_symbol_mono_black.svg` & `logo_symbol_mono_white.svg`
   - `brand/logo/logo_wordmark_mono_black.svg` & `logo_wordmark_mono_white.svg`
3. **Android App Launcher Icons**:
   - Adaptive foreground/background/monochrome in `android/app/src/main/res/drawable/`
   - Density-specific PNG icons (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) for launcher and round icons.
   - Status bar notification silhouette (`ic_notification.xml`, 24dp pure white).
   - Android 12 Splash API (`android/app/src/main/res/values-v31/styles.xml`).
4. **Play Store Materials**:
   - High-res 512x512 app icon: `brand/playstore/icon_512.png`
   - Feature graphic 1024x500: `brand/playstore/feature_graphic_1024x500.svg`
   - Localized Store Metadata: `brand/playstore/METADATA.md` (App titles, 80-char short descriptions, full descriptions in `en`, `hi`, `hi-Latn`, plus 8 screenshot frame specs).
5. **Legal & Trademark Checklist**: `brand/NAME_VERIFICATION_CHECKLIST.md` (Detailed steps for IP India Classes 9, 31, 35, 42, MCA company search, and domain availability).

---

## 5. Before vs. After Screen Audit (38 Screens)

| # | Screen | Before State | After State |
| :--- | :--- | :--- | :--- |
| 1 | `LanguageSelectScreen` | Generic placeholder | 3 interactive cards with script badges, localized previews, responsive layout |
| 2 | `WelcomeScreen` | Mixed bilingual "खाता बनाएं (Sign Up)", overflow on 1.5x font scale | Clean hero with `SeedSproutMotif`, localized CTA buttons, `LanguageSwitcherButton` |
| 3 | `LoginScreen` | Hardcoded Hindi labels, mixed hint texts | Pure localized strings via `.tr()`, 48dp buttons, language switcher |
| 4 | `SignupScreen` | "पासवर्ड (Password, min 8 chars)", "मजबूत (Strong)" | 100% pure script strings, responsive scroll view, instant validation |
| 5 | `ForgotPasswordScreen` | Hardcoded Hindi literals | Localized recovery flow with email/phone selection |
| 6 | `VerifyOtpScreen` | Generic English dialogs | Localized 6-digit pin input with retry countdown |
| 7 | `RoleSelectionScreen` | Cluttered cards, fixed heights | 3 clean role cards (Farmer, Buyer, Driver) with responsive spacing |
| 8 | `DeleteAccountScreen` | Hardcoded warnings | Localized multi-step confirmation dialog with explicit reason selection |
| 9 | `SplashScreen` | Default flutter circle | Branded `SeedSproutMotif` and warm background |
| 10 | `AboutScreen` | Missing / template | Branded about screen with version 1.0.0, license, and company details |
| 11 | `FarmerHomeScreen` | Generic purple gradients | Earthy dashboard, harvest stats, weather widget, quick actions |
| 12 | `FarmerAnalyticsScreen` | Mixed literals | Localized charts, yield trends, revenue cards |
| 13 | `CropAdvisorScreen` | Hardcoded ICAR advice strings | Clean parameter form, localized ICAR advice chips |
| 14 | `CropCalendarScreen` | Hardcoded Hindi calendar dates | Dynamic calendar with Noto Sans Devanagari typography |
| 15 | `KrishiSahayakScreen` | Mixed language chat bubbles | Pure localized prompt suggestions and chat bubbles |
| 16 | `DiseaseDetectionScreen` | Broken file upload texts | Camera/Gallery picker with localized confidence meters |
| 17 | `DiseaseResultScreen` | Hardcoded English disease remedies | Dynamic localized treatment protocols |
| 18 | `MandiPricesScreen` | Unformatted currency, mixed titles | Dynamic Agmarknet mandi rates with ₹ formatting and search |
| 19 | `MandiPriceChartScreen` | Cluttered axes | High-contrast trend chart with clean localized tooltip |
| 20 | `MachineryScreen` | Hardcoded district names | Localized machinery categories, rent-per-day formatters |
| 21 | `MachineryDetailScreen` | Low contrast booking buttons | Accessible 48dp booking action, deposit breakdown |
| 22 | `AddMachineryScreen` | Mixed form validation messages | Localized input fields with photo picker |
| 23 | `MyRentalsScreen` | Missing empty states | Branded empty state with `SeedSproutMotif` |
| 24 | `StoreCatalogScreen` | Mixed item titles | Clean agri-input catalog with category filters |
| 25 | `ProductDetailScreen` | Duplicate icons, hardcoded prices | Localized specs, certified seed badges, add-to-cart |
| 26 | `CartScreen` | Inconsistent spacing | Item list with quantity steppers and price breakdown |
| 27 | `CheckoutScreen` | Missing import, mixed addresses | Pure localized shipping form and payment selection |
| 28 | `OrderSuccessScreen` | Template tick | Branded celebration graphic with order tracking link |
| 29 | `MyOrdersScreen` | Missing status labels | Localized status chips (Delivered, Shipped, Processing) |
| 30 | `CommunityForumScreen` | Hardcoded Hindi post tags | Localized discussion categories and upvote counters |
| 31 | `CreatePostScreen` | Hardcoded placeholders | Localized title/content editor with image attach |
| 32 | `PostDetailScreen` | Mixed comment timestamps | Localized date formatters and comment thread |
| 33 | `LogisticsBookingScreen` | Broken truck type labels | Capacity-based vehicle selector with rate estimates |
| 34 | `TrackingScreen` | Hardcoded driver info | Live route tracking with localized driver status |
| 35 | `ProfileScreen` | Mixed bilingual menu items | Clean profile header with direct language picker and settings |
| 36 | `EditProfileScreen` | Untranslated farm size units | Localized acres/hectares units and crop history |
| 37 | `EmptyStateView` | Generic gray icon | Branded `SeedSproutMotif` with action button |
| 38 | `ErrorView` | Raw exception dump | User-friendly localized message with retry button |

---

## 6. ML Microservice / Swagger Documentation Fixes
- **Root Cause of White Screen on `/docs`**:
  - `SecurityHeadersMiddleware` applied `Content-Security-Policy: default-src 'none'` to `/docs/` due to strict trailing slash matching, blocking all browser scripts and stylesheets.
  - Custom HTML attempted to initialize `StandaloneLayout` without the required standalone preset, causing a silent JavaScript crash.
- **Resolution**:
  - Corrected `SecurityHeadersMiddleware` to exempt all variations of `/docs`, `/docs/`, and `/static`.
  - Switched Swagger UI configuration to standard `BaseLayout` with `SwaggerUIBundle.presets.apis`.
  - Added zero-JS HTML visual dashboard at root `http://127.0.0.1:8000/`.
  - Both `http://127.0.0.1:8000/docs` and `http://127.0.0.1:8000/docs/` now load cleanly in all modern browsers.

---

## 7. Remaining Decisions & Next Steps for User
1. **Supabase Credentials**:
   - Set real `SUPABASE_URL` and `SUPABASE_ANON_KEY` when running against your live Supabase cloud project:
     ```bash
     flutter run --flavor dev --dart-define=SUPABASE_URL="https://your-real-id.supabase.co" --dart-define=SUPABASE_ANON_KEY="your-real-anon-key" --dart-define=API_BASE_URL="http://10.0.2.2:8000"
     ```
2. **Trademark Search**:
   - Review `brand/NAME_VERIFICATION_CHECKLIST.md` and conduct official search on `ipindiaonline.gov.in` for Classes 9, 31, 35, and 42 before commercial launch.
3. **App Store Deployment**:
   - Review `brand/playstore/METADATA.md` for localized store descriptions and prepare screenshot captures using the 8 defined frame specifications.
