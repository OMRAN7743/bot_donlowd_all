import 'dart:convert';

import 'package:dhikri/app/bootstrap.dart';
import 'package:dhikri/core/services/preferences_service.dart';
import 'package:dhikri/data/datasources/bundled_adhkar_source.dart';
import 'package:dhikri/data/models/app_settings.dart';
import 'package:dhikri/data/models/dhikr.dart';
import 'package:dhikri/data/models/dhikr_category.dart';
import 'package:dhikri/data/models/reading_progress.dart';
import 'package:dhikri/data/repositories/adhkar_repository.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// بيانات اختبار اصطناعية بالكامل.
///
/// مهم: النصوص هنا **ليست أذكارًا** ولا تدّعي ذلك — هي عبارات محايدة
/// مصمَّمة لاختبار المحرك فقط، ولا تُشحن في أي نسخة إنتاج.
abstract final class TestData {
  static const List<Map<String, dynamic>> categories = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'morning',
      'name': 'قسم الاختبار الأول',
      'subtitle': 'وصف اختباري',
      'iconKey': 'sunrise',
      'order': 1,
      'isPrimary': true,
    },
    <String, dynamic>{
      'id': 'evening',
      'name': 'قسم الاختبار الثاني',
      'iconKey': 'sunset',
      'order': 2,
      'isPrimary': true,
    },
    <String, dynamic>{
      'id': 'sleep',
      'name': 'قسم الاختبار الثالث',
      'iconKey': 'moon',
      'order': 3,
    },
  ];

  static const List<Map<String, dynamic>> adhkar = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'test_001',
      'categoryId': 'morning',
      'title': 'عنصر اختباري أول',
      'text': 'نص اختباري قصير للتحقق من العدّاد.',
      'repeatCount': 3,
      'sourceName': 'مرجع اختباري',
      'sourceReference': 'صفحة ١',
      'keywords': <String>['اختبار', 'عدّاد'],
      'order': 1,
      'verificationStatus': 'verified',
    },
    <String, dynamic>{
      'id': 'test_002',
      'categoryId': 'morning',
      'title': 'عنصر اختباري ثانٍ',
      'text': 'نصٌّ اختباريٌّ آخَرُ فيه تشكيلٌ وتطويلـــات لاختبار البحث.',
      'repeatCount': 1,
      'sourceName': 'مرجع اختباري',
      'sourceReference': 'صفحة ٢',
      'order': 2,
      'verificationStatus': 'verified',
    },
    <String, dynamic>{
      'id': 'test_003',
      'categoryId': 'evening',
      'title': 'عنصر اختباري ثالث',
      'text':
          'نص طويل جدًا يُستخدم للتحقق من عدم حدوث تجاوز في التخطيط عند '
          'تكبير الخط بنسبة كبيرة، ويحتوي على كلمات كثيرة متتابعة حتى نتأكد '
          'أن الصفحة تتمدد وتُمرَّر بدل أن ينكسر التخطيط أو يظهر خطأ overflow '
          'في الاختبارات الآلية للواجهة.',
      'repeatCount': 2,
      'sourceName': 'مرجع اختباري',
      'sourceReference': 'صفحة ٣',
      'order': 3,
      'verificationStatus': 'verified',
    },
  ];

  static String get categoriesJson => jsonEncode(categories);

  static String get adhkarJson => jsonEncode(adhkar);

  static List<DhikrCategory> get categoryModels => <DhikrCategory>[
    for (var i = 0; i < categories.length; i++)
      DhikrCategory.fromJson(categories[i], index: i),
  ];

  static List<Dhikr> get dhikrModels => <Dhikr>[
    for (var i = 0; i < adhkar.length; i++) Dhikr.fromJson(adhkar[i], index: i),
  ];

  static AdhkarRepository repository() => AdhkarRepository(
    AdhkarBundle(categories: categoryModels, adhkar: dhikrModels),
  );

  /// حزمة أصول وهمية تُغذّي [BundledAdhkarSource] في الاختبارات.
  static AssetBundle bundle({
    String? adhkarOverride,
    String? categoriesOverride,
  }) {
    return _MapAssetBundle(<String, String>{
      'assets/data/categories.json': categoriesOverride ?? categoriesJson,
      'assets/data/adhkar.json': adhkarOverride ?? adhkarJson,
    });
  }

  /// حالة إقلاع جاهزة للاختبارات، بمخزن في الذاكرة.
  static AppBootstrap bootstrap({
    KeyValueStore? store,
    AdhkarRepository? repository,
    AppSettings settings = AppSettings.defaults,
    bool onboardingCompleted = true,
    Set<String> favorites = const <String>{},
    ContentState? content,
    ReadingProgress? lastSession,
    Map<String, ReadingProgress> categoryProgress =
        const <String, ReadingProgress>{},
  }) {
    return AppBootstrap(
      store: store ?? InMemoryKeyValueStore(),
      settings: settings,
      content: content ?? ContentReady(repository ?? TestData.repository()),
      favorites: favorites,
      onboardingCompleted: onboardingCompleted,
      categoryProgress: categoryProgress,
      lastSession: lastSession,
      completionLog: const <String, Set<String>>{},
    );
  }
}

/// حزمة أصول بسيطة تقرأ من خريطة في الذاكرة.
class _MapAssetBundle extends CachingAssetBundle {
  _MapAssetBundle(this._files);

  final Map<String, String> _files;

  @override
  Future<ByteData> load(String key) async {
    final content = _files[key];
    if (content == null) {
      throw FlutterError('الأصل غير موجود في حزمة الاختبار: \$key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final content = _files[key];
    if (content == null) {
      throw FlutterError('الأصل غير موجود في حزمة الاختبار: \$key');
    }
    return content;
  }
}
