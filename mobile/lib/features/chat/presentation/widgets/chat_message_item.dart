import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dvc_guide_mobile/app/router/app_router.dart';
import 'package:dvc_guide_mobile/app/theme/app_colors.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/core/services/url_launcher_service.dart';
import 'package:dvc_guide_mobile/features/chat/data/models/chat_models.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/procedure_repository_provider.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

/// Single unified mapper and renderer for all chat message types and answer states.
class ChatMessageItem extends ConsumerWidget {
  final TinNhan message;
  final bool? feedbackValue; // true: helpful, false: unhelpful, null: not set
  final Function(bool isHelpful, {String? note}) onToggleFeedback;
  final String? lastUserQuestion;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.feedbackValue,
    required this.onToggleFeedback,
    this.lastUserQuestion,
  });

  void _showDebugInfo(BuildContext context) {
    if (!kDebugMode) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'AI Debug Metadata (kDebugMode only)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _debugRow(AppStrings.debugDiemTop1, '${message.diemTop1 ?? "null"}'),
                _debugRow(AppStrings.debugDoTreMs, '${message.doTreMs ?? "null"} ms'),
                _debugRow(AppStrings.debugModelPhienBan, message.modelPhienBan ?? 'null'),
                _debugRow(AppStrings.debugTrangThai, '${message.trangThaiTraLoi?.name}'),
                _debugRow(AppStrings.debugNguonTrichDan, '${message.nguonTrichDan}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  void _showFeedbackNoteSheet(BuildContext context) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.feedbackSheetTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: AppStrings.feedbackSheetHint,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final note = textController.text.trim();
                    Navigator.pop(context);
                    onToggleFeedback(false, note: note.isNotEmpty ? note : null);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text(AppStrings.feedbackSubmit),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.vaiTro == VaiTroTinNhan.user;

    if (isUser) {
      return _buildUserBubble(context);
    } else {
      // Map and render assistant responses by trangThaiTraLoi
      return _mapAssistantAnswerByState(context, ref);
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: SelectableText(
          message.noiDung,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  /// Single centralized mapper for all AI response states
  Widget _mapAssistantAnswerByState(BuildContext context, WidgetRef ref) {
    final state = message.trangThaiTraLoi ?? TrangThaiTraLoi.answered;

    switch (state) {
      case TrangThaiTraLoi.gate:
        return _buildGateCard(context);
      case TrangThaiTraLoi.guard:
        return _buildGuardCard(context);
      case TrangThaiTraLoi.model:
        return _buildStandardBubble(context, ref, showModelDisclaimer: true);
      case TrangThaiTraLoi.answered:
        return _buildStandardBubble(context, ref, showModelDisclaimer: false);
    }
  }

  // ── State: gate (Chưa tìm thấy thông tin phù hợp) ───────────────────────────
  Widget _buildGateCard(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.gateCardTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.gateCardSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                final query = lastUserQuestion ?? '';
                context.go(query.isNotEmpty
                    ? '${AppRoutes.home}?q=${Uri.encodeComponent(query)}'
                    : AppRoutes.home);
              },
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text(AppStrings.searchInProceduresAction),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            _buildFeedbackButtons(context),
          ],
        ),
      ),
    );
  }

  // ── State: guard (Ngoài phạm vi hỗ trợ) ─────────────────────────────────────
  Widget _buildGuardCard(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.error.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.guardCardTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.guardCardSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── State: answered / model ────────────────────────────────────────────────
  Widget _buildStandardBubble(
    BuildContext context,
    WidgetRef ref, {
    required bool showModelDisclaimer,
  }) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showDebugInfo(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Answer Text (plain text preserving newlines, selectable)
              SelectableText(
                message.noiDung,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.45,
                ),
              ),

              // Model Disclaimer line if state is model
              if (showModelDisclaimer) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppStrings.modelDisclaimer,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Citations list (from nguonTrichDan)
              if (message.nguonTrichDan.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(
                  AppStrings.citationsLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: message.nguonTrichDan.map((maThuTuc) {
                    return _buildCitationChip(context, ref, maThuTuc);
                  }).toList(),
                ),
                const SizedBox(height: 10),
                _buildViewFullAndFormButtons(context, ref, message.nguonTrichDan.first),
              ],

              // Helpful Feedback buttons (OutlinedButtons >= 48dp)
              const SizedBox(height: 12),
              _buildFeedbackButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackButtons(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => onToggleFeedback(true),
          icon: Icon(
            feedbackValue == true
                ? Icons.thumb_up_rounded
                : Icons.thumb_up_outlined,
            size: 18,
            color: feedbackValue == true
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          label: Text(
            AppStrings.feedbackHelpful,
            style: TextStyle(
              color: feedbackValue == true
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: feedbackValue == true ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: BorderSide(
              color: feedbackValue == true
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: feedbackValue == true ? 1.5 : 1.0,
            ),
            backgroundColor: feedbackValue == true
                ? theme.colorScheme.primaryContainer.withAlpha(80)
                : null,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            onToggleFeedback(false);
            _showFeedbackNoteSheet(context);
          },
          icon: Icon(
            feedbackValue == false
                ? Icons.thumb_down_rounded
                : Icons.thumb_down_outlined,
            size: 18,
            color: feedbackValue == false
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
          label: Text(
            AppStrings.feedbackNotCorrect,
            style: TextStyle(
              color: feedbackValue == false
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
              fontWeight: feedbackValue == false ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: BorderSide(
              color: feedbackValue == false
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
              width: feedbackValue == false ? 1.5 : 1.0,
            ),
            backgroundColor: feedbackValue == false
                ? theme.colorScheme.errorContainer.withAlpha(80)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildViewFullAndFormButtons(
    BuildContext context,
    WidgetRef ref,
    String maThuTuc,
  ) {
    final theme = Theme.of(context);
    final repo = ref.read(procedureRepositoryProvider);

    return FutureBuilder<ThuTucDetail?>(
      future: repo.getProcedureByMa(maThuTuc),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final procedure = snapshot.data;
        final isUnavailable = !isLoading && procedure == null;

        // Find first real form url in procedure if any (not null and not containing example.com)
        String? realFormUrl;
        if (procedure != null) {
          for (final paper in procedure.thanhPhanHoSo) {
            final bm = paper.bieuMau;
            if (bm != null) {
              if (bm.fileDocxUrl != null &&
                  bm.fileDocxUrl!.trim().isNotEmpty &&
                  !bm.fileDocxUrl!.contains('example.com')) {
                realFormUrl = bm.fileDocxUrl;
                break;
              }
              if (bm.filePdfUrl != null &&
                  bm.filePdfUrl!.trim().isNotEmpty &&
                  !bm.filePdfUrl!.contains('example.com')) {
                realFormUrl = bm.filePdfUrl;
                break;
              }
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: (!isLoading && procedure != null)
                      ? () => context.push(AppRoutes.procedureDetailPath(procedure.id))
                      : null,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text(AppStrings.viewFullProcedure),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
                if (realFormUrl != null)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(realFormUrl!);
                      final launcher = ref.read(urlLauncherServiceProvider);
                      final success = uri != null && await launcher.open(uri);
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.cannotOpenLinkNotice),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(AppStrings.downloadTemplateAction),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
              ],
            ),
            if (isUnavailable)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  AppStrings.sourceUnavailable,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCitationChip(BuildContext context, WidgetRef ref, String maThuTuc) {
    final theme = Theme.of(context);
    final repo = ref.read(procedureRepositoryProvider);

    return FutureBuilder(
      future: repo.getProcedureByMa(maThuTuc),
      builder: (context, snapshot) {
        final procedure = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Chip(
            avatar: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            label: Text(maThuTuc),
            visualDensity: VisualDensity.compact,
          );
        }

        if (procedure == null) {
          // Disabled chip if not found
          return ActionChip(
            avatar: const Icon(Icons.link_off_rounded, size: 14),
            label: const Text(AppStrings.sourceUnavailable),
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            onPressed: null,
            visualDensity: VisualDensity.compact,
          );
        }

        return ActionChip(
          avatar: Icon(Icons.description_outlined, size: 14, color: theme.colorScheme.primary),
          label: Text(
            procedure.ten,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: theme.colorScheme.primaryContainer.withAlpha(120),
          onPressed: () {
            context.push(AppRoutes.procedureDetailPath(procedure.id));
          },
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }
}
