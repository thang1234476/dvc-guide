import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/favorites_repository.dart';

/// SharedPreferences implementation of [FavoritesRepository]
/// Corresponds to schema table `thu_tuc_yeu_thich`.
class SharedPrefFavoritesRepository implements FavoritesRepository {
  SharedPrefFavoritesRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _kStorageKey = 'favorite_procedure_ids_v1';

  @override
  Future<Set<int>> getFavoriteIds() async {
    final list = _prefs.getStringList(_kStorageKey);
    if (list == null) return {};
    return list.map((s) => int.tryParse(s)).whereType<int>().toSet();
  }

  @override
  Future<bool> toggle(int thuTucId) async {
    final current = await getFavoriteIds();
    final isFav = current.contains(thuTucId);
    if (isFav) {
      current.remove(thuTucId);
    } else {
      current.add(thuTucId);
    }
    await _prefs.setStringList(
      _kStorageKey,
      current.map((id) => id.toString()).toList(),
    );
    return !isFav;
  }

  @override
  Future<bool> isFavorite(int thuTucId) async {
    final current = await getFavoriteIds();
    return current.contains(thuTucId);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(_kStorageKey);
  }
}
