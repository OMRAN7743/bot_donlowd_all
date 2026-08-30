# مجلد الإصدار

**لا يحتوي هذا المجلد على ملف APK.**

لم يُبنَ أي APK لأن بيئة التنفيذ لا تملك Android SDK، ولا يمكن تثبيته فيها لأن
سياسة الشبكة تمنع مستودعات أدوات أندرويد (`dl.google.com` و`maven.google.com`
تُعيدان 403).

`flutter build apk --release` يتوقف عند:

```
[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.
```

هذا مانع بيئي لا علاقة له بالكود: `flutter analyze` نظيف و226 اختبارًا تمر.

## كيف تبني APK بنفسك

على أي جهاز فيه Android SDK وJava 17:

```bash
cd dhikri
flutter pub get
dart run tool/validate_adhkar.dart --release   # بوابة المحتوى — يجب أن تمر أولًا
flutter build apk --release
```

سيظهر الناتج في `build/app/outputs/flutter-apk/app-release.apk`، وانسخه هنا
باسم `Dhikri-release.apk` إن أردت.

الخطوات الكاملة وشروط التوقيع في `../QA_REPORT.md` (البند 9).
