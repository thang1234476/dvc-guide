import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/my_cases_repository_provider.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/auth_controller.dart';

class MyCasesState {
  final bool isLoading;
  final List<HoSoCuaToi> cases;
  final String? error;

  const MyCasesState({
    this.isLoading = false,
    this.cases = const [],
    this.error,
  });

  MyCasesState copyWith({
    bool? isLoading,
    List<HoSoCuaToi>? cases,
    String? error,
  }) {
    return MyCasesState(
      isLoading: isLoading ?? this.isLoading,
      cases: cases ?? this.cases,
      error: error,
    );
  }
}

class MyCasesViewModel extends StateNotifier<MyCasesState> {
  final Ref _ref;

  MyCasesViewModel(this._ref) : super(const MyCasesState(isLoading: true)) {
    loadCases();
  }

  Future<void> loadCases() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(myCasesRepositoryProvider);
      final cases = await repo.getMyCases();
      if (!mounted) return; // <- THÊM
      final sortedCases = List<HoSoCuaToi>.from(cases)
        ..sort((a, b) {
          final dateA =
              a.capNhatLuc ??
              a.taoLuc ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              b.capNhatLuc ??
              b.taoLuc ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });
      state = state.copyWith(isLoading: false, cases: sortedCases);
    } catch (e) {
      if (!mounted) return; // <- THÊM
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteCase(
    HoSoCuaToi caseItem,
    int index,
    BuildContext context,
  ) async {
    final updatedList = List<HoSoCuaToi>.from(state.cases)..removeAt(index);
    state = state.copyWith(cases: updatedList);

    final repo = _ref.read(myCasesRepositoryProvider);
    try {
      await repo.deleteCase(caseItem.id);
    } catch (e) {
      // Xóa thất bại: tải lại để danh sách khớp server.
      await loadCases();
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.caseDeleted),
          action: SnackBarAction(
            label: AppStrings.undoAction,
            onPressed: () => restoreCase(caseItem, index),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> restoreCase(HoSoCuaToi caseItem, int index) async {
    try {
      final repo = _ref.read(myCasesRepositoryProvider);
      await repo.restoreCase(caseItem, index);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
      return;
    }
    await loadCases(); // hồ sơ khôi phục có id mới nên phải tải lại
  }

  void resetForUser() {
    if (_ref.read(authControllerProvider).isAuthenticated) {
      state = const MyCasesState(isLoading: true);
      loadCases();
    } else {
      state = const MyCasesState();
    }
  }
}

final myCasesViewModelProvider =
    StateNotifierProvider<MyCasesViewModel, MyCasesState>((ref) {
  final vm = MyCasesViewModel(ref);
  ref.listen<String?>(
    authControllerProvider.select((s) => s.user?.id),
    (previous, next) {
      if (previous != next) vm.resetForUser();
    },
  );
  return vm;
});
