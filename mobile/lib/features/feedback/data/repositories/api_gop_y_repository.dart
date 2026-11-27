import 'package:dio/dio.dart';
import 'package:dvc_guide_mobile/core/constants/app_constants.dart';
import 'package:dvc_guide_mobile/core/error/app_exception.dart';
import 'package:dvc_guide_mobile/core/network/api_endpoints.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

import '../../domain/repositories/gop_y_repository.dart';

/// Bản thật của [GopYRepository]. Backend cho phép gửi ẩn danh (không cần đăng nhập).
class ApiGopYRepository implements GopYRepository {
  ApiGopYRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<void> submit({
    required LoaiGopY loai,
    required String noiDung,
    int? coQuanId,
    int? thuTucId,
  }) async {
    // Dữ liệu thủ tục/cơ quan giả có id không tồn tại trên server,
    // gửi kèm sẽ vi phạm khóa ngoại, nên bỏ đi khi đang dùng mock.
    final sendIds = !AppConstants.useMockProcedure;

    try {
      await _dio.post(ApiEndpoints.feedback, data: {
        'type': loai.toJson(),
        'content': noiDung.trim(),
        if (sendIds && coQuanId != null) 'agencyId': coQuanId,
        if (sendIds && thuTucId != null) 'procedureId': thuTucId,
      });
    } on DioException catch (e) {
      final inner = e.error;
      if (inner is AppException) throw inner;
      rethrow;
    }
  }
}