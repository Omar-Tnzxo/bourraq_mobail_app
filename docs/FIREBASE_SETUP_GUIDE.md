# Firebase & FCM Setup Guide | دليل إعداد Firebase والإشعارات

## خطوة 1: إنشاء مشروع Firebase

### 1.1 الدخول لـ Firebase Console

1. اذهب إلى: <https://console.firebase.google.com/>
2. سجل الدخول بحساب Google
3. اضغط **"Create a project"** أو **"Add project"**

### 1.2 إنشاء المشروع

1. **اسم المشروع**: `bourraq-app` (أو أي اسم تفضله)
2. **Google Analytics**: اختر **Enable** (موصى به للتحليلات)
3. اختر حساب Analytics موجود أو أنشئ جديد
4. اضغط **Create project**
5. انتظر حتى يكتمل الإنشاء

---

## خطوة 2: إعداد Android

### 2.1 إضافة تطبيق Android

1. في Firebase Console، اضغط على أيقونة **Android**
2. أدخل البيانات التالية:
   - **Android package name**: `com.bourraq.app` (تأكد أنه نفس الموجود في `android/app/build.gradle`)
   - **App nickname**: Bourraq Android
   - **Debug signing certificate SHA-1**: (اختياري للآن، مطلوب لـ Google Sign-In)

### 2.2 تحميل google-services.json

1. اضغط **Download google-services.json**
2. انسخ الملف إلى: `android/app/google-services.json`

### 2.3 تحديث Android configuration

#### في `android/build.gradle`

```gradle
buildscript {
    dependencies {
        // أضف هذا السطر
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### في `android/app/build.gradle`

```gradle
// في نهاية الملف
apply plugin: 'com.google.gms.google-services'
```

---

## خطوة 3: إعداد iOS

### 3.1 إضافة تطبيق iOS

1. في Firebase Console، اضغط على أيقونة **iOS**
2. أدخل البيانات:
   - **iOS bundle ID**: `com.bourraq.app` (تأكد أنه نفس الموجود في Xcode)
   - **App nickname**: Bourraq iOS

### 3.2 تحميل GoogleService-Info.plist

1. اضغط **Download GoogleService-Info.plist**
2. افتح Xcode:

   ```
   open ios/Runner.xcworkspace
   ```

3. اسحب الملف إلى مجلد `Runner` في Xcode
4. تأكد من تفعيل **"Copy items if needed"**

### 3.3 تحديث iOS Capabilities

1. في Xcode، اذهب لـ **Runner** → **Signing & Capabilities**
2. اضغط **+ Capability**
3. أضف **Push Notifications**
4. أضف **Background Modes** وفعّل:
   - Remote notifications

---

## خطوة 4: تفعيل Cloud Messaging

### 4.1 في Firebase Console

1. اذهب إلى **Project Settings** (ترس الإعدادات)
2. اختر **Cloud Messaging**
3. تأكد من أن Cloud Messaging API مفعّل

### 4.2 للـ iOS (APNs)

1. في **Cloud Messaging** → **Apple app configuration**
2. ارفع **APNs Authentication Key** أو **APNs Certificates**
   - للحصول على APNs Key:
     1. اذهب لـ <https://developer.apple.com/account/resources/authkeys/list>
     2. اضغط **+** لإنشاء key جديد
     3. فعّل **Apple Push Notifications service (APNs)**
     4. حمّل الـ `.p8` file
3. ارفع الـ key في Firebase Console

---

## خطوة 5: إضافة Firebase packages في Flutter

### 5.1 تحديث pubspec.yaml

```yaml
dependencies:
  firebase_core: ^2.25.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.0.0
```

### 5.2 تثبيت الـ packages

```bash
flutter pub get
```

---

## خطوة 6: التحقق من الإعداد

### 6.1 تشغيل التطبيق

```bash
flutter run
```

### 6.2 إرسال إشعار تجريبي

1. في Firebase Console، اذهب لـ **Messaging**
2. اضغط **Create your first campaign** → **Firebase Notification messages**
3. أدخل:
   - **Title**: اختبار
   - **Text**: هذا إشعار تجريبي
4. اضغط **Send test message**
5. أدخل FCM token من الـ console/logs
6. اضغط **Test**

---

## ملاحظات هامة

> ⚠️ **للمستخدمين اللي مثبتين التطبيق بدون حساب (Guests)**:
>
> - سيتم حفظ FCM token مع `device_id` بدون `user_id`
> - يمكن إرسال إشعارات لهم عبر استهداف `target_type = 'guests'`

> ⚠️ **أنواع الاستهداف المتاحة**:
>
> - `all`: جميع المستخدمين
> - `registered`: المستخدمين المسجلين فقط
> - `guests`: الزوار فقط (مثبتين بدون حساب)
> - `area`: منطقة معينة
> - `user`: مستخدم محدد

---

## الخطوة التالية

بعد إكمال هذا الإعداد، أخبرني وسأقوم بتفعيل الكود في التطبيق.
