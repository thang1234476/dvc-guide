import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../auth/presentation/viewmodels/auth_controller.dart';
import '../../../my_cases/data/models/my_case_models.dart';
import '../../../procedure/data/models/procedure_models.dart';
import '../../../procedure/data/repositories/procedure_repository_provider.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const HomeScreen({super.key, this.initialQuery});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery;
    _searchController = TextEditingController(text: initial ?? '');
    _scrollController = ScrollController()..addListener(_onScroll);

    if (initial != null && initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(homeViewModelProvider.notifier).onSearchChanged(initial);
      });
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != null && widget.initialQuery != oldWidget.initialQuery) {
      _searchController.text = widget.initialQuery!;
      ref.read(homeViewModelProvider.notifier).onSearchChanged(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(homeViewModelProvider.notifier).fetchProcedures();
    }
  }

  Future<void> _onProcedureTapped(BuildContext context, ThuTucSummary procedure) async {
    try {
      final repo = ref.read(procedureRepositoryProvider);
      final detail = await repo.getProcedureDetail(procedure.id);

      if (!context.mounted) return;

      if (detail.truongHop.length >= 2) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (sheetContext) {
            final theme = Theme.of(sheetContext);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        AppStrings.selectYourCase,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: detail.truongHop.length,
                        itemBuilder: (context, index) {
                          final th = detail.truongHop[index];
                          return ListTile(
                            title: Text(
                              th.ten,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: th.cauHoiPhanLoai != null
                                ? Text(th.cauHoiPhanLoai!)
                                : (th.dieuKien != null ? Text(th.dieuKien!) : null),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              context.push(
                                '${AppRoutes.procedureDetailPath(procedure.id)}?truongHopId=${th.id}',
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        context.push(AppRoutes.procedureDetailPath(procedure.id));
      }
    } catch (_) {
      if (context.mounted) {
        context.push(AppRoutes.procedureDetailPath(procedure.id));
      }
    }
  }

  Widget _buildActiveCasesSection(BuildContext context, List<HoSoCuaToi> cases) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppStrings.activeTrackedCases,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: cases.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final c = cases[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.go(AppRoutes.myCaseDetailPath(c.id)),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.tenHoSo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c.trangThai.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow(
    BuildContext context,
    HomeState state,
    HomeViewModel notifier,
  ) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          // Chip "Đã lưu"
          FilterChip(
            avatar: Icon(
              state.onlyFavorites ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 16,
              color: state.onlyFavorites ? theme.colorScheme.onPrimary : null,
            ),
            label: const Text(AppStrings.filterSaved),
            selected: state.onlyFavorites,
            onSelected: (_) => notifier.toggleOnlyFavorites(),
          ),
          const SizedBox(width: 8),

          // Chips Lĩnh vực (chọn được nhiều)
          for (final lv in state.categories) ...[
            FilterChip(
              label: Text(lv.ten),
              selected: state.selectedLinhVucIds.contains(lv.id),
              onSelected: (_) => notifier.toggleLinhVuc(lv.id),
            ),
            const SizedBox(width: 8),
          ],

          // Nút "Xóa bộ lọc" khi có lọc
          if (state.hasActiveFilter)
            ActionChip(
              avatar: const Icon(Icons.clear_rounded, size: 16),
              label: const Text(AppStrings.clearFilters),
              onPressed: () {
                _searchController.clear();
                notifier.clearFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProcedureItem(
    BuildContext context,
    ThuTucSummary p,
    bool isFavorite,
    HomeViewModel notifier,
  ) {
    final theme = Theme.of(context);
    final mainLinhVuc = p.linhVuc.isNotEmpty ? p.linhVuc.first.ten : null;

    return SectionCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: () => _onProcedureTapped(context, p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.maThuTuc,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.ten,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Tim yêu thích (>= 48dp, có tooltip, không chuyển màn hình)
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: IconButton(
                    tooltip: isFavorite
                        ? AppStrings.favoriteTooltipRemove
                        : AppStrings.favoriteTooltipAdd,
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorite ? AppColors.error : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: () => notifier.toggleFavorite(p.id),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (p.capThucHien != null)
                StatusChip.administrativeLevel(context, p.capThucHien!),
              if (mainLinhVuc != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mainLinhVuc,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noProceduresFound,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.tryDifferentKeywords,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => context.go(AppRoutes.chat),
            icon: const Icon(Icons.smart_toy_outlined, size: 18),
            label: const Text(
              AppStrings.askAssistantNotFound,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildLoadingSkeleton(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonCard(),
          SkeletonCard(),
          SkeletonCard(),
          SkeletonCard(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(homeViewModelProvider);
    final notifier = ref.read(homeViewModelProvider.notifier);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: notifier.loadHomeData,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header & Disclaimer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.account_balance_rounded,
                              size: 24,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.appName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  AppStrings.appTagline,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // User profile / login icon
                          IconButton(
                            key: const ValueKey('home_user_action_button'),
                            tooltip: AppStrings.accountTitle,
                            icon: authState.isAuthenticated
                                ? CircleAvatar(
                                    radius: 16,
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    child: Text(
                                      (authState.user?.tenHienThi != null &&
                                              authState.user!.tenHienThi!.isNotEmpty)
                                          ? authState.user!.tenHienThi![0].toUpperCase()
                                          : (authState.user?.email.isNotEmpty == true
                                              ? authState.user!.email[0].toUpperCase()
                                              : 'U'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.account_circle_outlined,
                                    size: 30,
                                    color: theme.colorScheme.primary,
                                  ),
                            onPressed: () {
                              context.push(AppRoutes.account);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Disclaimer Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.mockDataDisclaimer,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar (gõ trực tiếp tại chỗ, có nút xóa)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchProcedureHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              tooltip: AppStrings.clearSearch,
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                notifier.onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() {});
                      notifier.onSearchChanged(val);
                    },
                  ),
                ),
              ),

              // Khối "Hồ sơ đang theo dõi" (chỉ hiện khi có hồ sơ chưa ở trạng thái daNhanKetQua)
              if (state.activeCases.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildActiveCasesSection(context, state.activeCases),
                ),

              // Hàng chip lọc cuộn ngang ("Đã lưu" + Lĩnh vực multi-select + "Xóa bộ lọc")
              if (state.categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildFilterChipsRow(context, state, notifier),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Nội dung danh sách kết quả, loading, error, hoặc empty
              if (state.isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildLoadingSkeleton(context),
                )
              else if (state.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorWidget(
                    message: state.error!,
                    onRetry: notifier.loadHomeData,
                  ),
                )
              else if (state.procedures.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else ...[
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = state.procedures[index];
                      final isFav = state.favoriteIds.contains(p.id);
                      return _buildProcedureItem(context, p, isFav, notifier);
                    },
                    childCount: state.procedures.length,
                  ),
                ),
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
