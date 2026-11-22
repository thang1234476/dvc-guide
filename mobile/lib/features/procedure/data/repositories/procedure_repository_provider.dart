import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/procedure_repository.dart';
import 'mock_procedure_repository.dart';

/// Provider for ProcedureRepository.
/// Defaults to [MockProcedureRepository]. Can be overridden with Dio repository in tests or production.
final procedureRepositoryProvider = Provider<ProcedureRepository>((ref) {
  return MockProcedureRepository();
});
