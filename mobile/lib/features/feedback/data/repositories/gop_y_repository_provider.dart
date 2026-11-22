import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/gop_y_repository.dart';
import 'mock_gop_y_repository.dart';

final gopYRepositoryProvider = Provider<GopYRepository>((ref) {
  return MockGopYRepository();
});
