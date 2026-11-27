import 'package:dio/dio.dart';
import '../../domain/repositories/favorites_repository.dart';

/// Yêu thích lưu trên server (bảng thu_tuc_yeu_thich).
///  - Danh sách: GET /api/v1/procedures?savedOnly=true
///  - Lưu:       PUT /api/v1/users/me/favorites/{id}   (204, không body)
///  - Bỏ lưu:    DELETE /api/v1/users/me/favorites/{id} (204, không body)
class ApiFavoritesRepository implements FavoritesRepository {
  ApiFavoritesRepository(this._dio);

  final Dio _dio;
  Set<int>? _cache;

  static const _procedures = '/api/v1/procedures';
  static String _favorite(int id) => '/api/v1/users/me/favorites/$id';

  @override
  Future<Set<int>> getFavoriteIds() async {
    final ids = <int>{};
    var page = 0;
    var totalPages = 1;
    while (page < totalPages) {
      final res = await _dio.get(
        _procedures,
        queryParameters: {'savedOnly': true, 'page': page, 'size': 100},
      );
      final data = (res.data as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      for (final item in (data['items'] as List)) {
        final id = (item as Map<String, dynamic>)['id'];
        if (id is int) ids.add(id);
      }
      totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      page++;
    }
    _cache = ids;
    return Set<int>.from(ids);
  }

  @override
  Future<bool> toggle(int thuTucId) async {
    final current = _cache ?? await getFavoriteIds();
    final isFav = current.contains(thuTucId);
    if (isFav) {
      await _dio.delete(_favorite(thuTucId));
      current.remove(thuTucId);
    } else {
      await _dio.put(_favorite(thuTucId));
      current.add(thuTucId);
    }
    _cache = current;
    return !isFav;
  }

  @override
  Future<bool> isFavorite(int thuTucId) async {
    final current = _cache ?? await getFavoriteIds();
    return current.contains(thuTucId);
  }

  /// Chỉ bỏ từng mục yêu thích. Không gọi DELETE /users/me/data vì lệnh đó
  /// xóa cả hồ sơ và lịch sử chat của tài khoản.
  @override
  Future<void> clearAll() async {
    final ids = await getFavoriteIds();
    for (final id in ids) {
      await _dio.delete(_favorite(id));
    }
    _cache = {};
  }
}