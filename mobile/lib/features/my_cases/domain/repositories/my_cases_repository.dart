import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

abstract class MyCasesRepository {
  /// Get all tracked cases
  Future<List<HoSoCuaToi>> getMyCases();

  /// Get case details by ID
  Future<HoSoCuaToi?> getCaseById(String id);

  /// Get all cases by procedure ID
  Future<List<HoSoCuaToi>> getCasesByThuTuc(int thuTucId);

  /// Add a procedure to tracked cases (allows multiple cases for the same procedure)
  Future<HoSoCuaToi> addCase({
    required ThuTucSummary thuTuc,
    String? tenHoSo,
    int? truongHopId,
    int? coQuanDuDinhId,
    int? coQuanThucTeId,
    int? coQuanId,
    DateTime? ngayNop,
    String? maHoSo,
    DateTime? ngayHen,
    DateTime? hanTraKq,
    String? ghiChu,
    TrangThaiHoSo? trangThai,
    List<int>? allThanhPhanIds,
  });

  /// Update case fields
  Future<void> updateCase(
    String id, {
    String? tenHoSo,
    TrangThaiHoSo? trangThai,
    int? coQuanDuDinhId,
    int? coQuanThucTeId,
    bool clearDuDinh = false,
    bool clearThucTe = false,
    DateTime? ngayNop,
    String? maHoSo,
    DateTime? ngayHen,
    String? ghiChu,
    int? truongHopId,
  });

  /// Set status for a paper in checklist
  Future<void> setGiayToStatus(String caseId, int thanhPhanId, TrangThaiGiayTo status);

  /// Toggle checklist item state (backward compatibility)
  Future<void> toggleChecklist(String hoSoId, int thanhPhanId, bool isReady);

  /// Update case dates (submission date, expected return date)
  Future<void> updateDates(String hoSoId, {DateTime? ngayNop, DateTime? hanTraKq, DateTime? ngayHen});

  /// Update case selected truong hop (maintaining existing tick states)
  Future<void> updateTruongHop(String hoSoId, int? truongHopId);

  /// Update case selected agency
  Future<void> updateCoQuan(String hoSoId, int? coQuanId);

  /// Delete a case from tracking
  Future<void> deleteCase(String id);

  /// Restore previously deleted case (e.g. for Undo)
  Future<void> restoreCase(HoSoCuaToi caseToRestore, int index);

  /// Clear all tracked cases
  Future<void> clearAll();
}
