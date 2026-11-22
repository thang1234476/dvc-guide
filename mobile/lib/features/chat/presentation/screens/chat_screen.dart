import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dvc_guide_mobile/app/router/app_router.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../widgets/chat_message_item.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Object? extra;
  final String? initialMaThuTuc;

  const ChatScreen({
    super.key,
    this.extra,
    this.initialMaThuTuc,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;

  Object? _lastAppliedExtra;

  static bool _isSameExtra(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || a[key] != b[key]) return false;
      }
      return true;
    }
    return a == b;
  }

  String? get _resolvedMaThuTuc {
    if (widget.extra is Map<String, dynamic>) {
      return (widget.extra as Map<String, dynamic>)['maThuTuc'] as String?;
    }
    if (widget.extra is String) {
      return widget.extra as String;
    }
    return widget.initialMaThuTuc;
  }

  String? get _resolvedTenGiayTo {
    if (widget.extra is Map<String, dynamic>) {
      return (widget.extra as Map<String, dynamic>)['tenGiayTo'] as String?;
    }
    return null;
  }

  int? get _resolvedThanhPhanHoSoId {
    if (widget.extra is Map<String, dynamic>) {
      return (widget.extra as Map<String, dynamic>)['thanhPhanHoSoId'] as int?;
    }
    return null;
  }

  int? get _resolvedTruongHopId {
    if (widget.extra is Map<String, dynamic>) {
      return (widget.extra as Map<String, dynamic>)['truongHopId'] as int?;
    }
    return null;
  }

  String? get _resolvedInitialQuestion {
    if (widget.extra is Map<String, dynamic>) {
      return (widget.extra as Map<String, dynamic>)['initialQuestion'] as String?;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    _checkAndApplyExtra();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameExtra(widget.extra, _lastAppliedExtra) ||
        widget.initialMaThuTuc != oldWidget.initialMaThuTuc) {
      _checkAndApplyExtra();
    }
  }

  void _applyNewContext(ChatViewModel notifier) {
    if (_resolvedMaThuTuc != null) {
      notifier.setContextProcedure(_resolvedMaThuTuc);
    }
    if (_resolvedTenGiayTo != null) {
      notifier.setContextGiayTo(
        _resolvedTenGiayTo,
        thanhPhanHoSoId: _resolvedThanhPhanHoSoId,
        truongHopId: _resolvedTruongHopId,
      );
    } else if (widget.extra is String || (_resolvedMaThuTuc != null && _resolvedTenGiayTo == null)) {
      notifier.setContextGiayTo(null);
    }
    if (_resolvedInitialQuestion != null) {
      _textController.text = _resolvedInitialQuestion!;
      setState(() {});
    }
  }

  void _checkAndApplyExtra() {
    if (_isSameExtra(widget.extra, _lastAppliedExtra)) return;
    _lastAppliedExtra = widget.extra;

    final provider = chatViewModelProvider(_resolvedMaThuTuc);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(provider);
      final notifier = ref.read(provider.notifier);

      final hasUserMessages =
          state.messages.any((m) => m.vaiTro == VaiTroTinNhan.user);
      final hasNewContext = (_resolvedTenGiayTo != null &&
              _resolvedTenGiayTo != state.tenGiayToContext) ||
          (_resolvedMaThuTuc != null &&
              _resolvedMaThuTuc != state.maThuTucContext);

      if (hasNewContext && hasUserMessages) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(AppStrings.confirmNewChatTitle),
            content: const Text(AppStrings.confirmNewChatContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(AppStrings.cancelAction),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.clearConversation();
                  _applyNewContext(notifier);
                },
                child: const Text(AppStrings.newConversation),
              ),
            ],
          ),
        );
      } else if (_resolvedTenGiayTo != null ||
          _resolvedInitialQuestion != null ||
          _resolvedMaThuTuc != null) {
        _applyNewContext(notifier);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showNewConversationDialog(BuildContext context, ChatViewModel notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.confirmNewChatTitle),
          content: const Text(AppStrings.confirmNewChatContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancelAction),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.clearConversation();
              },
              child: const Text(AppStrings.newConversation),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = chatViewModelProvider(_resolvedMaThuTuc);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    // Auto scroll when message list changes or is typing
    ref.listen(provider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isTyping != next.isTyping) {
        _scrollToBottom();
      }
    });

    final hasUserMessages = state.messages.any((m) => m.vaiTro == VaiTroTinNhan.user);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.aiAssistantTitle),
        elevation: 0,
        actions: [
          IconButton(
            key: const ValueKey('chat_history_button'),
            icon: const Icon(Icons.history_rounded),
            tooltip: AppStrings.chatHistoryTitle,
            onPressed: () => context.push(AppRoutes.chatHistory),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: AppStrings.newConversation,
            onPressed: () {
              if (hasUserMessages) {
                _showNewConversationDialog(context, notifier);
              } else {
                notifier.clearConversation();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Context Procedure Chip (if present)
            if (state.maThuTucContext != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.secondaryContainer.withAlpha(120),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 18,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${AppStrings.contextAskingAbout} ${state.contextProcedureName ?? state.maThuTucContext}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.clearProcedureContext,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => notifier.setContextProcedure(null),
                    ),
                  ],
                ),
              ),

            // Active Context Paper Chip (if present)
            if (state.tenGiayToContext != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.tertiaryContainer.withAlpha(120),
                child: Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 18,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${AppStrings.contextAskingAboutPaper} ${state.tenGiayToContext}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.clearPaperContext,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => notifier.setContextGiayTo(null),
                    ),
                  ],
                ),
              ),

            // Messages List Area
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                children: [
                  // Messages
                  ...state.messages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final message = entry.value;

                    // Find last user question before this assistant message
                    String? lastUserQuestion;
                    if (message.vaiTro == VaiTroTinNhan.assistant) {
                      for (int i = index - 1; i >= 0; i--) {
                        if (state.messages[i].vaiTro == VaiTroTinNhan.user) {
                          lastUserQuestion = state.messages[i].noiDung;
                          break;
                        }
                      }
                    }

                    return ChatMessageItem(
                      message: message,
                      feedbackValue: state.feedbacks[message.id],
                      onToggleFeedback: (isHelpful, {note}) =>
                          notifier.toggleFeedback(message.id, isHelpful, note: note),
                      lastUserQuestion: lastUserQuestion,
                    );
                  }),

                  // Typing Indicator when AI is thinking
                  if (state.isTyping)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TypingIndicator(),
                      ),
                    ),

                  // Suggested Questions when no user message yet
                  if (!hasUserMessages && !state.isTyping)
                    _buildSuggestedQuestions(context, notifier, state.maThuTucContext),

                  // Send Error Banner with Retry button
                  if (state.error != null)
                    _buildErrorBanner(context, state.error!, notifier),
                ],
              ),
            ),

            // Fixed AI Disclaimer Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.aiDisclaimerNotice} • ${AppStrings.mockDataDisclaimer}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Input Bar
            _buildInputBar(context, state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestions(
    BuildContext context,
    ChatViewModel notifier,
    String? maThuTucContext,
  ) {
    final theme = Theme.of(context);

    final questions = maThuTucContext != null
        ? [
            AppStrings.suggestedProcQ1,
            AppStrings.suggestedProcQ2,
            AppStrings.suggestedProcQ3,
            AppStrings.suggestedProcQ4,
          ]
        : [
            AppStrings.suggestedQ1,
            AppStrings.suggestedQ2,
            AppStrings.suggestedQ3,
            AppStrings.suggestedQ4,
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.suggestedQuestionsTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questions.map((q) {
              return ActionChip(
                label: Text(q),
                backgroundColor: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                onPressed: () {
                  _textController.text = q;
                  notifier.sendMessage(q);
                  _textController.clear();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    BuildContext context,
    String errorMessage,
    ChatViewModel notifier,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: notifier.retryLastFailed,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    ChatState state,
    ChatViewModel notifier,
  ) {
    final theme = Theme.of(context);
    final canSend = _textController.text.trim().isNotEmpty && !state.isTyping;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) {
                if (canSend) {
                  final text = _textController.text.trim();
                  _textController.clear();
                  setState(() {});
                  notifier.sendMessage(text);
                }
              },
              decoration: InputDecoration(
                hintText: AppStrings.chatInputHint,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: AppStrings.sendAction,
            icon: const Icon(Icons.send_rounded),
            onPressed: canSend
                ? () {
                    final text = _textController.text.trim();
                    _textController.clear();
                    setState(() {});
                    notifier.sendMessage(text);
                  }
                : null,
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }
}
