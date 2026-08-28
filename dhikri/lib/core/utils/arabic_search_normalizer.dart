/// تطبيع النص العربي **لأغراض البحث فقط**.
///
/// تحذير مهم: لا تُستخدم هذه الدوال أبدًا على النص المعروض أو المخزَّن.
/// نص الذكر يبقى كما ورد في ملف البيانات حرفًا بحرف.
abstract final class ArabicSearchNormalizer {
  /// علامات التشكيل وعلامات الضبط القرآنية التي تُحذف قبل المطابقة.
  static bool _isDiacritic(int code) {
    return (code >= 0x064B && code <= 0x065F) || // الفتحة .. علامات إضافية
        code == 0x0670 || // ألف خنجرية
        (code >= 0x06D6 && code <= 0x06ED) || // علامات الوقف والضبط
        code == 0x0653 || // مدة
        code == 0x0654 || // همزة فوق
        code == 0x0655; // همزة تحت
  }

  /// محرف التطويل (ـ) الذي يُستخدم للتمديد البصري فقط.
  static const int _tatweel = 0x0640;

  /// يوحّد صور الألف والياء والتاء المربوطة لتحسين نتائج البحث.
  static String _foldLetter(String ch) {
    return switch (ch) {
      'أ' || 'إ' || 'آ' || 'ٱ' || 'ٲ' || 'ٳ' => 'ا',
      'ى' || 'ي' || 'ئ' => 'ي',
      'ؤ' => 'و',
      'ة' => 'ه',
      'ء' => '',
      'ک' => 'ك',
      'گ' => 'ك',
      'ٹ' => 'ت',
      _ => ch,
    };
  }

  /// يحوّل النص إلى صورة قابلة للمطابقة: بلا تشكيل ولا تطويل، بصور موحّدة،
  /// بمسافات مضغوطة، وبأحرف لاتينية صغيرة.
  static String normalize(String input) {
    if (input.isEmpty) return '';

    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (_isDiacritic(rune) || rune == _tatweel) continue;
      buffer.write(_foldLetter(String.fromCharCode(rune)));
    }

    return buffer
        .toString()
        .toLowerCase()
        .replaceAll(
          RegExp('[\\u200B-\\u200F\\u202A-\\u202E\\u2066-\\u2069]'),
          '',
        ) // محارف اتجاه خفية
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// هل يحتوي [haystack] على [needle] بعد تطبيع الاثنين؟
  static bool contains(String haystack, String needle) {
    final n = normalize(needle);
    if (n.isEmpty) return false;
    return normalize(haystack).contains(n);
  }

  /// يقسّم استعلام المستخدم إلى كلمات مطبَّعة غير فارغة.
  static List<String> tokenize(String query) =>
      normalize(query)
          .split(' ')
          .where((token) => token.isNotEmpty)
          .toList(growable: false);
}
