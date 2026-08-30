import '../../core/utils/arabic_search_normalizer.dart';
import '../datasources/bundled_adhkar_source.dart';
import '../models/dhikr.dart';
import '../models/dhikr_category.dart';

/// نتيجة بحث واحدة مع درجة ترتيب.
class DhikrSearchResult {
  const DhikrSearchResult({required this.dhikr, required this.score});

  final Dhikr dhikr;

  /// كلما زادت، كانت المطابقة أقرب لعنوان الذكر.
  final int score;
}

/// الواجهة التي تستهلكها الطبقات العليا للوصول إلى المحتوى.
class AdhkarRepository {
  AdhkarRepository(this._bundle);

  /// يبني المستودع بقراءة الأصول المرفقة.
  static Future<AdhkarRepository> fromSource(BundledAdhkarSource source) async {
    return AdhkarRepository(await source.load());
  }

  final AdhkarBundle _bundle;

  /// فهارس مبنية مرة واحدة — لا نعيد المسح الخطي في كل استدعاء.
  late final Map<String, Dhikr> _byId = <String, Dhikr>{
    for (final dhikr in _bundle.adhkar) dhikr.id: dhikr,
  };

  late final Map<String, List<Dhikr>> _byCategory = _groupByCategory();

  late final Map<String, String> _searchIndex = <String, String>{
    for (final dhikr in _bundle.adhkar)
      dhikr.id: ArabicSearchNormalizer.normalize(
        <String>[
          dhikr.title,
          dhikr.text,
          ...dhikr.keywords,
          categoryById(dhikr.categoryId)?.name ?? '',
        ].join(' '),
      ),
  };

  late final Map<String, String> _titleIndex = <String, String>{
    for (final dhikr in _bundle.adhkar)
      dhikr.id: ArabicSearchNormalizer.normalize(dhikr.title),
  };

  List<DhikrCategory> get categories => _bundle.categories;

  List<Dhikr> get allAdhkar => _bundle.adhkar;

  bool get isEmpty => _bundle.isEmpty;

  /// أقسام "وردك اليوم" (الصباح والمساء) بالترتيب.
  List<DhikrCategory> get primaryCategories =>
      categories.where((c) => c.isPrimary).toList(growable: false);

  List<DhikrCategory> get secondaryCategories =>
      categories.where((c) => !c.isPrimary).toList(growable: false);

  DhikrCategory? categoryById(String id) {
    for (final category in _bundle.categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Dhikr? dhikrById(String id) => _byId[id];

  /// أذكار قسم معيّن مرتَّبة حسب `order`.
  List<Dhikr> adhkarInCategory(String categoryId) =>
      _byCategory[categoryId] ?? const <Dhikr>[];

  /// عدد الأذكار داخل قسم — يُستخدم في شريط التقدُّم.
  int countInCategory(String categoryId) => adhkarInCategory(categoryId).length;

  /// موضع الذكر داخل قسمه، أو `-1` إن لم يوجد.
  int indexInCategory(String categoryId, String dhikrId) {
    final list = adhkarInCategory(categoryId);
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == dhikrId) return i;
    }
    return -1;
  }

  List<Dhikr> resolveAll(Iterable<String> ids) {
    final result = <Dhikr>[];
    for (final id in ids) {
      final dhikr = _byId[id];
      if (dhikr != null) result.add(dhikr);
    }
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  /// بحث عربي محلي: يطابق كل كلمات الاستعلام بعد التطبيع.
  ///
  /// المطابقة في العنوان تُرجّح النتيجة على المطابقة في متن النص.
  List<DhikrSearchResult> search(String query) {
    final tokens = ArabicSearchNormalizer.tokenize(query);
    if (tokens.isEmpty) return const <DhikrSearchResult>[];

    final results = <DhikrSearchResult>[];
    for (final dhikr in _bundle.adhkar) {
      final haystack = _searchIndex[dhikr.id] ?? '';
      final title = _titleIndex[dhikr.id] ?? '';

      var score = 0;
      var matchesAll = true;
      for (final token in tokens) {
        if (!haystack.contains(token)) {
          matchesAll = false;
          break;
        }
        score += title.contains(token) ? 3 : 1;
        if (title.startsWith(token)) score += 2;
      }
      if (matchesAll) {
        results.add(DhikrSearchResult(dhikr: dhikr, score: score));
      }
    }

    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.dhikr.order.compareTo(b.dhikr.order);
    });
    return List<DhikrSearchResult>.unmodifiable(results);
  }

  Map<String, List<Dhikr>> _groupByCategory() {
    final grouped = <String, List<Dhikr>>{};
    for (final dhikr in _bundle.adhkar) {
      grouped.putIfAbsent(dhikr.categoryId, () => <Dhikr>[]).add(dhikr);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.order.compareTo(b.order));
    }
    return grouped.map(
      (key, value) => MapEntry(key, List<Dhikr>.unmodifiable(value)),
    );
  }
}
