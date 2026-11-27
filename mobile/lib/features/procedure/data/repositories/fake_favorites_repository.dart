import '../../domain/repositories/favorites_repository.dart';

/// In-memory fake implementation of [FavoritesRepository] for tests and previews.
class FakeFavoritesRepository implements FavoritesRepository {
  final Set<int> _favorites = {};

  FakeFavoritesRepository([Set<int>? initial]) {
    if (initial != null) {
      _favorites.addAll(initial);
    }
  }

  @override
  Future<Set<int>> getFavoriteIds() async {
    return Set.from(_favorites);
  }

  @override
  Future<bool> toggle(int thuTucId) async {
    if (_favorites.contains(thuTucId)) {
      _favorites.remove(thuTucId);
      return false;
    } else {
      _favorites.add(thuTucId);
      return true;
    }
  }

  @override
  Future<bool> isFavorite(int thuTucId) async {
    return _favorites.contains(thuTucId);
  }

  @override
  Future<void> clearAll() async {
    _favorites.clear();
  }
}
