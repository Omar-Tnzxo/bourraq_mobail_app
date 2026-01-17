# Bourraq Brand Identity Guide | دليل الهوية البصرية لبُراق

> **⚠️ CRITICAL**: This document defines ALL visual identity rules that MUST be followed during development. Any deviation from these guidelines is strictly prohibited.

---

## Table of Contents | جدول المحتويات

1. [Brand Overview](#brand-overview)
2. [Logo System](#logo-system)
3. [Color Palette](#color-palette)
4. [Typography](#typography)
5. [Icons System](#icons-system)
6. [Safe Zones & Spacing](#safe-zones--spacing)
7. [Usage Guidelines](#usage-guidelines)
8. [Implementation Reference](#implementation-reference)

---

## Brand Overview

### Brand Name

- **English**: BOURRAQ
- **Arabic**: بُراق

### Brand Essence

- **Tagline EN**: "Your orders, at your fingertips"
- **Tagline AR**: "طلباتك، بين إيديك"

### Brand Story
>
> استعد لرحلة توصيل سلسة، نعتني فيها بكل التفاصيل ونمهد لك كل خطوة لتصل طلباتك بسرعة وأمان مع براق.

---

## Logo System

### Logo Concept | مفهوم الشعار

The logo is constructed from 4 key elements:

```
Letter B + حرف الباء + حقيبة التسوق + أقدام = الشعار المتحرك
(Letter B) + (Arabic Ba) + (Shopping Bag) + (Running Feet) = Animated Logo
```

### Logo Versions | نسخ الشعار

#### 1. Static Logo (الشعار الثابت)

- Bag icon with Arabic-English text
- Used for formal applications
- Clear zone: 50px minimum

#### 2. Animated/Running Logo (الشعار المتحرك)

- Bag character with running legs and sparkle star
- Used for app, digital media, and engaging contexts
- Conveys speed, motion, and delivery

### Logo Color Variations | النسخ اللونية للشعار

| Variant | Background | Logo Color | Usage |
|---------|------------|------------|-------|
| Primary | White | Dark Green (#226923) | Default, light backgrounds |
| Inverted Light | Light Green (#87BF54) | White | Light green backgrounds |
| Inverted Dark | Dark Green (#226923) | White + Light Green accent | Dark backgrounds |
| Photo Overlay | Image | White | Marketing materials |

### Logo Files Reference

```
📁 bourraq-assets/bourraq-logos-png/
├── 1.png          → Running logo (Light Green, transparent bg)
├── 2.png          → Sparkle star element only (Light Green)
├── 3.png          → Running logo (Dark Green with Light sparkle, transparent bg)
├── 4.png          → Running logo (Dark Green, transparent bg)
├── Artboard_11.png     → Running logo (Light Green on Dark Green bg)
├── Artboard_11_copy.png → Variations
├── Asset_2.png    → Text logo only (Arabic + English)
├── Asset_3.png    → Icon only
├── Asset_5-24.png → Various logo variations
```

---

## Color Palette

### Primary Colors | الألوان الرئيسية

> **Rule**: Use these colors at 100% intensity. Never adjust opacity unless specified.

| Name | HEX | RGB | Usage |
|------|-----|-----|-------|
| **Light Green** | `#87BF54` | 135, 191, 84 | Primary brand color, buttons, highlights, running logo |
| **Dark Green** | `#226923` | 34, 105, 35 | Logo text, headers, CTA buttons, text on light bg |
| **Grey Green** | `#92A092` | 146, 160, 146 | Subtle backgrounds, disabled states, secondary elements |
| **Olive Green** | `#113511` | 17, 53, 17 | Deep accents, footers, ultra-dark mode elements |

### Secondary Colors | الألوان الفرعية

> **Usage**: For social media, marketing materials, status indicators, and accent elements.

| Name | HEX | RGB | Usage |
|------|-----|-----|-------|
| **Yellow** | `#F340a3` | (Yellow variant) | Warnings, highlights |
| **Red** | `#EB803d` | (Red variant) | Errors, alerts, urgent notifications |
| **Purple** | `#280480` | (Purple variant) | Premium features, special promotions |
| **Blue** | `#d3f364` | (Blue variant) | Information, links |
| **Orange** | `#F2b5d0` | (Orange variant) | Promotions, offers |
| **Green Accent** | `#f6d352` | (Light accent) | Success states |

### Color Application Rules

```dart
// ✅ CORRECT Usage
const Color bourraqPrimary = Color(0xFF87BF54);    // Light Green
const Color bourraqSecondary = Color(0xFF226923);  // Dark Green
const Color bourraqSurface = Color(0xFF92A092);    // Grey Green
const Color bourraqDark = Color(0xFF113511);       // Olive Green

// ❌ WRONG - Never use
// - Pure green (#00FF00)
// - Generic colors not in palette
// - Opacity modifications without design approval
```

---

## Typography

### Primary Font Family | الخط الرئيسي

**Font**: PING AR LT (بينج العربي)
**Type**: Bilingual Arabic-Latin font
**Weights Available**: 9 weights

### Font Weights | أوزان الخط

```
📁 bourraq-assets/fonts/
├── PingAR+LT-Hairline.otf  → Hairline (الأخف)
├── PingAR+LT-Thin.otf      → Thin
├── PingAR+LT-ExtraLight.otf → Extra Light
├── PingAR+LT-Light.otf     → Light
├── PingAR+LT-Regular.otf   → Regular ✓ (Body text)
├── PingAR+LT-Medium.otf    → Medium ✓ (Subheadings)
├── PingAR+LT-Bold.otf      → Bold ✓ (Headings)
├── PingAR+LT-Heavy.otf     → Heavy
└── PingAR+LT-Black.otf     → Black (الأثقل)
```

### Typography Hierarchy

| Element | Arabic Example | Weight | Size (Mobile) |
|---------|---------------|--------|---------------|
| **Main Title** | عليــكم بحســن | Bold/Black | 32-40px |
| **Secondary Title** | عنوان ثانوي | Medium/Bold | 24-28px |
| **Subtitle** | عنوان فرعي | Regular/Medium | 18-20px |
| **Body Text** | براق طلباتك بين إيديك | Regular | 14-16px |

### RTL/LTR Support

```dart
// ✅ Always implement bidirectional text support
TextDirection.rtl  // Arabic
TextDirection.ltr  // English
```

---

## Icons System

### Icon Style | نمط الأيقونات

> All icons must follow these specifications:

- **Grid**: 2px base unit
- **Stroke Width**: 2px consistent
- **Corner Radius**: 90° rounded corners (when applicable)
- **Style**: Outline/Linear icons (not filled)
- **Color**: Single color from brand palette

### Icon Grid Specifications

```
┌─────────────────┐
│     2px units   │
│   ┌─────────┐   │
│   │    +    │   │  ← Icons drawn on 2px grid
│   └─────────┘   │
│                 │
└─────────────────┘
```

### Standard Icon Set (from identity)

| Category | Icons |
|----------|-------|
| Navigation | Page, Arrow, Home, Settings |
| Actions | Add (+), Edit, Delete, Search |
| Commerce | Cart, Bag, Location, Payment |
| Communication | Notification, Chat, Phone |
| User | Profile, Group, Shield |

---

## Safe Zones & Spacing

### Logo Safe Zone

> **Minimum clearance around logo**: 50px

```
         ← 50px →
        ┌─────────────────────┐
   ↑    │                     │
  50px  │   ┌───────────┐     │
        │   │   LOGO    │     │
        │   └───────────┘     │
   ↓    │                     │
  50px  └─────────────────────┘
         ← 50px →
```

### Spacing System

Use consistent spacing multiples:

```dart
const double spacingXS = 4.0;   // Extra Small
const double spacingSM = 8.0;   // Small
const double spacingMD = 16.0;  // Medium (Base)
const double spacingLG = 24.0;  // Large
const double spacingXL = 32.0;  // Extra Large
const double spacing2XL = 48.0; // 2X Large
```

---

## Usage Guidelines

### ✅ DO's

1. **Always maintain safe zone** around logo
2. **Use exact HEX values** from color palette
3. **Use PingAR font family** for all text
4. **Apply consistent spacing** using the spacing system
5. **Use running logo** for app and digital media
6. **Maintain color contrast** for accessibility

### ❌ DON'Ts

1. **Never stretch or distort** the logo
2. **Never change logo colors** outside defined variations
3. **Never use drop shadows** on logo
4. **Never place logo on busy backgrounds** without proper overlay
5. **Never use fonts outside PingAR family** without approval
6. **Never mix color palettes** from different brands

---

## Implementation Reference

### Flutter Theme Configuration

```dart
// app_colors.dart
class AppColors {
  // Primary Palette
  static const Color primaryLight = Color(0xFF87BF54);
  static const Color primaryDark = Color(0xFF226923);
  static const Color surfaceGrey = Color(0xFF92A092);
  static const Color deepOlive = Color(0xFF113511);
  
  // Secondary Palette
  static const Color warning = Color(0xFFF340A3);
  static const Color error = Color(0xFFEB803D);
  static const Color info = Color(0xFF280480);
  static const Color accent = Color(0xFFF2B5D0);
  static const Color success = Color(0xFFF6D352);
}

// app_typography.dart
class AppTypography {
  static const String fontFamily = 'PingAR';
  
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700, // Bold
    fontSize: 32,
  );
  
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400, // Regular
    fontSize: 16,
  );
}
```

### Asset Paths Reference

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: PingAR
      fonts:
        - asset: assets/fonts/PingAR+LT-Regular.otf
        - asset: assets/fonts/PingAR+LT-Medium.otf
          weight: 500
        - asset: assets/fonts/PingAR+LT-Bold.otf
          weight: 700
        - asset: assets/fonts/PingAR+LT-Black.otf
          weight: 900
  
  assets:
    - assets/icons/logo_running.png
    - assets/icons/logo_static.png
    - assets/icons/sparkle.png
```

---

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Created | 2026-01-13 |
| Source | Bourraq Identity PDF (Ibruvisuals Creative Studio) |
| Purpose | AI Development Reference |

---

> **📌 Note for AI Agents**: This document is the single source of truth for all visual decisions. Reference specific sections when implementing UI components.
