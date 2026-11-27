import 'package:dvc_guide_mobile/core/constants/app_constants.dart';
import 'package:dvc_guide_mobile/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../presentation/viewmodels/token_storage_provider.dart';
import 'api_auth_repository.dart';
import 'mock_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  if (AppConstants.useMockAuth) {
    return MockAuthRepository(tokenStorage: tokenStorage);
  }

  return ApiAuthRepository(
    dio: ref.watch(apiClientProvider),
    tokenStorage: tokenStorage,
  );
});