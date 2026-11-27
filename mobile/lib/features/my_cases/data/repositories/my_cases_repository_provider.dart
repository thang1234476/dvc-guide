import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dvc_guide_mobile/core/network/api_client.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/auth_controller.dart';
import '../../domain/repositories/my_cases_repository.dart';
import 'api_my_cases_repository.dart';

final myCasesRepositoryProvider = Provider<MyCasesRepository>((ref) {
  // Đổi tài khoản thì tạo repo mới.
  ref.watch(authControllerProvider.select((s) => s.user?.id));
  return ApiMyCasesRepository(ref.watch(apiClientProvider));
});