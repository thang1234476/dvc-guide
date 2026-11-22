import 'package:dvc_guide_mobile/core/utils/vietnamese_utils.dart';
import '../../domain/repositories/procedure_repository.dart';
import '../mock/procedure_mock_data.dart';
import '../models/procedure_models.dart';

class MockProcedureRepository implements ProcedureRepository {
  @override
  Future<List<LinhVuc>> getLinhVucList() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return mockLinhVucList;
  }

  @override
  Future<List<ThuTucSummary>> getProcedures({
    String? query,
    int? linhVucId,
    List<int>? linhVucIds,
    List<int>? onlyIds,
    int page = 1,
    int pageSize = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    Iterable<ThuTucDetail> filtered = mockProcedureDetails;

    if (onlyIds != null) {
      filtered = filtered.where((p) => onlyIds.contains(p.id));
    }

    final targetLinhVucIds = linhVucIds ?? (linhVucId != null ? [linhVucId] : null);
    if (targetLinhVucIds != null && targetLinhVucIds.isNotEmpty) {
      filtered = filtered.where(
        (p) => p.linhVuc.any((lv) => targetLinhVucIds.contains(lv.id)),
      );
    }

    if (query != null && query.trim().isNotEmpty) {
      final qSearch = VietnameseUtils.toSearchable(query);
      filtered = filtered.where(
        (p) =>
            VietnameseUtils.toSearchable(p.ten).contains(qSearch) ||
            VietnameseUtils.toSearchable(p.maThuTuc).contains(qSearch) ||
            p.linhVuc.any((lv) => VietnameseUtils.toSearchable(lv.ten).contains(qSearch)),
      );
    }

    final startIndex = (page - 1) * pageSize;
    if (startIndex >= filtered.length) {
      return [];
    }

    final pageItems = filtered.skip(startIndex).take(pageSize);
    return pageItems.map(toSummary).toList();
  }

  @override
  Future<ThuTucDetail> getProcedureDetail(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final item = mockProcedureDetails.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Không tìm thấy thủ tục với id $id'),
    );
    return item;
  }

  @override
  Future<ThuTucDetail?> getProcedureByMa(String maThuTuc) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return mockProcedureDetails.firstWhere(
        (p) => p.maThuTuc.trim() == maThuTuc.trim(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CoQuan>> getCoQuanTiepNhan({
    required int thuTucId,
    required int diaPhuongId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final proc = mockProcedureDetails.firstWhere(
      (p) => p.id == thuTucId,
      orElse: () => throw Exception('Không tìm thấy thủ tục với id $thuTucId'),
    );

    final agencies = mockCoQuanList.where((cq) {
      if (cq.diaPhuongId != diaPhuongId) return false;
      if (proc.capThucHien != null && cq.cap != proc.capThucHien) return false;
      return true;
    }).toList();

    // Cơ quan đã kiểm chứng xếp trước. Ghi chú: sau này ứng với GET /api/v1/co-quan
    agencies.sort((a, b) {
      if (a.daKiemChung == b.daKiemChung) return 0;
      return a.daKiemChung ? -1 : 1;
    });

    return agencies;
  }
}
