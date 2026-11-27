import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/vietnamese_utils.dart';
import '../../features/auth/domain/models/dia_phuong.dart';

/// Modal bottom sheet for searching and selecting an administrative locality (DiaPhuong).
class DiaPhuongPickerSheet extends StatefulWidget {
  final List<DiaPhuong> list;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const DiaPhuongPickerSheet({
    super.key,
    required this.list,
    required this.selectedId,
    required this.onSelected,
  });

  /// Helper to display this bottom sheet
  static Future<void> show(
    BuildContext context, {
    required List<DiaPhuong> list,
    required int? selectedId,
    required ValueChanged<int?> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return DiaPhuongPickerSheet(
          list: list,
          selectedId: selectedId,
          onSelected: onSelected,
        );
      },
    );
  }

  @override
  State<DiaPhuongPickerSheet> createState() => _DiaPhuongPickerSheetState();
}

class _DiaPhuongPickerSheetState extends State<DiaPhuongPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchableQuery = VietnameseUtils.toSearchable(_searchQuery);

    final filteredList = widget.list.where((dp) {
      if (_searchQuery.trim().isEmpty) return true;
      return VietnameseUtils.toSearchable(dp.ten).contains(searchableQuery);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                AppStrings.selectLocationTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('search_location_input'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppStrings.searchLocationHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Option to clear selection
                    ListTile(
                      key: const ValueKey('location_option_clear'),
                      title: const Text(AppStrings.locationClear),
                      leading: Icon(
                        Icons.clear_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      trailing: widget.selectedId == null
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        widget.onSelected(null);
                        Navigator.of(context).pop();
                      },
                    ),
                    const Divider(),
                    if (filteredList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            AppStrings.noLocationFound,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filteredList.map((dp) {
                        final isSelected = dp.id == widget.selectedId;
                        return ListTile(
                          key: ValueKey('location_option_${dp.id}'),
                          title: Text(dp.ten),
                          subtitle: dp.loai != null ? Text(dp.loai!) : null,
                          trailing: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            widget.onSelected(dp.id);
                            Navigator.of(context).pop();
                          },
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Backward compatibility alias for internal references
typedef SelectDiaPhuongSheet = DiaPhuongPickerSheet;
