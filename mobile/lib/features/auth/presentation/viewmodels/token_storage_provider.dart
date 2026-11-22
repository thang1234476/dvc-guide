import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:dvc_guide_mobile/features/auth/data/datasources/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});
