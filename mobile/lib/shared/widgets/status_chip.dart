import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../enums/procedure_enums.dart';

/// Reusable status chip supporting administrative levels, document status, and required badges.
class StatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  /// Factory for Administrative Level (CapCoQuan)
  factory StatusChip.administrativeLevel(BuildContext context, CapCoQuan level) {
    final theme = Theme.of(context);
    return StatusChip(
      label: level.displayName,
      backgroundColor: theme.colorScheme.secondaryContainer,
      textColor: theme.colorScheme.onSecondaryContainer,
      icon: Icons.account_balance_outlined,
    );
  }

  /// Factory for Legal Document Validity (TrangThaiHieuLuc)
  factory StatusChip.legalValidity(BuildContext context, TrangThaiHieuLuc status) {
    switch (status) {
      case TrangThaiHieuLuc.conHieuLuc:
        return StatusChip(
          label: AppStrings.statusValid,
          backgroundColor: AppColors.success.withAlpha(30),
          textColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case TrangThaiHieuLuc.hetHieuLuc:
        return StatusChip(
          label: AppStrings.statusInvalid,
          backgroundColor: AppColors.error.withAlpha(30),
          textColor: AppColors.error,
          icon: Icons.cancel_outlined,
        );
      case TrangThaiHieuLuc.chuaXacMinh:
        return StatusChip(
          label: AppStrings.statusUnverified,
          backgroundColor: AppColors.warning.withAlpha(30),
          textColor: AppColors.warning,
          icon: Icons.help_outline,
        );
    }
  }

  /// Factory for Case Tracking Status (TrangThaiHoSo)
  factory StatusChip.caseStatus(BuildContext context, TrangThaiHoSo status) {
    final theme = Theme.of(context);
    switch (status) {
      case TrangThaiHoSo.dangChuanBi:
        return StatusChip(
          label: status.displayName,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          textColor: theme.colorScheme.onSurfaceVariant,
          icon: Icons.hourglass_top_rounded,
        );
      case TrangThaiHoSo.daNop:
        return StatusChip(
          label: status.displayName,
          backgroundColor: theme.colorScheme.secondaryContainer,
          textColor: theme.colorScheme.onSecondaryContainer,
          icon: Icons.send_rounded,
        );
      case TrangThaiHoSo.dangXuLy:
        return StatusChip(
          label: status.displayName,
          backgroundColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
          icon: Icons.sync_rounded,
        );
      case TrangThaiHoSo.canBoSung:
        return StatusChip(
          label: status.displayName,
          backgroundColor: theme.colorScheme.errorContainer,
          textColor: theme.colorScheme.onErrorContainer,
          icon: Icons.warning_amber_rounded,
        );
      case TrangThaiHoSo.daNhanKetQua:
        return StatusChip(
          label: status.displayName,
          backgroundColor: theme.colorScheme.tertiaryContainer,
          textColor: theme.colorScheme.onTertiaryContainer,
          icon: Icons.task_alt_rounded,
        );
    }
  }

  /// Factory for Paper Status (TrangThaiGiayTo)
  factory StatusChip.paperStatus(BuildContext context, TrangThaiGiayTo status) {
    final theme = Theme.of(context);
    switch (status) {
      case TrangThaiGiayTo.daCo:
        return StatusChip(
          label: status.displayName,
          backgroundColor: theme.colorScheme.primaryContainer,
          textColor: theme.colorScheme.onPrimaryContainer,
          icon: Icons.check_circle_outline,
        );
      case TrangThaiGiayTo.chuaCo:
        return StatusChip(
          label: status.displayName,
          backgroundColor: theme.colorScheme.errorContainer,
          textColor: theme.colorScheme.onErrorContainer,
          icon: Icons.cancel_outlined,
        );
      case TrangThaiGiayTo.chuaRo:
        return StatusChip(
          label: status.displayName,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          textColor: theme.colorScheme.onSurfaceVariant,
          icon: Icons.help_outline,
        );
    }
  }

  /// Factory for Requirement Badge (batBuoc: bool?)
  /// NULL returns an empty SizedBox per strict legal null semantics!
  static Widget requirementBadge(BuildContext context, bool? isRequired) {
    if (isRequired == null) {
      return const SizedBox.shrink();
    }
    if (isRequired) {
      return StatusChip(
        label: AppStrings.requiredBadge,
        backgroundColor: AppColors.error.withAlpha(30),
        textColor: AppColors.error,
      );
    } else {
      return StatusChip(
        label: AppStrings.optionalBadge,
        backgroundColor: AppColors.info.withAlpha(30),
        textColor: AppColors.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
