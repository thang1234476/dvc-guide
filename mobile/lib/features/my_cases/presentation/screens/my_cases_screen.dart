import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dvc_guide_mobile/app/router/app_router.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/procedure/data/mock/procedure_mock_data.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';
import 'package:dvc_guide_mobile/shared/widgets/empty_state.dart';
import 'package:dvc_guide_mobile/shared/widgets/error_widget.dart';
import 'package:dvc_guide_mobile/shared/widgets/section_card.dart';
import 'package:dvc_guide_mobile/shared/widgets/skeleton_loading.dart';
import 'package:dvc_guide_mobile/shared/widgets/status_chip.dart';
import '../viewmodels/my_cases_viewmodel.dart';

class MyCasesScreen extends ConsumerWidget {
  const MyCasesScreen({super.key});

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    return '$d/$m/$y';
  }

  Widget? _buildDeadlineBadge(
    BuildContext context,
    DateTime? returnDate,
    TrangThaiHoSo status,
  ) {
    if (returnDate == null || status == TrangThaiHoSo.daNhanKetQua) {
      return null;
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(
      returnDate.year,
      returnDate.month,
      returnDate.day,
    );
    final difference = deadline.difference(today).inDays;

    String label;
    Color bgColor;
    Color textColor;

    if (difference < 0) {
      label = AppStrings.overdueBadge;
      bgColor = theme.colorScheme.errorContainer;
      textColor = theme.colorScheme.onErrorContainer;
    } else if (difference == 0) {
      label = AppStrings.dueTodayBadge;
      bgColor = theme.colorScheme.errorContainer;
      textColor = theme.colorScheme.onErrorContainer;
    } else {
      label =
          '${AppStrings.remainingDaysPrefix} $difference ${AppStrings.daysSuffix}';
      bgColor = theme.colorScheme.secondaryContainer;
      textColor = theme.colorScheme.onSecondaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(myCasesViewModelProvider);
    final notifier = ref.read(myCasesViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text(AppStrings.myCasesTitle), elevation: 0),
      body: SafeArea(
        child: state.isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (_, _) => const SkeletonCard(),
              )
            : state.error != null
            ? AppErrorWidget(message: state.error!, onRetry: notifier.loadCases)
            : state.cases.isEmpty
            ? EmptyStateWidget(
                icon: Icons.folder_open_outlined,
                title: AppStrings.emptyMyCasesTitle,
                subtitle: AppStrings.emptyMyCasesSubtitle,
                actionLabel: AppStrings.findProcedureAction,
                onAction: () => context.go(AppRoutes.home),
              )
            : RefreshIndicator(
                onRefresh: notifier.loadCases,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: state.cases.length,
                  itemBuilder: (context, index) {
                    final caseItem = state.cases[index];
                    return _buildDismissibleCaseItem(
                      context,
                      caseItem,
                      index,
                      notifier,
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildDismissibleCaseItem(
    BuildContext context,
    HoSoCuaToi caseItem,
    int index,
    MyCasesViewModel notifier,
  ) {
    final theme = Theme.of(context);

    // Resolve procedure detail & applicable papers
    final detail = mockProcedureDetails
        .where((p) => p.id == caseItem.thuTuc.id)
        .firstOrNull;

    final applicablePapers = filterApplicablePapers(
      detail?.thanhPhanHoSo ?? [],
      caseItem.truongHopId,
    );

    final totalPapers = applicablePapers.length;
    final readyCount = applicablePapers
        .where((p) => caseItem.checklist[p.id] == TrangThaiGiayTo.daCo)
        .length;
    final progress = totalPapers > 0
        ? (readyCount / totalPapers).clamp(0.0, 1.0)
        : 0.0;

    final deadlineBadge = _buildDeadlineBadge(
      context,
      caseItem.ngayHen,
      caseItem.trangThai,
    );

    return Dismissible(
      key: Key(caseItem.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onError,
          size: 28,
        ),
      ),
      onDismissed: (_) {
        notifier.deleteCase(caseItem, index, context);
      },
      child: SectionCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () => context.push(AppRoutes.myCaseDetailPath(caseItem.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with status chip and deadline badge
            Row(
              children: [
                StatusChip.caseStatus(context, caseItem.trangThai),
                const Spacer(),
                ?deadlineBadge,
              ],
            ),
            const SizedBox(height: 8),

            // tenHoSo (tiêu đề)
            Text(
              caseItem.tenHoSo,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // tên và mã thủ tục (phụ)
            Text(
              caseItem.thuTuc.ten,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              caseItem.thuTuc.maThuTuc,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Mức độ chuẩn bị "x/y giấy tờ đã có" kèm thanh tiến độ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$readyCount/$totalPapers ${AppStrings.papersReadySuffix}',
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),

            if (caseItem.ngayHen != null &&
                caseItem.trangThai != TrangThaiHoSo.daNhanKetQua) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${AppStrings.returnDeadlinePrefix}: ${_formatDate(caseItem.ngayHen!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
