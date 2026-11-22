import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/auth_validators.dart';
import '../../../../core/utils/redirect_utils.dart';
import '../../data/repositories/auth_gate_repository.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../viewmodels/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? from;

  const RegisterScreen({super.key, this.from});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String? _termsError;

  String? _serverErrorBanner;
  String? _emailFieldError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onSuccessNavigate() async {
    await ref.read(authGateRepositoryProvider).markAuthGateAsSeen();
    if (!mounted) return;
    final target = sanitizeRedirectUri(widget.from);
    context.go(target);
  }

  void _showTermsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.termsBottomSheetTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        AppStrings.termsSampleText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.termsBottomSheetClose),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleRegister() async {
    if (_isSubmitting) return;

    setState(() {
      _serverErrorBanner = null;
      _emailFieldError = null;
      _termsError = _agreedToTerms ? null : AppStrings.errMustAgreeTerms;
    });

    final isFormValid = _formKey.currentState!.validate();
    if (!isFormValid || !_agreedToTerms) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            tenHienThi: _nameController.text.trim(),
            email: _emailController.text.trim(),
            matKhau: _passwordController.text,
          );
      if (mounted) {
        _onSuccessNavigate();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        switch (e.code) {
          case AuthErrorCode.emailDaTonTai:
            _emailFieldError = AppStrings.authErrEmailExists;
            break;
          case AuthErrorCode.loiMang:
            _serverErrorBanner = AppStrings.authErrNetwork;
            break;
          case AuthErrorCode.saiThongTin:
            _serverErrorBanner = AppStrings.authErrInvalidCredentialsBanner;
            break;
          case AuthErrorCode.taiKhoanBiKhoa:
            _serverErrorBanner = AppStrings.authErrAccountLocked;
            break;
                    case AuthErrorCode.saiMatKhauHienTai:
            _serverErrorBanner = AppStrings.authErrUnknown;
            break;
          case AuthErrorCode.khac:
            _serverErrorBanner = e.message.isNotEmpty
                ? e.message
                : AppStrings.authErrUnknown;
            break;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serverErrorBanner = AppStrings.authErrUnknown;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNetworkError = _serverErrorBanner == AppStrings.authErrNetwork;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? BackButton(
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title & Subtitle
                    Text(
                      AppStrings.registerTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.registerSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Top Banner Error (e.g. loiMang)
                    if (_serverErrorBanner != null) ...[
                      Container(
                        key: const ValueKey('register_error_banner'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 20,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _serverErrorBanner!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (isNetworkError)
                              TextButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _handleRegister,
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      theme.colorScheme.onErrorContainer,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  AppStrings.retry,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Display Name input
                    TextFormField(
                      key: const ValueKey('register_name_input'),
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: AppStrings.displayNameLabel,
                        hintText: AppStrings.displayNameHint,
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: AuthValidators.validateDisplayName,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_emailFocusNode);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email input
                    TextFormField(
                      key: const ValueKey('register_email_input'),
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      decoration: InputDecoration(
                        labelText: AppStrings.emailLabel,
                        hintText: AppStrings.emailHint,
                        prefixIcon: const Icon(Icons.email_outlined),
                        errorText: _emailFieldError,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        if (_emailFieldError != null ||
                            _serverErrorBanner != null) {
                          setState(() {
                            _emailFieldError = null;
                            _serverErrorBanner = null;
                          });
                        }
                      },
                      validator: AuthValidators.validateEmail,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password input
                    TextFormField(
                      key: const ValueKey('register_password_input'),
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: AppStrings.passwordLabel,
                        hintText: AppStrings.passwordHint,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: AppStrings.togglePasswordVisibility,
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: AuthValidators.validatePassword,
                      onFieldSubmitted: (_) {
                        FocusScope.of(
                          context,
                        ).requestFocus(_confirmPasswordFocusNode);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password input
                    TextFormField(
                      key: const ValueKey('register_confirm_password_input'),
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: AppStrings.confirmPasswordLabel,
                        hintText: AppStrings.confirmPasswordHint,
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: AppStrings.togglePasswordVisibility,
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) => AuthValidators.validateConfirmPassword(
                        v,
                        _passwordController.text,
                      ),
                      onFieldSubmitted: (_) => _handleRegister(),
                    ),
                    const SizedBox(height: 16),

                    // Terms Checkbox & Link
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              key: const ValueKey('register_terms_checkbox'),
                              value: _agreedToTerms,
                              onChanged: (val) {
                                setState(() {
                                  _agreedToTerms = val ?? false;
                                  if (_agreedToTerms) {
                                    _termsError = null;
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${AppStrings.termsAgreement} ',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  InkWell(
                                    onTap: _showTermsBottomSheet,
                                    child: Text(
                                      AppStrings.termsAndConditions,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_termsError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              _termsError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        key: const ValueKey('register_submit_button'),
                        onPressed: _isSubmitting ? null : _handleRegister,
                        child: _isSubmitting
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Text(
                                AppStrings.registerButton,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Link to Login
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          AppStrings.alreadyHaveAccountPrompt,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('register_to_login_link'),
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    final fromParam = widget.from != null
                                        ? '?from=${Uri.encodeComponent(widget.from!)}'
                                        : '';
                                    context.go('${AppRoutes.login}$fromParam');
                                  }
                                },
                          child: const Text(
                            AppStrings.loginLink,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
