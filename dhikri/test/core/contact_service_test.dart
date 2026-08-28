import 'package:dhikri/core/errors/app_exception.dart';
import 'package:dhikri/core/services/contact_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

/// يسجّل الروابط التي طُلب فتحها بدل فتحها فعليًا.
class RecordingLauncher {
  RecordingLauncher({this.succeedFor});

  /// المخططات التي "ينجح" فتحها. `null` تعني نجاح الكل.
  final Set<String>? succeedFor;

  final List<Uri> attempts = <Uri>[];

  Future<bool> call(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    attempts.add(uri);
    return succeedFor == null || succeedFor!.contains(uri.scheme);
  }
}

void main() {
  group('ContactService', () {
    test('واتساب يجرّب التطبيق المثبَّت أولًا', () async {
      final launcher = RecordingLauncher();
      await ContactService(launcher: launcher.call)
          .openWhatsApp(version: '1.0.0', platform: 'Android');

      expect(launcher.attempts, hasLength(1));
      expect(launcher.attempts.single.scheme, 'whatsapp');
    });

    test('يسقط إلى رابط wa.me عندما لا يفتح التطبيق', () async {
      final launcher = RecordingLauncher(succeedFor: <String>{'https'});
      await ContactService(launcher: launcher.call)
          .openWhatsApp(version: '1.0.0');

      expect(launcher.attempts.map((u) => u.scheme), <String>[
        'whatsapp',
        'https',
      ]);
      expect(launcher.attempts.last.host, 'wa.me');
    });

    test('يرفع خطأً عربيًا واضحًا عندما يتعذّر فتح واتساب', () async {
      final launcher = RecordingLauncher(succeedFor: const <String>{});

      await expectLater(
        ContactService(launcher: launcher.call).openWhatsApp(version: '1.0.0'),
        throwsA(
          isA<ExternalAppException>().having(
            (e) => e.userMessage,
            'message',
            'واتساب غير متوفر على هذا الجهاز',
          ),
        ),
      );
    });

    test('الرسائل النصية تفتح sms بالرقم الصحيح', () async {
      final launcher = RecordingLauncher();
      await ContactService(launcher: launcher.call).openSms();

      expect(launcher.attempts.single.scheme, 'sms');
      expect(launcher.attempts.single.path, '+967774354548');
    });

    test('الاتصال يفتح tel بالرقم الصحيح', () async {
      final launcher = RecordingLauncher();
      await ContactService(launcher: launcher.call).openCall();

      expect(launcher.attempts.single.toString(), 'tel:+967774354548');
    });

    test('يفتح دائمًا كتطبيق خارجي ولا يرسل شيئًا بنفسه', () async {
      final modes = <LaunchMode>[];
      Future<bool> launcher(
        Uri uri, {
        LaunchMode mode = LaunchMode.platformDefault,
      }) async {
        modes.add(mode);
        return true;
      }

      final service = ContactService(launcher: launcher);
      await service.openCall();
      await service.openSms();
      await service.openWhatsApp(version: '1.0.0');

      expect(modes, everyElement(LaunchMode.externalApplication));
    });

    test('فشل المشغّل بخطأ لا يسبب انهيارًا بل رسالة مفهومة', () async {
      Future<bool> throwing(
        Uri uri, {
        LaunchMode mode = LaunchMode.platformDefault,
      }) async {
        throw PlatformExceptionStub();
      }

      await expectLater(
        ContactService(launcher: throwing).openSms(),
        throwsA(isA<ExternalAppException>()),
      );
    });
  });
}

class PlatformExceptionStub implements Exception {}
