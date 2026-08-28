import 'package:dhikri/core/utils/arabic_search_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArabicSearchNormalizer', () {
    test('يحذف التشكيل بالكامل', () {
      expect(ArabicSearchNormalizer.normalize('سَلامٌ'), 'سلام');
      expect(ArabicSearchNormalizer.normalize('الْحَمْدُ'), 'الحمد');
    });

    test('يحذف التطويل', () {
      expect(ArabicSearchNormalizer.normalize('سلـــام'), 'سلام');
    });

    test('يوحّد صور الألف', () {
      const forms = <String>['أمل', 'إمل', 'آمل', 'ٱمل'];
      for (final form in forms) {
        expect(ArabicSearchNormalizer.normalize(form), 'امل', reason: form);
      }
    });

    test('يوحّد الياء والألف المقصورة والتاء المربوطة', () {
      expect(
        ArabicSearchNormalizer.normalize('على'),
        ArabicSearchNormalizer.normalize('علي'),
      );
      expect(ArabicSearchNormalizer.normalize('رحمة'), 'رحمه');
    });

    test('يضغط المسافات ويحذف الأطراف', () {
      expect(
        ArabicSearchNormalizer.normalize('  ذكر    الصباح  '),
        'ذكر الصباح',
      );
    });

    test('يحوّل الحروف اللاتينية إلى صغيرة', () {
      expect(ArabicSearchNormalizer.normalize('Dhikri APP'), 'dhikri app');
    });

    test('يحذف محارف الاتجاه الخفية', () {
      expect(ArabicSearchNormalizer.normalize('ذكر​ي'), 'ذكري');
    });

    test('النص الفارغ يعطي نصًّا فارغًا', () {
      expect(ArabicSearchNormalizer.normalize(''), '');
      expect(ArabicSearchNormalizer.tokenize('   '), isEmpty);
    });

    test('contains يطابق رغم اختلاف التشكيل', () {
      expect(
        ArabicSearchNormalizer.contains('الْحَمْدُ لِلَّهِ', 'الحمد'),
        isTrue,
      );
      expect(ArabicSearchNormalizer.contains('الحمد لله', 'شكر'), isFalse);
    });

    test('tokenize يقسّم إلى كلمات مطبَّعة', () {
      expect(ArabicSearchNormalizer.tokenize('  أذكارُ   الصَّباح '), <String>[
        'اذكار',
        'الصباح',
      ]);
    });
  });
}
