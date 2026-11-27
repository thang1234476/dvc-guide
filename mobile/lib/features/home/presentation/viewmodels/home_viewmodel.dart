import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/my_cases_repository_provider.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/favorites_repository_provider.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/procedure_repository_provider.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/auth_controller.dart';

class HomeState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String searchQuery;
  final Set<int> selectedLinhVucIds;
  final bool onlyFavorites;
  final Set<int> favoriteIds;
  final List<LinhVuc> categories;
  final List<ThuTucSummary> procedures;
  final List<HoSoCuaToi> activeCases;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.searchQuery = '',
    this.selectedLinhVucIds = const {},
    this.onlyFavorites = false,
    this.favoriteIds = const {},
    this.categories = const [],
    this.procedures = const [],
    this.activeCases = const [],
    this.error,
  });

  bool get hasActiveFilter =>
      searchQuery.isNotEmpty || selectedLinhVucIds.isNotEmpty || onlyFavorites;

  HomeState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? searchQuery,
    Set<int>? selectedLinhVucIds,
    bool? onlyFavorites,
    Set<int>? favoriteIds,
    List<LinhVuc>? categories,
    List<ThuTucSummary>? procedures,
    List<HoSoCuaToi>? activeCases,
    String? error,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLinhVucIds: selectedLinhVucIds ?? this.selectedLinhVucIds,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      categories: categories ?? this.categories,
      procedures: procedures ?? this.procedures,
      activeCases: activeCases ?? this.activeCases,
      error: error,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref _ref;

  HomeViewModel(this._ref) : super(const HomeState(isLoading: true)) {
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final procRepo = _ref.read(procedureRepositoryProvider);
      final favRepo = _ref.read(favoritesRepositoryProvider);
      final myCasesRepo = _ref.read(myCasesRepositoryProvider);

      final categories = await procRepo.getLinhVucList();
      final favIds = await favRepo.getFavoriteIds();
      final allCases = await myCasesRepo.getMyCases();

      // Hồ sơ đang theo dõi: chưa ở trạng thái daNhanKetQua, tối đa 5 thẻ theo cập nhật gần nhất
      final active = allCases
          .where((c) => c.trangThai != TrangThaiHoSo.daNhanKetQua)
          .toList();
      active.sort((a, b) {
        final dateA = a.capNhatLuc ?? a.taoLuc ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.capNhatLuc ?? b.taoLuc ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      final topActiveCases = active.take(5).toList();

      state = state.copyWith(
        categories: categories,
        favoriteIds: favIds,
        activeCases: topActiveCases,
      );

      await fetchProcedures(resetPage: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchProcedures({bool resetPage = false}) async {
    final targetPage = resetPage ? 1 : state.page;
    if (resetPage) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      if (state.isLoadingMore || !state.hasMore) return;
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final procRepo = _ref.read(procedureRepositoryProvider);

      List<int>? onlyIds;
      if (state.onlyFavorites) {
        onlyIds = state.favoriteIds.toList();
      }

      final items = await procRepo.getProcedures(
        query: state.searchQuery.trim().isNotEmpty ? state.searchQuery.trim() : null,
        linhVucIds: state.selectedLinhVucIds.isNotEmpty ? state.selectedLinhVucIds.toList() : null,
        onlyIds: onlyIds,
        page: targetPage,
        pageSize: 10,
      );

      final newProcedures = resetPage ? items : [...state.procedures, ...items];

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        procedures: newProcedures,
        page: targetPage + 1,
        hasMore: items.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

    /// Gọi khi đổi tài khoản: bỏ dữ liệu của người trước.
  void resetForUser() {
    if (_ref.read(authControllerProvider).isAuthenticated) {
      state = const HomeState(isLoading: true);
      loadHomeData();
    } else {
      state = const HomeState();
    }
  }

  void onSearchChanged(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    fetchProcedures(resetPage: true);
  }

  void toggleLinhVuc(int linhVucId) {
    final updated = Set<int>.from(state.selectedLinhVucIds);
    if (updated.contains(linhVucId)) {
      updated.remove(linhVucId);
    } else {
      updated.add(linhVucId);
    }
    state = state.copyWith(selectedLinhVucIds: updated);
    fetchProcedures(resetPage: true);
  }

  void toggleOnlyFavorites() {
    state = state.copyWith(onlyFavorites: !state.onlyFavorites);
    fetchProcedures(resetPage: true);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedLinhVucIds: const {},
      onlyFavorites: false,
    );
    fetchProcedures(resetPage: true);
  }

    Future<void> toggleFavorite(int procedureId) async {
    try {
      final favRepo = _ref.read(favoritesRepositoryProvider);
      final isNowFav = await favRepo.toggle(procedureId);

      final updated = Set<int>.from(state.favoriteIds);
      if (isNowFav) {
        updated.add(procedureId);
      } else {
        updated.remove(procedureId);
      }
      state = state.copyWith(favoriteIds: updated);

      if (state.onlyFavorites) {
        fetchProcedures(resetPage: true);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reloadActiveCases() async {
    try {
      final myCasesRepo = _ref.read(myCasesRepositoryProvider);
      final allCases = await myCasesRepo.getMyCases();
      final active = allCases
          .where((c) => c.trangThai != TrangThaiHoSo.daNhanKetQua)
          .toList();
      active.sort((a, b) {
        final dateA = a.capNhatLuc ?? a.taoLuc ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.capNhatLuc ?? b.taoLuc ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      state = state.copyWith(activeCases: active.take(5).toList());
    } catch (_) {}
  }
}

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final vm = HomeViewModel(ref);
  ref.listen<String?>(
    authControllerProvider.select((s) => s.user?.id),
    (previous, next) {
      if (previous != next) vm.resetForUser();
    },
  );
  return vm;
});
