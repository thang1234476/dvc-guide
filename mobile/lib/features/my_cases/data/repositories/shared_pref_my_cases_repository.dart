import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
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

/// Persistent implementation of [MyCasesRepository] backed by [SharedPreferences].
class SharedPrefMyCasesRepository implements MyCasesRepository {
  SharedPrefMyCasesRepository(this._prefs) {
    _ensureSeeded();
  }

  final SharedPreferences _prefs;
  static const String _kStorageKey = 'my_cases_v1';

  // ── Seed data ──────────────────────────────────────────────────────────────

  void _ensureSeeded() {
    if (_prefs.containsKey(_kStorageKey)) return;
    final now = DateTime.now();
    final seedCases = [
      HoSoCuaToi(
        id: 'case-001',
        tenHoSo: mockProcedureSummaries[0].ten,
        thuTuc: mockProcedureSummaries[0], // Đăng ký khai sinh
        truongHopId: 1,
        trangThai: TrangThaiHoSo.dangChuanBi,
        coQuanDuDinhId: 1,
        ngayNop: now.subtract(const Duration(days: 1)),
        maHoSo: 'HSO-2026-000123',
        ngayHen: now.add(const Duration(days: 2)),
        ghiChu: 'Cần mang theo bản chính để đối chiếu',
        taoLuc: now.subtract(const Duration(days: 2)),
        capNhatLuc: now.subtract(const Duration(days: 1)),
        checklist: {
          1: TrangThaiGiayTo.daCo,
          2: TrangThaiGiayTo.chuaCo,
          4: TrangThaiGiayTo.chuaRo,
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
        ngayNop: now.subtract(const Duration(days: 10)),
        maHoSo: 'HSO-2026-009876',
        ngayHen: now.subtract(const Duration(days: 3)),
        ghiChu: 'Đã nộp trực tiếp tại Công an xã',
        taoLuc: now.subtract(const Duration(days: 11)),
        capNhatLuc: now.subtract(const Duration(days: 10)),
        checklist: {
          14: TrangThaiGiayTo.daCo,
          15: TrangThaiGiayTo.chuaCo,
        },
      ),
    ];
    _save(seedCases);
  }

  // ── Serialization helpers ──────────────────────────────────────────────────

  List<HoSoCuaToi> _load() {
    final raw = _prefs.getString(_kStorageKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((j) => HoSoCuaToi.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _save(List<HoSoCuaToi> cases) {
    _prefs.setString(
      _kStorageKey,
      jsonEncode(cases.map((c) => c.toJson()).toList()),
    );
  }

  // ── MyCasesRepository implementation ──────────────────────────────────────

  @override
  Future<List<HoSoCuaToi>> getMyCases() async {
    final cases = _load();
    cases.sort((a, b) {
      final dateA = a.capNhatLuc ?? a.taoLuc ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.capNhatLuc ?? b.taoLuc ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return cases;
  }

  @override
  Future<HoSoCuaToi?> getCaseById(String id) async {
    try {
      return _load().firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<HoSoCuaToi>> getCasesByThuTuc(int thuTucId) async {
    return _load().where((c) => c.thuTuc.id == thuTucId).toList();
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
    final cases = _load();

    final baseName = (tenHoSo != null && tenHoSo.trim().isNotEmpty)
        ? tenHoSo.trim()
        : thuTuc.ten;
    final uniqueName = _generateUniqueCaseName(cases, baseName);

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

    cases.insert(0, newCase);
    _save(cases);
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
    final cases = _load();
    final index = cases.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final current = cases[index];
    cases[index] = current.copyWith(
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
    _save(cases);
  }

  @override
  Future<void> setGiayToStatus(
    String caseId,
    int thanhPhanId,
    TrangThaiGiayTo status,
  ) async {
    final cases = _load();
    final index = cases.indexWhere((c) => c.id == caseId);
    if (index == -1) return;
    final updated = Map<int, TrangThaiGiayTo>.from(cases[index].checklist);
    if (status == TrangThaiGiayTo.chuaRo) {
      updated.remove(thanhPhanId);
    } else {
      updated[thanhPhanId] = status;
    }
    cases[index] = cases[index].copyWith(
      checklist: updated,
      capNhatLuc: DateTime.now(),
    );
    _save(cases);
  }

  @override
  Future<void> toggleChecklist(
    String hoSoId,
    int thanhPhanId,
    bool isReady,
  ) async {
    await setGiayToStatus(
      hoSoId,
      thanhPhanId,
      isReady ? TrangThaiGiayTo.daCo : TrangThaiGiayTo.chuaRo,
    );
  }

  @override
  Future<void> updateDates(
    String hoSoId, {
    DateTime? ngayNop,
    DateTime? hanTraKq,
    DateTime? ngayHen,
  }) async {
    await updateCase(hoSoId, ngayNop: ngayNop, ngayHen: ngayHen ?? hanTraKq);
  }

  @override
  Future<void> updateTruongHop(String hoSoId, int? truongHopId) async {
    await updateCase(hoSoId, truongHopId: truongHopId);
  }

  @override
  Future<void> updateCoQuan(String hoSoId, int? coQuanId) async {
    await updateCase(hoSoId, coQuanDuDinhId: coQuanId);
  }

  @override
  Future<void> deleteCase(String id) async {
    final cases = _load();
    cases.removeWhere((c) => c.id == id);
    _save(cases);
  }

  @override
  Future<void> restoreCase(HoSoCuaToi caseToRestore, int index) async {
    final cases = _load();
    final safeIndex = index.clamp(0, cases.length);
    cases.insert(safeIndex, caseToRestore);
    _save(cases);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(_kStorageKey);
  }
}
