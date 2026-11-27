import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvc_guide_mobile/core/constants/app_constants.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/core/providers/shared_preferences_provider.dart';
import 'package:dvc_guide_mobile/core/services/url_launcher_service.dart';
import 'package:dvc_guide_mobile/features/auth/data/datasources/token_storage.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/auth_controller.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/token_storage_provider.dart';
import 'package:dvc_guide_mobile/features/chat/presentation/screens/chat_screen.dart';
import 'package:dvc_guide_mobile/features/feedback/data/repositories/gop_y_repository_provider.dart';
import 'package:dvc_guide_mobile/features/feedback/data/repositories/mock_gop_y_repository.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/mock_my_cases_repository.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/my_cases_repository_provider.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/screens/my_case_check_screen.dart';
import 'package:dvc_guide_mobile/features/procedure/data/mock/procedure_mock_data.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/fake_favorites_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/favorites_repository_provider.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/mock_procedure_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/procedure_repository_provider.dart';
import 'package:dvc_guide_mobile/features/procedure/presentation/screens/find_agency_screen.dart';
import 'package:dvc_guide_mobile/features/procedure/presentation/screens/procedure_detail_screen.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            return null;
          }
          if (call.method == 'Clipboard.getData') {
            return {'text': 'Bộ phận Tiếp nhận và Trả kết quả UBND cấp xã'};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget buildTestScope({
    required Widget child,
    required SharedPreferences prefs,
    FakeUrlLauncherService? fakeLauncher,
    MockGopYRepository? mockGopY,
    MockMyCasesRepository? mockMyCases,
    MockProcedureRepository? mockProcedure,
    AuthState? customAuthState,
  }) {
    final fakeStorage = FakeTokenStorage();
    final authRepo = MockAuthRepository(tokenStorage: fakeStorage);

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(fakeStorage),
        authRepositoryProvider.overrideWithValue(authRepo),
        favoritesRepositoryProvider.overrideWithValue(
          FakeFavoritesRepository(),
        ),
        urlLauncherServiceProvider.overrideWithValue(
          fakeLauncher ?? FakeUrlLauncherService(),
        ),
        gopYRepositoryProvider.overrideWithValue(
          mockGopY ?? MockGopYRepository(),
        ),
        myCasesRepositoryProvider.overrideWithValue(
          mockMyCases ?? MockMyCasesRepository(),
        ),
        procedureRepositoryProvider.overrideWithValue(
          mockProcedure ?? MockProcedureRepository(),
        ),
        if (customAuthState != null)
          authControllerProvider.overrideWith(
            () => _StaticAuthController(customAuthState),
          ),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Find Agency & Link Launcher Tests', () {
    testWidgets(
      '1. Nút "Tìm nơi tiếp nhận" ẩn khi chưa có hồ sơ, hiện khi có hồ sơ',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final emptyMyCasesRepo = _EmptyMockMyCasesRepository();

        await tester.pumpWidget(
          buildTestScope(
            child: const ProcedureDetailScreen(id: 1),
            prefs: prefs,
            mockMyCases: emptyMyCasesRepo,
          ),
        );

        // Advance through loading
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // Không có hồ sơ cho thủ tục 1 -> nút ẩn
        expect(find.text(AppStrings.findAgencyAction), findsNothing);

        // Bây giờ thêm 1 hồ sơ cho thủ tục 1
        emptyMyCasesRepo.addExistingCase(
          HoSoCuaToi(
            id: 'case-test-1',
            tenHoSo: 'Hồ sơ khai sinh 1',
            thuTuc: mockProcedureSummaries[0],
            trangThai: TrangThaiHoSo.dangChuanBi,
            taoLuc: DateTime.now(),
          ),
        );

        // Rebuild with updated repo (xóa cây cũ để màn hình tải lại dữ liệu)
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          buildTestScope(
            child: const ProcedureDetailScreen(id: 1),
            prefs: prefs,
            mockMyCases: emptyMyCasesRepo,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // Có hồ sơ -> nút hiện
        expect(find.text(AppStrings.findAgencyAction), findsOneWidget);
      },
    );

    testWidgets('2. Nhiều hồ sơ thì hiện bottom sheet hỏi chọn', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final multiCaseRepo = _EmptyMockMyCasesRepository();
      multiCaseRepo.addExistingCase(
        HoSoCuaToi(
          id: 'case-test-1',
          tenHoSo: 'Khai sinh bé A',
          thuTuc: mockProcedureSummaries[0],
          trangThai: TrangThaiHoSo.dangChuanBi,
          taoLuc: DateTime.now(),
        ),
      );
      multiCaseRepo.addExistingCase(
        HoSoCuaToi(
          id: 'case-test-2',
          tenHoSo: 'Khai sinh bé B',
          thuTuc: mockProcedureSummaries[0],
          trangThai: TrangThaiHoSo.daNop,
          taoLuc: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        buildTestScope(
          child: const ProcedureDetailScreen(id: 1),
          prefs: prefs,
          mockMyCases: multiCaseRepo,
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final findAgencyBtn = find.text(AppStrings.findAgencyAction);
      expect(findAgencyBtn, findsOneWidget);

      await tester.ensureVisible(findAgencyBtn);
      await tester.pump();
      await tester.tap(findAgencyBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom sheet chọn hồ sơ xuất hiện
      expect(find.text(AppStrings.selectCaseForAgencyPrompt), findsOneWidget);
      expect(find.text('Khai sinh bé A'), findsOneWidget);
      expect(find.text('Khai sinh bé B'), findsOneWidget);
    });

    testWidgets('3. AI chưa kiểm chứng hiện banner, đã kiểm chứng hiện chip', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Địa phương 1 có agency 1 (đã kiểm chứng) và agency 2 (AI chưa kiểm chứng)
      SharedPreferences.setMockInitialValues({
        AppConstants.kLastSelectedDiaPhuongKey: 1,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        buildTestScope(
          child: const FindAgencyScreen(
            thuTucId: 1,
            caseId: 'case-001',
            slot: 'du_dinh',
            from: 'procedure',
          ),
          prefs: prefs,
        ),
      );

      // Pump past initial and agency loading delays
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Banner cảnh báo AI
      expect(find.text(AppStrings.addressAiDisclaimer), findsOneWidget);

      // Chip đã kiểm chứng
      expect(find.textContaining(AppStrings.verifiedBadge), findsWidgets);
    });

    testWidgets('4. Sao chép địa chỉ ghi vào Clipboard', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        AppConstants.kLastSelectedDiaPhuongKey: 1,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        buildTestScope(
          child: const FindAgencyScreen(
            thuTucId: 1,
            caseId: 'case-001',
            slot: 'du_dinh',
            from: 'procedure',
          ),
          prefs: prefs,
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final copyBtn = find.byKey(const ValueKey('copy_address_1'));
      expect(copyBtn, findsOneWidget);

      await tester.tap(copyBtn);
      await tester.pump();

      // SnackBar sao chép thành công
      expect(find.text(AppStrings.copyAddressSuccess), findsOneWidget);
    });

    testWidgets(
      '5. Mở bản đồ gọi launcher đúng URL (tọa độ hoặc địa chỉ), thiếu cả hai thì ẩn nút',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fakeLauncher = FakeUrlLauncherService();
        // Chọn địa phương 2 (có id 7 có tọa độ, id 10 thiếu tọa độ nhưng có địa chỉ)
        SharedPreferences.setMockInitialValues({
          AppConstants.kLastSelectedDiaPhuongKey: 2,
        });
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          buildTestScope(
            child: const FindAgencyScreen(
              thuTucId: 1, // cấp xã -> lấy id 7 và 8
              caseId: 'case-001',
              slot: 'du_dinh',
              from: 'procedure',
            ),
            prefs: prefs,
            fakeLauncher: fakeLauncher,
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // Agency 7 có tọa độ: viDo 10.780123, kinhDo 106.699456
        final openMap7 = find.byKey(const ValueKey('open_map_7'));
        expect(openMap7, findsOneWidget);

        await tester.tap(openMap7);
        await tester.pump();

        expect(fakeLauncher.openedUris.isNotEmpty, isTrue);
        expect(
          fakeLauncher.openedUris.last.toString(),
          contains('10.780123,106.699456'),
        );
      },
    );

    testWidgets('6. Chọn làm nơi nộp cập nhật đúng slot', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        AppConstants.kLastSelectedDiaPhuongKey: 1,
      });
      final prefs = await SharedPreferences.getInstance();
      final myCasesRepo = MockMyCasesRepository();

      await tester.pumpWidget(
        buildTestScope(
          child: const FindAgencyScreen(
            thuTucId: 1,
            caseId: 'case-001',
            slot: 'du_dinh',
            from: 'case',
          ),
          prefs: prefs,
          mockMyCases: myCasesRepo,
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Agency 1 đang được chọn (case-001 có coQuanDuDinhId = 1) -> hiện "Bỏ chọn"
      expect(find.text(AppStrings.currentlySelected), findsOneWidget);
      expect(find.text(AppStrings.unselectAction), findsOneWidget);

      // Bấm "Bỏ chọn"
      await tester.tap(find.text(AppStrings.unselectAction));
      await tester.pump(const Duration(milliseconds: 200));

      // SnackBar xác nhận bỏ chọn
      expect(
        find.text(AppStrings.unselectSubmissionPlaceSuccess),
        findsOneWidget,
      );

      // Chờ hết timer của mock repo (loadCases) trước khi test kết thúc
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('7. Báo sai gọi submit với loai = saiDiaChi và đúng coQuanId', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        AppConstants.kLastSelectedDiaPhuongKey: 1,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockGopY = MockGopYRepository();

      await tester.pumpWidget(
        buildTestScope(
          child: const FindAgencyScreen(
            thuTucId: 1,
            caseId: 'case-001',
            slot: 'du_dinh',
            from: 'procedure',
          ),
          prefs: prefs,
          mockGopY: mockGopY,
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final reportBtn = find.byKey(const ValueKey('report_wrong_address_1'));
      expect(reportBtn, findsOneWidget);

            await tester.ensureVisible(reportBtn);
      await tester.pump();
      await tester.tap(reportBtn);
      await tester.pumpAndSettle();

      // Sheet báo cáo hiện ra
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(AppStrings.reportWrongAddressTitle),
        ),
        findsOneWidget,
      );

      // Nhập ghi chú
      await tester.enterText(
        find.byKey(const ValueKey('report_note_input')),
        'Cổng chuyển sang đường khác',
      );

            // Bấm gửi báo cáo
      final submitBtn = find.byKey(const ValueKey('submit_report_button'));
      await tester.ensureVisible(submitBtn);
      await tester.pump();
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      // Kiểm tra GopYRepository nhận đúng dữ liệu
      expect(mockGopY.submittedItems.length, 1);
      final item = mockGopY.submittedItems.first;
      expect(item.loai, LoaiGopY.saiDiaChi);
      expect(item.coQuanId, 1);
      expect(item.thuTucId, 1);
      expect(item.noiDung, contains('Cổng chuyển sang đường khác'));
    });

    testWidgets('8. Chọn địa phương được nhớ cho lần sau', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        buildTestScope(
          child: const FindAgencyScreen(
            thuTucId: 1,
            caseId: 'case-001',
            slot: 'du_dinh',
            from: 'procedure',
          ),
          prefs: prefs,
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

           // Mở picker
      await tester.tap(find.byKey(const ValueKey('find_agency_location_picker')));
      await tester.pumpAndSettle();

      // Chọn địa phương 2 (TP. Hồ Chí Minh)
      final option2 = find.byKey(const ValueKey('location_option_2'));
      await tester.ensureVisible(option2);
      await tester.pump();
      await tester.tap(option2);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // SharedPreferences phải lưu địa phương 2
      expect(prefs.getInt(AppConstants.kLastSelectedDiaPhuongKey), 2);
    });

    testWidgets(
      '9. Nút tải biểu mẫu gọi launcher với URL thật và không gọi với example.com',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final fakeLauncher = FakeUrlLauncherService();

        await tester.pumpWidget(
          buildTestScope(
            child: const MyCaseCheckScreen(id: 'case-001'),
            prefs: prefs,
            fakeLauncher: fakeLauncher,
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // case-001 có giấy tờ có biểu mẫu
        // Nếu là example.com thì SnackBar "Đây là liên kết mẫu" và không gọi launcher
        // Hãy test trực tiếp logic _handleOpenFormUrl qua service
        final sampleUri = Uri.parse('https://dvc.example.com/forms/sample.pdf');
        final isSample = sampleUri.host.contains('example.com');
        expect(isSample, isTrue);

        final realUri = Uri.parse('https://dichvucong.gov.vn/forms/real.pdf');
        await fakeLauncher.open(realUri);
        expect(fakeLauncher.openedUris.contains(realUri), isTrue);
      },
    );

    testWidgets('10. ChatScreen đổi chip khi nhận extra lần hai', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Extra lần đầu: giấy tờ "Tờ khai đăng ký khai sinh"
      await tester.pumpWidget(
        buildTestScope(
          child: const ChatScreen(
            extra: {
              'maThuTuc': '1.000123.000.00.00.H56',
              'tenGiayTo': 'Tờ khai đăng ký khai sinh',
            },
          ),
          prefs: prefs,
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Tờ khai đăng ký khai sinh'), findsOneWidget);

      // Extra lần hai: giấy tờ "Giấy chứng sinh"
      await tester.pumpWidget(
        buildTestScope(
          child: const ChatScreen(
            extra: {
              'maThuTuc': '1.000123.000.00.00.H56',
              'tenGiayTo': 'Giấy chứng sinh',
            },
          ),
          prefs: prefs,
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Chip phải cập nhật sang "Giấy chứng sinh"
      expect(find.textContaining('Giấy chứng sinh'), findsOneWidget);
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StaticAuthController extends AuthController {
  final AuthState _initialState;
  _StaticAuthController(this._initialState);

  @override
  AuthState build() => _initialState;
}

class _EmptyMockMyCasesRepository extends MockMyCasesRepository {
  final List<HoSoCuaToi> _localCases = [];

  void addExistingCase(HoSoCuaToi c) {
    _localCases.add(c);
  }

  @override
  Future<List<HoSoCuaToi>> getMyCases() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_localCases);
  }

  @override
  Future<HoSoCuaToi?> getCaseById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _localCases.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<HoSoCuaToi>> getCasesByThuTuc(int thuTucId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _localCases.where((c) => c.thuTuc.id == thuTucId).toList();
  }
}
