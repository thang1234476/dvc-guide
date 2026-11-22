import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../shared/enums/procedure_enums.dart';
import '../../../../shared/widgets/dia_phuong_picker_sheet.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../auth/data/repositories/auth_repository_provider.dart';
import '../../../auth/domain/models/dia_phuong.dart';
import '../../../auth/presentation/viewmodels/auth_controller.dart';
import '../../../feedback/data/repositories/gop_y_repository_provider.dart';
import '../../../my_cases/data/models/my_case_models.dart';
import '../../../my_cases/data/repositories/my_cases_repository_provider.dart';
import '../../../my_cases/presentation/viewmodels/my_cases_viewmodel.dart';
import '../../data/models/procedure_models.dart';
import '../../data/repositories/procedure_repository_provider.dart';

class FindAgencyScreen extends ConsumerStatefulWidget {
  final int thuTucId;
  final String caseId;
  final String slot; // 'du_dinh' | 'thuc_te'
  final String from; // 'case' | 'procedure'

  const FindAgencyScreen({
    super.key,
    required this.thuTucId,
    required this.caseId,
    this.slot = 'du_dinh',
    this.from = 'procedure',
  });

  @override
  ConsumerState<FindAgencyScreen> createState() => _FindAgencyScreenState();
}

class _FindAgencyScreenState extends ConsumerState<FindAgencyScreen> {
  int? _selectedDiaPhuongId;
  List<DiaPhuong> _diaPhuongList = [];
  List<CoQuan> _agencies = [];

  bool _isLoadingInitial = true;
  bool _isLoadingAgencies = false;
  String? _error;

  ThuTucDetail? _procedure;
  HoSoCuaToi? _caseItem;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
      _error = null;
    });

    try {
      final procRepo = ref.read(procedureRepositoryProvider);
      final casesRepo = ref.read(myCasesRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final prefs = ref.read(sharedPreferencesProvider);

      final results = await Future.wait([
        procRepo.getProcedureDetail(widget.thuTucId),
        casesRepo.getCaseById(widget.caseId),
        authRepo.getDiaPhuongList(),
      ]);

      _procedure = results[0] as ThuTucDetail?;
      _caseItem = results[1] as HoSoCuaToi?;
      _diaPhuongList = results[2] as List<DiaPhuong>;

      // Determine default diaPhuongId:
      // 1. User diaPhuongId if logged in
      final authState = ref.read(authControllerProvider);
      int? initialDpId = authState.user?.diaPhuongId;

      // 2. If not, check SharedPreferences
      if (initialDpId == null) {
        final saved = prefs.getInt(AppConstants.kLastSelectedDiaPhuongKey);
        if (saved != null) {
          initialDpId = saved;
        }
      }

      _selectedDiaPhuongId = initialDpId;
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }

      if (_selectedDiaPhuongId != null) {
        _loadAgencies(_selectedDiaPhuongId!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<void> _loadAgencies(int diaPhuongId) async {
    setState(() {
      _isLoadingAgencies = true;
      _error = null;
    });

    try {
      final procRepo = ref.read(procedureRepositoryProvider);
      final list = await procRepo.getCoQuanTiepNhan(
        thuTucId: widget.thuTucId,
        diaPhuongId: diaPhuongId,
      );
      if (mounted) {
        setState(() {
          _agencies = list;
          _isLoadingAgencies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingAgencies = false;
        });
      }
    }
  }

  void _openLocationPicker() {
    DiaPhuongPickerSheet.show(
      context,
      list: _diaPhuongList,
      selectedId: _selectedDiaPhuongId,
      onSelected: (newId) async {
        setState(() => _selectedDiaPhuongId = newId);
        final prefs = ref.read(sharedPreferencesProvider);
        if (newId != null) {
          await prefs.setInt(AppConstants.kLastSelectedDiaPhuongKey, newId);
          _loadAgencies(newId);
        } else {
          await prefs.remove(AppConstants.kLastSelectedDiaPhuongKey);
          setState(() {
            _agencies = [];
          });
        }
      },
    );
  }

  Future<void> _handleCopyAddress(String? address) async {
    if (address == null || address.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: address));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.copyAddressSuccess)),
      );
    }
  }

  Future<void> _handleOpenMap(CoQuan cq) async {
    String mapUrl;
    if (cq.viDo != null && cq.kinhDo != null) {
      mapUrl = 'https://www.google.com/maps/search/?api=1&query=${cq.viDo},${cq.kinhDo}';
    } else if (cq.diaChi != null && cq.diaChi!.trim().isNotEmpty) {
      mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(cq.diaChi!)}';
    } else {
      return;
    }

    final uri = Uri.tryParse(mapUrl);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.cannotOpenLinkNotice)),
        );
      }
      return;
    }

    final isExample = uri.host.contains('example.com') || mapUrl.contains('example.com');
    if (isExample) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.exampleLinkNotice)),
        );
      }
      return;
    }

    final success = await ref.read(urlLauncherServiceProvider).open(uri);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.cannotOpenLinkNotice)),
      );
    }
  }

  Future<void> _handleSelectAgency(CoQuan cq, bool isCurrentlySelected) async {
    final isIntended = widget.slot == 'du_dinh';
    final repo = ref.read(myCasesRepositoryProvider);

    if (isCurrentlySelected) {
      // Unselect
      if (isIntended) {
        await repo.updateCase(widget.caseId, clearDuDinh: true);
      } else {
        await repo.updateCase(widget.caseId, clearThucTe: true);
      }
      ref.read(myCasesViewModelProvider.notifier).loadCases();
      if (_caseItem != null) {
        setState(() {
          _caseItem = _caseItem!.copyWith(
            coQuanDuDinhId: isIntended ? null : _caseItem!.coQuanDuDinhId,
            coQuanThucTeId: isIntended ? _caseItem!.coQuanThucTeId : null,
          );
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.unselectSubmissionPlaceSuccess)),
        );
      }
    } else {
      // Select
      if (isIntended) {
        await repo.updateCase(widget.caseId, coQuanDuDinhId: cq.id);
      } else {
        await repo.updateCase(widget.caseId, coQuanThucTeId: cq.id);
      }
      ref.read(myCasesViewModelProvider.notifier).loadCases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.selectSubmissionPlaceSuccess)),
        );
        if (widget.from == 'case') {
          context.pop();
        } else {
          context.go(AppRoutes.myCaseDetailPath(widget.caseId));
        }
      }
    }
  }

  void _showReportWrongAddressSheet(CoQuan cq) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return _ReportWrongAddressSheet(
          coQuan: cq,
          thuTucId: widget.thuTucId,
          onSubmit: (reason, note) async {
            final content = note.isNotEmpty ? '$reason: $note' : reason;
            await ref.read(gopYRepositoryProvider).submit(
                  loai: LoaiGopY.saiDiaChi,
                  coQuanId: cq.id,
                  thuTucId: widget.thuTucId,
                  noiDung: content,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.reportSuccess)),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingInitial) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.findAgencyTitle)),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonBox(width: double.infinity, height: 60),
              SizedBox(height: 16),
              SkeletonCard(),
              SkeletonCard(),
            ],
          ),
        ),
      );
    }

    if (_error != null && _procedure == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.findAgencyTitle)),
        body: AppErrorWidget(
          message: _error ?? AppStrings.defaultErrorMessage,
          onRetry: _loadInitialData,
        ),
      );
    }

    // Find current location display name
    DiaPhuong? currentDiaPhuong;
    if (_selectedDiaPhuongId != null) {
      for (final dp in _diaPhuongList) {
        if (dp.id == _selectedDiaPhuongId) {
          currentDiaPhuong = dp;
          break;
        }
      }
    }

    final isIntendedSlot = widget.slot == 'du_dinh';
    final currentSelectedAgencyId = isIntendedSlot
        ? _caseItem?.coQuanDuDinhId
        : _caseItem?.coQuanThucTeId;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.findAgencyTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Card: Tên thủ tục & Tên hồ sơ ─────────────────────────
              SectionCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _procedure?.ten ?? '',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppStrings.caseNameLabel}: ${_caseItem?.tenHoSo ?? ''}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vị trí tiếp nhận: ${isIntendedSlot ? AppStrings.intendedAgency : AppStrings.actualAgency}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Ô chọn địa phương ──────────────────────────────────────────
              InkWell(
                key: const ValueKey('find_agency_location_picker'),
                onTap: _openLocationPicker,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppStrings.selectLocationTitle,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    currentDiaPhuong != null
                        ? currentDiaPhuong.ten
                        : AppStrings.locationNotSelected,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: currentDiaPhuong != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: currentDiaPhuong != null ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Content Area: Prompt / Loading / Error / Empty / List ────────
              if (_selectedDiaPhuongId == null) ...[
                // Lời mời chọn địa phương
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(60),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_city_outlined,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.pleaseSelectLocationPrompt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const ValueKey('prompt_select_location_button'),
                        onPressed: _openLocationPicker,
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text(AppStrings.selectLocationAction),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_isLoadingAgencies) ...[
                const Column(
                  children: [
                    SkeletonCard(),
                    SkeletonCard(),
                  ],
                ),
              ] else if (_error != null) ...[
                AppErrorWidget(
                  message: _error!,
                  onRetry: () => _loadAgencies(_selectedDiaPhuongId!),
                ),
              ] else if (_agencies.isEmpty) ...[
                // Empty state
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.noAgenciesForLocation,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.tryOtherLocation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _openLocationPicker,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const Text(AppStrings.selectLocationAction),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Agency Cards List
                ..._agencies.map((cq) {
                  final isCurrentlySelected = currentSelectedAgencyId == cq.id;
                  final hasCoordinates = cq.viDo != null && cq.kinhDo != null;
                  final hasAddress = cq.diaChi != null && cq.diaChi!.trim().isNotEmpty;
                  final canOpenMap = hasCoordinates || hasAddress;

                  return _buildAgencyCard(
                    context,
                    theme,
                    cq,
                    isCurrentlySelected: isCurrentlySelected,
                    canOpenMap: canOpenMap,
                  );
                }),
              ],

              const SizedBox(height: 16),

              // ── Dòng cố định cảnh báo & Dữ liệu mẫu ──────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${AppStrings.agencyDisclaimerNotice}${AppConstants.kUseSampleData ? AppStrings.sampleDataSuffix : ''}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgencyCard(
    BuildContext context,
    ThemeData theme,
    CoQuan cq, {
    required bool isCurrentlySelected,
    required bool canOpenMap,
  }) {
    return SectionCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Badge cấp + Đang chọn (nếu có)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cq.ten,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusChip.administrativeLevel(context, cq.cap),
                  ],
                ),
              ),
              if (isCurrentlySelected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.currentlySelected,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Địa chỉ
          if (cq.diaChi != null && cq.diaChi!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cq.diaChi!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // Giờ làm việc (ẩn nếu null)
          if (cq.gioLamViec != null && cq.gioLamViec!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${AppStrings.workingHoursLabel}: ${cq.gioLamViec!}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Giờ phát số (ẩn nếu null)
          if (cq.gioPhatSo != null && cq.gioPhatSo!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${AppStrings.numberIssuingHoursLabel}: ${cq.gioPhatSo!}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Nhãn nguồn địa chỉ
          const SizedBox(height: 8),
          _buildSourceTag(context, theme, cq),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Nút hành động
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 1. Sao chép địa chỉ
              OutlinedButton.icon(
                key: ValueKey('copy_address_${cq.id}'),
                onPressed: () => _handleCopyAddress(cq.diaChi),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text(AppStrings.copyAddress),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),

              // 2. Mở bản đồ / Chỉ đường (ẩn nếu thiếu cả tọa độ và địa chỉ)
              if (canOpenMap)
                OutlinedButton.icon(
                  key: ValueKey('open_map_${cq.id}'),
                  onPressed: () => _handleOpenMap(cq),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text(AppStrings.openMap),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),

              // 3. Chọn làm nơi nộp / Bỏ chọn
              FilledButton.icon(
                key: ValueKey('select_submission_place_${cq.id}'),
                onPressed: () => _handleSelectAgency(cq, isCurrentlySelected),
                icon: Icon(
                  isCurrentlySelected ? Icons.clear_rounded : Icons.check_circle_outline,
                  size: 16,
                ),
                label: Text(
                  isCurrentlySelected ? AppStrings.unselectAction : AppStrings.selectAsSubmissionPlace,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: isCurrentlySelected
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primary,
                  foregroundColor: isCurrentlySelected
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimary,
                ),
              ),

              // 4. Báo địa chỉ không đúng
              TextButton.icon(
                key: ValueKey('report_wrong_address_${cq.id}'),
                onPressed: () => _showReportWrongAddressSheet(cq),
                icon: Icon(
                  Icons.report_problem_outlined,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  AppStrings.reportWrongAddress,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTag(BuildContext context, ThemeData theme, CoQuan cq) {
    if (cq.nguonDiaChi == NguonDiaChi.ai && !cq.daKiemChung) {
      // Banner cảnh báo AI chưa kiểm chứng (màu lấy từ colorScheme)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withAlpha(90),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.error.withAlpha(120)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.addressAiDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (cq.daKiemChung) {
      final dateText = cq.kiemChungLuc != null ? ' (${cq.kiemChungLuc})' : '';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(30),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 14,
              color: AppColors.success,
            ),
            const SizedBox(width: 4),
                        Flexible(
              child: Text(
                '${AppStrings.verifiedBadge}$dateText',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Còn lại: Chip "Thông tin tham khảo"
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
                    Flexible(
            child: Text(
              AppStrings.referenceInfoBadge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modal Bottom Sheet Báo địa chỉ không đúng ──────────────────────────────────

class _ReportWrongAddressSheet extends StatefulWidget {
  final CoQuan coQuan;
  final int thuTucId;
  final Future<void> Function(String reason, String note) onSubmit;

  const _ReportWrongAddressSheet({
    required this.coQuan,
    required this.thuTucId,
    required this.onSubmit,
  });

  @override
  State<_ReportWrongAddressSheet> createState() => _ReportWrongAddressSheetState();
}

class _ReportWrongAddressSheetState extends State<_ReportWrongAddressSheet> {
  final List<String> _reasons = const [
    AppStrings.reportReasonWrongAddress,
    AppStrings.reportReasonMoved,
    AppStrings.reportReasonStopped,
    AppStrings.reportReasonOther,
  ];

  late String _selectedReason;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasons.first;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_selectedReason, _noteController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.reportWrongAddressTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.coQuan.ten,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 24),
              Text(
                'Lý do báo cáo:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
                            RadioGroup<String>(
                groupValue: _selectedReason,
                onChanged: (v) {
                  if (v != null) setState(() => _selectedReason = v);
                },
                child: Column(
                  children: _reasons.map((reason) {
                    return RadioListTile<String>(
                      key: ValueKey('report_reason_$reason'),
                      value: reason,
                      title: Text(reason),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('report_note_input'),
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: AppStrings.reportNoteHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton(
                  key: const ValueKey('submit_report_button'),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.reportSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
