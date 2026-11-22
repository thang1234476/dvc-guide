import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/procedure_repository_provider.dart';

class ProcedureDetailState {
  final bool isLoading;
  final ThuTucDetail? procedure;
  final int? selectedTruongHopId;
  final HinhThucBuoc selectedHinhThucBuoc;
  final String? error;

  const ProcedureDetailState({
    this.isLoading = false,
    this.procedure,
    this.selectedTruongHopId,
    this.selectedHinhThucBuoc = HinhThucBuoc.chung,
    this.error,
  });

  ProcedureDetailState copyWith({
    bool? isLoading,
    ThuTucDetail? procedure,
    int? selectedTruongHopId,
    bool clearTruongHop = false,
    HinhThucBuoc? selectedHinhThucBuoc,
    String? error,
  }) {
    return ProcedureDetailState(
      isLoading: isLoading ?? this.isLoading,
      procedure: procedure ?? this.procedure,
      selectedTruongHopId: clearTruongHop
          ? null
          : (selectedTruongHopId ?? this.selectedTruongHopId),
      selectedHinhThucBuoc:
          selectedHinhThucBuoc ?? this.selectedHinhThucBuoc,
      error: error,
    );
  }
}

class ProcedureDetailViewModel extends StateNotifier<ProcedureDetailState> {
  final Ref _ref;
  final int procedureId;

  ProcedureDetailViewModel(this._ref, this.procedureId)
      : super(const ProcedureDetailState(isLoading: true)) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(procedureRepositoryProvider);
      final detail = await repo.getProcedureDetail(procedureId);

      // Determine default step execution method
      final availableStepMethods = detail.buocThucHien
          .map((b) => b.hinhThuc)
          .toSet();
      final defaultMethod = availableStepMethods.contains(HinhThucBuoc.chung)
          ? HinhThucBuoc.chung
          : (availableStepMethods.isNotEmpty
              ? availableStepMethods.first
              : HinhThucBuoc.chung);

      state = state.copyWith(
        isLoading: false,
        procedure: detail,
        selectedHinhThucBuoc: defaultMethod,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setInitialTruongHopId(int? id) {
    if (id != null && state.selectedTruongHopId == null) {
      state = state.copyWith(selectedTruongHopId: id);
    }
  }

  void selectTruongHop(int? id) {
    if (state.selectedTruongHopId == id) {
      state = state.copyWith(clearTruongHop: true);
    } else {
      state = state.copyWith(selectedTruongHopId: id);
    }
  }

  void selectHinhThucBuoc(HinhThucBuoc method) {
    state = state.copyWith(selectedHinhThucBuoc: method);
  }
}

final procedureDetailViewModelProvider = StateNotifierProvider.autoDispose
    .family<ProcedureDetailViewModel, ProcedureDetailState, int>(
  (ref, procedureId) {
    return ProcedureDetailViewModel(ref, procedureId);
  },
);
