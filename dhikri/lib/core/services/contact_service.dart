import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/developer_contact.dart';
import '../errors/app_exception.dart';
import '../utils/uri_utils.dart';

/// طرق التواصل المتاحة مع المطوّر.
enum ContactChannel { whatsApp, sms, call }

/// يبني روابط التواصل. دوال خالصة قابلة للاختبار بلا منصّة.
abstract final class ContactUris {
  /// نص الرسالة المقترح لواتساب (المواصفات §23).
  static String whatsAppMessage({required String version, String? platform}) {
    final buffer = StringBuffer()
      ..writeln('السلام عليكم')
      ..writeln('لدي ملاحظة بخصوص تطبيق ذكري')
      ..writeln()
      ..writeln('نوع الملاحظة:')
      ..writeln('المشكلة أو الاقتراح:')
      ..writeln()
      ..writeln('نسخة التطبيق:')
      ..write(version);

    // نظام التشغيل معلومة عامة فقط — لا معرّفات جهاز ولا بيانات شخصية.
    if (platform != null && platform.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln()
        ..writeln('النظام:')
        ..write(platform);
    }
    return buffer.toString();
  }

  static String smsMessage() => 'السلام عليكم\nلدي ملاحظة بخصوص تطبيق ذكري';

  /// رابط واتساب عبر الويب — يعمل حتى إن لم يكن التطبيق مثبَّتًا.
  static Uri whatsAppWeb(String message) => Uri(
    scheme: 'https',
    host: 'wa.me',
    path: '/${DeveloperContact.whatsAppNumber}',
    query: UriUtils.buildQuery(<String, String>{'text': message}),
  );

  /// رابط يفتح تطبيق واتساب المثبَّت مباشرة.
  static Uri whatsAppApp(String message) => Uri(
    scheme: 'whatsapp',
    host: 'send',
    query: UriUtils.buildQuery(<String, String>{
      'phone': DeveloperContact.whatsAppNumber,
      'text': message,
    }),
  );

  static Uri sms(String body) => Uri(
    scheme: 'sms',
    path: DeveloperContact.phoneE164,
    query: UriUtils.buildQuery(<String, String>{'body': body}),
  );

  static Uri call() => Uri(scheme: 'tel', path: DeveloperContact.phoneE164);
}

/// يفتح تطبيقًا خارجيًا للتواصل.
///
/// لا يُرسل التطبيق أي رسالة أو مكالمة تلقائيًا — يفتح التطبيق الخارجي
/// والمستخدم هو من يقرر الإرسال.
class ContactService {
  const ContactService({this.launcher = launchUrl});

  /// يمكن استبدالها في الاختبارات.
  final Future<bool> Function(Uri, {LaunchMode mode}) launcher;

  /// يفتح واتساب: يجرّب التطبيق المثبَّت أولًا ثم الرابط العام.
  Future<void> openWhatsApp({required String version, String? platform}) async {
    final message = ContactUris.whatsAppMessage(
      version: version,
      platform: platform,
    );

    if (await _tryLaunch(ContactUris.whatsAppApp(message))) return;
    if (await _tryLaunch(ContactUris.whatsAppWeb(message))) return;

    throw const ExternalAppException('واتساب غير متوفر على هذا الجهاز');
  }

  Future<void> openSms() async {
    if (await _tryLaunch(ContactUris.sms(ContactUris.smsMessage()))) return;
    throw const ExternalAppException('تطبيق الرسائل غير متوفر على هذا الجهاز');
  }

  Future<void> openCall() async {
    if (await _tryLaunch(ContactUris.call())) return;
    throw const ExternalAppException('تطبيق الهاتف غير متوفر على هذا الجهاز');
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launcher(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      // رابط غير مدعوم على هذا الجهاز — نجرّب البديل التالي بلا انهيار.
      if (kDebugMode) debugPrint('Launch failed for ${uri.scheme}: $error');
      return false;
    }
  }
}
