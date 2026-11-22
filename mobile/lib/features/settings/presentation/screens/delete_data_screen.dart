import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/vietnamese_utils.dart';
import '../../../chat/data/repositories/conversation_store_provider.dart';
import '../../../my_cases/data/models/my_case_models.dart';
import '../../../my_cases/data/repositories/my_cases_repository_provider.dart';
import '../../../my_cases/presentation/viewmodels/reminder_coordinator.dart';
import '../../../procedure/data/repositories/favorites_repository_provider.dart';

class DeleteDataScreen extends ConsumerStatefulWidget {
  const DeleteDataScreen({super.key});

  @override
  ConsumerState<DeleteDataScreen> createState() => _DeleteDataScreenState();
}

class _DeleteDataScreenState extends ConsumerState<DeleteDataScreen> {
  List<HoSoCuaToi> _cases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() => _isLoading = true);
    final repo = ref.read(myCasesRepositoryProvider);
    final list = await repo.getMyCases();
    if (mounted) {
      setState(() {
        _cases = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteSingleCase(HoSoCuaToi item, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(AppStrings.deleteCaseTitle),
        content: Text(
          'Bạn có chắc chắn muốn xóa hồ sơ "${item.tenHoSo}"?',
        ),
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
            child: const Text(AppStrings.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(myCasesRepositoryProvider);
      await repo.deleteCase(item.id);
      await ref.read(reminderServiceProvider).cancelForCase(item.id);
      setState(() {
        _cases.removeWhere((c) => c.id == item.id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.caseDeleted),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: AppStrings.undoAction,
            onPressed: () async {
              await repo.restoreCase(item, index);
              await ref.read(reminderCoordinatorProvider).sync();
              await _loadCases();
            },
          ),
        ),
      );
    }
  }

  Future<void> _showDeleteAllDataDialog() async {
    final confirmTextController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final input = confirmTextController.text.trim();
            final isMatch = VietnameseUtils.toSearchable(input) == 'xoa';

            return AlertDialog(
              title: Text(
                AppStrings.confirmDeleteAllDataTitle,
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
                    Text(
                      AppStrings.confirmDeleteAllDataContent,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('delete_all_data_confirm_input'),
                      controller: confirmTextController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: AppStrings.typeXoaToConfirm,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text(AppStrings.cancelAction),
                ),
                FilledButton(
                  key: const ValueKey('delete_all_data_confirm_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: isMatch
                      ? () async {
                          Navigator.of(dialogCtx).pop();
                          await _executeDeleteAllData();
                        }
                      : null,
                  child: const Text(AppStrings.confirmDeleteAllAction),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeDeleteAllData() async {
    // 1. Xóa mọi hồ sơ
    await ref.read(myCasesRepositoryProvider).clearAll();
    await ref.read(reminderCoordinatorProvider).onAllDataCleared();

    // 2. Xóa danh sách yêu thích
    await ref.read(favoritesRepositoryProvider).clearAll();

    // 3. Xóa lịch sử trò chuyện
    await ref.read(conversationStoreProvider).clearAll();

    // Lưu ý: Không xóa địa phương đã lưu, không xóa cờ onboarding, không đăng xuất/xóa tài khoản

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.allDataDeletedSuccess),
        duration: Duration(seconds: 3),
      ),
    );

    // Quay lại Cài đặt
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.deleteDataTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // Lựa chọn (a): Chọn xóa từng hồ sơ trong danh sách
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppStrings.deleteCasesSectionTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_cases.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.noCasesToDelete,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_cases.length, (index) {
                final item = _cases[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      item.tenHoSo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: item.thuTuc.ten != item.tenHoSo
                        ? Text(
                            item.thuTuc.ten,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: IconButton(
                      key: ValueKey('delete_case_${item.id}'),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: AppStrings.deleteAction,
                      onPressed: () => _confirmDeleteSingleCase(item, index),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 16),

            // Lựa chọn (b): Xóa toàn bộ dữ liệu cá nhân trên thiết bị
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppStrings.deleteAllDataSectionTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.errorContainer,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.deleteAllDataDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('delete_all_data_open_button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          minimumSize: const Size(0, 48),
                        ),
                        icon: const Icon(Icons.delete_forever_rounded, size: 20),
                        label: const Text(AppStrings.deleteAllDataButton),
                        onPressed: _showDeleteAllDataDialog,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
