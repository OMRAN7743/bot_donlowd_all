import 'package:dhikri/core/utils/arabic_numbers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArabicNumbers', () {
    test('يحوّل الأرقام إلى الصيغة العربية الهندية', () {
      expect(ArabicNumbers.format(0), '٠');
      expect(ArabicNumbers.format(5), '٥');
      expect(ArabicNumbers.format(33), '٣٣');
      expect(ArabicNumbers.format(100), '١٠٠');
    });

    test('outOf يبني صيغة "س من ص"', () {
      expect(ArabicNumbers.outOf(5, 20), '٥ من ٢٠');
    });

    test('timesLabel يستخدم صيغة عربية سليمة', () {
      expect(ArabicNumbers.timesLabel(1), 'مرة واحدة');
      expect(ArabicNumbers.timesLabel(2), 'مرتان');
      expect(ArabicNumbers.timesLabel(3), '٣ مرات');
    });
  });
}
