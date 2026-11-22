import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/entry_route_resolver.dart';
import '../../../auth/data/repositories/auth_gate_repository.dart';
import '../../../auth/presentation/viewmodels/auth_controller.dart';
import '../../../auth/presentation/viewmodels/auth_state.dart';
import '../../../my_cases/presentation/viewmodels/reminder_coordinator.dart';
import '../../data/repositories/onboarding_repository.dart';

/// Splash screen shown at app start.
///
/// Waits for [AuthController] to restore session (or up to 3s timeout), then
/// checks onboarding and auth gate status using [resolveEntryRoute].
/// A minimum delay of ~600 ms prevents a flash on fast devices.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final stopwatch = Stopwatch()..start();

    // 1. Wait until AuthController restores session (status != AuthStatus.initial)
    // with a maximum timeout of ~3 seconds (fallback to guest).
    AuthStatus status = ref.read(authControllerProvider).status;
    if (status == AuthStatus.initial) {
      final completer = Completer<AuthStatus>();
      final sub = ref.listenManual<AuthState>(
        authControllerProvider,
        (previous, next) {
          if (next.status != AuthStatus.initial && !completer.isCompleted) {
            completer.complete(next.status);
          }
        },
      );
      try {
        status = await completer.future.timeout(const Duration(seconds: 3));
      } catch (_) {
        status = AuthStatus.guest;
      } finally {
        sub.close();
      }
    }

    final onboardingSeen =
        ref.read(onboardingRepositoryProvider).hasSeenOnboarding();
    final authGateSeen =
        ref.read(authGateRepositoryProvider).hasSeenAuthGate();

    // 2. Ensure minimum delay of ~600 ms
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 600) {
      await Future<void>.delayed(Duration(milliseconds: 600 - elapsed));
    }
    if (!mounted) return;

    final pendingCaseId =
        ref.read(reminderServiceProvider).consumePendingLaunchPayload();
    if (pendingCaseId != null && pendingCaseId.isNotEmpty) {
      context.go(AppRoutes.myCaseDetailPath(pendingCaseId));
      return;
    }

    final targetRoute = resolveEntryRoute(
      onboardingSeen: onboardingSeen,
      authGateSeen: authGateSeen,
      status: status,
    );
    context.go(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              // App name
              Text(
                AppStrings.appName,
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              Text(
                AppStrings.appTagline,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
