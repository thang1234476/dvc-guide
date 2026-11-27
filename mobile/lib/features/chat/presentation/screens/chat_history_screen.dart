import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/vietnamese_utils.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/conversation_store_provider.dart';
import '../viewmodels/chat_viewmodel.dart';

class ChatHistoryScreen extends ConsumerStatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  ConsumerState<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends ConsumerState<ChatHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final store = ref.read(conversationStoreProvider);
    final list = await store.getConversations();
    if (mounted) {
      setState(() {
        _conversations = list;
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(itemDate).inDays;

    if (diff == 0) {
      return AppStrings.today;
    } else if (diff == 1) {
      return AppStrings.yesterday;
    } else {
      final d = dateTime.day.toString().padLeft(2, '0');
      final m = dateTime.month.toString().padLeft(2, '0');
      final y = dateTime.year.toString();
      return '$d/$m/$y';
    }
  }

  Future<void> _deleteItem(ChatConversation conv, int index) async {
    final store = ref.read(conversationStoreProvider);
    await store.deleteConversation(conv.id);
    setState(() {
      _conversations.removeWhere((c) => c.id == conv.id);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(AppStrings.chatDeleted),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: AppStrings.undoAction,
          onPressed: () async {
            await store.restoreConversation(conv, index);
            await _loadConversations();
          },
        ),
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(AppStrings.confirmClearAllChatTitle),
        content: const Text(AppStrings.confirmClearAllChatContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(AppStrings.cancelAction),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(AppStrings.clearAllConversations),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final store = ref.read(conversationStoreProvider);
      await store.clearAll();
      await _loadConversations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.allChatCleared),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openConversation(ChatConversation conv) async {
    // 1. Lưu cuộc hiện tại nếu có
    final chatNotifier = ref.read(chatViewModelProvider(null).notifier);
    await chatNotifier.saveCurrentConversation();

    // 2. Nạp cuộc đã lưu
    await chatNotifier.loadConversation(conv);

    // 3. Chuyển sang màn hình chat
    if (mounted) {
      context.go(AppRoutes.chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchableQuery = VietnameseUtils.toSearchable(_searchQuery);

    final filteredList = _conversations.where((c) {
      if (searchableQuery.isEmpty) return true;
      final searchableTitle = VietnameseUtils.toSearchable(c.tieuDe);
      return searchableTitle.contains(searchableQuery);
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.chatHistoryTitle),
        elevation: 0,
        actions: [
          if (_conversations.isNotEmpty)
            TextButton.icon(
              key: const ValueKey('clear_all_chat_button'),
              onPressed: _confirmClearAll,
              icon: Icon(
                Icons.delete_sweep_outlined,
                size: 20,
                color: theme.colorScheme.error,
              ),
              label: Text(
                AppStrings.clearAllConversations,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ô tìm kiếm
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                key: const ValueKey('chat_history_search_input'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppStrings.searchChatHistoryHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: AppStrings.clearSearch,
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Dòng ghi chú
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppStrings.chatHistoryLocalNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 8),

            // Nội dung danh sách / Empty state
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 64,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? AppStrings.noProceduresFound
                                      : AppStrings.emptyChatHistoryTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? AppStrings.tryDifferentKeywords
                                      : AppStrings.emptyChatHistorySubtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final lastMessage = item.tinNhan.isNotEmpty
                                ? item.tinNhan.last.noiDung
                                : '';

                            return Dismissible(
                              key: ValueKey('chat_conv_${item.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                color: theme.colorScheme.error,
                                child: Icon(
                                  Icons.delete_rounded,
                                  color: theme.colorScheme.onError,
                                ),
                              ),
                              onDismissed: (_) => _deleteItem(item, index),
                              child: InkWell(
                                onTap: () => _openConversation(item),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minHeight: 64),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Tiêu đề và thời gian
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.tieuDe,
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTime(item.capNhatLuc),
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Câu cuối cắt gọn
                                        if (lastMessage.isNotEmpty) ...[
                                          Text(
                                            lastMessage,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                        ],

                                        // Số tin nhắn
                                        Text(
                                          '${item.tinNhan.length} ${AppStrings.messagesCountSuffix}',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
