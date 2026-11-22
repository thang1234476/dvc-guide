abstract class FavoritesRepository {
  /// Get list of favorite procedure IDs
  Future<Set<int>> getFavoriteIds();

  /// Toggle favorite status of a procedure. Returns true if now favorite, false if unfavorited.
  Future<bool> toggle(int thuTucId);

  /// Check whether a procedure is favorited
  Future<bool> isFavorite(int thuTucId);

  /// Clear all favorites
  Future<void> clearAll();
}
