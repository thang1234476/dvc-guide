import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../features/procedure/data/models/procedure_models.dart';

/// Reusable information row respecting strict NULL display rules.
class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? customValueWidget;
  final IconData? icon;

  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.customValueWidget,
    this.icon,
  });

  /// Helper to format currency (e.g. 200000 -> "200.000 đ")
  static String formatCurrency(double amount, [String? currency = 'VND']) {
    final intVal = amount.toInt();
    final str = intVal.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    final formatted = buffer.toString().split('').reversed.join();
    return currency == 'VND' || currency == null ? '$formatted đ' : '$formatted $currency';
  }

  /// Format Fee text according to strict legal null rules
  static String formatFee(LePhi fee) {
    if (fee.mienPhi) {
      return AppStrings.freeOfCharge;
    }
    if (fee.soTien != null) {
      return formatCurrency(fee.soTien!, fee.tienTe);
    }
    // mien_phi = false and so_tien = null
    return AppStrings.feeUnknown;
  }

  /// Format Timeline according to strict legal null rules
  static String formatTimeline({
    double? thoiHanSo,
    String? thoiHanDonVi,
    String? thoiHanGoc,
  }) {
    // Has number and unit
    if (thoiHanSo != null && thoiHanDonVi != null && thoiHanDonVi.trim().isNotEmpty) {
      final numberStr = thoiHanSo % 1 == 0 ? thoiHanSo.toInt().toString() : thoiHanSo.toString();
      return '$numberStr $thoiHanDonVi';
    }
    // Has number but no unit -> use thoiHanGoc if present
    if (thoiHanGoc != null && thoiHanGoc.trim().isNotEmpty) {
      return thoiHanGoc;
    }
    // If thoiHanDonVi and thoiHanGoc are both null, even if thoiHanSo is present, show "Chưa có thông tin"
    return AppStrings.timelineUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: customValueWidget ??
                Text(
                  hasValue ? value! : AppStrings.notProvided,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasValue
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant.withAlpha(150),
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
