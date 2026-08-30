import 'dart:convert';

import 'package:dhikri/core/errors/app_exception.dart';
import 'package:dhikri/data/datasources/bundled_adhkar_source.dart';
import 'package:dhikri/data/models/dhikr.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/test_data.dart';

void main() {
  group('Dhikr.fromJson', () {
    test('يقرأ سجلًا صحيحًا بكل حقوله', () {
      final dhikr = Dhikr.fromJson(TestData.adhkar.first);

      expect(dhikr.id, 'test_001');
      expect(dhikr.categoryId, 'morning');
      expect(dhikr.repeatCount, 3);
      expect(dhikr.order, 1);
      expect(dhikr.verificationStatus, VerificationStatus.verified);
      expect(dhikr.keywords, contains('اختبار'));
      expect(dhikr.hasSource, isTrue);
      expect(dhikr.sourceLine, 'مرجع اختباري — صفحة ١');
      expect(dhikr.hasRecordedAudio, isFalse);
    });

    test('يرفض repeatCount أقل من 1', () {
      expect(
        () => Dhikr.fromJson(<String, dynamic>{
          ...TestData.adhkar.first,
          'repeatCount': 0,
        }),
        throwsA(
          isA<ContentValidationException>().having(
            (e) => e.issues.join(),
            'issues',
            contains('repeatCount'),
          ),
        ),
      );
    });

    test('يرفض repeatCount السالب', () {
      expect(
        () => Dhikr.fromJson(<String, dynamic>{
          ...TestData.adhkar.first,
          'repeatCount': -3,
        }),
        throwsA(isA<ContentValidationException>()),
      );
    });

    test('يرفض النص الفارغ', () {
      expect(
        () => Dhikr.fromJson(<String, dynamic>{
          ...TestData.adhkar.first,
          'text': '   ',
        }),
        throwsA(isA<ContentValidationException>()),
      );
    });

    test('يرفض المعرّف المفقود', () {
      final json = Map<String, dynamic>.from(TestData.adhkar.first)
        ..remove('id');
      expect(
        () => Dhikr.fromJson(json, index: 4),
        throwsA(
          isA<ContentValidationException>().having(
            (e) => e.issues.join(),
            'issues',
            contains('رقم 4'),
          ),
        ),
      );
    });

    test('يرفض verificationStatus غير معروف', () {
      expect(
        () => Dhikr.fromJson(<String, dynamic>{
          ...TestData.adhkar.first,
          'verificationStatus': 'approved',
        }),
        throwsA(isA<ContentValidationException>()),
      );
    });

    test('يجمع كل المشكلات في استثناء واحد', () {
      expect(
        () => Dhikr.fromJson(<String, dynamic>{'id': 'x'}),
        throwsA(
          isA<ContentValidationException>().having(
            (e) => e.issues.length,
            'issues count',
            greaterThan(3),
          ),
        ),
      );
    });

    test('toJson ثم fromJson يعطي نفس السجل', () {
      final original = Dhikr.fromJson(TestData.adhkar.first);
      final round = Dhikr.fromJson(original.toJson());
      expect(round.id, original.id);
      expect(round.text, original.text);
      expect(round.repeatCount, original.repeatCount);
      expect(round.verificationStatus, original.verificationStatus);
    });
  });

  group('BundledAdhkarSource', () {
    test('يحمّل الأقسام والأذكار من حزمة الأصول', () async {
      final bundle = await BundledAdhkarSource(TestData.bundle()).load();

      expect(bundle.categories, hasLength(3));
      expect(bundle.adhkar, hasLength(3));
      expect(bundle.isEmpty, isFalse);
    });

    test('يكتشف المعرّفات المكرّرة في الأذكار', () async {
      final duplicated = <Map<String, dynamic>>[
        TestData.adhkar[0],
        <String, dynamic>{...TestData.adhkar[1], 'id': 'test_001'},
      ];
      final source = BundledAdhkarSource(
        TestData.bundle(adhkarOverride: _encode(duplicated)),
      );

      await expectLater(
        source.load(),
        throwsA(
          isA<ContentValidationException>().having(
            (e) => e.debugDetail ?? '',
            'detail',
            contains('مكرَّر'),
          ),
        ),
      );
    });

    test('يكتشف الأقسام المكرّرة', () async {
      final duplicated = <Map<String, dynamic>>[
        TestData.categories[0],
        <String, dynamic>{...TestData.categories[1], 'id': 'morning'},
      ];
      final source = BundledAdhkarSource(
        TestData.bundle(categoriesOverride: _encode(duplicated)),
      );

      await expectLater(
        source.load(),
        throwsA(isA<ContentValidationException>()),
      );
    });

    test('يكتشف الذكر المرتبط بقسم غير موجود', () async {
      final orphan = <Map<String, dynamic>>[
        <String, dynamic>{...TestData.adhkar[0], 'categoryId': 'ghost'},
      ];
      final source = BundledAdhkarSource(
        TestData.bundle(adhkarOverride: _encode(orphan)),
      );

      await expectLater(
        source.load(),
        throwsA(
          isA<ContentValidationException>().having(
            (e) => e.issues.join(),
            'issues',
            contains('ghost'),
          ),
        ),
      );
    });

    test('يرفض JSON غير صالح برسالة عربية', () async {
      final source = BundledAdhkarSource(
        TestData.bundle(adhkarOverride: '{ this is not json'),
      );

      await expectLater(
        source.load(),
        throwsA(
          isA<ContentLoadException>().having(
            (e) => e.userMessage,
            'message',
            'ملف البيانات غير صالح.',
          ),
        ),
      );
    });

    test('يرفض الجذر الذي ليس قائمة', () async {
      final source = BundledAdhkarSource(
        TestData.bundle(adhkarOverride: '{"id":"x"}'),
      );
      await expectLater(source.load(), throwsA(isA<ContentLoadException>()));
    });

    test('يقبل مجموعة أذكار فارغة بلا خطأ', () async {
      final source = BundledAdhkarSource(TestData.bundle(adhkarOverride: '[]'));
      final bundle = await source.load();

      expect(bundle.isEmpty, isTrue);
      expect(bundle.categories, hasLength(TestData.categories.length));
    });

    test('يرتّب الأذكار حسب order', () async {
      final shuffled = <Map<String, dynamic>>[
        TestData.adhkar[2],
        TestData.adhkar[0],
        TestData.adhkar[1],
      ];
      final source = BundledAdhkarSource(
        TestData.bundle(adhkarOverride: _encode(shuffled)),
      );
      final bundle = await source.load();

      expect(bundle.adhkar.map((d) => d.order).toList(), <int>[1, 2, 3]);
    });
  });
}

String _encode(List<Map<String, dynamic>> entries) => jsonEncode(entries);
