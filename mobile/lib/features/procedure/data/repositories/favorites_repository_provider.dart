import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/viewmodels/auth_controller.dart';
import '../../domain/repositories/favorites_repository.dart';
import 'api_favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  // Đổi tài khoản thì tạo repo mới, không dùng lại cache của người trước.
  ref.watch(authControllerProvider.select((s) => s.user?.id));
  return ApiFavoritesRepository(ref.watch(apiClientProvider));
});