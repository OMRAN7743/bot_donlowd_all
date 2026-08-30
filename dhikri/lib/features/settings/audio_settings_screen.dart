import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/narration/narration_service.dart';
import '../../data/models/app_settings.dart';
import '../adhkar/narration_controller.dart';
import 'widgets/setting_tiles.dart';

/// إعدادات الصوت (المواصفات §22-C).
class AudioSettingsScreen extends ConsumerWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = DhikriTokens.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final availability = ref.watch(narrationAvailabilityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('القراءة الصوتية')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.pagePadding,
          0,
          tokens.pagePadding,
          32,
        ),
        children: <Widget>[
          _AvailabilityNotice(availability: availability),
          SettingSection(
            title: 'التشغيل',
            children: <Widget>[
              SettingSwitchTile(
                title: 'القراءة الصوتية',
                subtitle: 'تشغيل زر "استمع وردّد" في شاشة الذكر',
                icon: Icons.headset_mic_outlined,
                value: settings.audioEnabled,
                onChanged: controller.setAudioEnabled,
              ),
              SettingSwitchTile(
                title: 'متابعة الورد صوتيًا',
                subtitle: 'ينتقل تلقائيًا إلى الذكر التالي بعد إكماله',
                icon: Icons.playlist_play_rounded,
                value: settings.continueSessionAudio,
                onChanged: controller.setContinueSessionAudio,
              ),
            ],
          ),
          SettingSection(
            title: 'سرعة القراءة',
            children: <Widget>[
              SettingChoiceTile<double>(
                title: 'السرعة',
                subtitle: 'اختر ما يناسب سمعك',
                options: SpeechRates.values,
                selected: SpeechRates.nearest(settings.speechRate),
                labelOf: SpeechRates.label,
                onSelected: controller.setSpeechRate,
              ),
            ],
          ),
          SettingSection(
            title: 'مدة الترديد',
            footnote: 'في الوضع اليدوي ينتظرك التطبيق حتى تضغط "انتهيت" بعد كل قراءة.',
            children: <Widget>[
              SettingChoiceTile<RepeatPauseMode>(
                title: 'كم ننتظرك لتردّد؟',
                options: RepeatPauseMode.values,
                selected: settings.repeatPauseMode,
                labelOf: (mode) => mode.label,
                onSelected: controller.setRepeatPauseMode,
              ),
            ],
          ),
          _VoicePickerSection(settings: settings),
        ],
      ),
    );
  }
}

/// يشرح سبب عدم توفّر الصوت بلغة بسيطة، بلا مصطلحات تقنية.
class _AvailabilityNotice extends StatelessWidget {
  const _AvailabilityNotice({required this.availability});

  final AsyncValue<NarrationAvailability> availability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return availability.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (value) {
        if (value.isAvailable) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(value.message, style: theme.textTheme.bodySmall),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// اختيار الصوت العربي — يظهر فقط عند وجود أكثر من صوت.
class _VoicePickerSection extends ConsumerWidget {
  const _VoicePickerSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voices = ref.watch(arabicVoicesProvider);

    return voices.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (list) {
        if (list.length < 2) return const SizedBox.shrink();
        final controller = ref.read(settingsProvider.notifier);

        return SettingSection(
          title: 'اختيار الصوت',
          footnote: 'تُعرض الأصوات العربية المثبَّتة على جهازك فقط.',
          children: <Widget>[
            RadioGroup<String?>(
              groupValue: settings.preferredVoiceId,
              onChanged: controller.setPreferredVoice,
              child: Column(
                children: <Widget>[
                  const RadioListTile<String?>(
                    value: null,
                    title: Text('الصوت الافتراضي في الجهاز'),
                  ),
                  for (final voice in list)
                    RadioListTile<String?>(
                      value: voice.id,
                      title: Text(voice.name),
                      subtitle: Text(voice.locale),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
