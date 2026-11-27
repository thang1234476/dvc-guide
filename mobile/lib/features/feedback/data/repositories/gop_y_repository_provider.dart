import 'package:dvc_guide_mobile/core/constants/app_constants.dart';
import 'package:dvc_guide_mobile/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/gop_y_repository.dart';
import 'api_gop_y_repository.dart';
import 'mock_gop_y_repository.dart';

final gopYRepositoryProvider = Provider<GopYRepository>((ref) {
  if (AppConstants.useMockFeedback) {
    return MockGopYRepository();
  }
  return ApiGopYRepository(dio: ref.watch(apiClientProvider));
});