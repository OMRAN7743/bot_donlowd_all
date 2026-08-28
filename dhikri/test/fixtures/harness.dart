import 'package:dhikri/app/app.dart';
import 'package:dhikri/app/bootstrap.dart';
import 'package:dhikri/app/providers.dart';
import 'package:dhikri/core/services/narration/narration_service.dart';
import 'package:dhikri/core/services/preferences_service.dart';
import 'package:dhikri/data/models/app_settings.dart';
import 'package:dhikri/data/models/dhikr.dart';
import 'package:dhikri/features/adhkar/narration_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_data.dart';

/// خدمة نطق وهمية يتحكم بها الاختبار.
class FakeNarrationService implements NarrationService {
  FakeNarrationService({
    this.availability = const NarrationAvailability.available(),
    this.voices = const <NarrationVoice>[],
  });

  NarrationAvailability availability;
  List<NarrationVoice> voices;
  final List<String> spoken = <String>[];
  bool stopped = false;

  @override
  Future<NarrationAvailability> checkAvailability() async => availability;

  @override
  Future<List<NarrationVoice>> arabicVoices() async => voices;

  @override
  Future<void> playDhikr(Dhikr dhikr) async => spoken.add(dhikr.id);

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> setVoice(String? voiceId) async {}

  @override
  Future<void> dispose() async {}
}

/// يشغّل التطبيق كاملًا في الاختبار بحالة إقلاع مُحكَمة.
Future<KeyValueStore> pumpDhikriApp(
  WidgetTester tester, {
  AppSettings settings = AppSettings.defaults,
  KeyValueStore? store,
  bool onboardingCompleted = true,
  Set<String> favorites = const <String>{},
  ContentState? content,
  NarrationService? narration,
  Size surfaceSize = const Size(420, 900),
  double textScale = 1.0,
  Brightness platformBrightness = Brightness.light,
}) async {
  final resolvedStore = store ?? InMemoryKeyValueStore();

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  tester.platformDispatcher.platformBrightnessTestValue = platformBrightness;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bootstrapProvider.overrideWithValue(
          TestData.bootstrap(
            store: resolvedStore,
            settings: settings,
            onboardingCompleted: onboardingCompleted,
            favorites: favorites,
            content: content,
          ),
        ),
        narrationServiceProvider.overrideWithValue(
          narration ?? FakeNarrationService(),
        ),
      ],
      child: const DhikriApp(),
    ),
  );
  await tester.pumpAndSettle();

  return resolvedStore;
}

/// يتحقق أنه لم يقع أي تجاوز في التخطيط أثناء هذا الاختبار.
void expectNoOverflow() {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      errors.add(details.exceptionAsString());
    } else {
      previous?.call(details);
    }
  };
  addTearDown(() {
    FlutterError.onError = previous;
    expect(errors, isEmpty, reason: 'حدث تجاوز في التخطيط: $errors');
  });
}

/// يمرّر داخل شاشة معيّنة حتى يظهر نص مطلوب في قائمة كسولة.
Future<void> scrollToText(
  WidgetTester tester,
  Type screenType,
  String label, {
  double delta = 220,
}) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: find
        .descendant(
          of: find.byType(screenType),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}
