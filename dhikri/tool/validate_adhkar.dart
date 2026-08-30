// أداة التحقق من بيانات الأذكار قبل الإصدار.
//
//   dart run tool/validate_adhkar.dart              # فحص بنيوي (تطوير)
//   dart run tool/validate_adhkar.dart --release    # بوابة الإصدار الكاملة
//
// تُرجع رمز خروج غير صفري عند أي فشل.

import 'dart:convert';
import 'dart:io';

/// عبارات لا يجوز أن تصل إلى الإصدار.
const List<String> _placeholderMarkers = <String>[
  'TODO',
  'FIXME',
  'XXX',
  'lorem ipsum',
  '<النص',
  '<العنوان',
  '<المصدر',
  '<المرجع',
  'PLACEHOLDER',
  'placeholder',
  'نص تجريبي',
  'نص مؤقت',
];

/// حقول لا يجوز أن تحتوي حروفًا لاتينية في سجل موثق.
final RegExp _latinLetters = RegExp(r'[A-Za-z]');

void main(List<String> args) {
  final releaseMode = args.contains('--release');
  final report = _Report();

  final categoriesFile = File('assets/data/categories.json');
  final adhkarFile = File('assets/data/adhkar.json');

  final categories = _readJsonList(categoriesFile, report);
  final adhkar = _readJsonList(adhkarFile, report);

  if (report.hasErrors) {
    _finish(report, releaseMode);
    return;
  }

  final categoryIds = _validateCategories(categories!, report);
  _validateAdhkar(adhkar!, categoryIds, report, releaseMode: releaseMode);

  if (releaseMode && adhkar.isEmpty) {
    report.error(
      'BLOCKER: مجموعة الأذكار الإنتاجية فارغة. '
      'لا يمكن إصدار التطبيق بلا محتوى موثق — راجع CONTENT_AUDIT.md.',
    );
  }

  _finish(report, releaseMode);
}

Set<String> _validateCategories(List<dynamic> categories, _Report report) {
  final ids = <String>{};
  final orders = <int, String>{};

  for (var i = 0; i < categories.length; i++) {
    final entry = categories[i];
    final where = 'categories[$i]';
    if (entry is! Map<String, dynamic>) {
      report.error('$where: ليس كائن JSON.');
      continue;
    }

    final id = _stringOf(entry['id']);
    if (id == null) {
      report.error('$where: الحقل id مفقود أو فارغ.');
    } else if (!ids.add(id)) {
      report.error('$where: معرّف القسم "$id" مكرَّر.');
    }

    if (_stringOf(entry['name']) == null) {
      report.error('$where: الحقل name مفقود أو فارغ.');
    }
    if (_stringOf(entry['iconKey']) == null) {
      report.error('$where: الحقل iconKey مفقود أو فارغ.');
    }

    final order = entry['order'];
    if (order is! int) {
      report.error('$where: الحقل order مفقود أو ليس عددًا صحيحًا.');
    } else {
      final clash = orders[order];
      if (clash != null) {
        report.error('$where: الترتيب $order مستخدم أيضًا في القسم "$clash".');
      } else {
        orders[order] = id ?? where;
      }
    }
  }

  return ids;
}

void _validateAdhkar(
  List<dynamic> adhkar,
  Set<String> categoryIds,
  _Report report, {
  required bool releaseMode,
}) {
  final ids = <String>{};
  final ordersPerCategory = <String, Map<int, String>>{};

  for (var i = 0; i < adhkar.length; i++) {
    final entry = adhkar[i];
    final where = 'adhkar[$i]';
    if (entry is! Map<String, dynamic>) {
      report.error('$where: ليس كائن JSON.');
      continue;
    }

    final id = _stringOf(entry['id']);
    final label = id == null ? where : '$where (id: $id)';

    if (id == null) {
      report.error('$where: الحقل id مفقود أو فارغ.');
    } else if (!ids.add(id)) {
      report.error('$label: معرّف الذكر مكرَّر.');
    }

    final title = _stringOf(entry['title']);
    if (title == null) report.error('$label: الحقل title مفقود أو فارغ.');

    final text = _stringOf(entry['text']);
    if (text == null) report.error('$label: الحقل text مفقود أو فارغ.');

    final categoryId = _stringOf(entry['categoryId']);
    if (categoryId == null) {
      report.error('$label: الحقل categoryId مفقود أو فارغ.');
    } else if (!categoryIds.contains(categoryId)) {
      report.error(
        '$label: القسم "$categoryId" غير معرَّف في categories.json.',
      );
    }

    final repeatCount = entry['repeatCount'];
    if (repeatCount is! int) {
      report.error('$label: الحقل repeatCount مفقود أو ليس عددًا صحيحًا.');
    } else if (repeatCount < 1) {
      report.error(
        '$label: repeatCount يجب أن يكون 1 أو أكثر (القيمة $repeatCount).',
      );
    }

    final order = entry['order'];
    if (order is! int) {
      report.error('$label: الحقل order مفقود أو ليس عددًا صحيحًا.');
    } else if (categoryId != null) {
      final seen = ordersPerCategory.putIfAbsent(
        categoryId,
        () => <int, String>{},
      );
      final clash = seen[order];
      if (clash != null) {
        report.error(
          '$label: الترتيب $order مكرَّر داخل القسم "$categoryId" مع "$clash".',
        );
      } else {
        seen[order] = id ?? where;
      }
    }

    final status = _stringOf(entry['verificationStatus']);
    const allowed = <String>{'draft', 'reviewRequired', 'verified'};
    if (status == null || !allowed.contains(status)) {
      report.error(
        '$label: verificationStatus غير صالح ($status). '
        'المسموح: ${allowed.join(", ")}.',
      );
    }

    final keywords = entry['keywords'];
    if (keywords != null && keywords is! List) {
      report.error('$label: الحقل keywords يجب أن يكون قائمة.');
    }

    // نصوص مؤقتة ممنوعة في أي وضع.
    for (final field in <String>[
      'title',
      'text',
      'sourceName',
      'sourceReference',
      'note',
    ]) {
      final value = _stringOf(entry[field]);
      if (value == null) continue;
      for (final marker in _placeholderMarkers) {
        if (value.toLowerCase().contains(marker.toLowerCase())) {
          report.error(
            '$label: الحقل $field يحتوي نصًا مؤقتًا ممنوعًا: "$marker".',
          );
        }
      }
    }

    final audioPath = _stringOf(entry['audioAssetPath']);
    if (audioPath != null && !File(audioPath).existsSync()) {
      report.error('$label: ملف الصوت "$audioPath" غير موجود.');
    }

    // ------- قيود وضع الإصدار -------
    if (releaseMode) {
      if (status != 'verified') {
        report.error(
          'BLOCKER $label: verificationStatus = "$status". '
          'لا يدخل الإصدار إلا ما كان "verified".',
        );
      }
      if (_stringOf(entry['sourceName']) == null) {
        report.error('BLOCKER $label: sourceName مطلوب لكل سجل في الإصدار.');
      }
      if (_stringOf(entry['sourceReference']) == null) {
        report.error(
          'BLOCKER $label: sourceReference مطلوب لكل سجل في الإصدار.',
        );
      }
      if (title != null && _latinLetters.hasMatch(title)) {
        report.error(
          'BLOCKER $label: العنوان يحتوي حروفًا لاتينية — يُرجَّح أنه نص مؤقت.',
        );
      }
    }
  }
}

List<dynamic>? _readJsonList(File file, _Report report) {
  if (!file.existsSync()) {
    report.error('الملف ${file.path} غير موجود.');
    return null;
  }
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) {
      report.error('${file.path}: الجذر يجب أن يكون قائمة JSON.');
      return null;
    }
    return decoded;
  } on FormatException catch (error) {
    report.error('${file.path}: JSON غير صالح — ${error.message}');
    return null;
  }
}

String? _stringOf(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

void _finish(_Report report, bool releaseMode) {
  final mode = releaseMode ? 'بوابة الإصدار (--release)' : 'فحص بنيوي';
  stdout.writeln('أداة التحقق من بيانات الأذكار — $mode');

  if (report.errors.isEmpty) {
    stdout.writeln('✔ لا توجد أخطاء.');
    if (!releaseMode) {
      stdout.writeln(
        'ملاحظة: هذا فحص بنيوي فقط. شغّل --release قبل بناء نسخة للنشر.',
      );
    }
    exit(0);
  }

  stdout.writeln('✘ عدد المشكلات: ${report.errors.length}');
  for (final error in report.errors) {
    stdout.writeln('  - $error');
  }
  exit(1);
}

class _Report {
  final List<String> errors = <String>[];

  bool get hasErrors => errors.isNotEmpty;

  void error(String message) => errors.add(message);
}
