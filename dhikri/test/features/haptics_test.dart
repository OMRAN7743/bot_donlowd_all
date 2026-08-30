import 'package:dhikri/core/services/haptics_service.dart';
import 'package:dhikri/data/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// يسجّل كل نداء اهتزاز بدل تنفيذه، حتى نتحقق أنه لم يُستدعَ أصلًا.
class RecordingHaptics implements HapticsBackend {
  final List<String> calls = <String>[];

  @override
  Future<void> light() async => calls.add('light');

  @override
  Future<void> medium() async => calls.add('medium');

  @override
  Future<void> selection() async => calls.add('selection');
}

void main() {
  group('HapticsService', () {
    late RecordingHaptics backend;

    setUp(() => backend = RecordingHaptics());

    HapticsService serviceFor(AppSettings settings) =>
        HapticsService(() => settings, backend);

    test(
      'اهتزاز الإكمال يعمل عندما يكون المفتاح مُفعَّلًا (الافتراضي)',
      () async {
        await serviceFor(AppSettings.defaults).completion();
        expect(backend.calls, <String>['medium']);
      },
    );

    test(
      'لا يُستدعى النظام إطلاقًا عندما يكون اهتزاز الإكمال مُطفأً',
      () async {
        await serviceFor(const AppSettings(completionHaptics: false))
            .completion();
        expect(backend.calls, isEmpty);
      },
    );

    test('اهتزاز الضغطة مُطفأ افتراضيًا', () async {
      await serviceFor(AppSettings.defaults).counterTap();
      expect(backend.calls, isEmpty);
    });

    test('اهتزاز الضغطة يعمل عند تفعيله', () async {
      await serviceFor(const AppSettings(tapHaptics: true)).counterTap();
      expect(backend.calls, <String>['light']);
    });

    test('اهتزاز التسبيح مُطفأ افتراضيًا', () async {
      final service = serviceFor(AppSettings.defaults);
      await service.tasbihTap();
      await service.tasbihTargetReached();
      expect(backend.calls, isEmpty);
    });

    test('اهتزاز التسبيح يعمل عند تفعيله', () async {
      final service = serviceFor(const AppSettings(tasbihHaptics: true));
      await service.tasbihTap();
      await service.tasbihTargetReached();
      expect(backend.calls, <String>['selection', 'medium']);
    });

    test('كل مفتاح مستقل عن الآخر', () async {
      final service = serviceFor(
        const AppSettings(completionHaptics: false, tapHaptics: true),
      );
      await service.completion();
      await service.counterTap();
      expect(backend.calls, <String>['light']);
    });
  });
}
