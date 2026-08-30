import 'package:flutter/material.dart';

/// يحوّل `iconKey` النصي في ملف الأقسام إلى أيقونة Material.
///
/// نحتفظ بالمفاتيح نصية في JSON حتى لا يعتمد ملف البيانات على كود الواجهة.
IconData categoryIcon(String iconKey) {
  return switch (iconKey) {
    'sunrise' => Icons.wb_twilight_rounded,
    'sunset' => Icons.nights_stay_outlined,
    'moon' => Icons.bedtime_rounded,
    'wake' => Icons.alarm_on_rounded,
    'prayer' => Icons.mosque_rounded,
    'water' => Icons.water_drop_rounded,
    'home' => Icons.home_rounded,
    'mosque' => Icons.account_balance_rounded,
    'food' => Icons.restaurant_rounded,
    'travel' => Icons.flight_takeoff_rounded,
    'heart' => Icons.favorite_rounded,
    'healing' => Icons.healing_rounded,
    'weather' => Icons.grain_rounded,
    'gathering' => Icons.groups_rounded,
    'hands' => Icons.volunteer_activism_rounded,
    _ => Icons.auto_stories_rounded,
  };
}
