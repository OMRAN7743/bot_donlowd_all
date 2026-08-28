import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/services/notification_service.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// جذر تطبيق "ذكري".
///
/// الواجهة عربية RTL من الجذر، والثيم يتبع إعدادات المستخدم مباشرة.
class DhikriApp extends ConsumerStatefulWidget {
  const DhikriApp({super.key});

  @override
  ConsumerState<DhikriApp> createState() => _DhikriAppState();
}

class _DhikriAppState extends ConsumerState<DhikriApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// عند عودة التطبيق للمقدمة نعيد ضبط المنطقة الزمنية ونعيد جدولة التذكيرات.
  ///
  /// هذا ما يجعل التذكيرات تصمد عند سفر المستخدم أو تغيّر توقيت جهازه
  /// (المواصفات §21). لا نفعل شيئًا إذا لم يكن هناك تذكير مفعَّل أصلًا.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final settings = ref.read(settingsProvider);
    if (!settings.hasAnyReminder) return;

    NotificationService.instance.refreshTimezoneAndReschedule(settings);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    final scale = settings.effectiveTextScale;

    return MaterialApp.router(
      title: AppConstants.appNameArabic,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: settings.materialThemeMode,
      theme: AppTheme.light(
        textScale: scale,
        highContrast: settings.highContrast,
        seniorMode: settings.seniorMode,
      ),
      darkTheme: AppTheme.dark(
        textScale: scale,
        highContrast: settings.highContrast,
        seniorMode: settings.seniorMode,
      ),
      builder: (context, child) {
        // نُبقي تكبير خط النظام كما هو — الشاشات مبنية لتتحمّله.
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _SystemBarsFromTheme(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

/// يضبط ألوان شريطي الحالة والتنقّل من الثيم الفعلي بدل تثبيتها.
class _SystemBarsFromTheme extends StatelessWidget {
  const _SystemBarsFromTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: child,
    );
  }
}
