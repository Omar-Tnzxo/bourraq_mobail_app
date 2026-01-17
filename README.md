# 🛒 Bourraq - بُـــــراق

<div align="center">

**طلباتك، بين إيديك**  
*Your Orders, In Your Hands*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Development Status](#-development-status)

---

## 🎯 Overview

**Bourraq** is a modern grocery and services delivery application built for **6th of October City, Giza, Egypt**. The app connects customers with local merchants and provides fast delivery within 30 minutes.

### Business Model

- **Customer App** (Flutter) - Browse and order from local merchants
- **Merchant Dashboard** (Web) - Manage products and inventory
- **Pilot System** (Web) - Delivery management
- **Moderation Panel** (Web) - Order review and approval

### Supported Areas (Initial Launch)

**المحافظة:** الجيزة | **المدينة:** مدينة 6 أكتوبر

**المناطق:** ابني بيتك 2-7 • حدائق أكتوبر • دهشور • ميليشيا • حورس • دار مصر • ستان مصر • 390 فدان

---

## ✨ Features

### ✅ Implemented (MVP Phase 1-4)

#### 🔐 Authentication

- [x] Splash screen with animations
- [x] Onboarding (3 pages)
- [x] Email/Password + OTP
- [x] Google Sign-In (UI)
- [x] Guest mode

#### 🏠 Home Screen

- [x] Header with location
- [x] Banners carousel
- [x] Categories grid
- [x] Products grid
- [x] Bottom navigation

#### 🛍️ Products

- [x] Product cards
- [x] Product details
- [x] Add to cart

#### 🛒 Shopping Cart

- [x] Full cart system
- [x] Persistence
- [x] Quantity controls

### 🔜 Coming Soon

- [ ] Location & Maps
- [ ] Address management
- [ ] Search
- [ ] Checkout & Orders
- [ ] Payment (PayMob)
- [ ] Notifications (FCM)

---

## 🔧 Tech Stack

**Frontend:** Flutter 3.x • flutter_bloc • go_router • easy_localization  
**Backend:** Supabase (PostgreSQL) • Edge Functions (Deno)  
**Services:** PayMob • FCM • Google Maps

---

## 🚀 Getting Started

### Installation

```bash
# Clone & install
git clone https://github.com/your-org/bourraq.git
cd bourraq
flutter pub get

# Configure Supabase in lib/main.dart
# Apply migrations from supabase/migrations/

# Run
flutter run
```

---

## 📁 Project Structure

```
lib/
├── core/              # Constants, theme, router
├── features/          # Feature modules
│   ├── auth/         # Login, Register, OTP
│   ├── cart/         # Shopping cart
│   ├── home/         # Home screen
│   └── products/     # Product details
└── main.dart

assets/
├── fonts/            # PING AR
└── translations/     # ar.json, en.json

supabase/
└── migrations/       # Database schema
```

---

## 📊 Development Status

| Phase | Status | Progress |
|-------|--------|----------|
| Setup | ✅ | 100% |
| Authentication | 🔄 | 90% |
| Home & Products | 🔄 | 80% |
| Cart | ✅ | 100% |
| Location | ⏳ | 0% |

**Overall: ~35% Complete**

---

## 🎨 Design

**Colors:** #87BF54 (Green) • #CAFF00 (Yellow)  
**Font:** PING AR (all weights)  
**References:** Rabbit, Breadfast, Talabat

---

## 📞 Contact

🌐 [bourraq.com](http://www.bourraq.com/)  
📱 [WhatsApp](https://wa.me/+201102450471)  
📧 [bourraq.com@gmail.com](mailto:bourraq.com@gmail.com)

---

<div align="center">

Made with ❤️ in Egypt 🇪🇬

**بُـــــراق** - طلباتك، بين إيديك

</div>
