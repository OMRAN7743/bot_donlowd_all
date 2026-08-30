import 'package:dhikri/app/providers.dart';
import 'package:dhikri/core/services/narration/narration_service.dart';
import 'package:dhikri/data/models/app_settings.dart';
import 'package:dhikri/features/adhkar/narration_controller.dart';
import 'package:dhikri/features/adhkar/reading_controller.dart';
import 'package:dhikri/features/adhkar/reading_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/harness.dart';
import '../fixtures/test_data.dart';

ProviderContainer makeContainer({
  AppSettings settings = AppSettings.defaults,
  NarrationService? narration,
}) {
  final container = ProviderContainer(
    overrides: [
      bootstrapProvider.overrideWithValue(
        TestData.bootstrap(settings: settings),
      ),
      narrationServiceProvider.overrideWithValue(
        narration ?? FakeNarrationService(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('رسائل توفّر الصوت', () {
    test('لكل سبب رسالة عربية واضحة', () {
      for (final reason in NarrationUnavailableReason.values) {
        final availability = NarrationAvailability.unavailable(reason);
        expect(availability.isAvailable, isFalse);
        expect(availability.message, isNotEmpty);
      }
    });

    test('رسالة غياب الصوت العربي ترشد لإعدادات الجهاز', () {
      const availability = NarrationAvailability.unavailable(
        NarrationUnavailableReason.arabicVoiceMissing,
      );
      expect(availability.message, contains('الصوت العربي غير متوفر'));
      expect(availability.message, contains('تحويل النص إلى كلام'));
    });

    test('الحالة المتاحة بلا رسالة', () {
      const availability = NarrationAvailability.available();
      expect(availability.isAvailable, isTrue);
      expect(availability.message, isEmpty);
    });
  });

  group('مزوّد التوفّر', () {
    test('يُبلغ أن السبب هو إطفاء المستخدم عندما يكون الصوت مُطفأً', () async {
      final container = makeContainer(
        settings: const AppSettings(audioEnabled: false),
      );

      final availability = await container.read(
        narrationAvailabilityProvider.future,
      );

      expect(availability.isAvailable, isFalse);
      expect(availability.reason, NarrationUnavailableReason.disabledByUser);
    });

    test('يستخدم نتيجة الخدمة عندما يكون الصوت مُفعَّلًا', () async {
      final container = makeContainer(
        narration: FakeNarrationService(
          availability: const NarrationAvailability.unavailable(
            NarrationUnavailableReason.engineMissing,
          ),
        ),
      );

      final availability = await container.read(
        narrationAvailabilityProvider.future,
      );

      expect(availability.reason, NarrationUnavailableReason.engineMissing);
    });
  });

  group('وضع استمع وردّد', () {
    test('يبدأ من السكون', () {
      final container = makeContainer();
      expect(
        container.read(listenRepeatProvider('morning')).phase,
        NarrationPhase.idle,
      );
    });

    test('لا يشغّل شيئًا ويعرض خطأً عندما يكون الصوت مُطفأً', () async {
      final narration = FakeNarrationService();
      final container = makeContainer(
        settings: const AppSettings(audioEnabled: false),
        narration: narration,
      );

      await container
          .read(listenRepeatProvider('morning').notifier)
          .start(
            readState: () =>
                container.read(readingControllerProvider('morning')),
            registerRepeat: () async => RepeatOutcome.counted,
          );

      final state = container.read(listenRepeatProvider('morning'));
      expect(state.phase, NarrationPhase.error);
      expect(state.errorMessage, contains('القراءة الصوتية مُطفأة'));
      expect(narration.spoken, isEmpty);
    });

    test('يعرض خطأً محترمًا عندما لا يوجد صوت عربي، بلا انهيار', () async {
      final narration = FakeNarrationService(
        availability: const NarrationAvailability.unavailable(
          NarrationUnavailableReason.arabicVoiceMissing,
        ),
      );
      final container = makeContainer(narration: narration);

      await container
          .read(listenRepeatProvider('morning').notifier)
          .start(
            readState: () =>
                container.read(readingControllerProvider('morning')),
            registerRepeat: () async => RepeatOutcome.counted,
          );

      final state = container.read(listenRepeatProvider('morning'));
      expect(state.phase, NarrationPhase.error);
      expect(state.errorMessage, contains('الصوت العربي غير متوفر'));
      expect(narration.spoken, isEmpty);
    });

    test('يقرأ الذكر ثم ينتظر الترديد في الوضع اليدوي', () async {
      final narration = FakeNarrationService();
      final container = makeContainer(narration: narration);
      final controller = container.read(
        listenRepeatProvider('morning').notifier,
      );

      // الوضع الافتراضي يدوي: تبقى الحالة "انتظار الترديد" حتى يضغط المستخدم.
      final running = controller.start(
        readState: () => container.read(readingControllerProvider('morning')),
        registerRepeat: () async => RepeatOutcome.counted,
      );
      await Future<void>.delayed(Duration.zero);

      expect(narration.spoken, <String>['test_001']);
      expect(
        container.read(listenRepeatProvider('morning')).phase,
        NarrationPhase.waitingForRepeat,
      );

      await controller.stop();
      await running;
      expect(
        container.read(listenRepeatProvider('morning')).phase,
        NarrationPhase.idle,
      );
    });

    test('الإيقاف يوقف الخدمة ويعيد الحالة إلى السكون', () async {
      final narration = FakeNarrationService();
      final container = makeContainer(narration: narration);
      final controller = container.read(
        listenRepeatProvider('morning').notifier,
      );

      final running = controller.start(
        readState: () => container.read(readingControllerProvider('morning')),
        registerRepeat: () async => RepeatOutcome.counted,
      );
      await Future<void>.delayed(Duration.zero);
      await controller.stop();
      await running;

      expect(narration.stopped, isTrue);
      expect(
        container.read(listenRepeatProvider('morning')).phase,
        NarrationPhase.idle,
      );
    });

    test('اكتمال الورد ينهي الدورة بحالة إكمال', () async {
      final container = makeContainer(narration: FakeNarrationService());
      final controller = container.read(
        listenRepeatProvider('morning').notifier,
      );

      final running = controller.start(
        readState: () => container.read(readingControllerProvider('morning')),
        registerRepeat: () async => RepeatOutcome.sessionCompleted,
      );
      // الوضع اليدوي: ننتظر ضغطة "انتهيت" من المستخدم.
      await Future<void>.delayed(Duration.zero);
      controller.confirmRepeatDone();
      await running;

      expect(
        container.read(listenRepeatProvider('morning')).phase,
        NarrationPhase.completed,
      );
    });

    test('لا ينتقل للذكر التالي إذا لم تُفعَّل متابعة الورد صوتيًا', () async {
      final narration = FakeNarrationService();
      final container = makeContainer(narration: narration);
      final controller = container.read(
        listenRepeatProvider('morning').notifier,
      );

      final running = controller.start(
        readState: () => container.read(readingControllerProvider('morning')),
        registerRepeat: () async => RepeatOutcome.dhikrCompleted,
      );
      await Future<void>.delayed(Duration.zero);
      controller.confirmRepeatDone();
      await running;

      expect(narration.spoken, hasLength(1));
      expect(
        container.read(listenRepeatProvider('morning')).phase,
        NarrationPhase.completed,
      );
    });
  });

  group('العدّ التنازلي للترديد', () {
    test('الوضع الزمني يعرض ثوانيَ متبقية ثم يكمل تلقائيًا', () {
      fakeAsync((async) {
        final container = makeContainer(
          settings: const AppSettings(
            repeatPauseMode: RepeatPauseMode.seconds3,
          ),
          narration: FakeNarrationService(),
        );
        final controller = container.read(
          listenRepeatProvider('morning').notifier,
        );

        var calls = 0;
        controller.start(
          readState: () => container.read(readingControllerProvider('morning')),
          registerRepeat: () async {
            calls += 1;
            return RepeatOutcome.sessionCompleted;
          },
        );

        async.elapse(const Duration(milliseconds: 10));
        final waiting = container.read(listenRepeatProvider('morning'));
        expect(waiting.phase, NarrationPhase.waitingForRepeat);
        expect(waiting.secondsRemaining, 3);

        async.elapse(const Duration(seconds: 1));
        expect(
          container.read(listenRepeatProvider('morning')).secondsRemaining,
          2,
        );

        async.elapse(const Duration(seconds: 3));
        expect(calls, 1);
        expect(
          container.read(listenRepeatProvider('morning')).phase,
          NarrationPhase.completed,
        );
      });
    });
  });

  group('سرعات القراءة', () {
    test('القيم المدعومة ضمن النطاق المعتمد', () {
      expect(SpeechRates.values, <double>[0.75, 0.9, 1.0, 1.1, 1.2]);
      expect(SpeechRates.min, 0.75);
      expect(SpeechRates.max, 1.2);
    });

    test('nearest يقرّب لأقرب سرعة مدعومة', () {
      expect(SpeechRates.nearest(0.8), 0.75);
      expect(SpeechRates.nearest(0.95), 0.9);
      expect(SpeechRates.nearest(1.05), 1.0);
      expect(SpeechRates.nearest(5), 1.2);
    });
  });

  group('أوضاع مدة الترديد', () {
    test('الوضع اليدوي بلا مدة، والباقي بمدد صحيحة', () {
      expect(RepeatPauseMode.manual.duration, isNull);
      expect(RepeatPauseMode.seconds3.duration, const Duration(seconds: 3));
      expect(RepeatPauseMode.seconds5.duration, const Duration(seconds: 5));
      expect(RepeatPauseMode.seconds8.duration, const Duration(seconds: 8));
    });
  });
}
