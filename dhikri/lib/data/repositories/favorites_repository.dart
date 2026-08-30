import '../../core/services/preferences_service.dart';

/// يخزّن معرّفات الأذكار المفضّلة فقط — لا نص ولا نسخ مكرّرة.
class FavoritesRepository {
  const FavoritesRepository(this._store);

  final KeyValueStore _store;

  Future<Set<String>> load() async {
    final ids = await _store.getStringList(PrefKeys.favoriteIds);
    if (ids == null) return <String>{};
    return ids.where((id) => id.trim().isNotEmpty).toSet();
  }

  Future<void> save(Set<String> ids) =>
      _store.setStringList(PrefKeys.favoriteIds, ids.toList(growable: false));

  Future<Set<String>> toggle(String dhikrId) async {
    final current = await load();
    final next = <String>{...current};
    if (!next.remove(dhikrId)) next.add(dhikrId);
    await save(next);
    return next;
  }

  Future<void> clear() => _store.remove(PrefKeys.favoriteIds);
}
