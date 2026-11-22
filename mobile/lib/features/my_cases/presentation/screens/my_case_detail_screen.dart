import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dvc_guide_mobile/app/router/app_router.dart';
import 'package:dvc_guide_mobile/app/theme/app_colors.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/viewmodels/my_case_detail_viewmodel.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/viewmodels/my_cases_viewmodel.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';
import 'package:dvc_guide_mobile/shared/widgets/error_widget.dart';
import 'package:dvc_guide_mobile/shared/widgets/section_card.dart';
import 'package:dvc_guide_mobile/shared/widgets/skeleton_loading.dart';


class MyCaseDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const MyCaseDetailScreen({
    super.key,
    required this.id,
  });

  @override
  ConsumerState<MyCaseDetailScreen> createState() => _MyCaseDetailScreenState();
}

class _MyCaseDetailScreenState extends ConsumerState<MyCaseDetailScreen> {
  late final TextEditingController _maHoSoController;
  late final TextEditingController _ghiChuController;
  late final FocusNode _maHoSoFocusNode;
  late final FocusNode _ghiChuFocusNode;

  bool _initializedControllers = false;
    late MyCaseDetailViewModel _notifier;
  HoSoCuaToi? _latestCase;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(myCaseDetailViewModelProvider(widget.id).notifier);
    _maHoSoController = TextEditingController();
    _ghiChuController = TextEditingController();
    _maHoSoFocusNode = FocusNode()..addListener(_onMaHoSoFocusChange);
    _ghiChuFocusNode = FocusNode()..addListener(_onGhiChuFocusChange);
  }

  @override
  void dispose() {
    _autoSaveTextInputs();
    _maHoSoFocusNode.removeListener(_onMaHoSoFocusChange);
    _ghiChuFocusNode.removeListener(_onGhiChuFocusChange);
    _maHoSoFocusNode.dispose();
    _ghiChuFocusNode.dispose();
    _maHoSoController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  void _onMaHoSoFocusChange() {
    if (!_maHoSoFocusNode.hasFocus) {
      _autoSaveTextInputs();
    }
  }

  void _onGhiChuFocusChange() {
    if (!_ghiChuFocusNode.hasFocus) {
      _autoSaveTextInputs();
    }
  }

    void _autoSaveTextInputs() {
    final currentCase = _latestCase;
    if (currentCase == null) return;

    final newMa = _maHoSoController.text.trim();
    final newGhiChu = _ghiChuController.text.trim();

    if (newMa != (currentCase.maHoSo ?? '') ||
        newGhiChu != (currentCase.ghiChu ?? '')) {
      final maHoSo = newMa.isNotEmpty ? newMa : null;
      final ghiChu = newGhiChu.isNotEmpty ? newGhiChu : null;

      // Ghi nhớ giá trị vừa lưu để lần gọi sau (PopScope rồi dispose) không lưu trùng.
      _latestCase = currentCase.copyWith(maHoSo: maHoSo, ghiChu: ghiChu);

      // Lưu cố gắng hết sức: nếu màn hình đã bị gỡ thì bỏ qua lỗi, không làm app báo đỏ.
      _notifier.updateDetails(maHoSo: maHoSo, ghiChu: ghiChu).catchError((_) {});
    }
  }

  void _syncControllersIfFirstTime(HoSoCuaToi caseItem) {
    if (!_initializedControllers) {
      _maHoSoController.text = caseItem.maHoSo ?? '';
      _ghiChuController.text = caseItem.ghiChu ?? '';
      _initializedControllers = true;
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    return '$d/$m/$y';
  }

  Future<void> _pickDate(
    BuildContext context,
    MyCaseDetailViewModel notifier, {
    required bool isSubmissionDate,
    DateTime? currentDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      locale: const Locale('vi'),
    );

    if (picked != null) {
      if (isSubmissionDate) {
        await notifier.updateDetails(ngayNop: picked);
      } else {
        await notifier.updateDetails(ngayHen: picked);
      }
    }
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    MyCaseDetailViewModel notifier,
    String currentName,
  ) async {
    final textController = TextEditingController(text: currentName);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(AppStrings.editCaseName),
              content: TextField(
                controller: textController,
                maxLength: 100,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppStrings.caseNameLabel,
                  hintText: AppStrings.caseNameHint,
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text(AppStrings.cancelAction),
                ),
                FilledButton(
                  onPressed: () {
                    final trimmed = textController.text.trim();
                    if (trimmed.isEmpty) {
                      setDialogState(() {
                        errorText = AppStrings.errCaseNameEmpty;
                      });
                      return;
                    }
                    if (trimmed.length > 100) {
                      setDialogState(() {
                        errorText = AppStrings.errCaseNameTooLong;
                      });
                      return;
                    }
                    notifier.updateName(trimmed);
                    Navigator.of(dialogCtx).pop();
                  },
                  child: const Text(AppStrings.saveAction),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    MyCaseDetailViewModel notifier,
    HoSoCuaToi caseItem,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteCaseTitle),
        content: const Text(AppStrings.deleteCaseConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancelAction),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await notifier.deleteCase();
      if (context.mounted) {
        context.go(AppRoutes.myCases);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.caseDeleted),
            action: SnackBarAction(
              label: AppStrings.undoAction,
              onPressed: () {
                ref.read(myCasesViewModelProvider.notifier).restoreCase(caseItem, 0);
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showChangeCaseBottomSheet(
    BuildContext context,
    ThuTucDetail procedure,
    int? currentTruongHopId,
    MyCaseDetailViewModel notifier,
  ) {
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
                    itemCount: procedure.truongHop.length,
                    itemBuilder: (context, index) {
                      final th = procedure.truongHop[index];
                      final isSelected = th.id == currentTruongHopId;
                      return ListTile(
                        title: Text(
                          th.ten,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        subtitle: th.cauHoiPhanLoai != null
                            ? Text(th.cauHoiPhanLoai!)
                            : (th.dieuKien != null ? Text(th.dieuKien!) : null),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                            : null,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          notifier.selectTruongHop(th.id);
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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(myCaseDetailViewModelProvider(widget.id));
    final notifier = ref.read(myCaseDetailViewModelProvider(widget.id).notifier);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.caseDetailTitle)),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonBox(width: double.infinity, height: 80),
              SizedBox(height: 16),
              SkeletonCard(),
              SizedBox(height: 16),
              SkeletonCard(),
            ],
          ),
        ),
      );
    }

    if (state.error != null || state.caseItem == null || state.procedure == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.caseDetailTitle)),
        body: AppErrorWidget(
          message: state.error ?? AppStrings.defaultErrorMessage,
          onRetry: notifier.loadCaseDetail,
        ),
      );
    }

    final caseItem = state.caseItem!;
        _latestCase = caseItem;
    final procedure = state.procedure!;
    _syncControllersIfFirstTime(caseItem);

    // Selected case name
    final selectedTruongHop = procedure.truongHop
        .where((th) => th.id == caseItem.truongHopId)
        .firstOrNull;

    // Applicable papers and paper count summary
    final applicablePapers = filterApplicablePapers(
      procedure.thanhPhanHoSo,
      caseItem.truongHopId,
    );

    int daCoCount = 0;
    int chuaCoCount = 0;
    int chuaRoCount = 0;
    for (final paper in applicablePapers) {
      final pStatus = caseItem.checklist[paper.id] ?? TrangThaiGiayTo.chuaRo;
      switch (pStatus) {
        case TrangThaiGiayTo.daCo:
          daCoCount++;
          break;
        case TrangThaiGiayTo.chuaCo:
          chuaCoCount++;
          break;
        case TrangThaiGiayTo.chuaRo:
          chuaRoCount++;
          break;
      }
    }
    final totalPapers = applicablePapers.length;
    final progress = totalPapers > 0 ? (daCoCount / totalPapers).clamp(0.0, 1.0) : 0.0;

    // Agencies display name
    final intendedAgency = procedure.coQuan
        .where((cq) => cq.coQuan.id == caseItem.coQuanDuDinhId)
        .firstOrNull
        ?.coQuan;
    final actualAgency = procedure.coQuan
        .where((cq) => cq.coQuan.id == caseItem.coQuanThucTeId)
        .firstOrNull
        ?.coQuan;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _autoSaveTextInputs();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            caseItem.tenHoSo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // Pen icon to edit case name
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.editCaseName,
              onPressed: () => _showEditNameDialog(context, notifier, caseItem.tenHoSo),
            ),
            // Menu "Xóa hồ sơ"
            PopupMenuButton<String>(
              tooltip: AppStrings.moreOptions,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmDialog(context, notifier, caseItem);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.deleteAction,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── B. Thẻ thủ tục ──────────────────────────────────────────
                SectionCard(
                  margin: const EdgeInsets.all(16),
                  onTap: () {
                    final thQuery = caseItem.truongHopId != null
                        ? '?truongHopId=${caseItem.truongHopId}'
                        : '';
                    context.push('/procedures/${caseItem.thuTuc.id}$thQuery');
                  },
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
                                  caseItem.thuTuc.maThuTuc,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  caseItem.thuTuc.ten,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${AppStrings.caseLabel}: ${selectedTruongHop?.ten ?? AppStrings.noCaseSelected}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (procedure.truongHop.length >= 2) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showChangeCaseBottomSheet(
                            context,
                            procedure,
                            caseItem.truongHopId,
                            notifier,
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: const Text(AppStrings.changeCaseAction),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── C. Thanh trạng thái 5 bước ngang cuộn được ───────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    AppStrings.statusTimeline,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: TrangThaiHoSo.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final step = TrangThaiHoSo.values[index];
                      final isCurrent = caseItem.trangThai == step;
                      return InkWell(
                        onTap: () => notifier.updateStatus(step),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCurrent) ...[
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                step.displayName,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isCurrent
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── D. Nút Kiểm tra giấy tờ & Tóm tắt ────────────────────────
                SectionCard(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  onTap: () => context.push('/my-cases/${caseItem.id}/check'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.paperStatusSummary,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$daCoCount',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  Text(
                                    AppStrings.readyCountLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$chuaCoCount',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                  Text(
                                    AppStrings.missingCountLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$chuaRoCount',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    AppStrings.unknownCountLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/my-cases/${caseItem.id}/check'),
                        icon: const Icon(Icons.checklist_rounded, size: 18),
                        label: const Text(AppStrings.checkPapersAction),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── E. Nơi dự định nộp & Nơi thực tế đã nộp ───────────────────
                SectionCard(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nơi dự định nộp
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.place_outlined, color: theme.colorScheme.primary),
                        title: const Text(
                          AppStrings.intendedAgency,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          intendedAgency?.ten ?? AppStrings.unselected,
                          style: TextStyle(
                            color: intendedAgency == null
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          await context.push(
                            '/find-agency?thuTucId=${procedure.id}&caseId=${caseItem.id}&slot=du_dinh&from=case',
                          );
                          notifier.loadCaseDetail();
                        },
                      ),
                      const Divider(height: 1),
                      // Nơi thực tế đã nộp
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.domain_outlined, color: theme.colorScheme.secondary),
                        title: const Text(
                          AppStrings.actualAgency,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          actualAgency?.ten ?? AppStrings.unselected,
                          style: TextStyle(
                            color: actualAgency == null
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          await context.push(
                            '/find-agency?thuTucId=${procedure.id}&caseId=${caseItem.id}&slot=thuc_te&from=case',
                          );
                          notifier.loadCaseDetail();
                        },
                      ),
                    ],
                  ),
                ),

                // ── F. Ngày nộp, Ngày hẹn, Mã hồ sơ, Ghi chú ──────────────────
                SectionCard(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ngày nộp picker
                      InkWell(
                        onTap: () => _pickDate(
                          context,
                          notifier,
                          isSubmissionDate: true,
                          currentDate: caseItem.ngayNop,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.event_available_outlined, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.submittedDate,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      caseItem.ngayNop != null
                                          ? _formatDate(caseItem.ngayNop!)
                                          : AppStrings.unselected,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (caseItem.ngayNop != null)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
                                  tooltip: AppStrings.clearSelection,
                                  onPressed: () => notifier.updateDetails(clearNgayNop: true),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 16),

                      // Ngày hẹn picker
                      InkWell(
                        onTap: () => _pickDate(
                          context,
                          notifier,
                          isSubmissionDate: false,
                          currentDate: caseItem.ngayHen,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.event_outlined, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.expectedReturnDate,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      caseItem.ngayHen != null
                                          ? _formatDate(caseItem.ngayHen!)
                                          : AppStrings.unselected,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (caseItem.ngayHen != null)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
                                  tooltip: AppStrings.clearSelection,
                                  onPressed: () => notifier.updateDetails(clearNgayHen: true),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24),

                      // Mã hồ sơ TextField (tự lưu khi blur / thoát, max 100)
                      TextField(
                        controller: _maHoSoController,
                        focusNode: _maHoSoFocusNode,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: AppStrings.caseCode,
                          hintText: AppStrings.caseCodeHint,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onEditingComplete: _autoSaveTextInputs,
                      ),
                      const SizedBox(height: 12),

                      // Ghi chú TextField (tự lưu khi blur / thoát, nhiều dòng)
                      TextField(
                        controller: _ghiChuController,
                        focusNode: _ghiChuFocusNode,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: AppStrings.notes,
                          hintText: AppStrings.notesHint,
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onEditingComplete: _autoSaveTextInputs,
                      ),
                    ],
                  ),
                ),

                // ── G. Nút Hỏi trợ lý về hồ sơ này ───────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      _autoSaveTextInputs();
                      context.push(AppRoutes.chat, extra: caseItem.thuTuc.maThuTuc);
                    },
                    icon: const Icon(Icons.smart_toy_outlined, size: 20),
                    label: const Text(
                      AppStrings.askAiAboutThisCase,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
