import '../../data/models/procedure_models.dart';

abstract class ProcedureRepository {
  /// Fetch all administrative fields / categories
  Future<List<LinhVuc>> getLinhVucList();

  /// Search and filter procedures with pagination
  Future<List<ThuTucSummary>> getProcedures({
    String? query,
    int? linhVucId,
    List<int>? linhVucIds,
    List<int>? onlyIds,
    int page = 1,
    int pageSize = 10,
  });

  /// Get procedure details by procedure ID
  Future<ThuTucDetail> getProcedureDetail(int id);

  /// Get procedure details by procedure code (ma_thu_tuc)
  Future<ThuTucDetail?> getProcedureByMa(String maThuTuc);

  /// Lấy danh sách cơ quan tiếp nhận hồ sơ theo thủ tục và địa phương
  /// Cơ quan thuộc địa phương đó có cấp trùng capThucHien của thủ tục (capThucHien null thì lấy mọi cấp);
  /// Cơ quan đã kiểm chứng xếp trước.
  /// Ghi chú: sau này ứng với GET /api/v1/co-quan.
  Future<List<CoQuan>> getCoQuanTiepNhan({
    required int thuTucId,
    required int diaPhuongId,
  });
}
