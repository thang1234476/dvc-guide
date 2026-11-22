import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dvc_guide_mobile/app/router/app_router.dart';
import 'package:dvc_guide_mobile/core/constants/app_constants.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/core/providers/shared_preferences_provider.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/auth_controller.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/widgets/delete_account_dialog.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/viewmodels/reminder_coordinator.dart';
import 'package:dvc_guide_mobile/shared/widgets/section_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _remindScheduleEnabled;

  @override
  void initState() {
    super.initState();
    // Default is true
    final prefs = ref.read(sharedPreferencesProvider);
    _remindScheduleEnabled = prefs.getBool(AppConstants.kRemindScheduleKey) ?? true;
  }

  Future<void> _toggleRemindSchedule(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (value) {
      final granted = await ref.read(reminderServiceProvider).requestPermission();
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _remindScheduleEnabled = false;
        });
        await prefs.setBool(AppConstants.kRemindScheduleKey, false);
        _showPermissionDeniedDialog();
        return;
      }
    }

    await prefs.setBool(AppConstants.kRemindScheduleKey, value);
    if (!mounted) return;
    setState(() {
      _remindScheduleEnabled = value;
    });

    await ref.read(reminderCoordinatorProvider).onToggleChanged(value);
  }

  void _showPermissionDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(AppStrings.notificationPermissionRequiredTitle),
        content: const Text(AppStrings.notificationPermissionDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(AppStrings.closeAction),
          ),
        ],
      ),
    );
  }

  void _showConfirmLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.confirmLogoutTitle),
          content: const Text(AppStrings.confirmLogoutContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.cancelAction),
            ),
            FilledButton(
              key: const ValueKey('settings_confirm_logout_dialog_action'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(authControllerProvider.notifier).logout();
              },
              child: const Text(AppStrings.logoutConfirmAction),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isRemindOn = _remindScheduleEnabled ??
        (ref.watch(sharedPreferencesProvider).getBool(AppConstants.kRemindScheduleKey) ?? true);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // 1. Nhóm Tài khoản
            SectionCard(
              icon: Icons.person_outline_rounded,
              title: AppStrings.accountTitle,
              child: authState.isAuthenticated && user != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.tenHienThi != null && user.tenHienThi!.isNotEmpty) ...[
                          Text(
                            user.tenHienThi!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        ListTile(
                          key: const ValueKey('manage_account_tile'),
                          contentPadding: EdgeInsets.zero,
                          minVerticalPadding: 14,
                          leading: Icon(
                            Icons.manage_accounts_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            AppStrings.manageAccount,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(AppRoutes.account),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.guestAccountPrompt,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.guestAccountSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                key: const ValueKey('settings_login_button'),
                                onPressed: () => context.push(AppRoutes.login),
                                icon: const Icon(Icons.login_rounded, size: 18),
                                label: const Text(AppStrings.loginButton),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const ValueKey('settings_register_button'),
                                onPressed: () => context.push(AppRoutes.register),
                                icon: const Icon(Icons.person_add_outlined, size: 18),
                                label: const Text(AppStrings.registerButton),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 8),

            // 2. Nhóm Tùy chọn & Tiện ích (Nhắc lịch, Lịch sử trò chuyện)
            SectionCard(
              icon: Icons.tune_rounded,
              title: 'Tùy chọn & Tiện ích',
              child: Column(
                children: [
                  // Công tắc "Nhắc lịch"
                  SwitchListTile(
                    key: const ValueKey('remind_schedule_switch'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      AppStrings.remindSchedule,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.remindScheduleNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.remindScheduleDetails,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    value: isRemindOn,
                    onChanged: _toggleRemindSchedule,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const ValueKey('test_notification_button'),
                      onPressed: () async {
                        await ref.read(reminderServiceProvider).showTestIn(const Duration(seconds: 10));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppStrings.testNotificationScheduled),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_active_outlined, size: 18),
                      label: const Text(AppStrings.testNotificationButton),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                  const Divider(height: 1),

                  // Quản lý lịch sử trò chuyện
                  ListTile(
                    key: const ValueKey('manage_chat_history_tile'),
                    contentPadding: EdgeInsets.zero,
                    minVerticalPadding: 14,
                    leading: Icon(
                      Icons.history_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      AppStrings.manageChatHistory,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      AppStrings.chatHistoryLocalNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.chatHistory),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. Nhóm Dữ liệu & Phản hồi
            SectionCard(
              icon: Icons.storage_rounded,
              title: 'Dữ liệu & Đóng góp',
              child: Column(
                children: [
                  // Xóa hồ sơ hoặc toàn bộ dữ liệu cá nhân
                  ListTile(
                    key: const ValueKey('delete_data_tile'),
                    contentPadding: EdgeInsets.zero,
                    minVerticalPadding: 14,
                    leading: Icon(
                      Icons.delete_sweep_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      AppStrings.deleteDataOrCases,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.deleteData),
                  ),
                  const Divider(height: 1),

                  // Gửi góp ý, báo lỗi
                  ListTile(
                    key: const ValueKey('feedback_tile'),
                    contentPadding: EdgeInsets.zero,
                    minVerticalPadding: 14,
                    leading: Icon(
                      Icons.feedback_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      AppStrings.sendFeedbackOrReport,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.feedback),
                  ),
                ],
              ),
            ),

            // 4. Nhóm Đăng xuất & Xóa tài khoản (Chỉ khi đã đăng nhập)
            if (authState.isAuthenticated && user != null) ...[
              const SizedBox(height: 8),
              SectionCard(
                icon: Icons.shield_outlined,
                title: AppStrings.dangerZoneTitle,
                child: Column(
                  children: [
                    // Đăng xuất
                    ListTile(
                      key: const ValueKey('settings_logout_button'),
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: 14,
                      leading: Icon(
                        Icons.logout_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        AppStrings.logoutButton,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showConfirmLogoutDialog(context),
                    ),
                    const Divider(height: 1),

                    // Xóa tài khoản
                    ListTile(
                      key: const ValueKey('delete_account_button'),
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: 14,
                      leading: Icon(
                        Icons.delete_forever_rounded,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        AppStrings.deleteAccountButton,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.error,
                      ),
                      onTap: () => showDeleteAccountDialog(
                        context,
                        ref,
                        userEmail: user.email,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 5. Về ứng dụng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${AppConstants.appName} v${AppConstants.appVersion}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.appDisclaimer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
