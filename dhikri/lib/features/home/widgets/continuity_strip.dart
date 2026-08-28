import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../data/models/reading_progress.dart';

/// عرض بسيط للمداومة خلال آخر سبعة أيام.
///
/// بلا نقاط، وبلا سلاسل، وبلا لوم — مجرد إشارة هادئة إلى الأيام التي أُكمل
/// فيها ورد.
class ContinuityStrip extends StatelessWidget {
  const ContinuityStrip({super.key, required this.days, required this.today});

  final List<DailyCompletion> days;
  final DateTime today;

  static const List<String> _weekdayInitials = <String>[
    'ن', // الاثنين
    'ث', // الثلاثاء
    'ر', // الأربعاء
    'خ', // الخميس
    'ج', // الجمعة
    'س', // السبت
    'ح', // الأحد
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final todayKey = DailyCompletion.dayKey(today);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          for (final day in days)
            _DayDot(
              label: _initialFor(day.day),
              done: !day.isEmpty,
              isToday: day.day == todayKey,
              successColor: tokens.success,
            ),
        ],
      ),
    );
  }

  String _initialFor(String dayKey) {
    final parsed = DateTime.tryParse(dayKey);
    if (parsed == null) return '؟';
    // DateTime.weekday: الاثنين = 1 ... الأحد = 7
    return _weekdayInitials[parsed.weekday - 1];
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.done,
    required this.isToday,
    required this.successColor,
  });

  final String label;
  final bool done;
  final bool isToday;
  final Color successColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label — ${done ? 'اكتمل ورد' : 'لا يوجد ورد مكتمل'}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? successColor : theme.colorScheme.surfaceContainer,
              border: isToday
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
