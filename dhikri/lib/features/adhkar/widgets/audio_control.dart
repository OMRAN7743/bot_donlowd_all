import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../narration_controller.dart';

/// زر "استمع وردد" مع عرض حالته الحالية.
///
/// لا يبدأ الصوت من تلقاء نفسه أبدًا — المستخدم هو من يضغط.
class AudioControl extends StatelessWidget {
  const AudioControl({
    super.key,
    required this.state,
    required this.audioEnabled,
    required this.onStart,
    required this.onStop,
    required this.onPauseResume,
    required this.onConfirmRepeat,
    required this.onOpenAudioSettings,
  });

  final ListenRepeatState state;
  final bool audioEnabled;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPauseResume;
  final VoidCallback onConfirmRepeat;
  final VoidCallback onOpenAudioSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);

    if (state.phase == NarrationPhase.error) {
      return _AudioNotice(
        message: state.errorMessage ?? 'تعذّر تشغيل الصوت.',
        actionLabel: 'إعدادات الصوت',
        onAction: onOpenAudioSettings,
        onDismiss: onStop,
      );
    }

    if (state.phase == NarrationPhase.waitingForRepeat) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: <Widget>[
            Text(
              'ردّد الآن',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (state.secondsRemaining != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                '${ArabicNumbers.format(state.secondsRemaining!)} ثانية',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirmRepeat,
                    style: FilledButton.styleFrom(
                      minimumSize: Size(0, tokens.primaryButtonHeight - 8),
                    ),
                    child: const Text('انتهيت'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(onPressed: onStop, child: const Text('إيقاف')),
              ],
            ),
          ],
        ),
      );
    }

    if (state.isBusy || state.isPaused) {
      final label = switch (state.phase) {
        NarrationPhase.preparing => 'جارٍ التحضير…',
        NarrationPhase.speaking => 'يقرأ الآن',
        NarrationPhase.paused => 'متوقّف مؤقتًا',
        _ => 'الاستماع',
      };

      return Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                if (state.phase == NarrationPhase.preparing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    state.isPaused
                        ? Icons.pause_circle_outline_rounded
                        : Icons.graphic_eq_rounded,
                    color: theme.colorScheme.primary,
                  ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (state.phase == NarrationPhase.speaking || state.isPaused)
            IconButton(
              onPressed: onPauseResume,
              tooltip: state.isPaused ? 'متابعة' : 'إيقاف مؤقت',
              icon: Icon(
                state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              ),
            ),
          IconButton(
            onPressed: onStop,
            tooltip: 'إيقاف',
            icon: const Icon(Icons.stop_rounded),
          ),
        ],
      );
    }

    // حالة السكون: الزر الأساسي.
    return OutlinedButton.icon(
      onPressed: audioEnabled ? onStart : onOpenAudioSettings,
      icon: const Icon(Icons.headset_mic_outlined),
      label: Text(audioEnabled ? 'استمع وردّد' : 'تشغيل القراءة الصوتية'),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, tokens.primaryButtonHeight - 4),
      ),
    );
  }
}

/// رسالة صوتية محترمة بدل الانهيار عندما لا يتوفّر صوت عربي.
class _AudioNotice extends StatelessWidget {
  const _AudioNotice({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onDismiss,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.volume_off_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
            ],
          ),
          const SizedBox(height: 8),
          // Wrap وليس Row: نصوص الأزرار تطول مع تكبير الخط فتنتقل لسطر جديد
          // بدل أن تتجاوز عرض البطاقة.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              TextButton(onPressed: onAction, child: Text(actionLabel)),
              TextButton(onPressed: onDismiss, child: const Text('حسنًا')),
            ],
          ),
        ],
      ),
    );
  }
}
