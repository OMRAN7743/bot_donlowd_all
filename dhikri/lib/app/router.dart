import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/about/sources_screen.dart';
import '../features/adhkar/completion_screen.dart';
import '../features/adhkar/reading_screen.dart';
import '../features/contact/contact_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/appearance_settings_screen.dart';
import '../features/settings/audio_settings_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/reminders_settings_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tasbih/tasbih_screen.dart';
import 'providers.dart';
import 'shell.dart';

/// مسارات التطبيق (المواصفات §30).
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String favorites = '/favorites';
  static const String tasbih = '/tasbih';
  static const String settings = '/settings';
  static const String appearanceSettings = '/settings/appearance';
  static const String audioSettings = '/settings/audio';
  static const String remindersSettings = '/settings/reminders';
  static const String privacy = '/settings/privacy';
  static const String search = '/search';
  static const String about = '/about';
  static const String sources = '/about/sources';
  static const String contact = '/contact';

  static String category(String id) => '/category/$id';

  static String dhikr(String id) => '/dhikr/$id';

  static String completion(String categoryId) => '/completion/$categoryId';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final done = ref.read(onboardingCompletedProvider);
      final atOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!done && !atOnboarding) return AppRoutes.onboarding;
      if (done && atOnboarding) return AppRoutes.home;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // الأقسام الأربعة الظاهرة في الشريط السفلي.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.favorites,
                name: 'favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.tasbih,
                name: 'tasbih',
                builder: (context, state) => const TasbihScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // شاشات تُفتح فوق الشريط السفلي بملء الشاشة.
      GoRoute(
        path: '/category/:categoryId',
        name: 'category',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ReadingScreen(categoryId: state.pathParameters['categoryId']!),
      ),
      GoRoute(
        path: '/dhikr/:dhikrId',
        name: 'dhikr',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ReadingScreen.forDhikr(dhikrId: state.pathParameters['dhikrId']!),
      ),
      GoRoute(
        path: '/completion/:categoryId',
        name: 'completion',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            CompletionScreen(categoryId: state.pathParameters['categoryId']!),
      ),
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.appearanceSettings,
        name: 'appearanceSettings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AppearanceSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.audioSettings,
        name: 'audioSettings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AudioSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.remindersSettings,
        name: 'remindersSettings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RemindersSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        name: 'privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.sources,
        name: 'sources',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SourcesScreen(),
      ),
      GoRoute(
        path: AppRoutes.contact,
        name: 'contact',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ContactScreen(),
      ),
    ],
    errorBuilder: (context, state) => const _RouteNotFoundScreen(),
  );
});

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('صفحة غير موجودة')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('لم نجد هذه الصفحة', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
