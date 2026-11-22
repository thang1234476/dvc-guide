import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/entry_route_resolver.dart';
import '../../../auth/data/repositories/auth_gate_repository.dart';
import '../../../auth/presentation/viewmodels/auth_controller.dart';
import '../../data/repositories/onboarding_repository.dart';

/// Onboarding screen with 3 pages presented as a [PageView].
///
/// Each page contains a self-built illustration (Icon + shapes from Theme),
/// a title, and a description. Navigation controls:
///   - Custom dot indicator (active dot stretches).
///   - "Tiếp" button to advance; "Bắt đầu" on the last page.
///   - "Bỏ qua" button in the top-right corner (hidden on the last page).
///
/// On completion (or skip), marks onboarding as seen via [OnboardingRepository]
/// and navigates to [AppRoutes.home] with [context.go] so this screen is not
/// kept in the back stack.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const int _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final repo = ref.read(onboardingRepositoryProvider);
    await repo.markOnboardingAsSeen();
    if (!mounted) return;

    final authGateRepo = ref.read(authGateRepositoryProvider);
    final authState = ref.read(authControllerProvider);
    final target = resolveEntryRoute(
      onboardingSeen: true,
      authGateSeen: authGateRepo.hasSeenAuthGate(),
      status: authState.status,
    );
    context.go(target);
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  bool get _isLastPage => _currentPage == _pageCount - 1;

  // ── Page data ───────────────────────────────────────────────────────────────

  static const List<_PageData> _pages = [
    _PageData(
      title: AppStrings.onboardingPage1Title,
      description: AppStrings.onboardingPage1Desc,
      illustrationType: _IllustrationType.search,
    ),
    _PageData(
      title: AppStrings.onboardingPage2Title,
      description: AppStrings.onboardingPage2Desc,
      illustrationType: _IllustrationType.ai,
    ),
    _PageData(
      title: AppStrings.onboardingPage3Title,
      description: AppStrings.onboardingPage3Desc,
      illustrationType: _IllustrationType.tracking,
    ),
  ];

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Page content ─────────────────────────────────────────────────
            PageView.builder(
              controller: _pageController,
              itemCount: _pageCount,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return _OnboardingPage(
                  data: _pages[index],
                  isLast: index == _pageCount - 1,
                );
              },
            ),

            // ── Top-right skip button ─────────────────────────────────────────
            if (!_isLastPage)
              Positioned(
                top: 8,
                right: 8,
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(
                    AppStrings.onboardingSkip,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

            // ── Bottom controls: indicator + button ───────────────────────────
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicator
                  Semantics(
                    label: 'Trang ${_currentPage + 1} trong $_pageCount',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pageCount, (i) {
                        final isActive = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Next / Start button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _nextPage,
                      child: Text(
                        _isLastPage
                            ? AppStrings.onboardingStart
                            : AppStrings.onboardingNext,
                        style: textTheme.labelLarge,
                      ),
                    ),
                  ),

                  // Link to login on last page
                  if (_isLastPage) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('onboarding_login_link'),
                      onPressed: () {
                        ref.read(onboardingRepositoryProvider).markOnboardingAsSeen();
                        context.go(AppRoutes.login);
                      },
                      child: Text(
                        AppStrings.onboardingLoginLink,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page data model ───────────────────────────────────────────────────────────

enum _IllustrationType { search, ai, tracking }

class _PageData {
  final String title;
  final String description;
  final _IllustrationType illustrationType;

  const _PageData({
    required this.title,
    required this.description,
    required this.illustrationType,
  });
}

// ── Single onboarding page ────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  final bool isLast;

  const _OnboardingPage({
    required this.data,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Illustration
          _Illustration(type: data.illustrationType),
          const SizedBox(height: 40),
          // Title
          Text(
            data.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            data.description,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          if (isLast) ...[
            const SizedBox(height: 24),
            // Legal disclaimer
            Text(
              AppStrings.onboardingDisclaimer,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Self-built illustrations ──────────────────────────────────────────────────

class _Illustration extends StatelessWidget {
  final _IllustrationType type;

  const _Illustration({required this.type});

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      _IllustrationType.search => const _SearchIllustration(),
      _IllustrationType.ai => const _AiIllustration(),
      _IllustrationType.tracking => const _TrackingIllustration(),
    };
  }
}

/// Illustration 1: search / document lookup
class _SearchIllustration extends StatelessWidget {
  const _SearchIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background card
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Document lines
          Positioned(
            top: 36,
            left: 44,
            right: 44,
            child: Column(
              children: [
                _DocLine(width: double.infinity, color: cs.outlineVariant),
                const SizedBox(height: 8),
                _DocLine(width: double.infinity, color: cs.outlineVariant),
                const SizedBox(height: 8),
                _DocLine(width: 100, color: cs.outlineVariant),
              ],
            ),
          ),
          // Search magnifier badge
          Positioned(
            bottom: 8,
            right: 24,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.search_rounded, color: cs.primary, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

/// Illustration 2: AI assistant chat
class _AiIllustration extends StatelessWidget {
  const _AiIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        children: [
          // User bubble (right)
          Positioned(
            top: 16,
            right: 8,
            child: _ChatBubble(
              color: cs.primaryContainer,
              width: 130,
              height: 36,
            ),
          ),
          // AI bubble (left)
          Positioned(
            top: 68,
            left: 8,
            child: _ChatBubble(
              color: cs.surfaceContainerHighest,
              width: 160,
              height: 52,
            ),
          ),
          // Citation tag
          Positioned(
            top: 100,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link_rounded, size: 12, color: cs.secondary),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.onboardingCitationDemo,
                    style: TextStyle(fontSize: 10, color: cs.secondary),
                  ),
                ],
              ),
            ),
          ),
          // AI bot icon
          Positioned(
            bottom: 0,
            right: 16,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded, color: cs.primary, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

/// Illustration 3: document tracking / checklist
class _TrackingIllustration extends StatelessWidget {
  const _TrackingIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      height: 180,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Clipboard background
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Clip handle
          Positioned(
            top: 0,
            child: Container(
              width: 48,
              height: 14,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Checklist items
          Positioned(
            top: 24,
            left: 36,
            right: 36,
            child: Column(
              children: [
                _CheckItem(checked: true, label: AppStrings.onboardingChecklistCccd, cs: cs),
                const SizedBox(height: 8),
                _CheckItem(checked: true, label: AppStrings.onboardingChecklistHousePaper, cs: cs),
                const SizedBox(height: 8),
                _CheckItem(checked: false, label: AppStrings.onboardingChecklistRentContract, cs: cs),
              ],
            ),
          ),
          // Calendar icon (deadline)
          Positioned(
            bottom: 4,
            right: 24,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_rounded,
                color: cs.tertiary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small shared drawing helpers ──────────────────────────────────────────────

class _DocLine extends StatelessWidget {
  final double width;
  final Color color;

  const _DocLine({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const _ChatBubble({
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final bool checked;
  final String label;
  final ColorScheme cs;

  const _CheckItem({
    required this.checked,
    required this.label,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: checked ? cs.primary : cs.outlineVariant,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              color: checked ? cs.onSurface : cs.onSurfaceVariant,
              decoration: checked ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }
}
