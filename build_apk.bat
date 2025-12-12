@echo off
echo ===============================================
echo    بناء تطبيق ادارة مخزون التبرعات
echo ===============================================
echo.

REM التحقق من وجود Flutter
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [خطأ] Flutter غير مثبت!
    echo يرجى تثبيت Flutter أولاً من:
    echo https://docs.flutter.dev/get-started/install/windows
    echo.
    pause
    exit /b 1
)

echo [✓] Flutter مثبت
echo.

REM التحقق من وجود google-services.json
if not exist "android\app\google-services.json" (
    echo [خطأ] ملف google-services.json غير موجود!
    echo يرجى تحميله من Firebase Console ووضعه في:
    echo android\app\google-services.json
    echo.
    echo راجع: FIREBASE_SETUP.md
    echo.
    pause
    exit /b 1
)

echo [✓] google-services.json موجود
echo.

REM تثبيت المكتبات
echo [1/3] تثبيت المكتبات...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [خطأ] فشل تثبيت المكتبات
    pause
    exit /b 1
)
echo [✓] تم تثبيت المكتبات
echo.

REM تنظيف البناء السابق
echo [2/3] تنظيف البناء السابق...
call flutter clean
echo.

REM بناء APK
echo [3/3] بناء APK...
echo هذا قد يستغرق عدة دقائق...
echo.
call flutter build apk --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [خطأ] فشل بناء APK
    echo راجع الأخطاء أعلاه
    pause
    exit /b 1
)

echo.
echo ===============================================
echo            تم البناء بنجاح! 🎉
echo ===============================================
echo.
echo ملف APK موجود في:
echo %CD%\build\app\outputs\flutter-apk\app-release.apk
echo.
echo يمكنك نسخ هذا الملف إلى هاتف Android وتثبيته
echo.

REM فتح مجلد APK
start "" "%CD%\build\app\outputs\flutter-apk"

pause
