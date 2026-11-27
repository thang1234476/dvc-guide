import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../viewmodels/auth_controller.dart';

Future<void> showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref, {
  required String userEmail,
}) {
  final confirmController = TextEditingController();
  String? localError;
  bool isSubmitting = false;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);

          return AlertDialog(
            title: Text(
              AppStrings.deleteAccountDialogTitle,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withAlpha(120),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppStrings.deleteAccountWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.deleteAccountConfirmPrompt,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('delete_account_confirm_input'),
                    controller: confirmController,
                    decoration: InputDecoration(
                      hintText: AppStrings.deleteAccountInputHint,
                      errorText: localError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text(AppStrings.cancelAction),
              ),
              FilledButton(
                key: const ValueKey('delete_account_confirm_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final input = confirmController.text.trim();
                        if (input.isEmpty) {
                          setDialogState(() {
                            localError =
                                AppStrings.errDeleteAccountInputMismatch;
                          });
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);

                        setDialogState(() {
                          isSubmitting = true;
                          localError = null;
                        });

                        try {
                          await ref
                              .read(authControllerProvider.notifier)
                              .deleteAccount(
                                email: userEmail,
                                matKhau: input,
                              );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(AppStrings.deleteAccountSuccess),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } on AuthException {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            isSubmitting = false;
                            localError =
                                AppStrings.errDeleteAccountInputMismatch;
                          });
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            isSubmitting = false;
                            localError = e.toString();
                          });
                        }
                      },
                child: isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onError,
                        ),
                      )
                    : const Text(AppStrings.deleteAccountConfirmAction),
              ),
            ],
          );
        },
      );
    },
  );
}
