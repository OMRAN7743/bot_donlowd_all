import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// اختبارات تحرس شروط الإصدار التي لا يمكن اكتشافها من الواجهة.
void main() {
  group('صلاحيات أندرويد', () {
    late String manifest;

    setUpAll(() {
      manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
    });

    test('لا يطلب التطبيق أي صلاحية محظورة', () {
      const forbidden = <String>[
        'android.permission.INTERNET',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.ACCESS_COARSE_LOCATION',
        'android.permission.READ_CONTACTS',
        'android.permission.WRITE_CONTACTS',
        'android.permission.RECORD_AUDIO',
        'android.permission.CAMERA',
        'android.permission.SEND_SMS',
        'android.permission.READ_SMS',
        'android.permission.CALL_PHONE',
        'android.permission.READ_CALL_LOG',
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.WRITE_EXTERNAL_STORAGE',
        'android.permission.SCHEDULE_EXACT_ALARM',
        'android.permission.USE_EXACT_ALARM',
      ];

      for (final permission in forbidden) {
        expect(
          manifest.contains(permission),
          isFalse,
          reason: 'الصلاحية المحظورة موجودة: $permission',
        );
      }
    });

    test('يطلب فقط ما تحتاجه التذكيرات والاهتزاز', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.VIBRATE'));
    });

    test('يدعم الاتجاه من اليمين لليسار', () {
      expect(manifest, contains('android:supportsRtl="true"'));
    });
  });

  group('اعتماديات المشروع', () {
    late String pubspec;

    setUpAll(() => pubspec = File('pubspec.yaml').readAsStringSync());

    test('لا توجد حزم تتبّع أو إعلانات أو خدمات سحابية', () {
      const forbidden = <String>[
        'firebase',
        'google_mobile_ads',
        'admob',
        'supabase',
        'amplitude',
        'mixpanel',
        'sentry',
        'posthog',
        'facebook_',
        'onesignal',
        'appsflyer',
      ];

      final lower = pubspec.toLowerCase();
      for (final package in forbidden) {
        expect(
          lower.contains(package),
          isFalse,
          reason: 'حزمة محظورة في pubspec: $package',
        );
      }
    });
  });

  group('بيانات الأذكار المرفقة', () {
    test('categories.json صالح ولا يحتوي معرّفات مكرَّرة', () {
      final raw = File('assets/data/categories.json').readAsStringSync();
      final decoded = jsonDecode(raw);

      expect(decoded, isA<List<dynamic>>());
      final ids = <String>{};
      for (final entry in decoded as List<dynamic>) {
        expect(entry, isA<Map<String, dynamic>>());
        final map = entry as Map<String, dynamic>;
        expect(map['id'], isA<String>());
        expect(map['name'], isA<String>());
        expect(map['iconKey'], isA<String>());
        expect(map['order'], isA<int>());
        expect(ids.add(map['id'] as String), isTrue, reason: 'معرّف مكرَّر');
      }
    });

    test('adhkar.json موجود وصالح كقائمة JSON', () {
      final raw = File('assets/data/adhkar.json').readAsStringSync();
      expect(jsonDecode(raw), isA<List<dynamic>>());
    });

    test('كل ذكر مرفق ينتمي إلى قسم معرَّف وحالته موثقة', () {
      final categories =
          (jsonDecode(File('assets/data/categories.json').readAsStringSync())
                  as List<dynamic>)
              .map((e) => (e as Map<String, dynamic>)['id'] as String)
              .toSet();

      final adhkar = jsonDecode(
        File('assets/data/adhkar.json').readAsStringSync(),
      ) as List<dynamic>;

      for (final entry in adhkar) {
        final map = entry as Map<String, dynamic>;
        expect(categories, contains(map['categoryId']));
        expect(
          map['verificationStatus'],
          'verified',
          reason: 'لا يُشحن في الإصدار إلا سجل موثق: ${map['id']}',
        );
      }
    });
  });

  group('أداة التحقق من المحتوى', () {
    test('تمر على البيانات المرفقة في الفحص البنيوي', () {
      final result = Process.runSync('dart', <String>[
        'run',
        'tool/validate_adhkar.dart',
      ], workingDirectory: Directory.current.path);

      expect(
        result.exitCode,
        0,
        reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
      );
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
