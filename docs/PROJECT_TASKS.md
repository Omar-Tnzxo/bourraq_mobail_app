# Bourraq App - Project Tasks & Features

> **Project:** Bourraq - Grocery & Services Delivery App  
> **Platform:** Flutter (Mobile App for Customers Only)  
> **Backend:** Supabase (Database + Edge Functions + Storage)  
> **Created:** 2026-01-10  
> **Last Updated:** 2026-01-16 (Geofencing / Supported Areas Feature)  
> **Status:** Active Development

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Core Features](#core-features)
3. [Detailed Task Breakdown](#detailed-task-breakdown)
4. [Future Features (Soon)](#future-features-soon)
5. [Technical Stack](#technical-stack)
6. [Database Schema Overview](#database-schema-overview)

---

## 🎯 Project Overview

### Business Model

- **Customer App:** تطبيق للعملاء للطلب من تجار محليين في منطقتهم
- **Merchant System:** التجار يضيفوا منتجاتهم عبر موقع Dashboard خارجي
- **Pilot System:** الطيارين يوصلوا الطلبات عبر موقع Dashboard خارجي
- **Moderation:** فريق المراجعة يراجع الطلبات قبل التوصيل
- **Pricing:** التطبيق يضيف markup على أسعار التجار لتحقيق الربح

### Supported Areas (Initial Launch)

- **المحافظة:** الجيزة
- **المدينة:** مدينة 6 أكتوبر
- **المناطق:**
  - ابني بيتك 2، 3، 4، 5، 7
  - حدائق أكتوبر
  - دهشور
  - ميليشيا
  - كومباوند حورس
  - كومباوند دار مصر 6 أكتوبر
  - كومباوند ستان مصر الدون تاون
  - مشروع 390 فدان

### Languages & Localization

- **Arabic (RTL)** - اللغة الأساسية (semi-formal Egyptian dialect)
- **English (LTR)** - اللغة الثانوية
- **Default:** حسب لغة الجهاز (fallback: English)
- **Font:** PING AR

---

## ✨ Core Features

### 1. Authentication & User Management

- [x] Splash screen with brand animation
- [x] Onboarding screens (max 4 screens, dynamic from database)
- [x] Registration with Email + OTP (via Resend service)
- [x] Google Sign-In integration
- [x] Guest mode (browse only, can't order)
- [x] JWT token authentication
- [x] User profile management (edit name, phone, email)
- [x] Account deletion (moves to deleted_users table)
- [x] Phone number validation (max 3 accounts per phone)
- [x] Email uniqueness enforcement

### 2. Location & Area Management

- [x] Auto-detect user location via GPS
- [x] Map location to supported areas (geofencing with radius)
- [x] Manual area selection from predefined list
- [x] Request new area support (stores in area_requests table)
- [x] Multiple addresses per user (max 5)
- [x] Default address selection
- [x] Address types (Apartment, Villa, Office)
- [x] Google Maps integration for address selection
- [ ] Address fields:
  - Location on map
  - Address type
  - Building name
  - Apartment number
  - Floor number (optional)
  - Street name
  - Phone number (auto-filled)
  - Landmark (optional)
  - Address label (optional)

### 3. Home Screen (Dynamic)

- [x] Header with greeting + delivery location
- [x] Dynamic banners carousel
  - Arabic + English images
  - Internal or external links
  - Custom order/priority
  - Start/end dates
  - Custom dimensions (configurable by admin)
- [x] Categories section (images only, no text)
  - Arabic + English images
  - Dynamic from database
- [x] Featured products section
  - "Best sellers" (auto or manual selection)
  - Dynamic title
  - All content configurable by admin
- [x] Pull to refresh
- [x] No search bar on home (search in dedicated tab)

### 4. Products & Categories

- [x] Categories with subcategories (configurable depth)
- [x] Product listing with filters
- [x] Product card design:
  - Product image(s) - swipeable carousel
  - Product name
  - Price (large) + decimal (small)
  - Old price (if discount)
  - Discount badge
  - Favorite heart icon
  - Add to cart (+/-) buttons
- [x] Product details page:
  - Image carousel (unlimited images)
  - Name, price, discount
  - Size/weight with units (gram, kg, ton, etc.)
  - Stock status (available/out of stock)
  - Expandable sections:
    - Description
    - Ingredients
    - Nutritional information
    - Storage instructions
    - Expiry date (if applicable)
  - Similar products section
  - Sticky add to cart button at bottom
- [x] Out of stock handling (configurable):
  - Hide completely
  - Show as disabled
  - [x] Show "notify me when available" (NotifyWhenAvailableButton)
- [x] Product sorting:
  - Price (low to high / high to low)
  - Newest
  - Best selling
- [x] Infinite scroll for product lists
- [ ] Dynamic visibility control (admin can hide/show sections)

### 5. Services (Separate from Products)

- [ ] Service listings (doctors, plumbers, etc.)
- [ ] Service booking flow:
  - Select service
  - Choose date and time
  - Confirm with service provider
  - Different pricing model (consultation vs. visit)
- [ ] Flexible service attributes
- [ ] Add to cart like products

### 6. Search & Discovery

- [x] Dedicated search tab in bottom nav
- [x] Advanced search:
  - Search in product names, descriptions, categories
  - Category-specific search
  - Search within selected category only
- [x] Search history (last 20 searches, auto-delete old)
- [x] Popular searches (chips/tags)
- [x] No voice search
- [x] No filters (price range, etc.)

### 7. Shopping Cart

- [x] Add/remove products
- [x] Quantity controls (+/-)
- [x] Multiple merchants in single cart (allowed)
- [x] Cart persistence (saved even after logout)
- [x] Clear all button
- [ ] View by merchant (optional grouping)
- [x] Minimum order amount validation (configurable)
- [x] No cart expiry

### 8. Favorites/Wishlist

- [x] Add products to favorites (heart icon)
- [x] Dedicated favorites page
- [x] Remove from favorites
- [x] Empty state with suggestions

### 9. Checkout & Orders

- [x] Checkout page with:
  - [x] Cart items review (can edit quantities/remove)
  - [x] Address selection (from saved addresses)
  - [x] Add new address inline
  - [x] Delivery time selection:
    - [x] ASAP (default)
    - [x] Schedule for later (date + time)
  - [x] Payment method selection:
    - [x] Cash on delivery (default)
    - [ ] Credit/debit card (PayMob) - UI ready, integration pending
  - [x] Apply coupon code
  - [x] Order summary:
    - Subtotal
    - Delivery fee (area-based or fixed)
    - Discount
    - Total
  - [x] Confirm order button
- [ ] Online payment (PayMob integration) - Pending
- [x] Order confirmation (order_success_screen.dart)
- [x] Order tracking:
  - [x] Dedicated tracking screen
  - [x] Order status updates
  - [x] Estimated delivery time
  - [ ] Real-time pilot location (Soon)
- [x] Order history:
  - [x] All orders since registration
  - [x] Filter by status
  - [x] Reorder functionality
  - [x] Order details view
- [x] Order cancellation:
  - [x] Cancel with reasons
  - [x] Refund to wallet (if paid online)
- [x] Order rating (rate pilot/experience after delivery)
- [ ] Multi-pilot support for large orders

### 10. Wallet & Payments

- [x] Wallet page (wallet_screen.dart - 568 lines):
  - [x] Display balance
  - [x] Add balance button
  - [x] Saved cards management
- [x] Add balance flow (add_balance_screen.dart):
  - [x] Enter amount (with quick add: 100/200/500/1000)
  - [x] Payment method selection UI
  - [ ] Process payment via PayMob - Pending integration
- [x] Transaction history (view only)
- [ ] Refunds auto-credited to wallet
- [x] Saved cards:
  - [x] Store payment token (NOT raw card details)
  - [x] Card label
  - [x] Delete saved cards

### 11. Discounts & Coupons ✅

- [x] Product discounts (old_price field in products table):
  - [x] Show old price + new price on product cards
  - [x] Discount badge display
- [x] Coupon system (promo_code_service.dart):
  - [x] Enter coupon code at checkout
  - [x] Validation via Supabase promo_codes table
  - [x] Apply discount to order total
- [ ] First order discount (optional, configurable)
- [ ] Discount stacking (configurable by admin)

### 12. Pricing & Markup

- [ ] Merchant sets their product prices
- [ ] System adds markup (percentage or fixed amount)
- [ ] Markup configurable per:
  - Product
  - Category
  - Merchant
- [ ] Show cheapest price to customer (from all merchants)
- [ ] Price display format: 00,000.00 (with commas)

### 13. Notifications

- [x] FCM push notifications
- [x] Notification types:
  - Order confirmed
  - Order on the way
  - Order delivered
  - Order cancelled
  - New offers/promotions (can be disabled)
  - Stock alerts for favorited items
- [ ] Notification preferences (enable/disable by type)
- [x] No in-app notification center
- [x] Retry failed notifications (3 attempts)
- [x] Topic-based (user-specific, area-based, role-based)

### 14. Profile & Settings

- [x] Profile page (account_screen.dart - 771 lines):
  - [x] User greeting (no profile picture)
  - [x] Quick actions: Orders, Promo Codes, Saved Items
  - [x] Wallet balance
  - [x] My Addresses
  - [x] Saved Cards
  - [x] Language switcher (Arabic/English)
  - [x] Help & Support (contact_options_sheet.dart)
  - [x] Terms & Conditions (external link)
  - [x] Privacy Policy (external link)
  - [x] About Us / Follow Us
  - [x] Request new area support
  - [x] Delete account
  - [x] Logout
- [x] Settings:
  - [x] Language switcher
  - [ ] Notification preferences - Pending
- [x] No profile picture upload

### 15. Error Handling & Edge Cases

- [x] 404 error page with "Back to Home" button (not_found_screen.dart)
- [x] User-friendly error messages (no technical errors shown)
- [x] Offline mode: connectivity_service.dart
- [x] Empty states for all lists (cart, favorites, orders, etc.)
- [ ] Price change handling: cancel pending orders if merchant updates price
- [ ] Product removal: delete immediately, cancel pending orders
- [ ] Failed payment: return to checkout, suggest cash on delivery

### 16. App Updates & Maintenance

- [x] Force update popup (force_update_sheet.dart):
  - [x] Show for specific app versions
  - [x] Force or optional update
  - [x] Custom message (AR/EN)
  - [x] With or without illustration
  - [x] Block app usage if force update
  - [x] Database table: app_versions
- [ ] Maintenance mode (future)

### 17. Analytics & Tracking ✅

- [x] Firebase Analytics (analytics_service.dart - 680 lines)
- [x] Firebase Crashlytics (automatic error reporting)
- [x] Firebase Performance Monitoring
- [x] Custom analytics in Supabase (analytics_events table)
- [x] **Events tracked:**
  - [x] Screen views (automatic via Observer)
  - [x] Product views (view_product, view_category)
  - [x] Cart actions (add_to_cart, clear_cart)
  - [x] Checkout flow (begin_checkout, purchase)
  - [x] Search (search, search_no_results)
  - [x] Favorites (add_to_favorites, remove_from_favorites)
  - [x] Auth events (sign_up, login, logout, delete_account)
  - [x] Notifications (notification_received, notification_opened)
  - [x] Error tracking (Crashlytics automatic)
- [x] Supabase Views for analytics dashboard:
  - v_daily_active_users
  - v_popular_events
  - v_search_analytics
  - v_product_views
  - v_purchase_funnel

### 18. UI/UX Requirements

- [ ] Brand colors: #87bf54 (green) + white
- [ ] Light mode only
- [ ] PING AR font (all weights)
- [ ] Responsive design (all screen sizes)
- [ ] RTL support for Arabic
- [ ] LTR support for English
- [ ] Modern, professional 2026 standards
- [ ] Reference apps: Rabbit, Talabat, Breadfast, Waffarha
- [ ] Bottom navigation:
  - Home
  - Search
  - Cart (with badge count)
  - Account
- [ ] Smooth animations and transitions
- [ ] Skeleton loaders (Skeletonizer package)
- [ ] Image resize on-the-fly (if free)

---

## 📊 Detailed Task Breakdown

### Phase 1: Project Setup (Week 1) ✅

- [x] Initialize Flutter project
- [x] Set up project structure (clean architecture)
- [x] Configure Supabase connection
- [x] Set up localization (easy_localization)
- [x] Configure state management (flutter_bloc)
- [x] Set up local storage (Hive)
- [x] Configure routing/navigation
- [x] Add brand assets (logos, icons)
- [x] Configure PING AR font
- [x] Set up theme (colors, text styles)
- [x] Configure flutter_native_splash

### Phase 2: Authentication (Week 2) ✅

- [x] Design auth screens (Splash, Onboarding, Login, Register, OTP)
- [x] Implement splash screen with animation
- [x] Implement onboarding (dynamic from DB)
- [x] Implement login screen
- [x] Implement registration screen
- [x] Implement OTP verification (Resend integration)
- [x] Implement Google Sign-In
- [x] Implement JWT token management
- [x] Implement guest mode
- [x] Create auth service (Bloc)
- [x] Create Edge Functions for auth:
  - `auth/register`
  - `auth/verify_otp`
  - `auth/google_sign_in`
  - `auth/refresh_token`

### Phase 3: Location & Addresses (Week 3) ✅

- [x] Design location selection screen
- [x] Implement Google Maps integration
- [x] Implement geofencing logic (area detection)
- [x] Design address form
- [x] Implement address CRUD
- [x] Implement area request form
- [ ] Create Edge Functions:
  - `locations/detect_area`
  - `addresses/create`
  - `addresses/update`
  - `addresses/delete`
  - `areas/request_new`

### Phase 4: Home Screen & Navigation (Week 4) ✅

- [x] Design bottom navigation
- [x] Implement bottom navigation with state persistence
- [x] Design home screen layout
- [x] Implement dynamic banners carousel
- [x] Implement categories grid (dynamic)
- [x] Implement featured products section
- [x] Implement pull to refresh
- [ ] Create Edge Functions:
  - `home/get_banners`
  - `home/get_categories`
  - `home/get_featured_products`

### Phase 5: Products & Categories (Week 5-6) ✅

- [x] Design product card
- [x] Design product details page
- [x] Design category listing page
- [x] Implement product listing (with infinite scroll)
- [x] Implement product details
- [x] Implement product image carousel
- [x] Implement category navigation
- [x] Implement subcategories (if any)
- [x] Implement product sorting
- [x] Implement stock status display
- [ ] Create Edge Functions:
  - `products/get_by_area`
  - `products/get_by_category`
  - `products/get_details`
  - `products/get_similar`

### Phase 6: Search (Week 7) ✅

- [x] Design search screen
- [x] Implement search bar
- [x] Implement search history
- [x] Implement popular searches
- [x] Implement search results
- [x] Implement category-specific search
- [ ] Create Edge Functions:
  - `search/products`
  - `search/save_history`
  - `search/get_popular`

### Phase 7: Cart & Favorites (Week 8) ✅

- [x] Design cart screen
- [x] Design favorites screen
- [x] Implement add to cart
- [x] Implement cart quantity controls
- [x] Implement cart persistence (Hive)
- [x] Implement favorites
- [x] Implement empty states
- [ ] Create Edge Functions:
  - `cart/sync` (optional, for multi-device)
  - `favorites/add`
  - `favorites/remove`
  - `favorites/get_all`

### Phase 8: Checkout & Orders (Week 9-10) ✅

- [x] Design checkout screen
- [x] Design order tracking screen
- [x] Design order history screen
- [x] Design order details screen
- [x] Implement checkout flow
- [x] Implement address selection in checkout
- [x] Implement delivery time selection
- [x] Implement payment method selection
- [x] Implement coupon application
- [x] Implement order summary calculation
- [x] Implement order placement
- [x] Implement order tracking
- [x] Implement order history
- [x] Implement order details
- [x] Implement reorder
- [x] Implement order cancellation
- [x] Implement order rating
- [ ] Create Edge Functions:
  - `orders/create`
  - `orders/get_user_orders`
  - `orders/get_details`
  - `orders/track`
  - `orders/cancel`
  - `orders/rate`
  - `orders/validate_coupon`

### Phase 9: Wallet & Payments (Week 11) ✅

- [x] Design wallet screen
- [x] Design add balance screen
- [x] Design card info screen
- [x] Design saved cards screen
- [x] Implement wallet page
- [x] Implement add balance flow
- [ ] Implement PayMob integration (Pending)
- [x] Implement saved cards management
- [x] Implement transaction history
- [ ] Create Edge Functions:
  - `wallet/get_balance`
  - `wallet/add_balance`
  - `wallet/process_payment`
  - `wallet/get_transactions`
  - `payments/save_card_token`
  - `payments/delete_card`

### Phase 10: Services (Week 12)

- [ ] Design service listing
- [ ] Design service booking flow
- [ ] Implement service display
- [ ] Implement service booking
- [ ] Create Edge Functions:
  - `services/get_all`
  - `services/book`
  - `services/get_bookings`

### Phase 11: Discounts & Coupons (Week 13) ✅

- [x] Implement discount display on products
- [x] Implement coupon input at checkout
- [ ] Implement first order discount
- [ ] Implement discount stacking logic
- [ ] Create Edge Functions:
  - `coupons/validate`
  - `coupons/apply`
  - `discounts/get_active`

### Phase 12: Notifications (Week 14) ✅

- [x] Set up FCM
- [x] Implement notification handling
- [x] Implement notification permissions
- [ ] Implement notification preferences (UI pending)
- [x] Create Edge Functions:
  - `notifications/send`
  - `notifications/send_bulk`
  - `notifications/subscribe_to_topic`

### Phase 13: Profile & Settings (Week 15) ✅

- [x] Design profile screen
- [x] Design settings screen
- [x] Design help & support screen
- [x] Implement profile page
- [x] Implement edit profile
- [x] Implement language switcher
- [ ] Implement notification preferences (UI pending)
- [x] Implement delete account
- [x] Implement logout
- [x] Implement help & support page
- [ ] Create Edge Functions:
  - `users/update_profile`
  - `users/delete_account`
  - `users/get_profile`

### Phase 14: Error Handling & Polish (Week 16) ✅

- [x] Implement 404 error page
- [x] Implement user-friendly error messages
- [x] Implement offline mode detection
- [x] Implement all empty states
- [x] Implement loading states
- [x] Implement app update popup
- [ ] Test all error scenarios
- [ ] Polish animations and transitions

### Phase 15: Analytics & Tracking (Week 17) ✅

- [x] Integrate Firebase Analytics
- [x] Integrate Firebase Crashlytics
- [x] Integrate Firebase Performance
- [x] Implement custom event tracking (Supabase analytics_events)
- [x] Implement screen view tracking (automatic via Observer)
- [x] Implement product view tracking
- [x] Implement search tracking
- [x] Implement cart/checkout tracking
- [x] Implement auth events tracking
- [x] Create Supabase migration (020_analytics_events.sql)
- [x] Create analytics Views for dashboard

### Phase 16: Testing & QA (Week 18-19)

- [ ] Unit tests for business logic
- [ ] Widget tests for UI components
- [ ] Integration tests for critical flows
- [ ] Test on different screen sizes
- [ ] Test RTL layout
- [ ] Test all user flows
- [ ] Test error scenarios
- [ ] Test offline behavior
- [ ] Performance testing
- [ ] Security testing

### Phase 17: Deployment Preparation (Week 20)

- [ ] Generate app icons
- [ ] Generate splash screens
- [ ] Prepare store screenshots
- [ ] Write app description (AR/EN)
- [ ] Prepare privacy policy
- [ ] Prepare terms & conditions
- [ ] Configure app signing
- [ ] Configure ProGuard (Android)
- [ ] Build release APK/AAB
- [ ] Build release IPA
- [ ] Submit to Google Play
- [ ] Submit to App Store

---

## 🔴 Missing from Requirements Q&A (182 Questions Analysis)

> **تم تحليل ملف `requirements_qa.md` بالكامل وإضافة التاسكات المفقودة هنا**
> **تاريخ التحليل:** 2026-01-16

### 1. Authentication & Security (المصادقة والأمان)

- [ ] Banned Account Re-registration Flow
  - لو الحساب banned (مش محذوف): الدعم يقدر يستعيد الحساب
  - لو الحساب محذوف: لازم ينشئ واحد جديد
  - Edge Function: `auth/restore_banned_account`
- [ ] IP/Device Banning System
  - الأدمن يقدر يحظر IP أو Device ID
  - Table: `banned_ips`, `banned_devices`
- [ ] OTP via Resend Service Integration
  - توثيق واضح أن الـ OTP يتم عبر Resend (مش SMS)
  - Edge Function: `auth/send_otp_email`

### 2. Products & Merchants (المنتجات والتجار)

- [ ] Product Request by Merchant
  - لو المنتج مش موجود في الكتالوج، التاجر يبعت request لإضافته
  - Table: `product_requests` (merchant_id, product_name, description, suggested_price, status)
  - Edge Function: `merchants/request_product`
- [ ] Merchant Price Modification Flow
  - التاجر يختار منتج من الكتالوج الأساسي
  - التاجر يحدد سعره (أقل أو أعلى من السعر المقترح)
  - الـ markup يُضاف تلقائياً
  - المنتج يظهر للعميل بعد موافقة المودريشن
- [ ] Multiple Units per Product per Merchant
  - التاجر يقدر يبيع نفس المنتج بوحدات مختلفة (كيلو، نص كيلو، 250 جرام)
  - Table: `merchant_product_units`
- [ ] Auto-Approval Rules for Orders
  - الأوردر يوصل تلقائي للطيار لو التاجر عدى عدد أوردرات ناجح معين
  - Config: `app_settings.auto_approval_enabled`, `app_settings.min_successful_orders`
  - يُحدد من الأدمن
- [ ] Merchant Cannot Add Discounts
  - الخصومات من الأدمن/المودريشن فقط
  - التاجر يحدد سعره فقط

### 3. Pricing & Markup (التسعير)

- [ ] Price Display Format with Commas
  - المبالغ الكبيرة تظهر بفواصل: `10,000.00` بدل `10000.00`
  - Utility function: `formatPrice(double amount)`
- [ ] Markup Types Configuration
  - نسبة مئوية (مثلاً 10%)
  - رقم ثابت (مثلاً 5 ج.م)
  - يُحدد per Product/Category/Merchant
- [ ] Show Cheapest Price to Customer
  - لو فيه 3 تجار بيبيعوا نفس المنتج بأسعار مختلفة
  - يظهر للعميل أرخص سعر فقط
  - Edge Function: `products/get_cheapest_by_area`

### 4. Pilots/Drivers System (نظام الطيارين)

- [ ] Pilot Fixed Salary (NOT Commission)
  - راتب ثابت للطيار
  - Column: `pilots.salary_type = 'fixed'`
- [ ] Pilot Rejection Flow
  - لو الطيار رفض الأوردر → يروح لطيار تاني
  - لو كل الطيارين رفضوا → يروح للمودريشن
  - Edge Function: `orders/reassign_pilot`
- [ ] Pilot Assignment Logic
  - Option A: أقرب طيار متاح (auto)
  - Option B: الأدمن/المودريشن يحول يدوياً
  - Config: `app_settings.pilot_assignment_mode`
- [ ] Pilot Availability Toggle
  - الطيار بنفسه يقدر يحدد (online/offline)
  - أو الأدمن يقدر يحدد
  - Column: `pilots.is_available`, `pilots.availability_set_by`
- [ ] Delivery Proof Photo
  - الطيار يصور صورة عند بيت/عمارة العميل كإثبات
  - Column: `orders.delivery_proof_image_url`
  - Edge Function: `orders/upload_delivery_proof`
- [ ] Pilot Order Limit
  - لو مفيش طيارين متاحين → الطلب يوصل للمودريشن/الأدمن
  - Config: `app_settings.max_orders_per_pilot`

### 5. Moderation System (نظام المراجعة)

- [ ] Moderation SLA (Service Level Agreement)
  - الافتراضي: خلال 5 دقائق
  - Config: `app_settings.moderation_sla_minutes`
  - Alert if exceeded
- [ ] Moderation FIFO Queue Priority
  - First In, First Out
  - الأوردرات تتراص حسب وقت الوصول
- [ ] Auto Distribution to Moderation Team
  - توزيع تلقائي بين أعضاء فريق المودريشن
  - لو فيه مودريشن واحد → يوصله كل شيء
- [ ] Moderation Verification Call to Merchant
  - المودريشن يتصل تليفونياً بالتاجر للتأكيد
  - Column: `moderation_queue.merchant_called`, `moderation_queue.call_notes`
- [ ] Moderation Order Modification
  - لو منتج مش متوفر عند التاجر
  - المودريشن يتواصل مع العميل
  - يعدل الأوردر بعد موافقة العميل
  - Edge Function: `orders/modify_by_moderation`

### 6. Orders & Checkout (الطلبات)

- [ ] Minimum Order per Merchant
  - حد أدنى لكل تاجر (configurable by admin)
  - Column: `merchants.min_order_amount`
- [ ] Multi-Merchant Order Display
  - للمستخدم: يظهر أوردر واحد
  - للمودريشن والطيار: يظهر كل منتج من تاجر مختلف بتفاصيله وموقعه
- [ ] Cancel Only at "Preparing" Stage
  - المستخدم يقدر يلغي فقط في مرحلة "جاري التحضير"
  - بعدها مش هيقدر يلغي
- [ ] Refunds to Wallet Only
  - لو الأوردر اتلغى بعد الدفع أونلاين
  - الفلوس ترجع للمحفظة (مش للفيزا)
  - Edge Function: `wallet/refund_order`
- [ ] Order Rating After Delivery
  - تقييم الطيار/التجربة بعد التوصيل
  - ✅ Already implemented

### 7. Wallet & Payments (المحفظة والدفع)

- [ ] Wallet Initial Balance = 0
  - كل حساب جديد يبدأ برصيد 0.00
  - Trigger: `on_user_created → create_wallet(0.00)`
- [ ] Card Save Checkbox on Payment Flow
  - تشيك بوكس "حفظ البطاقة للمرات القادمة"
  - UI component in checkout
- [ ] Transaction Types
  - `top_up`: شحن رصيد
  - `payment`: دفع طلب
  - `refund`: استرداد
  - Column: `wallet_transactions.type`

### 8. Multi-Pilot System (نظام الطيارين المتعددين)

- [ ] Multi-Pilot Trigger Criteria
  - عدد المنتجات (مثلاً > 20 منتج)
  - الوزن الإجمالي (مثلاً > 50 كجم)
  - عدد التجار (مثلاً > 3 تجار)
  - Config: `app_settings.multi_pilot_triggers`
- [ ] Both Pilots Go Together
  - لازم الاتنين يروحوا سوا لنفس التاجر ثم نفس العميل
  - مش منفصلين
- [ ] Default: Moderation Decides Manually
  - الافتراضي: المودريشن يقرر يدوياً إذا الأوردر يحتاج طيارين
  - Config: `app_settings.multi_pilot_mode = 'manual'`

### 9. Discounts & Coupons (الخصومات والكوبونات)

- [ ] Discount Types
  - نسبة مئوية (مثلاً 10%)
  - رقم ثابت (مثلاً 20 ج.م)
  - Column: `discounts.type = 'percentage' | 'fixed'`
- [ ] Coupon Types
  - خصم على الأوردر الكلي
  - خصم على منتجات معينة
  - Free delivery
  - Column: `promo_codes.type`
- [ ] Coupon Validation Rules
  - تاريخ انتهاء الصلاحية
  - حد أدنى للطلب
  - عدد استخدامات كلي
  - مرة واحدة لكل مستخدم
  - Columns in `promo_codes` table
- [ ] Discount Added by Admin Only
  - التاجر لا يضيف خصومات
  - الأدمن/المودريشن فقط
- [ ] First Order Discount (Optional)
  - خصم لأول طلب
  - الأدمن يقدر يفعله أو يوقفه
  - Config: `app_settings.first_order_discount_enabled`
- [ ] Discount Stacking Rules
  - خصم المنتج + كوبون في نفس الوقت؟
  - Config: `app_settings.allow_discount_stacking`

### 10. Services (الخدمات)

- [ ] Service Examples Documentation
  - دكتور (استشارة)
  - سباكة
  - كهربائي
  - نجار
  - وغيرها
- [ ] Service Flow (Different from Products)
  - اختيار الخدمة
  - اختيار التاريخ والوقت
  - التأكيد مع مقدم الخدمة
  - نظام تسعير مختلف (استشارة vs زيارة)
- [ ] Service Booking Flexibility
  - فليكسبل جداً
  - تفاصيل الخدمة
  - وقت الخدمة
  - سعر الاستشارة vs الزيارة

### 11. Analytics & Data Collection (التحليلات)

- [ ] Device Info Collection
  - نوع الجهاز (Android/iOS)
  - إصدار الجهاز
  - Device ID
  - App Version
  - OS Version
  - Table: `user_devices`
- [ ] Full Analytics Implementation
  - ✅ Already implemented (Firebase + Supabase)

### 12. UI/UX Requirements (متطلبات واجهة المستخدم)

- [ ] App Restart After Language Change
  - لما المستخدم يغير اللغة، التطبيق يعيد فتح نفسه
  - `RestartWidget` or similar
- [ ] SKU for Admin Only
  - الـ SKU مش بيظهر للمستخدم
  - بيظهر في Dashboard للأدمن فقط
- [ ] Expiry Date: Optional/Not Required
  - تاريخ انتهاء الصلاحية مش مهم حالياً
  - Column nullable: `products.expiry_date`
- [ ] Single Image Fallback for Banners/Categories
  - لو الأدمن ضاف صورة واحدة (مش عربي وإنجليزي)
  - تظهر نفس الصورة في اللغتين
  - Logic in `BannerWidget`, `CategoryWidget`

### 13. Database Schema Additions (إضافات للداتا بيز)

- [ ] `product_requests` Table

  ```sql
  CREATE TABLE product_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID REFERENCES merchants(id),
    product_name_ar TEXT NOT NULL,
    product_name_en TEXT,
    description TEXT,
    suggested_price DECIMAL(10,2),
    suggested_unit TEXT,
    status TEXT DEFAULT 'pending', -- pending, approved, rejected
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES users(id)
  );
  ```

- [ ] `referral_codes` Table (للمستقبل)

  ```sql
  CREATE TABLE referral_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    code TEXT UNIQUE NOT NULL,
    uses_count INT DEFAULT 0,
    max_uses INT,
    reward_amount DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

- [ ] `banned_ips` Table

  ```sql
  CREATE TABLE banned_ips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ip_address TEXT NOT NULL,
    reason TEXT,
    banned_by UUID REFERENCES users(id),
    banned_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
  );
  ```

- [ ] `banned_devices` Table

  ```sql
  CREATE TABLE banned_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL,
    reason TEXT,
    banned_by UUID REFERENCES users(id),
    banned_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
  );
  ```

- [ ] `user_devices` Table

  ```sql
  CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    device_id TEXT NOT NULL,
    device_type TEXT, -- android, ios
    device_model TEXT,
    os_version TEXT,
    app_version TEXT,
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

### 14. Business Rules Documentation (قواعد العمل)

- [ ] Merchant Has NO Notifications
  - التاجر مش بيستلم إشعارات
  - يشوف كل حاجة في Dashboard فقط
- [ ] Nested Permission Control
  - كل رول بيحدده شخص رول أعلى منه
  - Owner → Super Admin → Admin → Moderation → إلخ
- [ ] Order Assignment to Merchant
  - الأوردر مش بيروح للتاجر مباشرة
  - بيروح للمودريشن أولاً
  - بعد الموافقة بيروح للطيار
  - التاجر يشوف الأوردرات المكتملة فقط في السجل
- [ ] Delivery Fee Rules
  - تختلف حسب المنطقة/المسافة
  - أو موحدة
  - Config: `app_settings.delivery_fee_type`, `area_delivery_fees` table

### 15. Edge Functions (الفانكشنز المطلوبة)

- [ ] `auth/restore_banned_account` - استعادة حساب محظور
- [ ] `auth/send_otp_email` - إرسال OTP عبر Resend Service
- [ ] `merchants/request_product` - طلب إضافة منتج
- [ ] `products/get_cheapest_by_area` - أرخص سعر في المنطقة
- [ ] `products/get_similar` - منتجات مشابهة
- [ ] `orders/reassign_pilot` - إعادة تعيين طيار
- [ ] `orders/upload_delivery_proof` - رفع صورة إثبات التوصيل
- [ ] `orders/modify_by_moderation` - تعديل الأوردر من المودريشن
- [ ] `orders/cancel_on_price_change` - إلغاء الأوردر لو التاجر عدل السعر
- [ ] `wallet/refund_order` - استرداد مبلغ الأوردر للمحفظة
- [ ] `wallet/create_on_signup` - إنشاء محفظة برصيد 0 عند التسجيل

---

## 🔴 Full Requirements Q&A Gap Analysis (2026-01-16)

> **تحليل شامل لـ 182 سؤال من `requirements_qa.md`**
> **تم اكتشاف 53+ تاسك مفقود أو غير مكتمل**

### 16. Authentication & Onboarding Gaps

- [ ] **Onboarding Max 4 Screens**
  - الحد الأقصى 4 صفحات onboarding
  - Validation in database: `onboarding_screens.max_count = 4`
  - Q.61

- [ ] **OTP via Resend Service (NOT SMS)**
  - توثيق واضح أن الـ OTP يتم عبر Resend عبر الإيميل
  - Edge Function: `auth/send_otp_email`
  - Service: Resend API integration
  - Q.4, Q.125

- [ ] **No Password Requirements**
  - مفيش شروط على كلمة المرور (no complexity rules)
  - Simple validation only
  - Q.124 (ضمنياً)

### 17. Address Management Gaps

- [ ] **Phone Auto-filled with Country Code**
  - رقم الهاتف تلقائياً به رقم هاتفه وكود دولته (+20)
  - Default: user's phone from profile
  - UI: `AddressForm.phone` pre-populated
  - Q.52-60

- [ ] **Address Validation Details**
  - Validation على كل حقول العنوان
  - Required fields vs Optional fields enforcement
  - Location on map validation (within supported areas)
  - Q.81

### 18. Products & Display Gaps

- [ ] **Admin Can Hide/Show Product Sections**
  - الأدمن يقدر يخفي/يظهر أي قسم في صفحة المنتج
  - Columns: `products.show_description`, `products.show_ingredients`, etc.
  - OR: `product_section_visibility` table
  - Q.75

- [ ] **Similar Products Edge Function**
  - Edge Function: `products/get_similar`
  - Based on: same category, same subcategory, same merchant
  - Q.73

- [ ] **Product Expiry Date - Nullable & Optional**
  - تاريخ انتهاء الصلاحية مش مهم حالياً
  - Column: `products.expiry_date NULLABLE`
  - Q.68, Q.131

### 19. Cart Behavior Gaps

- [ ] **Cart Contradiction Resolution**
  - Q.73: السلة تتحفظ حتى لو Logout
  - Q.93: لو عمل Logout، السلة تتمسح
  - **Resolution Needed:**
    - Option A: Cart persists (stored in Hive locally)
    - Option B: Cart clears on logout
  - **Recommendation:** Cart persists locally (Hive), syncs when logged in
  - Q.73, Q.93

- [ ] **Cart Sync Across Devices (Optional)**
  - اختياري: لو المستخدم عنده أكتر من جهاز
  - Table: `cart_items` (server-side)
  - Edge Function: `cart/sync`
  - Q.73

### 20. Order Flow Gaps

- [ ] **Order Goes to Moderation First (NOT Merchant)**
  - المنتج مش بيروح للتاجر
  - بيروح للمودريشن أولاً
  - بعد الموافقة بيروح للطيار
  - Flow: Customer → Moderation → Pilot → Merchant → Customer
  - Q.111

- [ ] **Merchant Sees Completed Orders Only**
  - التاجر يشوف الأوردرات المكتملة فقط في السجل
  - بعد التوصيل بنجاح
  - Dashboard: `orders.status = 'delivered'` only
  - Q.114

- [ ] **Merchant Total Sales (No Financial Details)**
  - إجمالي مبيعاته فقط
  - هيشوفه بعد التوصيل بدون تفاصيل مالية
  - Column: `merchants.total_sales` (aggregate)
  - Q.181

- [ ] **Preparation Time Set by Moderation**
  - المودريشن بيحدد وقت التحضير
  - مش التاجر
  - Column: `orders.estimated_prep_time` (set by moderation)
  - Q.114

- [ ] **Cancel Only at "Preparing" Stage Clarification**
  - المستخدم يقدر يلغي فقط في مرحلة "جاري التحضير" (Stage 3)
  - بعدها (On the way, Delivered) مش هيقدر
  - Business rule enforcement in Edge Function
  - Q.83

### 21. Delivery Fees Gaps

- [ ] **Delivery Fee Once Per Order**
  - مرة واحدة حتى لو من أكتر من تاجر
  - Not per-merchant
  - Q.113

- [ ] **Area-based or Fixed Delivery Fee Config**
  - تختلف حسب المنطقة/المسافة، أو موحدة
  - Config: `app_settings.delivery_fee_type = 'fixed' | 'area_based'`
  - Table: `area_delivery_fees` (area_id, fee_amount)
  - Q.16

### 22. Pilot System Gaps

- [ ] **No Real-time Pilot Location (Soon)**
  - يظهر للمستخدم وقت تقديري للوصول فقط
  - Real-time tracking is SOON/Future
  - Column: `orders.estimated_delivery_time`
  - Q.116

- [ ] **Same Area Restriction (Strict Rule)**
  - الطيار والتاجر والعميل لازم في نفس المنطقة
  - Validation in Edge Functions
  - Business rule: `pilot.area_id = merchant.area_id = customer.address.area_id`
  - Q.117

- [ ] **Pilot Pays Merchant First (Cash Flow)**
  - الطيار بيدفع للتاجر من جيبه عند شراء المنتج
  - Before delivering to customer
  - Q.138, Q.139

- [ ] **Pilot Collects Cash at End of Day**
  - الطيار بيحتفظ بالفلوس المحصلة من العميل
  - يديها للإدارة آخر اليوم
  - Column: `pilot_daily_collections` table
  - Q.138

### 23. Moderation Workflow Gaps

- [ ] **Moderation Notes Column**
  - المودريشن يقدر يضيف notes على الأوردر
  - Column: `moderation_queue.notes`, `moderation_queue.merchant_call_notes`
  - Q.156

- [ ] **Moderation Queue FIFO Implementation**
  - First In, First Out
  - ORDER BY `created_at ASC`
  - Q.155

### 24. Merchant Gaps

- [ ] **Merchant Verification Levels Table**
  - مستويات توثيق للتجار
  - Table: `merchant_verification_levels` (level_name, requirements, benefits)
  - Column: `merchants.verification_level_id`
  - Q.123

- [ ] **Merchant Stock Update Instant**
  - التحديث فوري (real-time)
  - No moderation queue for stock updates
  - Q.133

- [ ] **Order Cancelled if Merchant Updates Price (Pending Orders)**
  - لو التاجر عدل السعر أثناء order pending
  - الأوردر يتلغى تلقائياً
  - Trigger: `on_merchant_product_price_update`
  - Edge Function: `orders/cancel_on_price_change`
  - Q.134

- [ ] **Product Deleted Immediately**
  - لو التاجر حذف منتج يُحذف فوراً
  - Cascade: cancel pending orders with this product
  - Q.135

### 25. Notifications Gaps

- [ ] **Merchant Has NO Notifications (Explicit Task)**
  - التاجر مش بيستلم إشعارات push
  - يشوف كل حاجة في Dashboard فقط
  - Q.152

- [ ] **FCM Only - No SMS/Email for Push**
  - Push notifications via FCM only
  - No SMS or email for order updates
  - Q.149, Q.150

### 26. Search Gaps

- [ ] **Search Includes Description**
  - البحث يشمل الوصف أيضاً (مش بس الاسم)
  - Full-text search: `product_name`, `description`, `category_name`
  - Q.70

- [ ] **No Voice Search - Confirmed**
  - لا يوجد voice search
  - Q.72

- [ ] **No Search Filters - Confirmed**
  - لا يوجد filters (price range, etc.)
  - Q.71

### 27. App Configuration Gaps

- [ ] **`app_settings` Table - Complete List**
  - السيتنجز في جدول `app_settings`
  - Keys needed:
    - `min_order_amount`
    - `delivery_fee_type`
    - `delivery_fee_fixed_amount`
    - `auto_approval_enabled`
    - `min_successful_orders_for_auto_approval`
    - `moderation_sla_minutes`
    - `multi_pilot_mode`
    - `pilot_assignment_mode`
    - `max_orders_per_pilot`
    - `first_order_discount_enabled`
    - `allow_discount_stacking`
    - `max_addresses_per_user` (default: 5)
    - `max_search_history` (default: 20)
    - `max_accounts_per_phone` (default: 3)
  - Q.127

- [ ] **Feature Flags Table**
  - Table: `feature_flags` (key, is_enabled, description)
  - Flags: `wallet_enabled`, `services_enabled`, `scheduled_orders_enabled`, etc.
  - Q.128

- [ ] **Banners with Start/End Dates Scheduling Logic**
  - البانرز لها تاريخ بداية ونهاية
  - Auto-show/hide based on dates
  - Query: `WHERE NOW() BETWEEN start_date AND end_date`
  - Q.131

### 28. Privacy & Data Gaps

- [ ] **Deleted User Data Archived (NOT Deleted)**
  - كل البيانات تتأرشف في `deleted_users` table
  - لا تُحذف نهائياً
  - Q.157

- [ ] **Order History Forever**
  - كل الأوردرات من أول التسجيل
  - لا يوجد حد زمني
  - Q.159

### 29. Roles & Permissions Gaps

- [ ] **Nested Permission Control**
  - كل رول بيحدده شخص رول أعلى منه
  - Owner → Super Admin → Admin → Moderation → Support → إلخ
  - Column: `roles.parent_role_id`
  - Q.91

- [ ] **Role Hierarchy Documentation**
  - توثيق واضح لتسلسل الصلاحيات
  - What each role can/cannot do
  - Who can create/modify which role
  - Q.91

### 30. UI/UX Specific Gaps

- [ ] **PING AR Font Files**
  - ملفات الخطوط
  - All weights needed
  - To be added to `assets/fonts/`
  - Q.24

- [ ] **Price Display with Commas**
  - المبالغ الكبيرة تظهر بفواصل: `10,000.00`
  - Utility function: `formatPrice(double amount, {bool withCommas = true})`
  - Applied everywhere prices are displayed
  - Q.78-80

- [ ] **Price: Large + Decimal Small**
  - السعر كبير والعشري أصغر
  - UI: `300` large, `.00` small superscript
  - Widget: `PriceWidget(amount, {bool splitDecimal = true})`
  - Q.27

### 31. Geofencing Gaps

- [ ] **Radius-based Geofencing**
  - دائرة بنصف قطر من نقطة مركزية
  - Column: `areas.center_lat`, `areas.center_lng`, `areas.radius_km`
  - Q.110

- [ ] **Area Geofencing Detection Logic**
  - Calculate distance from user location to area center
  - If distance <= radius, user is in area
  - Edge Function: `locations/detect_area`
  - Q.110

### 32. Offline Mode Gaps

- [ ] **Block All Actions When Offline**
  - يمنعه من أي حاجة (مش بس رسالة)
  - Show full-screen overlay: "لا يوجد اتصال بالإنترنت"
  - Block all interactions except retry
  - Q.98

### 33. Language Change Gaps

- [ ] **App Restart After Language Change**
  - لما المستخدم يغير اللغة، التطبيق يعيد فتح نفسه
  - `RestartWidget` implementation
  - Full app reload to apply RTL/LTR correctly
  - Q.99

### 34. Scheduled Orders Gaps

- [ ] **Schedule Options Details**
  - "في أقرب وقت" (ASAP) - default
  - "غداً الساعة X"
  - "بعد غد الساعة X"
  - Custom date/time picker
  - Column: `orders.scheduled_for TIMESTAMPTZ NULLABLE`
  - Q.161

### 35. Referral Schema Gaps

- [ ] **Referral Schema Ready for Future**
  - حضّر الـ schema دلوقتي للاستعمال المستقبلي
  - Table: `referral_codes` (already in DB additions)
  - Table: `referral_usages` (referrer_id, referred_id, reward_given, created_at)
  - Q.160

### 36. Payment & Cash Flow Gaps

- [ ] **Online Payment Immediately on Confirm**
  - الدفع بالفيزا فوراً أول ما يضغط "تأكيد الطلب"
  - Not after moderation approval
  - Payment before order creation
  - Q.136

- [ ] **Pilot Cash Collection Tracking**
  - Table: `pilot_daily_collections` (pilot_id, date, total_collected, returned_to_admin, created_at)
  - Q.138

- [ ] **Merchant Gets Paid Immediately (by Pilot)**
  - الطيار بيدفع للتاجر فوراً
  - Before picking up the order
  - Q.139, Q.140

### 37. Account Tab Gaps

- [ ] **"حسابي" With Organized Sub-pages**
  - منظمة أكثر داخل صفحات عشان متبقاش زحمة
  - Sub-pages:
    - طلباتي
    - عناويني
    - محفظتي
    - البطاقات المحفوظة
    - الإعدادات (اللغة، الإشعارات)
    - المساعدة والدعم
    - عن التطبيق
  - Q.167

### 38. Empty States Gaps

- [ ] **Empty States Complete List**
  - السلة فارغة ✅
  - المفضلة فارغة ✅
  - لا توجد طلبات ✅
  - لا توجد عناوين
  - لا توجد نتائج بحث ✅
  - لا توجد منتجات في هذا القسم
  - لا توجد إشعارات
  - لا توجد بطاقات محفوظة
  - Q.169

### 39. Additional Database Tables Needed

- [ ] `area_delivery_fees` Table

  ```sql
  CREATE TABLE area_delivery_fees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    area_id UUID REFERENCES areas(id) ON DELETE CASCADE,
    fee_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    is_free_delivery_available BOOLEAN DEFAULT false,
    free_delivery_min_order DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

- [ ] `pilot_daily_collections` Table

  ```sql
  CREATE TABLE pilot_daily_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pilot_id UUID REFERENCES pilots(id) ON DELETE CASCADE,
    collection_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_collected DECIMAL(10,2) DEFAULT 0,
    total_paid_to_merchants DECIMAL(10,2) DEFAULT 0,
    returned_to_admin BOOLEAN DEFAULT false,
    returned_at TIMESTAMPTZ,
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

- [ ] `referral_usages` Table

  ```sql
  CREATE TABLE referral_usages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referral_code_id UUID REFERENCES referral_codes(id),
    referrer_id UUID REFERENCES users(id),
    referred_id UUID REFERENCES users(id),
    reward_amount DECIMAL(10,2),
    reward_given_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

- [ ] `product_section_visibility` Table (Alternative to columns)

  ```sql
  CREATE TABLE product_section_visibility (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    section_name TEXT NOT NULL, -- 'description', 'ingredients', 'nutrition', 'storage', 'expiry'
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

### 40. App Settings Complete List

- [ ] Add all settings to `app_settings` table:

  | Key | Type | Default | Description |
  |-----|------|---------|-------------|
  | `min_order_amount` | DECIMAL | 50.00 | الحد الأدنى للطلب |
  | `delivery_fee_type` | TEXT | 'fixed' | 'fixed' أو 'area_based' |
  | `delivery_fee_fixed` | DECIMAL | 15.00 | رسوم التوصيل الثابتة |
  | `auto_approval_enabled` | BOOLEAN | false | تفعيل الموافقة التلقائية |
  | `auto_approval_min_orders` | INTEGER | 50 | عدد الأوردرات الناجحة للموافقة التلقائية |
  | `moderation_sla_minutes` | INTEGER | 5 | وقت SLA للمودريشن |
  | `multi_pilot_mode` | TEXT | 'manual' | 'manual' أو 'auto' |
  | `pilot_assignment_mode` | TEXT | 'auto' | 'auto' أو 'manual' |
  | `max_orders_per_pilot` | INTEGER | 5 | الحد الأقصى للأوردرات لكل طيار |
  | `first_order_discount_enabled` | BOOLEAN | false | تفعيل خصم أول طلب |
  | `first_order_discount_amount` | DECIMAL | 20.00 | قيمة خصم أول طلب |
  | `first_order_discount_type` | TEXT | 'fixed' | 'fixed' أو 'percentage' |
  | `allow_discount_stacking` | BOOLEAN | false | السماح بتكديس الخصومات |
  | `max_addresses_per_user` | INTEGER | 5 | الحد الأقصى للعناوين |
  | `max_search_history` | INTEGER | 20 | الحد الأقصى لسجل البحث |
  | `max_accounts_per_phone` | INTEGER | 3 | الحد الأقصى للحسابات لكل رقم |
  | `max_onboarding_screens` | INTEGER | 4 | الحد الأقصى لصفحات Onboarding |
  | `wallet_enabled` | BOOLEAN | true | تفعيل المحفظة |
  | `services_enabled` | BOOLEAN | true | تفعيل الخدمات |
  | `scheduled_orders_enabled` | BOOLEAN | true | تفعيل الطلبات المجدولة |
  | `default_language` | TEXT | 'en' | اللغة الافتراضية (fallback) |
  | `country_code` | TEXT | '+20' | كود الدولة |
  | `currency_code` | TEXT | 'EGP' | كود العملة |
  | `currency_symbol` | TEXT | 'ج.م' | رمز العملة |

---

## 🔴 Additional Missing Tasks (2026-01-16 Final Analysis)

> **تحليل نهائي شامل اكتشف 17+ تاسك إضافي مفقود**
> **تم اكتشافها بعد مراجعة requirements_qa.md بالكامل (182 سؤال)**

### 41. Localization & Dialect

- [ ] **Egyptian Semi-Formal Dialect Guidelines**
  - توثيق واضح للمصطلحات المستخدمة
  - أمثلة: "مشترياتك"، "الحساب"، "اضف للسلة"
  - Review all Arabic translations for dialect consistency
  - Create `docs/DIALECT_GUIDELINES.md`
  - Q.8, Q.40

### 42. Country & Currency Configuration

- [ ] **Country/Currency Lock (Fixed to Egypt/EGP)**
  - Default: مصر / ج.م (EGP)
  - غير قابلة للتغيير من المستخدم (مفيش دول أخرى في الداتا بيز حالياً)
  - Schema ready for future expansion
  - Tables: `countries`, `currencies` (with only Egypt/EGP initially)
  - Columns already in `app_settings`: `country_code`, `currency_code`, `currency_symbol`
  - Q.11-12

### 43. Merchant Identity Hidden from Customers

- [ ] **Hide Merchant Names from Customer UI** 🔴 HIGH PRIORITY
  - المستخدم لا يرى اسم التاجر أبداً
  - يظهر كأنه من التطبيق مباشرة / مخازن التطبيق
  - Affected screens:
    - Product cards ❌ No merchant name
    - Product details ❌ No merchant name
    - Cart ❌ No merchant name
    - Checkout ❌ No merchant name
    - Order details ❌ No merchant name
    - Order history ❌ No merchant name
  - Review ALL UI components for merchant name leakage
  - Q.15

### 44. Dynamic UI Control

- [ ] **Dynamic UI Control from Database**
  - الأدمن يتحكم في ترتيب العناصر في الصفحة الرئيسية
  - الأدمن يتحكم في إظهار/إخفاء sections
  - Table: `home_sections` with columns:
    - `id`, `section_type` (banner/categories/products)
    - `title_ar`, `title_en`
    - `display_order`
    - `is_visible`
    - `config_json` (for custom settings)
  - Q.88, Q.130

- [ ] **Dynamic Section Titles on Home Page**
  - كل section له عنوان ديناميك (AR/EN)
  - Column: `home_sections.title_ar`, `home_sections.title_en`
  - Examples:
    - "الأكثر بيعاً في منطقتك"
    - "جميع الأقسام"
    - "عروض اليوم"
  - Q.88

### 45. Brand Identity & Design

- [ ] **Brand Identity Assets Integration**
  - تأكد من استخدام ألوان الهوية من `bourraq-assets`
  - Primary color: #87bf54 (green)
  - Secondary: white
  - Create `docs/BRAND_GUIDELINES.md`
  - Document: logo usage, color codes, spacing
  - Q.135

- [ ] **UI/UX Reference Apps Analysis Document**
  - Create design inspiration document
  - Reference apps to study:
    - Breadfast (بريد فاست)
    - Rabbit
    - Talabat (طلبات)
    - Waffarha (وفرها)
  - Take screenshots for reference (per Q.137)
  - Create `docs/UI_INSPIRATION.md`
  - Q.136-137

### 46. Store Compliance

- [ ] **Google Play Store Compliance Checklist** 🔴 HIGH PRIORITY
  - Review all Google Play policies
  - Payment policies compliance
  - Privacy policy requirements
  - Data safety form requirements
  - Target SDK requirements
  - Create `docs/GOOGLE_PLAY_CHECKLIST.md`
  - Q.142

- [ ] **Apple App Store Compliance Checklist** 🔴 HIGH PRIORITY
  - Review all App Store guidelines
  - In-app purchase rules (if applicable)
  - Privacy requirements
  - App Tracking Transparency
  - Create `docs/APPLE_STORE_CHECKLIST.md`
  - Q.142

### 47. Error Handling & Messages

- [ ] **Error Messages Audit (Full App Review)**
  - Review ALL error messages in app
  - Ensure no technical/debug messages shown to user
  - All errors must be user-friendly
  - Create error message guidelines
  - Test offline scenarios
  - Test API failure scenarios
  - Create `docs/ERROR_MESSAGES.md`
  - Q.145

- [ ] **Failed Payment UI Flow Details**
  - Show user-friendly error message
  - "حاول مرة أخرى" button
  - "التحويل للدفع عند الاستلام" suggestion
  - Retain cart items on failure
  - Log failure for analytics
  - Q.88 (specific error handling)

### 48. Documentation

- [ ] **Complete Edge Functions Documentation**
  - List ALL Edge Functions with their purposes
  - Include function signatures and payloads
  - Request/Response examples
  - Error codes
  - Create `docs/EDGE_FUNCTIONS.md`
  - Already have partial list, needs completion
  - Q.150, 153

- [ ] **User Data Collection Documentation**
  - List all collected data points
  - Purpose for each data point
  - Legal compliance notes (GDPR, etc.)
  - Create `docs/DATA_COLLECTION.md`
  - Data collected:
    - Device type (Android/iOS)
    - Device model
    - Device ID
    - OS version
    - App version
    - IP address (for security)
    - FCM token
    - Location (when permitted)
    - Search queries
    - Product views
    - Cart actions
    - Order history
  - Q.183

### 49. Help & Support

- [ ] **Help & Support Page Content**
  - FAQs content (AR/EN)
  - Common issues and solutions
  - Contact methods display:
    - Phone
    - WhatsApp
    - Email
  - Create FAQ content in database
  - Table: `faqs` (question_ar, question_en, answer_ar, answer_en, order)
  - Q.159

- [ ] **Terms & Privacy Policy External Links Config**
  - External URL configuration in database
  - Table: `static_pages` (key, url_ar, url_en)
  - Keys: `terms_and_conditions`, `privacy_policy`, `about_us`
  - Allow different URLs for AR/EN if needed
  - Q.162

### 50. Testing & Quality

- [ ] **Responsive Design Testing Checklist**
  - Test on small screens (320px width)
  - Test on large screens (tablets if supported)
  - Test on different aspect ratios
  - Test RTL layout on all screens
  - Test LTR layout on all screens
  - Create device testing matrix
  - Create `docs/DEVICE_TESTING_MATRIX.md`
  - Q.168

### 51. App Update Popup Enhancement

- [ ] **App Update Popup - Illustration Optional**
  - Config: `app_update.show_illustration` (BOOLEAN)
  - If true, show illustration image
  - If false, text only
  - Column: `app_versions.illustration_url` (NULLABLE)
  - Q.192

### 52. Security

- [ ] **Full Security Audit (2026 Best Practices)** 🔴 HIGH PRIORITY
  - Review all RLS policies for completeness
  - Review all Edge Functions for vulnerabilities
  - Penetration testing checklist
  - Bug bounty ready review
  - Ensure no data leakage even with anon key exposed
  - Test with exposed `anon key` + `project URL`
  - Verify JWT token validation
  - Check for SQL injection
  - Check for XSS (if any web views)
  - Create `docs/SECURITY_AUDIT.md`
  - Q.196-200

### 53. Additional Database Configurations

- [ ] **Static Pages Table**

  ```sql
  CREATE TABLE static_pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL, -- 'terms', 'privacy', 'about'
    url_ar TEXT,
    url_en TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

- [ ] **FAQs Table**

  ```sql
  CREATE TABLE faqs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_ar TEXT NOT NULL,
    question_en TEXT,
    answer_ar TEXT NOT NULL,
    answer_en TEXT,
    category TEXT, -- 'orders', 'payment', 'delivery', 'account'
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

- [ ] **Home Sections Table**

  ```sql
  CREATE TABLE home_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_type TEXT NOT NULL, -- 'banners', 'categories', 'products', 'custom'
    title_ar TEXT,
    title_en TEXT,
    display_order INT DEFAULT 0,
    is_visible BOOLEAN DEFAULT true,
    config_json JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```

### 54. Documentation Files to Create

- [ ] `docs/DIALECT_GUIDELINES.md` - Egyptian dialect usage
- [ ] `docs/BRAND_GUIDELINES.md` - Brand identity and colors
- [ ] `docs/UI_INSPIRATION.md` - Reference apps analysis
- [ ] `docs/GOOGLE_PLAY_CHECKLIST.md` - Play Store compliance
- [ ] `docs/APPLE_STORE_CHECKLIST.md` - App Store compliance
- [ ] `docs/ERROR_MESSAGES.md` - Error handling guidelines
- [ ] `docs/EDGE_FUNCTIONS.md` - Complete Edge Functions list
- [ ] `docs/DATA_COLLECTION.md` - User data collection policy
- [ ] `docs/DEVICE_TESTING_MATRIX.md` - Device testing checklist
- [ ] `docs/SECURITY_AUDIT.md` - Security audit checklist

---

## 🔮 Future Features (Soon)

### Features Marked as "Soon" (Not in MVP)

- [ ] Real-time pilot location tracking on map
- [ ] In-app notification center
- [ ] Rating & review system for products/merchants
- [ ] Referral program
- [ ] Chat support with customer service
- [ ] Voice search
- [ ] Search filters (price range, etc.)
- [ ] Product variations system
- [ ] Advanced analytics dashboard
- [ ] Dark mode
- [ ] Multi-currency support
- [ ] Multi-country support
- [ ] Video product previews
- [ ] AR product preview
- [ ] Wishlist sharing
- [ ] Social media sharing
- [ ] Product comparison
- [ ] Price drop alerts
- [ ] Order scheduling (recurring orders)
- [ ] Subscription model
- [ ] Loyalty points program

### Additional Admin Features (Soon)

- [ ] More pages/sections in "Account" tab (to be defined in .md file)

---

## 🔧 Technical Stack

### Frontend (Mobile App)

- **Framework:** Flutter (Dart)
- **State Management:** flutter_bloc (Bloc/Cubit)
- **Localization:** flutter_localizations + easy_localization
- **Local Storage:** Hive
- **HTTP Client:** Supabase SDK
- **UI/UX:**
  - Skeletonizer (loading states)
  - google_sign_in: 7.2.0
  - flutter_native_splash
  - Google Maps (latest stable)
- **Notifications:** Firebase Cloud Messaging (FCM)
- **Analytics:** Firebase Analytics + Custom

### Backend (Supabase)

- **Database:** PostgreSQL
- **Authentication:** Supabase Auth + JWT
- **Storage:** Supabase Storage
- **Edge Functions:** Deno (TypeScript)
- **Real-time:** Supabase Realtime (for order updates)
- **Security:** Row Level Security (RLS) policies

### Third-Party Services

- **Payment Gateway:** PayMob (Egypt)
- **Email OTP:** Resend
- **Maps:** Google Maps API
- **Push Notifications:** FCM
- **Analytics:** Google Analytics

---

## 🗄️ Database Schema Overview

### User Management

- `users` - Customer accounts
- `deleted_users` - Soft-deleted accounts (archive)
- `user_sessions` - Active sessions
- `otp_verifications` - OTP codes for email verification
- `user_roles` - Role assignments
- `fcm_tokens` - Push notification tokens

### Locations

- `governorates` - المحافظات
- `cities` - المدن
- `areas` - المناطق
- `area_geo_zones` - Geofencing data (radius/coordinates)
- `area_requests` - User requests for new areas
- `user_addresses` - Customer delivery addresses

### Products & Categories

- `categories` - Main categories
- `subcategories` - Subcategories (optional hierarchy)
- `products` - Product catalog
- `product_images` - Multiple images per product
- `product_units` - Units of measurement (kg, gram, ton, etc.)

### Merchants

- `merchants` - Merchant accounts
- `merchant_products` - Products offered by each merchant (price, stock)
- `merchant_areas` - Areas served by each merchant
- `merchant_verification_levels` - Verification status

### Services

- `services` - Service catalog (separate from products)
- `service_providers` - Service providers (like merchants)
- `service_bookings` - Service appointments

### Orders

- `orders` - Customer orders
- `order_items` - Products/services in each order
- `order_status_history` - Status change log
- `order_pilots` - Pilot assignments (supports multi-pilot)
- `order_ratings` - Customer ratings after delivery

### Pilots

- `pilots` - Pilot/driver accounts
- `pilot_locations` - Real-time location (for future tracking)
- `pilot_availability` - Online/offline status
- `pilot_earnings` - Earnings tracker (future)

### Cart & Favorites

- `cart_items` - Shopping cart (optional server-side sync)
- `favorites` - Wishlist/favorites

### Payments & Wallet

- `wallets` - User wallet balances
- `wallet_transactions` - Transaction history
- `payment_methods` - Saved payment methods (tokens only)
- `payment_transactions` - Payment logs

### Discounts & Coupons

- `discounts` - Product/category/merchant discounts
- `coupons` - Promo codes
- `coupon_usages` - Coupon usage tracking

### Moderation

- `moderation_queue` - Orders awaiting review
- `merchant_requests` - New merchant applications
- `moderation_notes` - Notes on orders/merchants

### Notifications

- `notifications` - Notification log
- `notification_preferences` - User preferences

### Analytics

- `user_analytics` - User behavior data
- `search_history` - Search queries
- `product_views` - Product view tracking
- `order_analytics` - Order metrics

### App Configuration

- `app_settings` - Global settings (min order, delivery fees, etc.)
- `app_update` - App version control
- `feature_flags` - Feature toggles
- `banners` - Home screen banners
- `onboarding_screens` - Onboarding content

### Roles & Permissions

- `roles` - System roles (customer, merchant, pilot, moderation, admin, etc.)
- `permissions` - Permission definitions
- `role_permissions` - Role-permission mapping

---

## 📝 Notes & Constraints

### Business Rules

1. **One merchant, one area**: Merchant can only operate in one area (admin can override to serve multiple)
2. **Cheapest price wins**: Customer sees cheapest price from all merchants in their area
3. **Moderation first**: All orders go through moderation before reaching pilot (unless auto-approved)
4. **Pilot payment flow**: Pilot pays merchant from own pocket → delivers to customer → collects payment → returns to admin at end of day
5. **Markup flexibility**: Markup can be percentage or fixed amount, per product/category/merchant
6. **No merchant app**: Merchants manage inventory via web dashboard only
7. **No pilot app**: Pilots receive orders via web dashboard only
8. **Customer app only**: This Flutter app is ONLY for customers
9. **Same-area restriction**: Pilot, merchant, and customer must all be in same area
10. **Multi-pilot support**: Large orders can be assigned to multiple pilots

### Data Retention

- Deleted user data: Full archive in `deleted_users` table
- Order history: Forever (no deletion)
- Search history: Last 20 searches only
- Cart: Persistent (no expiry)

### Security Requirements

- JWT tokens for all API calls
- RLS policies on all tables
- Never expose Supabase anon key logic
- Payment tokens only (no raw card data)
- No CVV storage (PCI DSS compliance)
- IP/device banning capability

### Performance Requirements

- Infinite scroll for product lists
- Image resize on-the-fly
- Skeleton loaders for all data fetching
- Cache frequently used data (Hive)
- Optimize for 2G/3G networks

### Compliance

- Google Play Store policies
- Apple App Store policies
- GDPR considerations (data retention, deletion)
- PCI DSS (payment card security)

---

## 🎯 Success Metrics

### Key Performance Indicators (KPIs)

- [ ] User registration rate
- [ ] Order completion rate
- [ ] Average order value
- [ ] Customer retention rate
- [ ] App crash rate < 1%
- [ ] Average delivery time
- [ ] Customer satisfaction rating
- [ ] Cart abandonment rate

---

## 📞 Contact & Support

- **Facebook:** <https://www.facebook.com/Bourraq>
- **Website:** <http://www.bourraq.com/>
- **WhatsApp:** Wa.me/+20 102450471
- **Email:** <bourraq.com@gmail.com>

---

**Last Updated:** 2026-01-16  
**Version:** 1.0.2  
**Status:** ✅ Active Development

---

## 📝 Implementation Log

### 2026-01-16: Implementation Audit (60+ Tasks Documented)

#### ✅ Completed

**Full Project Scan & Documentation:**

- Scanned entire project codebase against PROJECT_TASKS.md
- Identified **60+ tasks** that were implemented but not marked as complete
- Updated Phases 1-14 to reflect actual implementation status

**Phases Updated to ✅:**

| Phase | Name | Tasks Completed |
|-------|------|-----------------|
| 1 | Project Setup | 11/11 ✅ |
| 2 | Authentication | 14/14 ✅ |
| 3 | Location & Addresses | 6/6 (UI) ✅ |
| 4 | Home Screen & Navigation | 7/7 ✅ |
| 5 | Products & Categories | 10/10 ✅ |
| 6 | Search | 6/6 ✅ |
| 7 | Cart & Favorites | 7/7 ✅ |
| 8 | Checkout & Orders | 17/17 ✅ |
| 9 | Wallet & Payments | 8/9 (PayMob pending) |
| 11 | Discounts & Coupons | 2/4 |
| 12 | Notifications | 4/5 ✅ |
| 13 | Profile & Settings | 9/10 ✅ |
| 14 | Error Handling & Polish | 6/8 ✅ |
| 15 | Analytics & Tracking | 11/11 ✅ |

**Key Files Verified:**

- `lib/features/auth/presentation/screens/` - 7 auth screens
- `lib/features/orders/presentation/screens/` - 5 order screens
- `lib/features/wallet/presentation/screens/` - 4 wallet screens
- `lib/features/account/presentation/screens/` - 5 account screens
- `lib/core/services/analytics_service.dart` - 687 lines
- `lib/core/services/fcm_service.dart` - FCM integration
- `lib/core/widgets/` - Force update, offline banner, contact options
- `supabase/migrations/` - 24 migration files
- `supabase/functions/` - 4 Edge Functions

**Database Tables Confirmed:**

- 36 tables in PUBLIC schema
- All RLS policies in place
- Analytics views created

---

### 2026-01-16: Final Gap Analysis (17+ Additional Tasks)

#### ✅ Completed

**Final Analysis of `requirements_qa.md` (182 Questions):**

- Re-analyzed ALL 182 Q&A items after initial gap analysis
- Discovered **17+ additional missing tasks** not covered before
- Added new comprehensive section: "Additional Missing Tasks (2026-01-16 Final Analysis)"

**New Sections Added (41-54):**

| Section | Category | Tasks |
|---------|----------|-------|
| 41 | Localization & Dialect | 1 |
| 42 | Country & Currency Configuration | 1 |
| 43 | Merchant Identity Hidden | 1 🔴 |
| 44 | Dynamic UI Control | 2 |
| 45 | Brand Identity & Design | 2 |
| 46 | Store Compliance | 2 🔴 |
| 47 | Error Handling & Messages | 2 |
| 48 | Documentation | 2 |
| 49 | Help & Support | 2 |
| 50 | Testing & Quality | 1 |
| 51 | App Update Popup Enhancement | 1 |
| 52 | Security | 1 🔴 |
| 53 | Additional Database Configurations | 3 tables |
| 54 | Documentation Files to Create | 10 files |

**New Database Tables to Add:**

- `static_pages` - روابط الصفحات الثابتة (الشروط، الخصوصية)
- `faqs` - الأسئلة الشائعة
- `home_sections` - التحكم في أقسام الصفحة الرئيسية

**Documentation Files Needed:**

1. `docs/DIALECT_GUIDELINES.md`
2. `docs/BRAND_GUIDELINES.md`
3. `docs/UI_INSPIRATION.md`
4. `docs/GOOGLE_PLAY_CHECKLIST.md`
5. `docs/APPLE_STORE_CHECKLIST.md`
6. `docs/ERROR_MESSAGES.md`
7. `docs/EDGE_FUNCTIONS.md`
8. `docs/DATA_COLLECTION.md`
9. `docs/DEVICE_TESTING_MATRIX.md`
10. `docs/SECURITY_AUDIT.md`

**🔴 High Priority Tasks Identified:**

1. Hide Merchant Names from Customer UI (Q.15)
2. Google Play Store Compliance Checklist (Q.142)
3. Apple App Store Compliance Checklist (Q.142)
4. Full Security Audit (Q.196-200)

---

### 2026-01-16: Full Requirements Q&A Gap Analysis (53+ Tasks)

#### ✅ Completed

**Comprehensive Analysis of `requirements_qa.md` (182 Questions):**

- Analyzed ALL 182 Q&A items from requirements_qa.md
- Compared against existing PROJECT_TASKS.md
- Identified **53+ missing or incomplete tasks**
- Added new comprehensive section: "Full Requirements Q&A Gap Analysis"

**New Sections Added (16-40):**

| Section | Category | Tasks |
|---------|----------|-------|
| 16 | Authentication & Onboarding Gaps | 3 |
| 17 | Address Management Gaps | 2 |
| 18 | Products & Display Gaps | 3 |
| 19 | Cart Behavior Gaps | 2 |
| 20 | Order Flow Gaps | 5 |
| 21 | Delivery Fees Gaps | 2 |
| 22 | Pilot System Gaps | 4 |
| 23 | Moderation Workflow Gaps | 2 |
| 24 | Merchant Gaps | 4 |
| 25 | Notifications Gaps | 2 |
| 26 | Search Gaps | 3 |
| 27 | App Configuration Gaps | 3 |
| 28 | Privacy & Data Gaps | 2 |
| 29 | Roles & Permissions Gaps | 2 |
| 30 | UI/UX Specific Gaps | 3 |
| 31 | Geofencing Gaps | 2 |
| 32 | Offline Mode Gaps | 1 |
| 33 | Language Change Gaps | 1 |
| 34 | Scheduled Orders Gaps | 1 |
| 35 | Referral Schema Gaps | 1 |
| 36 | Payment & Cash Flow Gaps | 3 |
| 37 | Account Tab Gaps | 1 |
| 38 | Empty States Gaps | 1 |
| 39 | Additional Database Tables | 4 |
| 40 | App Settings Complete List | 24 settings |

**New Edge Functions Added:**

- `auth/send_otp_email` - إرسال OTP عبر Resend
- `products/get_similar` - منتجات مشابهة
- `orders/cancel_on_price_change` - إلغاء لو التاجر عدل السعر
- `wallet/create_on_signup` - إنشاء محفظة عند التسجيل

**New Database Tables to Add:**

- `area_delivery_fees` - رسوم التوصيل لكل منطقة
- `pilot_daily_collections` - تحصيلات الطيار اليومية
- `referral_usages` - استخدامات كود الإحالة
- `product_section_visibility` - التحكم في إظهار/إخفاء أقسام المنتج

**Important Business Rules Documented:**

1. Order Flow: Customer → Moderation → Pilot → Merchant → Customer
2. Same Area Restriction: الطيار والتاجر والعميل لازم في نفس المنطقة
3. Pilot Cash Flow: الطيار بيدفع للتاجر من جيبه ويحصل من العميل
4. Cart Contradiction: يحتاج قرار (تتحفظ ولا تتمسح عند logout)
5. Merchant Sees Completed Orders Only: التاجر يشوف المكتمل فقط
6. Cancel Only at Preparing Stage: الإلغاء فقط في مرحلة التحضير

**App Settings Complete List (24 settings):**

تم توثيق جميع الإعدادات المطلوبة في جدول `app_settings` مع القيم الافتراضية.

---

### 2026-01-16: Requirements Q&A Initial Analysis

#### ✅ Completed

**Initial Analysis of `requirements_qa.md` (182 Questions):**

- Compared all 182 Q&A items against PROJECT_TASKS.md
- Identified 70+ missing or incomplete tasks
- Added new section: "Missing from Requirements Q&A"

**Previous Sections Added (1-15):**

1. Authentication & Security - 3 tasks
2. Products & Merchants - 5 tasks
3. Pricing & Markup - 3 tasks
4. Pilots/Drivers System - 6 tasks
5. Moderation System - 5 tasks
6. Orders & Checkout - 5 tasks
7. Wallet & Payments - 3 tasks
8. Multi-Pilot System - 3 tasks
9. Discounts & Coupons - 6 tasks
10. Services - 3 tasks
11. Analytics & Data Collection - 2 tasks
12. UI/UX Requirements - 4 tasks
13. Database Schema Additions - 5 SQL tables
14. Business Rules Documentation - 4 items
15. Edge Functions - 7 new functions

**Database Tables Added:**

- `product_requests` - Merchant product addition requests
- `referral_codes` - Future referral system
- `banned_ips` - IP banning
- `banned_devices` - Device banning
- `user_devices` - Device info collection

---

### 2026-01-15: FCM & Order Rating Implementation

#### ✅ Completed

**Push Notifications (FCM):**

- `lib/core/services/fcm_service.dart` - FCM Service for Flutter
- Custom notification icon (`ic_notification`)
- Local notifications support (foreground)
- Background message handling
- FCM token storage in `fcm_tokens` table

**Edge Functions:**

- `supabase/functions/send-notification/` - Send FCM notifications
- `supabase/functions/order-status-webhook/` - Auto-notify on order status change
- Database Webhook configured for `orders` table

**Order Rating:**

- `lib/features/orders/presentation/screens/order_rating_screen.dart`
- `lib/features/orders/presentation/cubit/order_rating_cubit.dart`
- `lib/features/orders/data/order_rating_service.dart`
- Route: `/orders/:id/rating`
- "Rate Order" button on delivered orders

**Database Migrations Created:**

- `015_fcm_notifications.sql` - FCM tokens, notifications, preferences, stock alerts
- `016_pilots_and_tracking.sql` - Pilots, locations, earnings
- `017_app_versions.sql` - Force update support

**Documentation:**

- `GAP_ANALYSIS.md` - Requirements vs Implementation analysis
- `FIREBASE_SETUP_GUIDE.md` - Firebase configuration guide
- `supabase/functions/FCM_SETUP.md` - Edge Functions setup guide

---

### 2026-01-16: Geofencing / Supported Areas Implementation

#### ✅ Completed

**Geofencing Feature - Restrict Orders to Supported Areas:**

- Created `lib/features/location/data/area_model.dart` - Area model
- Created `lib/features/location/data/area_service.dart` - Geofencing service with Haversine formula
- Updated `lib/features/location/data/address_service.dart` - Added areaId parameter
- Updated `lib/features/location/presentation/screens/add_address_screen.dart`:
  - Detect area on map tap
  - Show area name and delivery fee if supported
  - Show "area not supported" warning if outside
  - Disable save button if unsupported
- Updated `lib/features/checkout/presentation/screens/checkout_screen.dart`:
  - Validate areaId before placing order
  - Show warning on unsupported addresses
  - Disable confirm button if unsupported
- Added translation keys in `ar.json` and `en.json` for location.*
