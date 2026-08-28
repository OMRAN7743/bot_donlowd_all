import 'package:flutter_test/flutter_test.dart';

import '../fixtures/test_data.dart';

void main() {
  final repository = TestData.repository();

  group('البحث العربي', () {
    test('يجد النتيجة رغم اختلاف التشكيل', () {
      final results = repository.search('نص اختباري');
      expect(results, isNotEmpty);
      expect(results.map((r) => r.dhikr.id), contains('test_001'));
    });

    test('يتجاهل التطويل في نص المصدر', () {
      // النص يحتوي "تطويلـــات"
      final results = repository.search('تطويلات');
      expect(results.map((r) => r.dhikr.id), contains('test_002'));
    });

    test('يتجاهل التشكيل في نص المصدر', () {
      // النص يحتوي "نصٌّ اختباريٌّ آخَرُ"
      final results = repository.search('اختباري اخر');
      expect(results.map((r) => r.dhikr.id), contains('test_002'));
    });

    test('يبحث في الكلمات المفتاحية', () {
      final results = repository.search('عدّاد');
      expect(results.map((r) => r.dhikr.id), contains('test_001'));
    });

    test('يبحث في اسم القسم', () {
      final results = repository.search('قسم الاختبار الثاني');
      expect(results.map((r) => r.dhikr.id), contains('test_003'));
    });

    test('يشترط تطابق كل كلمات الاستعلام', () {
      expect(repository.search('اختباري زرافة'), isEmpty);
    });

    test('مطابقة العنوان تُرجَّح على مطابقة المتن', () {
      final results = repository.search('اختباري');
      expect(results.length, greaterThan(1));
      // الأول يجب أن يطابق العنوان.
      expect(results.first.score, greaterThanOrEqualTo(results.last.score));
    });

    test('الاستعلام الفارغ لا يُعيد شيئًا', () {
      expect(repository.search(''), isEmpty);
      expect(repository.search('    '), isEmpty);
    });

    test('لا نتائج لكلمة غير موجودة', () {
      expect(repository.search('زرافة'), isEmpty);
    });
  });

  group('استعلامات المستودع', () {
    test('أذكار القسم مرتَّبة', () {
      final morning = repository.adhkarInCategory('morning');
      expect(morning.map((d) => d.id), <String>['test_001', 'test_002']);
    });

    test('countInCategory صحيح', () {
      expect(repository.countInCategory('morning'), 2);
      expect(repository.countInCategory('evening'), 1);
      expect(repository.countInCategory('sleep'), 0);
      expect(repository.countInCategory('ghost'), 0);
    });

    test('indexInCategory يجد الموضع أو -1', () {
      expect(repository.indexInCategory('morning', 'test_002'), 1);
      expect(repository.indexInCategory('morning', 'test_003'), -1);
    });

    test('الأقسام الرئيسية هي الصباح والمساء', () {
      expect(repository.primaryCategories.map((c) => c.id), <String>[
        'morning',
        'evening',
      ]);
      expect(repository.secondaryCategories.map((c) => c.id), <String>[
        'sleep',
      ]);
    });

    test('resolveAll يتجاهل المعرّفات المجهولة', () {
      final resolved = repository.resolveAll(<String>[
        'test_003',
        'ghost',
        'test_001',
      ]);
      expect(resolved.map((d) => d.id), <String>['test_001', 'test_003']);
    });

    test('dhikrById وcategoryById', () {
      expect(repository.dhikrById('test_001')?.title, 'عنصر اختباري أول');
      expect(repository.dhikrById('ghost'), isNull);
      expect(repository.categoryById('morning')?.name, 'قسم الاختبار الأول');
      expect(repository.categoryById('ghost'), isNull);
    });
  });
}
