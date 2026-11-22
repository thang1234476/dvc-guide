import 'package:dvc_guide_mobile/features/procedure/data/mock/procedure_mock_data.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/domain/repositories/my_cases_repository.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

String _generateUniqueCaseName(List<HoSoCuaToi> cases, String baseName) {
  final names = cases.map((c) => c.tenHoSo).toSet();
  if (!names.contains(baseName)) return baseName;
  int index = 2;
  while (names.contains('$baseName ($index)')) {
    index++;
  }
  return '$baseName ($index)';
}

class MockMyCasesRepository implements MyCasesRepository {
  final List<HoSoCuaToi> _cases = [
    HoSoCuaToi(
      id: 'case-001',
      tenHoSo: mockProcedureSummaries[0].ten,
      thuTuc: mockProcedureSummaries[0], // Đăng ký khai sinh
      truongHopId: 1,
      trangThai: TrangThaiHoSo.dangChuanBi,
      coQuanDuDinhId: 1,
      ngayNop: DateTime.now().subtract(const Duration(days: 1)),
      maHoSo: 'HSO-2026-000123',
      ngayHen: DateTime.now().add(const Duration(days: 2)), // Remaining 2 days
      ghiChu: 'Cần mang theo bản chính để đối chiếu',
      taoLuc: DateTime.now().subtract(const Duration(days: 2)),
      capNhatLuc: DateTime.now().subtract(const Duration(days: 1)),
      checklist: {
        1: TrangThaiGiayTo.daCo,   // Tờ khai đã có
        2: TrangThaiGiayTo.chuaCo, // Giấy chứng sinh chưa có
        4: TrangThaiGiayTo.chuaRo, // Chưa rõ (có đủ cả 3 trạng thái)
      },
    ),
    HoSoCuaToi(
      id: 'case-002',
      tenHoSo: mockProcedureSummaries[3].ten,
      thuTuc: mockProcedureSummaries[3], // Đăng ký thường trú
      truongHopId: 7,
      trangThai: TrangThaiHoSo.dangXuLy,
      coQuanDuDinhId: 2,
      coQuanThucTeId: 2,
      ngayNop: DateTime.now().subtract(const Duration(days: 10)),
      maHoSo: 'HSO-2026-009876',
      ngayHen: DateTime.now().subtract(const Duration(days: 3)), // Overdue 3 days
      ghiChu: 'Đã nộp trực tiếp tại Công an xã',
      taoLuc: DateTime.now().subtract(const Duration(days: 11)),
      capNhatLuc: DateTime.now().subtract(const Duration(days: 10)),
      checklist: {
        14: TrangThaiGiayTo.daCo,  // Mẫu CT01 đã có
        15: TrangThaiGiayTo.chuaCo, // Sổ hồng chưa có
      },
    ),
  ];

  @override
  Future<List<HoSoCuaToi>> getMyCases() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = List<HoSoCuaToi>.from(_cases);
    list.sort((a, b) {
      final dateA = a.capNhatLuc ?? a.taoLuc ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.capNhatLuc ?? b.taoLuc ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return list;
  }

  @override
  Future<HoSoCuaToi?> getCaseById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _cases.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<HoSoCuaToi>> getCasesByThuTuc(int thuTucId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _cases.where((c) => c.thuTuc.id == thuTucId).toList();
  }

  @override
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final baseName = (tenHoSo != null && tenHoSo.trim().isNotEmpty)
        ? tenHoSo.trim()
        : thuTuc.ten;
    final uniqueName = _generateUniqueCaseName(_cases, baseName);

    final resolvedDuDinhId = coQuanDuDinhId ?? coQuanId;
    final resolvedHen = ngayHen ?? hanTraKq;
    final now = DateTime.now();

    final newCase = HoSoCuaToi(
      id: 'case-${now.millisecondsSinceEpoch}',
      tenHoSo: uniqueName,
      thuTuc: thuTuc,
      truongHopId: truongHopId,
      trangThai: trangThai ?? TrangThaiHoSo.dangChuanBi,
      coQuanDuDinhId: resolvedDuDinhId,
      coQuanThucTeId: coQuanThucTeId,
      ngayNop: ngayNop,
      maHoSo: maHoSo,
      ngayHen: resolvedHen,
      ghiChu: ghiChu,
      taoLuc: now,
      capNhatLuc: now,
      checklist: const {},
    );

    _cases.insert(0, newCase);
    return newCase;
  }

  @override
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _cases.indexWhere((c) => c.id == id);
    if (index != -1) {
      final current = _cases[index];
      _cases[index] = current.copyWith(
        tenHoSo: tenHoSo ?? current.tenHoSo,
        trangThai: trangThai ?? current.trangThai,
        coQuanDuDinhId: clearDuDinh ? null : (coQuanDuDinhId ?? current.coQuanDuDinhId),
        coQuanThucTeId: clearThucTe ? null : (coQuanThucTeId ?? current.coQuanThucTeId),
        ngayNop: ngayNop ?? current.ngayNop,
        maHoSo: maHoSo ?? current.maHoSo,
        ngayHen: ngayHen ?? current.ngayHen,
        ghiChu: ghiChu ?? current.ghiChu,
        truongHopId: truongHopId ?? current.truongHopId,
        capNhatLuc: DateTime.now(),
      );
    }
  }

  @override
  Future<void> setGiayToStatus(String caseId, int thanhPhanId, TrangThaiGiayTo status) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final index = _cases.indexWhere((c) => c.id == caseId);
    if (index != -1) {
      final updatedChecklist = Map<int, TrangThaiGiayTo>.from(_cases[index].checklist);
      if (status == TrangThaiGiayTo.chuaRo) {
        updatedChecklist.remove(thanhPhanId);
      } else {
        updatedChecklist[thanhPhanId] = status;
      }
      _cases[index] = _cases[index].copyWith(
        checklist: updatedChecklist,
        capNhatLuc: DateTime.now(),
      );
    }
  }

  @override
  Future<void> toggleChecklist(String hoSoId, int thanhPhanId, bool isReady) async {
    await setGiayToStatus(
      hoSoId,
      thanhPhanId,
      isReady ? TrangThaiGiayTo.daCo : TrangThaiGiayTo.chuaRo,
    );
  }

  @override
  Future<void> updateDates(String hoSoId, {DateTime? ngayNop, DateTime? hanTraKq, DateTime? ngayHen}) async {
    await updateCase(hoSoId, ngayNop: ngayNop, ngayHen: ngayHen ?? hanTraKq);
  }

    @override
  Future<void> updateTruongHop(String hoSoId, int? truongHopId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _cases.indexWhere((c) => c.id == hoSoId);
    if (index != -1) {
      _cases[index] = _cases[index].copyWith(
        truongHopId: truongHopId,
        capNhatLuc: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateCoQuan(String hoSoId, int? coQuanId) async {
    await updateCase(hoSoId, coQuanDuDinhId: coQuanId);
  }

  @override
  Future<void> deleteCase(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _cases.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> restoreCase(HoSoCuaToi caseToRestore, int index) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final safeIndex = index.clamp(0, _cases.length);
    _cases.insert(safeIndex, caseToRestore);
  }

  @override
  Future<void> clearAll() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _cases.clear();
  }
}
