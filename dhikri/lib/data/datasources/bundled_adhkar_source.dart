import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/dhikr.dart';
import '../models/dhikr_category.dart';

/// محتوى الأذكار كما حُمِّل من ملفات الأصول المرفقة مع التطبيق.
class AdhkarBundle {
  const AdhkarBundle({required this.categories, required this.adhkar});

  final List<DhikrCategory> categories;
  final List<Dhikr> adhkar;

  bool get isEmpty => adhkar.isEmpty;
}

/// يقرأ `assets/data/*.json` — بدون أي اتصال بالشبكة.
class BundledAdhkarSource {
  const BundledAdhkarSource([this._bundle]);

  final AssetBundle? _bundle;

  AssetBundle get _assets => _bundle ?? rootBundle;

  Future<AdhkarBundle> load() async {
    final categories = await _loadCategories();
    final adhkar = await _loadAdhkar();
    _crossValidate(categories, adhkar);
    return AdhkarBundle(categories: categories, adhkar: adhkar);
  }

  Future<List<DhikrCategory>> _loadCategories() async {
    final raw = await _readAsset(
      AppConstants.categoriesAssetPath,
      'أقسام الأذكار',
    );
    final decoded = _decodeList(raw, AppConstants.categoriesAssetPath);

    final categories = <DhikrCategory>[];
    final seen = <String>{};
    for (var i = 0; i < decoded.length; i++) {
      final entry = decoded[i];
      if (entry is! Map<String, dynamic>) {
        throw ContentValidationException(
          'تعذّرت قراءة أقسام الأذكار.',
          debugDetail: 'categories.json: العنصر رقم $i ليس كائنًا.',
        );
      }
      final category = DhikrCategory.fromJson(entry, index: i);
      if (!seen.add(category.id)) {
        throw ContentValidationException(
          'تعذّرت قراءة أقسام الأذكار.',
          debugDetail: 'categories.json: معرّف مكرَّر "${category.id}".',
          issues: <String>['معرّف قسم مكرَّر: ${category.id}'],
        );
      }
      categories.add(category);
    }

    categories.sort((a, b) => a.order.compareTo(b.order));
    return List<DhikrCategory>.unmodifiable(categories);
  }

  Future<List<Dhikr>> _loadAdhkar() async {
    final raw = await _readAsset(AppConstants.adhkarAssetPath, 'الأذكار');
    final decoded = _decodeList(raw, AppConstants.adhkarAssetPath);

    final adhkar = <Dhikr>[];
    final seen = <String>{};
    for (var i = 0; i < decoded.length; i++) {
      final entry = decoded[i];
      if (entry is! Map<String, dynamic>) {
        throw ContentValidationException(
          'تعذّرت قراءة بيانات الأذكار.',
          debugDetail: 'adhkar.json: العنصر رقم $i ليس كائنًا.',
        );
      }
      final dhikr = Dhikr.fromJson(entry, index: i);
      if (!seen.add(dhikr.id)) {
        throw ContentValidationException(
          'تعذّرت قراءة بيانات الأذكار.',
          debugDetail: 'adhkar.json: معرّف مكرَّر "${dhikr.id}".',
          issues: <String>['معرّف ذكر مكرَّر: ${dhikr.id}'],
        );
      }
      adhkar.add(dhikr);
    }

    adhkar.sort((a, b) => a.order.compareTo(b.order));
    return List<Dhikr>.unmodifiable(adhkar);
  }

  /// يتأكد أن كل ذكر ينتمي إلى قسم موجود فعلًا.
  void _crossValidate(List<DhikrCategory> categories, List<Dhikr> adhkar) {
    final ids = categories.map((c) => c.id).toSet();
    final missing = <String>{};
    for (final dhikr in adhkar) {
      if (!ids.contains(dhikr.categoryId)) missing.add(dhikr.categoryId);
    }
    if (missing.isNotEmpty) {
      throw ContentValidationException(
        'تعذّرت قراءة بيانات الأذكار.',
        debugDetail: 'أقسام غير معرَّفة: ${missing.join(", ")}',
        issues: missing.map((id) => 'قسم غير معرَّف: $id').toList(),
      );
    }
  }

  Future<String> _readAsset(String path, String label) async {
    try {
      return await _assets.loadString(path);
    } catch (error) {
      throw ContentLoadException(
        'لم نتمكن من فتح ملف $label.',
        debugDetail: 'تعذّر تحميل $path: $error',
      );
    }
  }

  List<dynamic> _decodeList(String raw, String path) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('الجذر يجب أن يكون قائمة.');
      }
      return decoded;
    } on FormatException catch (error) {
      throw ContentLoadException(
        'ملف البيانات غير صالح.',
        debugDetail: '$path: ${error.message}',
      );
    }
  }
}
