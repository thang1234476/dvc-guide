import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/procedure_repository.dart';
import 'api_procedure_repository.dart';
import 'mock_procedure_repository.dart';

/// Mặc định dùng dữ liệu thật từ server.
/// Muốn dùng dữ liệu giả: flutter run --dart-define=USE_MOCK_PROCEDURE=true
final procedureRepositoryProvider = Provider<ProcedureRepository>((ref) {
  if (AppConstants.useMockProcedure) {
    return MockProcedureRepository();
  }
  return ApiProcedureRepository(dio: ref.watch(apiClientProvider));
});