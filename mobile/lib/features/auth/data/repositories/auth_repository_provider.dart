import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
   import 'package:dvc_guide_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import '../../presentation/viewmodels/token_storage_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return MockAuthRepository(tokenStorage: tokenStorage);
});
