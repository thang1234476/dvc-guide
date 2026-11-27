import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/my_cases_repository_provider.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/viewmodels/my_cases_viewmodel.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/procedure_repository_provider.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

class MyCaseDetailState {
  final bool isLoading;
  final HoSoCuaToi? caseItem;
  final ThuTucDetail? procedure;
  final String? error;

  const MyCaseDetailState({
    this.isLoading = false,
    this.caseItem,
    this.procedure,
    this.error,
  });

  MyCaseDetailState copyWith({
    bool? isLoading,
    HoSoCuaToi? caseItem,
    ThuTucDetail? procedure,
    String? error,
  }) {
    return MyCaseDetailState(
      isLoading: isLoading ?? this.isLoading,
      caseItem: caseItem ?? this.caseItem,
      procedure: procedure ?? this.procedure,
      error: error,
    );
  }
}

class MyCaseDetailViewModel extends StateNotifier<MyCaseDetailState> {
  final Ref _ref;
  final String caseId;

  MyCaseDetailViewModel(this._ref, this.caseId)
      : super(const MyCaseDetailState(isLoading: true)) {
    loadCaseDetail();
  }

  Future<void> loadCaseDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final casesRepo = _ref.read(myCasesRepositoryProvider);
      final c = await casesRepo.getCaseById(caseId);

      if (c == null) {
        state = state.copyWith(isLoading: false, error: AppStrings.defaultErrorMessage);
        return;
      }

      final procRepo = _ref.read(procedureRepositoryProvider);
      final proc = await procRepo.getProcedureDetail(c.thuTuc.id);

      state = state.copyWith(
        isLoading: false,
        caseItem: c,
        procedure: proc,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleChecklist(int thanhPhanId, bool isReady) async {
    await setGiayToStatus(
      thanhPhanId,
      isReady ? TrangThaiGiayTo.daCo : TrangThaiGiayTo.chuaRo,
    );
  }

  Future<void> setGiayToStatus(int thanhPhanId, TrangThaiGiayTo status) async {
    if (state.caseItem == null) return;

    final updatedChecklist = Map<int, TrangThaiGiayTo>.from(state.caseItem!.checklist);
    if (status == TrangThaiGiayTo.chuaRo) {
      updatedChecklist.remove(thanhPhanId);
    } else {
      updatedChecklist[thanhPhanId] = status;
    }

    state = state.copyWith(
      caseItem: state.caseItem!.copyWith(checklist: updatedChecklist),
    );

    final repo = _ref.read(myCasesRepositoryProvider);
    await repo.setGiayToStatus(caseId, thanhPhanId, status);
    _ref.read(myCasesViewModelProvider.notifier).loadCases();
  }

  Future<void> updateStatus(TrangThaiHoSo status) async {
    if (state.caseItem == null) return;
    if (state.caseItem!.trangThai == status) return;

    state = state.copyWith(
      caseItem: state.caseItem!.copyWith(trangThai: status),
    );

    final repo = _ref.read(myCasesRepositoryProvider);
    await repo.updateCase(caseId, trangThai: status);
    _ref.read(myCasesViewModelProvider.notifier).loadCases();
  }

  Future<void> updateName(String name) async {
    if (state.caseItem == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 100) return;

    state = state.copyWith(
      caseItem: state.caseItem!.copyWith(tenHoSo: trimmed),
    );

    final repo = _ref.read(myCasesRepositoryProvider);
    await repo.updateCase(caseId, tenHoSo: trimmed);
    _ref.read(myCasesViewModelProvider.notifier).loadCases();
  }

  Future<void> selectTruongHop(int? truongHopId) async {
    if (state.caseItem == null) return;
    if (state.caseItem!.truongHopId == truongHopId) return;

    state = state.copyWith(
      caseItem: state.caseItem!.copyWith(truongHopId: truongHopId),
    );

    final repo = _ref.read(myCasesRepositoryProvider);
    await repo.updateTruongHop(caseId, truongHopId);
    _ref.read(myCasesViewModelProvider.notifier).loadCases();
  }

  Future<void> selectCoQuan(int? coQuanId) async {
    if (state.caseItem == null) return;

    state = state.copyWith(
      caseItem: state.caseItem!.copyWith(coQuanDuDinhId: coQuanId),
    );

    final repo = _ref.read(myCasesRepositoryProvider);
    await repo.updateCoQuan(caseId, coQuanId);
    _ref.read(myCasesViewModelProvider.notifier).loadCases();
  }

  Future<void> updateAgencies({
    int? coQuanDuDinhId,
    int? coQuanThucTeId,
    bool clearDuDinh = false,
    bool clearThucTe = false,
  }) async {
    if (state.caseItem == null) return;

    final newDuDinh = clearDuDinh ? null : (coQuanDuDinhId ?? state.caseItem!.coQuanDuDinhId);
    final newThucTe = clearThucTe ? null : (coQuanThucTeId ?? state.caseItem!.coQuanThucTeId);

    state = state.copyWith(
      caseItem: state.caseItem!.copyWith(
        coQuanDuDinhId: newDuDinh,
        coQuanThucTeId: newThucTe,
      ),
    );

    final repo = _ref.read(myCasesRepositoryProvider);
    await repo.updateCase(
      caseId,
      coQuanDuDinhId: newDuDinh,
      coQuanThucTeId: newThucTe,
    );
    _ref.read(myCasesViewModelProvider.notifier).loadCases();
  }

  Future<void> updateDates({DateTime? ngayNop, DateTime? ngayHen, DateTime? hanTraKq}) async {
    if (state.caseItem == null) return;

    final targetHen = ngayHen ?? hanTraKq;
    state = state.copyWith(
      caseItem: state.caseItem!.copyWith(
        ngayNop: ngayNop ?? state.caseItem!.ngayNop,
        ngayHen: targetHen ?? state.caseItem!.ngayHen,
      ),
    );

    final repo = _ref.read(myCasesRepositoryProvider);
    await repo.updateDates(caseId, ngayNop: ngayNop, ngayHen: targetHen);
    _ref.read(myCasesViewModelProvider.notifier).loadCases();
  }

  Future<void> updateDetails({
    String? maHoSo,
    String? ghiChu,
    DateTime? ngayNop,
    DateTime? ngayHen,
    bool clearNgayNop = false,
    bool clearNgayHen = false,
  }) async {
    if (state.caseItem == null) return;

    final targetNop = clearNgayNop ? null : (ngayNop ?? state.caseItem!.ngayNop);
    final targetHen = clearNgayHen ? null : (ngayHen ?? state.caseItem!.ngayHen);
    final targetMa = maHoSo ?? state.caseItem!.maHoSo;
    final targetGhiChu = ghiChu ?? state.caseItem!.ghiChu;

    state = state.copyWith(
      caseItem: state.caseItem!.copyWith(
        ngayNop: targetNop,
        ngayHen: targetHen,
        maHoSo: targetMa,
        ghiChu: targetGhiChu,
      ),
    );

    final repo = _ref.read(myCasesRepositoryProvider);
    await repo.updateCase(
      caseId,
      ngayNop: targetNop,
      ngayHen: targetHen,
      maHoSo: targetMa,
      ghiChu: targetGhiChu,
    );
    _ref.read(myCasesViewModelProvider.notifier).loadCases();
  }

  Future<void> deleteCase() async {
    final repo = _ref.read(myCasesRepositoryProvider);
    await repo.deleteCase(caseId);
    _ref.read(myCasesViewModelProvider.notifier).loadCases();
  }
}

final myCaseDetailViewModelProvider = StateNotifierProvider.autoDispose
    .family<MyCaseDetailViewModel, MyCaseDetailState, String>(
  (ref, caseId) {
    return MyCaseDetailViewModel(ref, caseId);
  },
);
