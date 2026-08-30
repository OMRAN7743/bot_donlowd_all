import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';

/// حالة توثيق النص الشرعي.
///
/// لا يدخل الإصدار النهائي إلا ما كان [VerificationStatus.verified].
enum VerificationStatus {
  draft('draft'),
  reviewRequired('reviewRequired'),
  verified('verified');

  const VerificationStatus(this.wireName);

  final String wireName;

  static VerificationStatus? tryParse(String? value) {
    for (final status in VerificationStatus.values) {
      if (status.wireName == value) return status;
    }
    return null;
  }
}

/// ذكر واحد كما هو مخزَّن في `assets/data/adhkar.json`.
@immutable
class Dhikr {
  const Dhikr({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.text,
    required this.repeatCount,
    required this.order,
    required this.verificationStatus,
    this.sourceName,
    this.sourceReference,
    this.note,
    this.audioAssetPath,
    this.keywords = const <String>[],
  });

  /// يبني [Dhikr] من خريطة JSON، ويجمع كل المشكلات في استثناء واحد واضح.
  ///
  /// [index] يُستخدم فقط لتحسين رسالة الخطأ عندما يكون `id` مفقودًا.
  factory Dhikr.fromJson(Map<String, dynamic> json, {int? index}) {
    final issues = <String>[];
    final where =
        json['id'] is String && (json['id'] as String).trim().isNotEmpty
        ? 'الذكر "${json['id']}"'
        : 'الذكر رقم ${index ?? 0}';

    final id = _requiredString(json['id'], 'id', where, issues);
    final categoryId = _requiredString(
      json['categoryId'],
      'categoryId',
      where,
      issues,
    );
    final title = _requiredString(json['title'], 'title', where, issues);
    final text = _requiredString(json['text'], 'text', where, issues);

    final rawRepeat = json['repeatCount'];
    var repeatCount = 0;
    if (rawRepeat is int) {
      repeatCount = rawRepeat;
    } else if (rawRepeat is num) {
      repeatCount = rawRepeat.toInt();
    } else {
      issues.add('$where: الحقل repeatCount مفقود أو ليس رقمًا.');
    }
    if (rawRepeat != null && repeatCount < 1) {
      issues.add(
        '$where: repeatCount يجب أن يكون 1 أو أكثر (القيمة $repeatCount).',
      );
    }

    final rawOrder = json['order'];
    var order = 0;
    if (rawOrder is int) {
      order = rawOrder;
    } else if (rawOrder is num) {
      order = rawOrder.toInt();
    } else {
      issues.add('$where: الحقل order مفقود أو ليس رقمًا.');
    }

    final status = VerificationStatus.tryParse(
      json['verificationStatus'] as String?,
    );
    if (status == null) {
      issues.add(
        '$where: verificationStatus غير معروف '
        '(${json['verificationStatus']}). المسموح: draft, reviewRequired, verified.',
      );
    }

    final rawKeywords = json['keywords'];
    final keywords = <String>[];
    if (rawKeywords is List) {
      for (final k in rawKeywords) {
        if (k is String && k.trim().isNotEmpty) keywords.add(k.trim());
      }
    } else if (rawKeywords != null) {
      issues.add('$where: الحقل keywords يجب أن يكون قائمة نصوص.');
    }

    if (issues.isNotEmpty) {
      throw ContentValidationException(
        'تعذّرت قراءة بيانات الأذكار.',
        debugDetail: issues.join(' | '),
        issues: issues,
      );
    }

    return Dhikr(
      id: id,
      categoryId: categoryId,
      title: title,
      text: text,
      repeatCount: repeatCount,
      order: order,
      verificationStatus: status!,
      sourceName: _optionalString(json['sourceName']),
      sourceReference: _optionalString(json['sourceReference']),
      note: _optionalString(json['note']),
      audioAssetPath: _optionalString(json['audioAssetPath']),
      keywords: List<String>.unmodifiable(keywords),
    );
  }

  final String id;
  final String categoryId;
  final String title;
  final String text;
  final int repeatCount;
  final int order;
  final VerificationStatus verificationStatus;
  final String? sourceName;
  final String? sourceReference;
  final String? note;

  /// مسار تسجيل بشري موثق داخل `assets/audio/` إن وُجد.
  final String? audioAssetPath;
  final List<String> keywords;

  bool get hasSource =>
      (sourceName != null && sourceName!.isNotEmpty) ||
      (sourceReference != null && sourceReference!.isNotEmpty);

  bool get hasRecordedAudio =>
      audioAssetPath != null && audioAssetPath!.trim().isNotEmpty;

  /// سطر المصدر كما يُعرض تحت نص الذكر.
  String get sourceLine {
    final parts = <String>[
      if (sourceName != null && sourceName!.isNotEmpty) sourceName!,
      if (sourceReference != null && sourceReference!.isNotEmpty)
        sourceReference!,
    ];
    return parts.join(' — ');
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'categoryId': categoryId,
    'title': title,
    'text': text,
    'repeatCount': repeatCount,
    'sourceName': sourceName,
    'sourceReference': sourceReference,
    'note': note,
    'audioAssetPath': audioAssetPath,
    'keywords': keywords,
    'order': order,
    'verificationStatus': verificationStatus.wireName,
  };

  @override
  bool operator ==(Object other) => other is Dhikr && other.id == id;

  @override
  int get hashCode => id.hashCode;

  static String _requiredString(
    Object? value,
    String field,
    String where,
    List<String> issues,
  ) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    issues.add('$where: الحقل $field مفقود أو فارغ.');
    return '';
  }

  static String? _optionalString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}
