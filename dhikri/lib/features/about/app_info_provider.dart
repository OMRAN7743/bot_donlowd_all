import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// معلومات النسخة كما يعرضها التطبيق.
@immutable
class AppVersionInfo {
  const AppVersionInfo({required this.version, required this.buildNumber});

  static const AppVersionInfo unknown = AppVersionInfo(
    version: '—',
    buildNumber: '',
  );

  final String version;
  final String buildNumber;

  /// "1.0.0 (1)"
  String get display =>
      buildNumber.isEmpty ? version : '$version ($buildNumber)';
}

/// اسم النظام بصيغة عامة — بلا أي معرّف جهاز.
String currentPlatformLabel() => switch (defaultTargetPlatform) {
  TargetPlatform.android => 'Android',
  TargetPlatform.iOS => 'iOS',
  _ => '',
};

final appVersionProvider = FutureProvider<AppVersionInfo>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return AppVersionInfo(version: info.version, buildNumber: info.buildNumber);
  } catch (error) {
    // بيئة بلا حزمة مثبَّتة (اختبارات): نعرض شرطة بدل الفشل.
    if (kDebugMode) debugPrint('PackageInfo unavailable: $error');
    return AppVersionInfo.unknown;
  }
});
