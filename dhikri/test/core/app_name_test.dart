import 'dart:convert';
import 'dart:io';

import 'package:dhikri/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('اسم التطبيق', () {
    test('الاسم العربي هو "ذكري" بالضبط', () {
      expect(AppConstants.appNameArabic, 'ذكري');
    });

    test('ليس "ذكرى" وليس "ذكر"', () {
      expect(AppConstants.appNameArabic, isNot('ذكرى'));
      expect(AppConstants.appNameArabic, isNot('ذكر'));
      expect(AppConstants.appNameArabic.endsWith('ى'), isFalse);
      expect(AppConstants.appNameArabic.endsWith('ي'), isTrue);
    });

    test('لا يظهر الاسم الخاطئ "ذكرى" في أي ملف مصدر أو إعداد', () {
      final offenders = <String>[];
      final roots = <String>['lib', 'android/app/src/main', 'assets/data'];

      for (final root in roots) {
        final dir = Directory(root);
        if (!dir.existsSync()) continue;
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is! File) continue;
          if (!<String>[
            '.dart',
            '.xml',
            '.json',
            '.yaml',
          ].any(entity.path.endsWith)) {
            continue;
          }
          final content = utf8.decode(
            entity.readAsBytesSync(),
            allowMalformed: true,
          );
          if (content.contains('ذكرى')) offenders.add(entity.path);
        }
      }

      expect(offenders, isEmpty, reason: 'وُجد الاسم الخاطئ في: $offenders');
    });

    test('اسم التطبيق في AndroidManifest هو "ذكري"', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml');
      expect(manifest.existsSync(), isTrue);
      expect(manifest.readAsStringSync(), contains('android:label="ذكري"'));
    });
  });
}
