import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dvc_guide_mobile/app/router/app_router.dart';
import 'package:dvc_guide_mobile/app/theme/app_colors.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/core/services/url_launcher_service.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/my_cases_repository_provider.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/viewmodels/my_cases_viewmodel.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/favorites_repository_provider.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';
import 'package:dvc_guide_mobile/shared/widgets/error_widget.dart';
import 'package:dvc_guide_mobile/shared/widgets/info_row.dart';
import 'package:dvc_guide_mobile/shared/widgets/section_card.dart';
import 'package:dvc_guide_mobile/shared/widgets/skeleton_loading.dart';
import 'package:dvc_guide_mobile/shared/widgets/status_chip.dart';
import '../viewmodels/procedure_detail_viewmodel.dart';

class ProcedureDetailScreen extends ConsumerStatefulWidget {
  final int id;
  final int? initialTruongHopId;

  const ProcedureDetailScreen({
    super.key,
    required this.id,
    this.initialTruongHopId,
  });

  @override
  ConsumerState<ProcedureDetailScreen> createState() => _ProcedureDetailScreenState();
}

class _ProcedureDetailScreenState extends ConsumerState<ProcedureDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTruongHopId != null) {
        ref
            .read(procedureDetailViewModelProvider(widget.id).notifier)
            .setInitialTruongHopId(widget.initialTruongHopId);
      }
    });
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final fav = await ref.read(favoritesRepositoryProvider).isFavorite(widget.id);
    if (mounted) {
      setState(() => _isFavorite = fav);
    }
  }

  Future<void> _handleOpenLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final isExample = uri?.host.contains('example.com') == true || url.contains('example.com');
    if (isExample) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.exampleLinkNotice),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.cannotOpenLinkNotice),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final success = await ref.read(urlLauncherServiceProvider).open(uri);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.cannotOpenLinkNotice),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleFindAgency(BuildContext context, ThuTucDetail p, List<HoSoCuaToi> cases) {
    if (cases.isEmpty) return;
    if (cases.length == 1) {
      context.push(
        '/find-agency?thuTucId=${p.id}&caseId=${cases.first.id}&slot=du_dinh&from=procedure',
      );
      return;
    }

    // Nhiều hồ sơ: bottom sheet chọn hồ sơ
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
                    AppStrings.selectCaseForAgencyPrompt,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cases.length,
                    itemBuilder: (context, index) {
                      final c = cases[index];
                      String? agencyName;
                      if (c.coQuanDuDinhId != null) {
                        final found = p.coQuan
                            .where((cqd) => cqd.coQuan.id == c.coQuanDuDinhId)
                            .firstOrNull;
                        agencyName = found?.coQuan.ten;
                      }

                      return ListTile(
                        key: ValueKey('select_case_for_agency_${c.id}'),
                        title: Text(
                          c.tenHoSo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text('Trạng thái: ${c.trangThai.displayName}'),
                            Text(
                              '${AppStrings.intendedAgency}: ${agencyName ?? AppStrings.unselected}',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          context.push(
                            '/find-agency?thuTucId=${p.id}&caseId=${c.id}&slot=du_dinh&from=procedure',
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
  }

  void _showMockLinkSnackBar(BuildContext context, String title, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleAddToMyCases(
    BuildContext context,
    WidgetRef ref,
    ThuTucDetail procedure,
    int? selectedTruongHopId,
  ) async {
    final myCasesRepo = ref.read(myCasesRepositoryProvider);

    final summary = ThuTucSummary(
      id: procedure.id,
      maThuTuc: procedure.maThuTuc,
      ten: procedure.ten,
      capThucHien: procedure.capThucHien,
      linhVuc: procedure.linhVuc,
    );

    final allPaperIds = procedure.thanhPhanHoSo.map((p) => p.id).toList();

    final newCase = await myCasesRepo.addCase(
      thuTuc: summary,
      truongHopId: selectedTruongHopId,
      coQuanDuDinhId: procedure.coQuan.isNotEmpty ? procedure.coQuan.first.coQuan.id : null,
      allThanhPhanIds: allPaperIds,
    );

    // Refresh myCases list
    ref.read(myCasesViewModelProvider.notifier).loadCases();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.addCaseSuccess),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: AppStrings.viewCaseAction,
            textColor: Colors.white, // white on success-green SnackBar — intentional semantic contrast
            onPressed: () => context.go(AppRoutes.myCaseDetailPath(newCase.id)),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(procedureDetailViewModelProvider(widget.id));
    final notifier = ref.read(procedureDetailViewModelProvider(widget.id).notifier);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.loading)),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonBox(width: double.infinity, height: 40),
              SizedBox(height: 16),
              SkeletonCard(),
              SkeletonCard(),
            ],
          ),
        ),
      );
    }

    if (state.error != null || state.procedure == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.errorOccurred)),
        body: AppErrorWidget(
          message: state.error ?? AppStrings.defaultErrorMessage,
          onRetry: notifier.loadDetail,
        ),
      );
    }

    final p = state.procedure!;

    final myCasesState = ref.watch(myCasesViewModelProvider);
    final casesForProcedure = myCasesState.cases.where((c) => c.thuTuc.id == p.id).toList();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            p.ten,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: _isFavorite
                  ? AppStrings.favoriteTooltipRemove
                  : AppStrings.favoriteTooltipAdd,
              icon: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isFavorite ? AppColors.error : null,
              ),
              onPressed: () async {
                final nowFav = await ref.read(favoritesRepositoryProvider).toggle(widget.id);
                if (mounted) {
                  setState(() => _isFavorite = nowFav);
                }
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: AppStrings.tabOverview),
              Tab(text: AppStrings.tabDossier),
              Tab(text: AppStrings.tabSteps),
              Tab(text: AppStrings.tabFeesAndTimeline),
              Tab(text: AppStrings.tabLegalBasis),
            ],
          ),
        ),
        body: Column(
          children: [
            // Disclaimer Banner at top of page
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
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

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(context, p, casesForProcedure),
                  _buildDossierTab(context, p, state, notifier),
                  _buildStepsTab(context, p, state, notifier),
                  _buildFeesAndTimelineTab(context, p),
                  _buildLegalBasisTab(context, p),
                ],
              ),
            ),

            // Sticky Bottom Action Bar
            _buildBottomActionBar(context, ref, p, state.selectedTruongHopId),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Tổng quan ────────────────────────────────────────────────────────
  Widget _buildOverviewTab(BuildContext context, ThuTucDetail p, List<HoSoCuaToi> casesForProcedure) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (p.capThucHien != null) ...[
                      StatusChip.administrativeLevel(context, p.capThucHien!),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        p.maThuTuc,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  p.ten,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (p.linhVuc.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: p.linhVuc
                        .map((lv) => Chip(
                              label: Text(lv.ten),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          // Target Audience (Đối tượng)
          SectionCard(
            icon: Icons.person_outline,
            title: AppStrings.targetAudience,
            child: Text(
              p.doiTuong ?? AppStrings.notProvided,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Requirements & Conditions (Điều kiện thực hiện)
          SectionCard(
            icon: Icons.rule_outlined,
            title: AppStrings.requirements,
            child: Text(
              p.dieuKien ?? AppStrings.notProvided,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Executing Agency (Cơ quan thực hiện)
          SectionCard(
            icon: Icons.account_balance_outlined,
            title: AppStrings.executingAgency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.coQuanThucHienGoc != null) ...[
                  Text(
                    p.coQuanThucHienGoc!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ...p.coQuan.map((coQuanDetail) {
                  final cq = coQuanDetail.coQuan;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${cq.ten}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (cq.diaChi != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 2),
                            child: Text(
                              '${AppStrings.addressLabel}: ${cq.diaChi}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (coQuanDetail.ghiChu != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 2),
                            child: Text(
                              '${AppStrings.noteLabel}: ${coQuanDetail.ghiChu}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                if (casesForProcedure.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const ValueKey('find_agency_button'),
                    onPressed: () => _handleFindAgency(context, p, casesForProcedure),
                    icon: const Icon(Icons.location_searching_rounded),
                    label: const Text(AppStrings.findAgencyAction),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Results Obtained (Kết quả nhận được)
          SectionCard(
            icon: Icons.assignment_turned_in_outlined,
            title: AppStrings.resultsObtained,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: p.ketQua.isEmpty
                  ? [Text(AppStrings.notProvided, style: theme.textTheme.bodyMedium)]
                  : p.ketQua
                      .map((kq) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    kq.ten,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
            ),
          ),

          // DVC Portal Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.tonalIcon(
              onPressed: p.linkDvc != null
                  ? () => _handleOpenLink(context, p.linkDvc!)
                  : null,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text(AppStrings.openDvcPortal),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Tab 2: Hồ sơ (Dossier) ──────────────────────────────────────────────────
  Widget _buildDossierTab(
    BuildContext context,
    ThuTucDetail p,
    ProcedureDetailState state,
    ProcedureDetailViewModel notifier,
  ) {
    final theme = Theme.of(context);
    final hasMultipleCases = p.truongHop.length >= 2;
    final selectedCaseId = state.selectedTruongHopId;

    // Filter papers according to selected case
    final filteredPapers = p.thanhPhanHoSo.where((paper) {
      if (selectedCaseId == null) {
        // When no case is selected, only show general papers (truongHopId == null)
        return paper.truongHopId == null;
      }
      return paper.truongHopId == null || paper.truongHopId == selectedCaseId;
    }).toList();

    // Group papers by `nhom`
    final groupedPapers = <String, List<ThanhPhanHoSo>>{};
    for (final paper in filteredPapers) {
      final groupKey = paper.nhom ?? AppStrings.paperGroupGeneral;
      groupedPapers.putIfAbsent(groupKey, () => []).add(paper);
    }

    // Determine current question for case selector
    final selectedCase = p.truongHop.where((th) => th.id == selectedCaseId).firstOrNull;
    final questionText = selectedCase?.cauHoiPhanLoai ??
        (p.truongHop.isNotEmpty && p.truongHop.first.cauHoiPhanLoai != null
            ? p.truongHop.first.cauHoiPhanLoai!
            : AppStrings.defaultCaseQuestion);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case Selector (ChoiceChip) if 2 or more cases
          if (hasMultipleCases)
            SectionCard(
              title: AppStrings.selectCasePrompt,
              subtitle: questionText,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.truongHop.map((th) {
                  final isSelected = selectedCaseId == th.id;
                  return ChoiceChip(
                    label: Text(th.ten),
                    selected: isSelected,
                    onSelected: (_) => notifier.selectTruongHop(th.id),
                  );
                }).toList(),
              ),
            ),

          // Notice when no case is selected
          if (hasMultipleCases && selectedCaseId == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.secondary.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.selectCaseNoteDetail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Grouped Paper List
          ...groupedPapers.entries.map((entry) {
            return SectionCard(
              title: entry.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entry.value.map((paper) {
                  return _buildPaperItem(context, paper);
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaperItem(BuildContext context, ThanhPhanHoSo paper) {
    final theme = Theme.of(context);

    // Build copy count text
    final countParts = <String>[];
    if (paper.soLuongBanChinh != null) {
      countParts.add('${paper.soLuongBanChinh} ${AppStrings.originalCount}');
    }
    if (paper.soLuongBanSao != null) {
      countParts.add('${paper.soLuongBanSao} ${AppStrings.copyCount}');
    }
    final countText = countParts.join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(100)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  paper.tenGiayTo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Requirement Badge (Bắt buộc / Tùy chọn / hidden if null)
              StatusChip.requirementBadge(context, paper.batBuoc),
            ],
          ),
          if (countText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  countText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          if (paper.ghiChu != null) ...[
            const SizedBox(height: 4),
            Text(
              paper.ghiChu!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          // Download Form Templates
          if (paper.bieuMau != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (paper.bieuMau!.fileDocxUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => _showMockLinkSnackBar(
                      context,
                      AppStrings.wordTemplateTitle,
                      paper.bieuMau!.fileDocxUrl!,
                    ),
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text(AppStrings.downloadTemplateDocx),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                if (paper.bieuMau!.filePdfUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => _showMockLinkSnackBar(
                      context,
                      AppStrings.pdfTemplateTitle,
                      paper.bieuMau!.filePdfUrl!,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text(AppStrings.downloadTemplatePdf),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 3: Trình tự (Steps) ─────────────────────────────────────────────────
  Widget _buildStepsTab(
    BuildContext context,
    ThuTucDetail p,
    ProcedureDetailState state,
    ProcedureDetailViewModel notifier,
  ) {
    final theme = Theme.of(context);

    // Only include execution methods that actually have steps in this procedure
    final availableMethods = p.buocThucHien.map((b) => b.hinhThuc).toSet().toList();
    if (availableMethods.isEmpty) {
      return Center(
        child: Text(
          AppStrings.notProvided,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    // Filter steps for the selected execution method, sorted by thuTu
    final filteredSteps = p.buocThucHien
        .where((b) => b.hinhThuc == state.selectedHinhThucBuoc)
        .toList()
      ..sort((a, b) => a.thuTu.compareTo(b.thuTu));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Segmented Button for step methods
          if (availableMethods.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<HinhThucBuoc>(
                segments: availableMethods.map((m) {
                  return ButtonSegment<HinhThucBuoc>(
                    value: m,
                    label: Text(m.displayName),
                  );
                }).toList(),
                selected: {state.selectedHinhThucBuoc},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    notifier.selectHinhThucBuoc(set.first);
                  }
                },
              ),
            ),

          // Timeline Step List (ordered by thuTu, unlimited steps)
          if (filteredSteps.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                AppStrings.noStepsForMethod,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredSteps.length,
              itemBuilder: (context, index) {
                final step = filteredSteps[index];
                final isLast = index == filteredSteps.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline indicator column
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${step.thuTu}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Step Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (step.tieuDe != null)
                                Text(
                                  step.tieuDe!,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (step.moTa != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  step.moTa!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Tab 4: Thời hạn & Lệ phí ────────────────────────────────────────────────
  Widget _buildFeesAndTimelineTab(BuildContext context, ThuTucDetail p) {
    final theme = Theme.of(context);

    if (p.hinhThucNop.isEmpty) {
      return Center(
        child: Text(AppStrings.notProvided, style: theme.textTheme.bodyMedium),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: p.hinhThucNop.map((ht) {
          final timelineStr = InfoRow.formatTimeline(
            thoiHanSo: ht.thoiHanSo,
            thoiHanDonVi: ht.thoiHanDonVi,
            thoiHanGoc: ht.thoiHanGoc,
          );

          return SectionCard(
            title: ht.hinhThucGoc ?? ht.hinhThuc.displayName,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  label: AppStrings.processingTime,
                  value: timelineStr,
                  icon: Icons.timer_outlined,
                ),
                // Lệ phí items
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 130,
                        child: Text(
                          AppStrings.feeLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ht.lePhi.isEmpty
                            ? Text(
                                AppStrings.feeUnknown,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: ht.lePhi.map((fee) {
                                  final feeText = InfoRow.formatFee(fee);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          feeText,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: fee.mienPhi
                                                ? AppColors.success
                                                : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        if (fee.ghiChu != null)
                                          Text(
                                            fee.ghiChu!,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
                if (ht.diaChiNop != null)
                  InfoRow(
                    label: AppStrings.submitAddress,
                    value: ht.diaChiNop,
                    icon: Icons.location_on_outlined,
                  ),
                if (ht.linkNop != null)
                  InfoRow(
                    label: AppStrings.submissionMethod,
                    customValueWidget: InkWell(
                      onTap: () => _showMockLinkSnackBar(
                        context,
                        AppStrings.submissionLink,
                        ht.linkNop!,
                      ),
                      child: Text(
                        AppStrings.submitOnlineLink,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    icon: Icons.link_rounded,
                  ),
                if (ht.gioTiepNhan != null)
                  InfoRow(
                    label: AppStrings.receivingHours,
                    value: ht.gioTiepNhan,
                    icon: Icons.access_time_outlined,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Tab 5: Căn cứ pháp lý ───────────────────────────────────────────────────
  Widget _buildLegalBasisTab(BuildContext context, ThuTucDetail p) {
    final theme = Theme.of(context);

    if (p.vanBan.isEmpty) {
      return Center(
        child: Text(AppStrings.notProvided, style: theme.textTheme.bodyMedium),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: p.vanBan.length,
      itemBuilder: (context, index) {
        final vb = p.vanBan[index];

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${vb.loai.displayName} số ${vb.soHieu}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Validity status chip
                  StatusChip.legalValidity(context, vb.trangThaiHieuLuc),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                vb.ten,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (vb.dieuKhoan.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${AppStrings.applicableClause}: ${vb.dieuKhoan}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              if (vb.coQuanBanHanh != null)
                Text(
                  '${AppStrings.issuingAgency}: ${vb.coQuanBanHanh}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (vb.ngayHieuLuc != null)
                Text(
                  '${AppStrings.effectiveDate} ${vb.ngayHieuLuc}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (vb.ngayHetHieuLuc != null)
                Text(
                  '${AppStrings.expiredDate} ${vb.ngayHetHieuLuc}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Sticky Bottom Action Bar ───────────────────────────────────────────────
  Widget _buildBottomActionBar(
    BuildContext context,
    WidgetRef ref,
    ThuTucDetail p,
    int? selectedTruongHopId,
  ) {
    final theme = Theme.of(context);
    final myCasesState = ref.watch(myCasesViewModelProvider);
    final existingCase = myCasesState.cases.where((c) => c.thuTuc.id == p.id).firstOrNull;
    final isAdded = existingCase != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (isAdded) {
                    context.go(AppRoutes.myCaseDetailPath(existingCase.id));
                  } else {
                    _handleAddToMyCases(
                      context,
                      ref,
                      p,
                      selectedTruongHopId,
                    );
                  }
                },
                icon: Icon(
                  isAdded ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                  color: isAdded ? AppColors.success : null,
                ),
                label: Text(
                  isAdded ? AppStrings.addedToMyCases : AppStrings.addToMyCases,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  context.go(AppRoutes.chat, extra: p.maThuTuc);
                },
                icon: const Icon(Icons.smart_toy_rounded),
                label: const Text(
                  AppStrings.askAiAboutThis,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
