# Upajo (उपजो) — Brand Identity & Design System Guidelines

---

## 1. Brand Identity & Purpose
- **Brand Name**: Upajo (Devanagari: उपजो)
- **Pronunciation**: /ʊp.dʒoː/ ("Up-joe")
- **Etymology**: Derived from the Sanskrit root *Upaja* (उपज) meaning *produce, harvest, fertility, and organic growth*.
- **Mission**: To dismantle agricultural exploitative monopolies by establishing a direct, transparent digital bridge between rural Indian farmers and urban/suburban consumers with zero middlemen, fair remuneration, and authentic organic traceability.

---

## 2. Official Taglines (Strict Single-Script per Locale)

| Locale | Official Tagline | Tone & Nuance |
| :--- | :--- | :--- |
| **हिन्दी (Hindi)** | **सीधे खेत से घर तक — 100% शुद्ध एवं पारदर्शी** | आत्मीय, विश्वासपात्र, पारंपरिक एवं सच्चा |
| **English** | **Direct from farm to fork — 100% pure & transparent** | Crisp, authoritative, modern agtech |
| **Hinglish** | **Seedhe khet se ghar tak — 100% shuddh aur transparent** | Natural, accessible, urban conversational |

---

## 3. Brand Color Palette

Upajo's palette is grounded in the organic lifecycle of traditional Indian farmland: fertile alluvial black soil, ripening winter wheat fields, handmade terracotta clay cups (*kulhad*), and sun-bleached handloom khadi.

```
+-------------------------------------------------------------------------------+
| HARVEST GREEN   | WHEAT GOLD     | TERRACOTTA CLAY | KHADI CREAM    | DARK LOAM       |
| #25603A         | #D8972C        | #BA4A38         | #FAF7F0        | #2E1F14         |
| Primary CTA     | Badges/Trends  | Alerts/Warning  | Base Canvas    | High-Contrast   |
+-------------------------------------------------------------------------------+
```

### Color Tokens & Hex Codes

| Token Name | Hex Code | Semantic Role & Guidance |
| :--- | :--- | :--- |
| **Primary 500 (Harvest Green)** | `#25603A` | Primary brand color, main call-to-action buttons, active navigation indicator, verified badges. |
| **Primary 600 (Forest Canopy)** | `#1B492C` | Deep high-contrast buttons, app bar text, pressed states. |
| **Wheat 500 (Ripe Wheat Gold)** | `#D8972C` | Mandi market trends, rating stars, premium produce tags. |
| **Clay 500 (Terracotta Kulhad)** | `#BA4A38` | Destructive actions (Cancel, Delete), high-priority disease alerts, price drop flags. |
| **Soil 50 (Khadi Cream)** | `#FAF7F0` | Scaffold background. Softer on farmers' eyes under direct sunlight than clinical pure white `#FFFFFF`. |
| **Soil 100 (Sand Dune)** | `#F2ECE1` | Card surfaces, container dividers, subtle chips. |
| **Soil 200 (Field Ridge Border)** | `#E2D7C3` | Outlines, borders, subtle card separation lines. |
| **Soil 800 (Dark Loam)** | `#2E1F14` | Primary body typography (Contrast ratio > 11.5:1 against Soil 50, WCAG AAA compliant). |
| **Soil 600 (Earth Silt)** | `#524530` | Secondary typography, captions, hints. |

---

## 4. Typography Scale

- **Primary Font**: `Noto Sans Devanagari` (Bundled in `assets/fonts/`).
- **Characteristics**: Crisp geometric balance designed specifically for complex Indian conjuncts (*samyukt-akshar*), matras, and halants.
- **Hierarchy**:
  - `displayLarge`: 32sp, SemiBold / ExtraBold (W900), -0.5px letter spacing
  - `headlineMedium`: 22sp, Bold (W700), Soil 800
  - `titleMedium`: 16sp, Medium (W600), Soil 800
  - `bodyLarge`: 15sp, Regular (W400), Soil 800, 1.4 line-height
  - `bodyMedium`: 13.5sp, Regular (W400), Soil 700
  - `labelLarge`: 14sp, SemiBold (W600), Button & Action text

---

## 5. Logo Construction & Rules

- **The Symbol**:
  - A resilient two-leaf young seedling emerging vertically from three parallel curved soil furrow ridges.
  - Symmetrical, balanced, and readable from 24px icon sizes to billboard dimensions.
- **Clear Space**:
  - Maintain a minimum margin equal to `1x` (where `x` is the height of the sprout leaf) around all edges of the logo.
- **Minimum Sizing**:
  - Digital screens: `24px x 24px` for app bar and status bars.
  - Print: `10mm x 10mm`.
- **Permitted Variants**:
  1. Full-color mark on Light/Khadi backgrounds (Harvest Green `#25603A` + Soil furrow lines).
  2. Full-color mark on Dark backgrounds (Wheat Gold `#D8972C` + Green `#4ADE80`).
  3. Monochrome pure Black (`#000000`).
  4. Monochrome pure White (`#FFFFFF`).
- **Strict Prohibitions**:
  - DO NOT apply drop shadows, 3D skeuomorphic bevels, or generic AI gradients.
  - DO NOT stretch, skew, or rotate the symbol.
  - DO NOT replace the font with cursive or script typefaces.

---

## 6. Voice and Tone Guidelines

- **Empowering, Not Paternalistic**: Farmers are seasoned professionals running essential enterprises; address them with dignity, precision, and respect.
- **Plain Speech Over Tech Jargon**: Say *"खेती की जानकारी"* instead of *"एआई एनालिटिक्स एल्गोरिदम"*. Say *"खाता बनाएं"* instead of *"यूजर रजिस्ट्रेशन ऑथेंटिकेशन"*.
- **High Clarity**: One primary action per card or viewport. Critical figures (₹ amount, quintals, kg, dates) must be prominently formatted using localized separators.

