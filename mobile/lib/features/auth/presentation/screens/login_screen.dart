import 'package:flutter/foundation.dart';
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
import '../../../../core/constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? from;

  const LoginScreen({super.key, this.from});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  String? _serverErrorBanner;
  String? _emailFieldError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onSuccessNavigate() async {
    await ref.read(authGateRepositoryProvider).markAuthGateAsSeen();
    if (!mounted) return;
    final target = sanitizeRedirectUri(widget.from);
    context.go(target);
  }

  // Future<void> _handleContinueAsGuest() async {
  //   await ref.read(authGateRepositoryProvider).markAuthGateAsSeen();
  //   if (!mounted) return;
  //   if (context.canPop()) {
  //     context.pop();
  //   } else {
  //     context.go(AppRoutes.home);
  //   }
  // }

  Future<void> _handleLogin() async {
    if (_isSubmitting) return;

    setState(() {
      _serverErrorBanner = null;
      _emailFieldError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(
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
          case AuthErrorCode.saiThongTin:
            _serverErrorBanner = AppStrings.authErrInvalidCredentialsBanner;
            break;
          case AuthErrorCode.emailDaTonTai:
            _emailFieldError = AppStrings.authErrEmailExists;
            break;
          case AuthErrorCode.taiKhoanBiKhoa:
            _serverErrorBanner = AppStrings.authErrAccountLocked;
            break;
          case AuthErrorCode.loiMang:
            _serverErrorBanner = AppStrings.authErrNetwork;
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

  void _fillDemoAccount() {
    _emailController.text = 'demo@dvcguide.vn';
    _passwordController.text = 'Demo1234';
    setState(() {
      _serverErrorBanner = null;
      _emailFieldError = null;
    });
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
            ? BackButton(onPressed: () => context.pop())
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
                      AppStrings.loginTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.loginSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Debug demo hint (kDebugMode only)
                    if (kDebugMode && AppConstants.useMockAuth) ...[
                      InkWell(
                        onTap: _isSubmitting ? null : _fillDemoAccount,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer
                                .withAlpha(120),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.tertiary.withAlpha(100),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bug_report_outlined,
                                size: 20,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppStrings.demoAccountHint,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Top Banner Error (e.g. saiThongTin or loiMang)
                    if (_serverErrorBanner != null) ...[
                      Container(
                        key: const ValueKey('server_error_banner'),
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
                                onPressed: _isSubmitting ? null : _handleLogin,
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

                    // Email input
                    TextFormField(
                      key: const ValueKey('login_email_input'),
                      controller: _emailController,
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
                      key: const ValueKey('login_password_input'),
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
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
                      onChanged: (_) {
                        if (_serverErrorBanner != null) {
                          setState(() {
                            _serverErrorBanner = null;
                          });
                        }
                      },
                      validator: AuthValidators.validatePassword,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        key: const ValueKey('login_submit_button'),
                        onPressed: _isSubmitting ? null : _handleLogin,
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
                                AppStrings.loginButton,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    // const SizedBox(height: 12),

                    // // Continue as guest button
                    // SizedBox(
                    //   height: 48,
                    //   child: OutlinedButton(
                    //     key: const ValueKey('login_guest_button'),
                    //     onPressed: _isSubmitting
                    //         ? null
                    //         : _handleContinueAsGuest,
                    //     child: const Text(
                    //       AppStrings.continueAsGuest,
                    //       style: TextStyle(
                    //         fontSize: 15,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 24),

                    // Link to register
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          AppStrings.noAccountPrompt,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('login_to_register_link'),
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  final fromParam = widget.from != null
                                      ? '?from=${Uri.encodeComponent(widget.from!)}'
                                      : '';
                                  context.push(
                                    '${AppRoutes.register}$fromParam',
                                  );
                                },
                          child: const Text(
                            AppStrings.registerLink,
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
