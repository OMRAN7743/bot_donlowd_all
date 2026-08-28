/// أدوات بناء الروابط بأمان.
abstract final class UriUtils {
  /// يبني سلسلة استعلام بترميز نسبة مئوية صحيح.
  ///
  /// نتجنّب `Uri.queryParameters` عمدًا لأنه يرمّز المسافة إلى `+`، وبعض
  /// تطبيقات الرسائل تعرض علامة الزائد حرفيًا داخل نص الرسالة.
  static String buildQuery(Map<String, String> parameters) {
    return parameters.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');
  }
}
