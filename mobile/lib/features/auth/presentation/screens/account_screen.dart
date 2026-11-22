import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/auth_validators.dart';
import '../../data/repositories/auth_repository_provider.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/models/dia_phuong.dart';
import '../../../../shared/widgets/dia_phuong_picker_sheet.dart';
import '../widgets/delete_account_dialog.dart';
import '../viewmodels/auth_controller.dart';
import '../viewmodels/auth_state.dart';

final diaPhuongListProvider = FutureProvider<List<DiaPhuong>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getDiaPhuongList();
});

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  // Profile form
  final _profileFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  int? _selectedDiaPhuongId;
  bool _isSavingProfile = false;

  // Password form
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirmNew = true;
  String? _currentPasswordError;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController = TextEditingController(text: user?.tenHienThi ?? '');
    _selectedDiaPhuongId = user?.diaPhuongId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _syncUserToForm(AuthState authState) {
    if (authState.user != null) {
      if (!_isSavingProfile &&
          _nameController.text != (authState.user!.tenHienThi ?? '')) {
        _nameController.text = authState.user!.tenHienThi ?? '';
      }
      _selectedDiaPhuongId = authState.user!.diaPhuongId;
    }
  }

  Future<void> _handleSaveProfile() async {
    if (_isSavingProfile) return;
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            tenHienThi: _nameController.text.trim(),
            diaPhuongId: _selectedDiaPhuongId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.profileUpdatedSuccess),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _handleChangePassword() async {
    if (_isChangingPassword) return;

    setState(() => _currentPasswordError = null);

    if (_currentPasswordController.text.isEmpty) {
      setState(
        () => _currentPasswordError = AppStrings.errCurrentPasswordEmpty,
      );
      return;
    }

    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            matKhauHienTai: _currentPasswordController.text,
            matKhauMoi: _newPasswordController.text,
          );
      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.changePasswordSuccess),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        if (e.code == AuthErrorCode.saiMatKhauHienTai ||
            e.code == AuthErrorCode.saiThongTin) {
          setState(
            () => _currentPasswordError = AppStrings.errWrongCurrentPassword,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  void _showSelectDiaPhuongSheet(List<DiaPhuong> list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return _SelectDiaPhuongSheet(
          list: list,
          selectedId: _selectedDiaPhuongId,
          onSelected: (id) {
            setState(() => _selectedDiaPhuongId = id);
          },
        );
      },
    );
  }

  void _confirmLogout() {
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
              key: const ValueKey('confirm_logout_dialog_action'),
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

  void _showDeleteAccountDialog(String userEmail) {
    showDeleteAccountDialog(context, ref, userEmail: userEmail);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final diaPhuongAsync = ref.watch(diaPhuongListProvider);

    // Sync state when loaded
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      _syncUserToForm(next);
    });

    final diaPhuongList = diaPhuongAsync.valueOrNull ?? [];
    DiaPhuong? currentDiaPhuong;
    if (_selectedDiaPhuongId != null) {
      for (final dp in diaPhuongList) {
        if (dp.id == _selectedDiaPhuongId) {
          currentDiaPhuong = dp;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text(AppStrings.accountTitle), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!authState.isAuthenticated) ...[
                // ── Guest View ─────────────────────────────────────────────
                _buildGuestCard(context, theme),
                const SizedBox(height: 20),
              ] else ...[
                // ── Authenticated User View ────────────────────────────────
                _buildUserProfileHeader(context, theme, authState.user!),
                const SizedBox(height: 20),
                _buildEditProfileSection(
                  context,
                  theme,
                  currentDiaPhuong,
                  diaPhuongList,
                ),
                const SizedBox(height: 20),
                _buildChangePasswordSection(context, theme),
                const SizedBox(height: 20),
              ],

              // ── Theme Selection ──────────────────────────────────────────
              _buildThemeSection(context, theme, currentThemeMode),
              const SizedBox(height: 20),

              // ── Logout & Danger Zone (if authenticated) ──────────────────
              if (authState.isAuthenticated) ...[
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const ValueKey('account_logout_button'),
                    icon: Icon(Icons.logout, color: theme.colorScheme.error),
                    label: Text(
                      AppStrings.logoutButton,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: _confirmLogout,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDangerZone(context, theme, authState.user!.email),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _buildGuestCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.guestAccountPrompt,
                      style: theme.textTheme.titleMedium?.copyWith(
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    key: const ValueKey('account_login_button'),
                    onPressed: () => context.push(AppRoutes.login),
                    child: const Text(
                      AppStrings.loginButton,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    key: const ValueKey('account_register_button'),
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text(
                      AppStrings.registerButton,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader(
    BuildContext context,
    ThemeData theme,
    dynamic user,
  ) {
    final displayName = user.tenHienThi ?? '';
    final email = user.email as String;
    final firstLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'U');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              firstLetter,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isNotEmpty ? displayName : AppStrings.guestUser,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.emailReadonlyNotice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileSection(
    BuildContext context,
    ThemeData theme,
    DiaPhuong? currentDiaPhuong,
    List<DiaPhuong> diaPhuongList,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.profileSectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            // Display Name
            TextFormField(
              key: const ValueKey('profile_name_input'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.displayNameLabel,
                hintText: AppStrings.displayNameHint,
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: AuthValidators.validateDisplayName,
            ),
            const SizedBox(height: 16),
            // Location Picker
            InkWell(
              key: const ValueKey('profile_location_picker'),
              onTap: () => _showSelectDiaPhuongSheet(diaPhuongList),
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: AppStrings.locationLabel,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  currentDiaPhuong != null
                      ? currentDiaPhuong.ten
                      : AppStrings.locationNotSelected,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: currentDiaPhuong != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const ValueKey('save_profile_button'),
                onPressed: _isSavingProfile ? null : _handleSaveProfile,
                child: _isSavingProfile
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        AppStrings.saveChangesButton,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.securitySectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            // Current password
            TextFormField(
              key: const ValueKey('current_password_input'),
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: AppStrings.currentPasswordLabel,
                hintText: AppStrings.currentPasswordHint,
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                errorText: _currentPasswordError,
                suffixIcon: IconButton(
                  tooltip: AppStrings.togglePasswordVisibility,
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              onChanged: (_) {
                if (_currentPasswordError != null) {
                  setState(() => _currentPasswordError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            // New password
            TextFormField(
              key: const ValueKey('new_password_input'),
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: AppStrings.newPasswordLabel,
                hintText: AppStrings.newPasswordHint,
                prefixIcon: const Icon(Icons.lock_reset),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: AppStrings.togglePasswordVisibility,
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: AuthValidators.validatePassword,
            ),
            const SizedBox(height: 16),
            // Confirm new password
            TextFormField(
              key: const ValueKey('confirm_new_password_input'),
              controller: _confirmNewPasswordController,
              obscureText: _obscureConfirmNew,
              decoration: InputDecoration(
                labelText: AppStrings.confirmNewPasswordLabel,
                hintText: AppStrings.confirmNewPasswordHint,
                prefixIcon: const Icon(Icons.check_circle_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: AppStrings.togglePasswordVisibility,
                  icon: Icon(
                    _obscureConfirmNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirmNew = !_obscureConfirmNew),
                ),
              ),
              validator: (v) => AuthValidators.validateConfirmPassword(
                v,
                _newPasswordController.text,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const ValueKey('change_password_button'),
                onPressed: _isChangingPassword ? null : _handleChangePassword,
                child: _isChangingPassword
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        AppStrings.changePasswordButton,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    ThemeData theme,
    ThemeMode currentThemeMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.themeSectionTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<ThemeMode>(
            groupValue: currentThemeMode,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
              }
            },
            child: Column(
              children: const [
                RadioListTile<ThemeMode>(
                  key: ValueKey('theme_mode_system'),
                  value: ThemeMode.system,
                  title: Text(AppStrings.themeModeSystem),
                  secondary: Icon(Icons.brightness_auto),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<ThemeMode>(
                  key: ValueKey('theme_mode_light'),
                  value: ThemeMode.light,
                  title: Text(AppStrings.themeModeLight),
                  secondary: Icon(Icons.light_mode_outlined),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<ThemeMode>(
                  key: ValueKey('theme_mode_dark'),
                  value: ThemeMode.dark,
                  title: Text(AppStrings.themeModeDark),
                  secondary: Icon(Icons.dark_mode_outlined),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, ThemeData theme, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.dangerZoneTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.deleteAccountWarning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.tonal(
              key: const ValueKey('delete_account_button'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
              onPressed: () => _showDeleteAccountDialog(email),
              child: const Text(
                AppStrings.deleteAccountButton,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Select Dia Phuong Bottom Sheet ─────────────────────────────────────────────

typedef _SelectDiaPhuongSheet = DiaPhuongPickerSheet;
