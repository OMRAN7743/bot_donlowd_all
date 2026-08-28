# إشعارات الطرف الثالث — ذكري

يستخدم تطبيق ذكري المكوّنات المفتوحة التالية. تظهر النصوص الكاملة لتراخيص
الحزم داخل التطبيق في: **الإعدادات ← عن ذكري ← التراخيص**.

## الخط

### Noto Sans Arabic

- الملف: `assets/fonts/NotoSansArabic.ttf`
- الترخيص: SIL Open Font License 1.1 — نصّه الكامل في `assets/fonts/OFL.txt`
- حقوق النشر: Copyright 2022 The Noto Project Authors
  (<https://github.com/notofonts/arabic>)
- الخط مضمَّن محليًا مع التطبيق. **لا يوجد أي تنزيل خطوط وقت التشغيل.**

## إطار العمل

- **Flutter** و**Dart** — رخصة BSD‑3‑Clause، Copyright 2014 The Flutter Authors.

## الحزم

| الحزمة | الاستخدام | الترخيص |
|---|---|---|
| `flutter_riverpod` | إدارة الحالة | MIT |
| `go_router` | التنقّل بين الشاشات | BSD‑3‑Clause |
| `shared_preferences` | تخزين الإعدادات والتقدُّم محليًا | BSD‑3‑Clause |
| `flutter_tts` | القراءة الصوتية بمحرك الجهاز | MIT |
| `just_audio` | تشغيل التسجيلات المرفقة | MIT |
| `audio_session` | التعامل مع مقاطعات الصوت | MIT |
| `flutter_local_notifications` | التذكيرات المحلية | BSD‑3‑Clause |
| `timezone` | حساب مواعيد التذكير محليًا | BSD‑2‑Clause |
| `flutter_timezone` | قراءة المنطقة الزمنية للجهاز | MIT |
| `url_launcher` | فتح واتساب والرسائل والهاتف | BSD‑3‑Clause |
| `package_info_plus` | عرض رقم الإصدار | BSD‑3‑Clause |
| `flutter_lints` | قواعد التحليل (تطوير فقط) | BSD‑3‑Clause |
| `flutter_launcher_icons` | توليد الأيقونات (تطوير فقط) | MIT |
| `flutter_native_splash` | توليد شاشة البداية (تطوير فقط) | MIT |

الأرقام الدقيقة للإصدارات في `pubspec.lock`.

## محتوى الأذكار

لا يتضمّن الإصدار الحالي أي نص شرعي بعد — راجع `CONTENT_AUDIT.md`.

عند استيراد محتوى موثق لاحقًا تُضاف مصادره هنا وفي شاشة «مصادر المحتوى» داخل
التطبيق. وإذا استُخدم نص قرآني من **Tanzil** فيجب الالتزام بشروط رخصته
(Creative Commons Attribution 3.0): النسخ الحرفي، وعدم تغيير النص، وذكر Tanzil
مصدرًا، وتضمين إشعار الترخيص المطلوب — <https://tanzil.net/docs/Text_License>.

## أيقونة التطبيق

العمل الفني للأيقونة (`assets/branding/app_icon_source.png`) قدّمه صاحب المشروع،
وتُشتق منه بقية المقاسات عبر `tool/generate_branding.py`.
