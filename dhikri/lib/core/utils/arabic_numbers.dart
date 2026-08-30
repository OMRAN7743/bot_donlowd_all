/// عرض الأرقام بالصيغة العربية الهندية (٠١٢٣...) المألوفة لجمهور التطبيق.
abstract final class ArabicNumbers {
  static const List<String> _digits = <String>[
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  /// يحوّل عددًا صحيحًا إلى أرقام عربية هندية.
  static String format(int value) {
    if (value < 0) return '؜-${format(-value)}';
    final buffer = StringBuffer();
    for (final ch in value.toString().split('')) {
      final digit = int.tryParse(ch);
      buffer.write(digit == null ? ch : _digits[digit]);
    }
    return buffer.toString();
  }

  /// "٥ من ٢٠"
  static String outOf(int current, int total) =>
      '${format(current)} من ${format(total)}';

  /// صيغة عربية سليمة لعدد المرات: مرة، مرتان، ٣ مرات...
  static String timesLabel(int count) => switch (count) {
    1 => 'مرة واحدة',
    2 => 'مرتان',
    _ => '${format(count)} مرات',
  };
}
