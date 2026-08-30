import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/services/preferences_service.dart';

/// أهداف العدّ الجاهزة. `null` تعني عدًّا مفتوحًا بلا سقف.
enum TasbihTarget {
  thirtyThree(33, '٣٣'),
  hundred(100, '١٠٠'),
  open(null, 'مفتوح');

  const TasbihTarget(this.value, this.label);

  final int? value;
  final String label;

  static TasbihTarget fromValue(int? value) {
    for (final target in TasbihTarget.values) {
      if (target.value == value) return target;
    }
    return TasbihTarget.open;
  }
}

/// عبارات التسبيح المعروفة التي يختار منها المستخدم.
///
/// هذه عبارات ذكر مشهورة، ولا نُرفق بها أي فضل عددي أو ادعاء ثواب محدد.
enum TasbihPhrase {
  subhanAllah('سبحان الله'),
  alhamdulillah('الحمد لله'),
  allahuAkbar('الله أكبر'),
  tahlil('لا إله إلا الله'),
  free('عدّاد حر');

  const TasbihPhrase(this.label);

  final String label;
}

/// حالة عدّاد التسبيح.
@immutable
class TasbihState {
  const TasbihState({
    required this.count,
    required this.target,
    required this.phrase,
  });

  final int count;
  final TasbihTarget target;
  final TasbihPhrase phrase;

  bool get hasTarget => target.value != null;

  bool get isTargetReached => hasTarget && count >= target.value!;

  double get ratio {
    final goal = target.value;
    if (goal == null || goal <= 0) return 0;
    return (count / goal).clamp(0.0, 1.0);
  }

  TasbihState copyWith({
    int? count,
    TasbihTarget? target,
    TasbihPhrase? phrase,
  }) => TasbihState(
    count: count ?? this.count,
    target: target ?? this.target,
    phrase: phrase ?? this.phrase,
  );
}

/// عدّاد التسبيح: بسيط، هادئ، ويحفظ حالته بين الجلسات.
class TasbihController extends Notifier<TasbihState> {
  @override
  TasbihState build() {
    // القيم الأولية تأتي من التخزين بعد الإقلاع مباشرة عبر [hydrate].
    return const TasbihState(
      count: 0,
      target: TasbihTarget.thirtyThree,
      phrase: TasbihPhrase.subhanAllah,
    );
  }

  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  /// يقرأ آخر حالة محفوظة. يُستدعى مرة عند فتح الشاشة.
  Future<void> hydrate() async {
    final count = await _store.getInt(PrefKeys.tasbihCount) ?? 0;
    final target = await _store.getInt(PrefKeys.tasbihTarget);
    final phraseIndex = await _store.getInt(PrefKeys.tasbihPhraseIndex) ?? 0;

    state = TasbihState(
      count: count < 0 ? 0 : count,
      target: TasbihTarget.fromValue(target),
      phrase: phraseIndex >= 0 && phraseIndex < TasbihPhrase.values.length
          ? TasbihPhrase.values[phraseIndex]
          : TasbihPhrase.subhanAllah,
    );
  }

  /// يزيد العدّاد. يُعيد `true` عند بلوغ الهدف في هذه الضغطة بالذات.
  Future<bool> increment() async {
    if (state.isTargetReached) return false;

    final next = state.count + 1;
    state = state.copyWith(count: next);
    await _store.setInt(PrefKeys.tasbihCount, next);
    return state.isTargetReached;
  }

  Future<void> reset() async {
    state = state.copyWith(count: 0);
    await _store.setInt(PrefKeys.tasbihCount, 0);
  }

  Future<void> setTarget(TasbihTarget target) async {
    state = state.copyWith(target: target, count: 0);
    await _store.setInt(PrefKeys.tasbihCount, 0);
    if (target.value == null) {
      await _store.remove(PrefKeys.tasbihTarget);
    } else {
      await _store.setInt(PrefKeys.tasbihTarget, target.value!);
    }
  }

  Future<void> setPhrase(TasbihPhrase phrase) async {
    state = state.copyWith(phrase: phrase);
    await _store.setInt(PrefKeys.tasbihPhraseIndex, phrase.index);
  }
}

final tasbihProvider = NotifierProvider<TasbihController, TasbihState>(
  TasbihController.new,
);
