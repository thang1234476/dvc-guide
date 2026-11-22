import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dvc_guide_mobile/app/router/app_router.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/core/services/url_launcher_service.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/viewmodels/my_case_detail_viewmodel.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';
import 'package:dvc_guide_mobile/shared/widgets/error_widget.dart';
import 'package:dvc_guide_mobile/shared/widgets/section_card.dart';
import 'package:dvc_guide_mobile/shared/widgets/skeleton_loading.dart';
import 'package:dvc_guide_mobile/shared/widgets/status_chip.dart';

class MyCaseCheckScreen extends ConsumerStatefulWidget {
  final String id;

  const MyCaseCheckScreen({super.key, required this.id});

  @override
  ConsumerState<MyCaseCheckScreen> createState() => _MyCaseCheckScreenState();
}

class _MyCaseCheckScreenState extends ConsumerState<MyCaseCheckScreen> {
  bool _isCaseExpanded = false;

  bool _isExampleUrl(String? url) {
    if (url == null) return false;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.contains('example.com')) return true;
    return url.contains('example.com');
  }

  bool _isRealUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return !_isExampleUrl(url);
  }

  bool _hasRealForm(BieuMau? bieuMau) {
    if (bieuMau == null) return false;
    return _isRealUrl(bieuMau.fileDocxUrl) || _isRealUrl(bieuMau.filePdfUrl);
  }

  Future<void> _handleOpenFormUrl(BuildContext context, String url) async {
    if (_isExampleUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.exampleLinkNotice),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
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

  void _onDownloadFormPressed(BuildContext context, BieuMau bieuMau) {
    final hasDocx = bieuMau.fileDocxUrl != null;
    final hasPdf = bieuMau.filePdfUrl != null;

    if (hasDocx && hasPdf) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      AppStrings.selectDownloadFormat,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.description_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text(AppStrings.downloadTemplateDocx),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleOpenFormUrl(context, bieuMau.fileDocxUrl!);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: theme.colorScheme.error,
                    ),
                    title: const Text(AppStrings.downloadTemplatePdf),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleOpenFormUrl(context, bieuMau.filePdfUrl!);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (hasDocx) {
      _handleOpenFormUrl(context, bieuMau.fileDocxUrl!);
    } else if (hasPdf) {
      _handleOpenFormUrl(context, bieuMau.filePdfUrl!);
    }
  }

  Widget _buildDetermineCaseCard(
    BuildContext context,
    HoSoCuaToi caseItem,
    ThuTucDetail procedure,
    MyCaseDetailViewModel notifier,
  ) {
    // Only display when procedure has >= 2 cases
    if (procedure.truongHop.length < 2) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isUnselected = caseItem.truongHopId == null;

    final selectedTh = procedure.truongHop
        .where((th) => th.id == caseItem.truongHopId)
        .firstOrNull;

    // Collapsed state: case is selected and user hasn't tapped "Đổi"
    if (!isUnselected && !_isCaseExpanded) {
      return SectionCard(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.determineCaseTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _isCaseExpanded = true),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text(AppStrings.changeCaseShort),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedTh?.ten ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (selectedTh?.dieuKien != null &&
                      selectedTh!.dieuKien!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      selectedTh.dieuKien!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Expanded / Unselected state
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isUnselected
            ? theme.colorScheme.primaryContainer.withAlpha(40)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnselected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isUnselected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUnselected
                      ? Icons.warning_amber_rounded
                      : Icons.help_outline_rounded,
                  color: isUnselected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.determineCaseTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUnselected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
                if (!isUnselected)
                  TextButton.icon(
                    onPressed: () => setState(() => _isCaseExpanded = false),
                    icon: const Icon(Icons.expand_less_rounded, size: 16),
                    label: const Text(AppStrings.collapseAction),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
              ],
            ),
            if (isUnselected) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppStrings.noteSelectCaseForPapers,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Material(
              type: MaterialType.transparency,
              child: RadioGroup<int>(
                groupValue: caseItem.truongHopId,
                onChanged: (newId) {
                  if (newId != null) {
                    notifier.selectTruongHop(newId);
                    setState(() => _isCaseExpanded = false);
                  }
                },
                child: Column(
                  children: procedure.truongHop.map((th) {
                    final isSelected = th.id == caseItem.truongHopId;
                    return RadioListTile<int>(
                      value: th.id,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        th.cauHoiPhanLoai ?? th.ten,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      subtitle: th.dieuKien != null && th.dieuKien!.isNotEmpty
                          ? Text(
                              th.dieuKien!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(myCaseDetailViewModelProvider(widget.id));
    final notifier = ref.read(
      myCaseDetailViewModelProvider(widget.id).notifier,
    );

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.checkPapersTitle)),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonBox(width: double.infinity, height: 100),
              SizedBox(height: 16),
              SkeletonCard(),
              SizedBox(height: 16),
              SkeletonCard(),
            ],
          ),
        ),
      );
    }

    if (state.error != null ||
        state.caseItem == null ||
        state.procedure == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.checkPapersTitle)),
        body: AppErrorWidget(
          message: state.error ?? AppStrings.defaultErrorMessage,
          onRetry: notifier.loadCaseDetail,
        ),
      );
    }

    final caseItem = state.caseItem!;
    final procedure = state.procedure!;

    // Resolve applicable papers based on current truongHopId
    // If truongHopId is null, filterApplicablePapers returns only general papers (truongHopId == null)
    final applicablePapers = filterApplicablePapers(
      procedure.thanhPhanHoSo,
      caseItem.truongHopId,
    );

    // Group papers by nhom
    final groupedPapers = <String, List<ThanhPhanHoSo>>{};
    for (final paper in applicablePapers) {
      final group = (paper.nhom != null && paper.nhom!.isNotEmpty)
          ? paper.nhom!
          : AppStrings.defaultPaperGroup;
      groupedPapers.putIfAbsent(group, () => []).add(paper);
    }

    // Counts: Đã có, Chưa có, Chưa rõ
    // Papers without an explicit entry in checklist default to Chưa rõ
    int daCoCount = 0;
    int chuaCoCount = 0;
    int chuaRoCount = 0;
    final missingPapers = <ThanhPhanHoSo>[];

    for (final paper in applicablePapers) {
      final status = caseItem.checklist[paper.id] ?? TrangThaiGiayTo.chuaRo;
      switch (status) {
        case TrangThaiGiayTo.daCo:
          daCoCount++;
          break;
        case TrangThaiGiayTo.chuaCo:
          chuaCoCount++;
          missingPapers.add(paper);
          break;
        case TrangThaiGiayTo.chuaRo:
          chuaRoCount++;
          missingPapers.add(paper);
          break;
      }
    }

    final totalPapers = applicablePapers.length;
    final progress = totalPapers > 0
        ? (daCoCount / totalPapers).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              AppStrings.checkPapersTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              caseItem.tenHoSo,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Thẻ xác định trường hợp của bạn (nếu có >= 2 trường hợp) ───
              _buildDetermineCaseCard(context, caseItem, procedure, notifier),

              // ── 2. Thẻ tổng hợp tiến độ & thống kê ────────────────────────
              SectionCard(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat Counts
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            context,
                            label: AppStrings.readyCountLabel,
                            count: daCoCount,
                            color: theme.colorScheme.primary,
                            bgColor: theme.colorScheme.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatBox(
                            context,
                            label: AppStrings.missingCountLabel,
                            count: chuaCoCount,
                            color: theme.colorScheme.error,
                            bgColor: theme.colorScheme.errorContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatBox(
                            context,
                            label: AppStrings.unknownCountLabel,
                            count: chuaRoCount,
                            color: theme.colorScheme.onSurfaceVariant,
                            bgColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$daCoCount/$totalPapers ${AppStrings.papersReadySuffix}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 12),

                    // Disclaimer notice
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withAlpha(120),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.preparationDisclaimer,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── 3. Danh sách giấy tờ theo nhóm ─────────────────────────────
              for (final entry in groupedPapers.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text(
                    entry.key,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                SectionCard(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (int i = 0; i < entry.value.length; i++) ...[
                        if (i > 0) const Divider(height: 24),
                        _buildPaperItem(
                          context,
                          caseItem,
                          entry.value[i],
                          caseItem.checklist[entry.value[i].id] ??
                              TrangThaiGiayTo.chuaRo,
                          notifier,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ── 4. Mục Giấy tờ còn thiếu ở cuối trang ──────────────────────
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppStrings.missingPapersTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SectionCard(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: missingPapers.isEmpty
                    ? Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.noMissingPapers,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < missingPapers.length; i++) ...[
                            if (i > 0) const Divider(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    missingPapers[i].tenGiayTo,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusChip.paperStatus(
                                  context,
                                  caseItem.checklist[missingPapers[i].id] ??
                                      TrangThaiGiayTo.chuaRo,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPaperItem(
    BuildContext context,
    HoSoCuaToi caseItem,
    ThanhPhanHoSo paper,
    TrangThaiGiayTo currentStatus,
    MyCaseDetailViewModel notifier,
  ) {
    final theme = Theme.of(context);

    final countParts = <String>[];
    if (paper.soLuongBanChinh != null && paper.soLuongBanChinh! > 0) {
      countParts.add('${paper.soLuongBanChinh} ${AppStrings.originalCount}');
    }
    if (paper.soLuongBanSao != null && paper.soLuongBanSao! > 0) {
      countParts.add('${paper.soLuongBanSao} ${AppStrings.copyCount}');
    }
    final countText = countParts.join(', ');

    final hasRealForm = _hasRealForm(paper.bieuMau);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tên giấy tờ & Nhãn Bắt buộc / Tùy chọn (ẩn nếu batBuoc null)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                paper.tenGiayTo,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (paper.batBuoc != null) ...[
              const SizedBox(width: 8),
              StatusChip.requirementBadge(context, paper.batBuoc),
            ],
          ],
        ),

        // Số bản chính / bản sao (ẩn nếu null)
        if (countText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            countText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        // Ghi chú (ẩn nếu null)
        if (paper.ghiChu != null && paper.ghiChu!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            paper.ghiChu!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],

        // Nút "Tải biểu mẫu" (CHỈ hiện khi có đường dẫn thật) & Nút "Hỏi trợ lý"
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (hasRealForm)
              FilledButton.tonalIcon(
                onPressed: () =>
                    _onDownloadFormPressed(context, paper.bieuMau!),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text(AppStrings.downloadTemplateAction),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
            OutlinedButton.icon(
              onPressed: () {
                context.go(
                  AppRoutes.chat,
                  extra: {
                    'maThuTuc': caseItem.thuTuc.maThuTuc,
                    'tenGiayTo': paper.tenGiayTo,
                    'thanhPhanHoSoId': paper.id,
                    'truongHopId': caseItem.truongHopId,
                    'initialQuestion':
                        "Giấy tờ '${paper.tenGiayTo}' là gì và cần chuẩn bị thế nào?",
                  },
                );
              },
              icon: const Icon(Icons.smart_toy_outlined, size: 16),
              label: const Text(AppStrings.askAssistantAction),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 3-choice SegmentedButton: Đã có / Chưa có / Chưa rõ (mặc định Chưa rõ)
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<TrangThaiGiayTo>(
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            ),
            segments: const [
              ButtonSegment<TrangThaiGiayTo>(
                value: TrangThaiGiayTo.daCo,
                label: Text(
                  AppStrings.statusPaperReady,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ButtonSegment<TrangThaiGiayTo>(
                value: TrangThaiGiayTo.chuaCo,
                label: Text(
                  AppStrings.statusPaperMissing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ButtonSegment<TrangThaiGiayTo>(
                value: TrangThaiGiayTo.chuaRo,
                label: Text(
                  AppStrings.statusPaperUnknown,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            selected: {currentStatus},
            onSelectionChanged: (newSelection) {
              if (newSelection.isNotEmpty) {
                notifier.setGiayToStatus(paper.id, newSelection.first);
              }
            },
          ),
        ),
      ],
    );
  }
}
