# البدء السريع ⚡

تعليمات سريعة لتشغيل التطبيق.

## الخطوات الضرورية

### 1. تثبيت Flutter (إذا لم يكن مثبتاً)

**Windows:**
```bash
# قم بتحميل Flutter من:
# https://docs.flutter.dev/get-started/install/windows

# بعد التثبيت، تحقق من التثبيت:
flutter doctor
```

### 2. إعداد Firebase (خطوات سريعة)

1. اذهب إلى https://console.firebase.google.com/
2. أنشئ مشروع جديد
3. فعّل:
   - **Authentication** > Google Sign-In
   - **Firestore Database** > Create database (test mode)
4. أضف Android App:
   - Package: `com.bloodcenter.donation_storage`
   - حمّل `google-services.json`
   - ضعه في: `android/app/google-services.json`

**للتفاصيل:** اقرأ [FIREBASE_SETUP.md](file:///c:/Users/zidan/Desktop/Donation%20Storage/FIREBASE_SETUP.md)

### 3. تثبيت المكتبات

```bash
cd "c:\Users\zidan\Desktop\Donation Storage"
flutter pub get
```

### 4. تشغيل التطبيق

```bash
# على محاكي أو هاتف متصل:
flutter run

# أو لبناء APK:
flutter build apk --release
```

## ملف google-services.json مطلوب! ⚠️

**التطبيق لن يعمل بدون هذا الملف.**

موقعه المطلوب:
```
android/app/google-services.json
```

يوجد ملف نموذجي في:
```
android/app/google-services.json.TEMPLATE
```

## اختبار سريع

بعد تشغيل التطبيق:

1. ✅ **تسجيل الدخول** بحساب Google
2. ✅ **أضف صنف** من تبويب "إدارة الأصناف"
3. ✅ **أضف طلبية** من تبويب "إضافة طلبية"
4. ✅ **ابحث** عن الصنف في تبويب "استعلام"
5. ✅ **اخصم رصيد** من تبويب "خصم رصيد"

## مشاكل شائعة

### "google-services.json not found"
➡️ **الحل:** حمّل الملف من Firebase ضعه في `android/app/`

### "Google Sign-In failed"
➡️ **الحل:** 
1. تأكد من تفعيل Google في Firebase Console
2. أضف SHA-1 fingerprint (راجع FIREBASE_SETUP.md)

### Flutter command not found
➡️ **الحل:** تأكد من إضافة Flutter إلى PATH

## دعم

- 📖 دليل كامل: [README.md](file:///c:/Users/zidan/Desktop/Donation%20Storage/README.md)
- 🔥 إعداد Firebase: [FIREBASE_SETUP.md](file:///c:/Users/zidan/Desktop/Donation%20Storage/FIREBASE_SETUP.md)
- 📋 نظرة شاملة: راجع artifacts/walkthrough.md

---

**بالتوفيق! 🎉**
