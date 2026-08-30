import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';

/// قسم من أقسام الأذكار كما يظهر في الواجهة.
@immutable
class DhikrCategory {
  const DhikrCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.order,
    this.subtitle,
    this.isPrimary = false,
  });

  factory DhikrCategory.fromJson(Map<String, dynamic> json, {int? index}) {
    final issues = <String>[];
    final where =
        json['id'] is String && (json['id'] as String).trim().isNotEmpty
        ? 'القسم "${json['id']}"'
        : 'القسم رقم ${index ?? 0}';

    String required(Object? value, String field) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      issues.add('$where: الحقل $field مفقود أو فارغ.');
      return '';
    }

    final id = required(json['id'], 'id');
    final name = required(json['name'], 'name');
    final iconKey = required(json['iconKey'], 'iconKey');

    final rawOrder = json['order'];
    var order = 0;
    if (rawOrder is num) {
      order = rawOrder.toInt();
    } else {
      issues.add('$where: الحقل order مفقود أو ليس رقمًا.');
    }

    if (issues.isNotEmpty) {
      throw ContentValidationException(
        'تعذّرت قراءة أقسام الأذكار.',
        debugDetail: issues.join(' | '),
        issues: issues,
      );
    }

    final subtitle = json['subtitle'];
    return DhikrCategory(
      id: id,
      name: name,
      iconKey: iconKey,
      order: order,
      subtitle: subtitle is String && subtitle.trim().isNotEmpty
          ? subtitle.trim()
          : null,
      isPrimary: json['isPrimary'] == true,
    );
  }

  final String id;
  final String name;
  final String? subtitle;

  /// مفتاح رمزي تُترجمه الواجهة إلى أيقونة — لا نخزّن كود الأيقونة في JSON.
  final String iconKey;
  final int order;

  /// أقسام "وردك اليوم" (الصباح والمساء) تُعرض ببطاقات كبيرة.
  final bool isPrimary;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'subtitle': subtitle,
    'iconKey': iconKey,
    'order': order,
    'isPrimary': isPrimary,
  };

  @override
  bool operator ==(Object other) => other is DhikrCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
