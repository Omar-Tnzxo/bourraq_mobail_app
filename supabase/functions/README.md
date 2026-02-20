# Bourraq Dashboard - Edge Functions Deployment Guide

## 📋 نظرة عامة

تم إنشاء Edge Functions لإدارة الطلبات بشكل آمن مع التحقق من الصلاحيات.

## 🚀 Edge Functions المتوفرة

### 1. `update-order-status`

**الوظيفة:** تحديث حالة الطلب

**المسار:** `/functions/v1/update-order-status`

**الصلاحية المطلوبة:** `can_edit_order_status`

**الحالات المتاحة:**

- `pending` → `confirmed`, `cancelled`
- `confirmed` → `preparing`, `cancelled`
- `preparing` → `ready`, `cancelled`
- `ready` → `picked_up`, `cancelled`
- `picked_up` → `delivered`, `cancelled`

**Request Body:**

```json
{
  "order_id": "uuid",
  "new_status": "confirmed",
  "notes": "optional cancellation reason"
}
```

---

### 2. `assign-pilot`

**الوظيفة:** تعيين طيار للطلب

**المسار:** `/functions/v1/assign-pilot`

**الصلاحية المطلوبة:** `can_assign_orders`

**Request Body:**

```json
{
  "order_id": "uuid",
  "pilot_id": "uuid"
}
```

---

## 📦 نشر Edge Functions على Supabase

### الخطوة 1: التأكد من تثبيت Supabase CLI

```bash
# تثبيت Supabase CLI
npm install -g supabase

# التحقق من التثبيت
supabase --version
```

### الخطوة 2: تسجيل الدخول

```bash
supabase login
```

### الخطوة 3: ربط المشروع

```bash
cd bourraq_mobail_app
supabase link --project-ref vthdyrqdtudtngachsdl
```

### الخطوة 4: نشر Functions

```bash
# نشر جميع Functions
supabase functions deploy

# أو نشر Function محددة
supabase functions deploy update-order-status
supabase functions deploy assign-pilot
```

---

## 🔐 إعداد المتغيرات البيئية

تأكد من إعداد المتغيرات التالية في Supabase Dashboard:

```
SUPABASE_URL=https://vthdyrqdtudtngachsdl.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

---

## ✅ اختبار Functions

### اختبار محلي

```bash
# تشغيل Function محلياً
supabase functions serve update-order-status

# اختبار
curl -i --location --request POST 'http://localhost:54321/functions/v1/update-order-status' \
  --header 'Authorization: Bearer YOUR_JWT_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{"order_id":"uuid","new_status":"confirmed"}'
```

### اختبار على Production

```bash
curl -i --location --request POST 'https://vthdyrqdtudtngachsdl.supabase.co/functions/v1/update-order-status' \
  --header 'Authorization: Bearer YOUR_JWT_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{"order_id":"uuid","new_status":"confirmed"}'
```

---

## 🛡️ الأمان

- ✅ جميع Functions تتطلب JWT Token صالح
- ✅ التحقق من الصلاحيات على مستوى Admin
- ✅ التحقق من تسلسل الحالات المنطقي
- ✅ RLS Policies مفعلة على جميع الجداول

---

## 📝 ملاحظات مهمة

1. **JWT Token:** يتم الحصول عليه تلقائياً من `supabase.auth.getSession()`
2. **CORS:** مفعل للسماح بالطلبات من Dashboard
3. **Error Handling:** جميع الأخطاء تُرجع برسائل واضحة
4. **Logging:** يمكن مراجعة Logs من Supabase Dashboard → Edge Functions

---

## 🔄 تحديث Functions

عند تعديل أي Function:

```bash
# نشر التحديثات
supabase functions deploy function-name

# مراجعة Logs
supabase functions logs function-name
```

---

## 📞 الدعم

في حالة وجود مشاكل:

1. تحقق من Logs في Supabase Dashboard
2. تأكد من صحة JWT Token
3. تحقق من الصلاحيات في جدول `admin_permissions`
