import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dvc_guide_mobile/app/app.dart';
import 'package:dvc_guide_mobile/app/router/app_router.dart';
import 'package:dvc_guide_mobile/core/constants/app_constants.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/core/providers/shared_preferences_provider.dart';
import 'package:dvc_guide_mobile/features/auth/data/datasources/token_storage.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:dvc_guide_mobile/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:dvc_guide_mobile/features/auth/presentation/viewmodels/token_storage_provider.dart';
import 'package:dvc_guide_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/mock_my_cases_repository.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/my_cases_repository_provider.dart';
import 'package:dvc_guide_mobile/features/my_cases/domain/repositories/my_cases_repository.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/services/fake_reminder_service.dart';
import 'package:dvc_guide_mobile/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/fake_favorites_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/favorites_repository_provider.dart';
import 'package:dvc_guide_mobile/features/procedure/presentation/screens/procedure_detail_screen.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';
import 'package:dvc_guide_mobile/shared/widgets/section_card.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/viewmodels/reminder_coordinator.dart';

class EmptyFakeMyCasesRepository implements MyCasesRepository {
  @override
  Future<List<HoSoCuaToi>> getMyCases() async => [];
  @override
  Future<HoSoCuaToi?> getCaseById(String id) async => null;
  @override
  Future<List<HoSoCuaToi>> getCasesByThuTuc(int thuTucId) async => [];
  @override
  Future<HoSoCuaToi> addCase({
    required ThuTucSummary thuTuc,
    String? tenHoSo,
    int? truongHopId,
    int? coQuanDuDinhId,
    int? coQuanThucTeId,
    int? coQuanId,
    DateTime? ngayNop,
    String? maHoSo,
    DateTime? ngayHen,
    DateTime? hanTraKq,
    String? ghiChu,
    TrangThaiHoSo? trangThai,
    List<int>? allThanhPhanIds,
  }) async => throw UnimplementedError();
  @override
  Future<void> updateCase(
    String id, {
    String? tenHoSo,
    TrangThaiHoSo? trangThai,
    int? coQuanDuDinhId,
    int? coQuanThucTeId,
    DateTime? ngayNop,
    String? maHoSo,
    DateTime? ngayHen,
    String? ghiChu,
    int? truongHopId,
    bool clearDuDinh = false,
    bool clearThucTe = false,
  }) async {}
  @override
  Future<void> setGiayToStatus(
    String caseId,
    int thanhPhanId,
    TrangThaiGiayTo status,
  ) async {}
  @override
  Future<void> toggleChecklist(
    String hoSoId,
    int thanhPhanId,
    bool isReady,
  ) async {}
  @override
  Future<void> updateDates(
    String hoSoId, {
    DateTime? ngayNop,
    DateTime? hanTraKq,
    DateTime? ngayHen,
  }) async {}
  @override
  Future<void> updateTruongHop(String hoSoId, int? truongHopId) async {}
  @override
  Future<void> updateCoQuan(String hoSoId, int? coQuanId) async {}
  @override
  Future<void> deleteCase(String id) async {}
  @override
  Future<void> restoreCase(HoSoCuaToi caseToRestore, int index) async {}
  @override
  Future<void> clearAll() async {}
}

/// Dựng HomeScreen trong MaterialApp thường (không qua router của app).
Widget _buildHome({
  required FakeFavoritesRepository fav,
  required MyCasesRepository cases,
}) {
  return ProviderScope(
    overrides: [
      favoritesRepositoryProvider.overrideWithValue(fav),
      myCasesRepositoryProvider.overrideWithValue(cases),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('vi')],
      home: HomeScreen(),
    ),
  );
}

/// Chỉ xét các thẻ trong danh sách kết quả (không tính khối "Hồ sơ đang theo dõi").
Finder _inResults(String text) => find.descendant(
  of: find.byType(SectionCard),
  matching: find.textContaining(text),
);

void main() {
  group('Home & Navigation Tests', () {
    testWidgets(
      '1. Bottom navigation bar has exactly 4 tabs with correct labels and icons',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({
          kOnboardingSeenKey: true,
          AppConstants.kAuthGateSeenKey: true,
        });
        final prefs = await SharedPreferences.getInstance();
        final fakeStorage = FakeTokenStorage();
        final authRepo = MockAuthRepository(tokenStorage: fakeStorage);
        final fakeFav = FakeFavoritesRepository();
        final mockMyCases = MockMyCasesRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              tokenStorageProvider.overrideWithValue(fakeStorage),
              authRepositoryProvider.overrideWithValue(authRepo),
              favoritesRepositoryProvider.overrideWithValue(fakeFav),
              myCasesRepositoryProvider.overrideWithValue(mockMyCases),
              reminderServiceProvider.overrideWithValue(FakeReminderService()),
            ],
            child: const DvcGuideApp(),
          ),
        );

        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(seconds: 1));

        // 4 tab labels
        expect(find.text(AppStrings.navHome), findsOneWidget);
        expect(find.text(AppStrings.navAssistant), findsOneWidget);
        expect(find.text(AppStrings.navMyCases), findsOneWidget);
        expect(find.text(AppStrings.navSettings), findsOneWidget);

        // Old "Thủ tục" tab is gone
        expect(find.text('Thủ tục'), findsNothing);

        // Thanh tab có đúng 4 biểu tượng
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.byType(Icon),
          ),
          findsNWidgets(4),
        );
      },
    );

    testWidgets(
      '2. Search diacritics-insensitive "dang ky khai sinh" yields birth registration',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildHome(
            fav: FakeFavoritesRepository(),
            cases: MockMyCasesRepository(),
          ),
        );

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(seconds: 1));

        await tester.enterText(find.byType(TextField), 'dang ky khai sinh');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(seconds: 1));

        expect(_inResults('Đăng ký khai sinh'), findsOneWidget);
        expect(_inResults('Đăng ký thường trú'), findsNothing);
      },
    );

    testWidgets(
      '3. Multi-selecting 2 categories unions procedures belonging to either',
      (tester) async {
        // Màn rộng để hàng chip cuộn ngang dựng đủ mọi chip
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildHome(
            fav: FakeFavoritesRepository(),
            cases: MockMyCasesRepository(),
          ),
        );

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(seconds: 1));

        // Chọn 'Quản lý căn cước'
        await tester.tap(find.widgetWithText(FilterChip, 'Quản lý căn cước'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(seconds: 1));

        // Chọn thêm 'Quản lý cư trú'
        await tester.tap(find.widgetWithText(FilterChip, 'Quản lý cư trú'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(seconds: 1));

        // Kết quả là hợp của hai lĩnh vực
        expect(_inResults('Căn cước'), findsOneWidget);
        expect(_inResults('thường trú'), findsOneWidget);
        // Khai sinh (Hộ tịch) không có trong kết quả
        expect(_inResults('Đăng ký khai sinh'), findsNothing);
      },
    );

    testWidgets('4. Filter chip "Đã lưu" filters only favorited procedures', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Thủ tục 1 (khai sinh) là yêu thích
      await tester.pumpWidget(
        _buildHome(
          fav: FakeFavoritesRepository({1}),
          cases: MockMyCasesRepository(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.widgetWithText(FilterChip, AppStrings.filterSaved));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));

      expect(_inResults('Đăng ký khai sinh'), findsOneWidget);
      expect(_inResults('Đăng ký thường trú'), findsNothing);
      expect(_inResults('Căn cước'), findsNothing);
    });

    testWidgets(
      '5. Tapping heart icon toggles favorite without navigating away',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildHome(
            fav: FakeFavoritesRepository(),
            cases: MockMyCasesRepository(),
          ),
        );

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(seconds: 1));

        final heartBtn = find.byTooltip(AppStrings.favoriteTooltipAdd).first;
        await tester.tap(heartBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(seconds: 1));

        // Vẫn ở Trang chủ
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text(AppStrings.appName), findsOneWidget);

        expect(
          find.byTooltip(AppStrings.favoriteTooltipRemove),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '6. Procedure with >=2 cases opens bottom sheet, selecting pushes with truongHopId',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fakeFav = FakeFavoritesRepository();
        final mockMyCases = MockMyCasesRepository();

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(
              path: '/procedures/:id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                final thIdStr = state.uri.queryParameters['truongHopId'];
                final thId = thIdStr != null ? int.tryParse(thIdStr) : null;
                return ProcedureDetailScreen(id: id, initialTruongHopId: thId);
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoritesRepositoryProvider.overrideWithValue(fakeFav),
              myCasesRepositoryProvider.overrideWithValue(mockMyCases),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('vi')],
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(seconds: 1));

        // Bấm thủ tục khai sinh TRONG DANH SÁCH KẾT QUẢ (không phải thẻ hồ sơ)
        await tester.tap(_inResults('Đăng ký khai sinh').first);
        await tester.pump();
        await tester.pump(
          const Duration(milliseconds: 400),
        ); // chờ tải chi tiết
        await tester.pump(
          const Duration(milliseconds: 500),
        ); // chờ bảng trượt lên xong

        // Bảng chọn trường hợp hiện ra
        expect(find.text(AppStrings.selectYourCase), findsOneWidget);
        expect(find.text('Khai sinh có yếu tố nước ngoài'), findsOneWidget);

        // Chọn trường hợp 2
        await tester.tap(find.text('Khai sinh có yếu tố nước ngoài'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(ProcedureDetailScreen), findsOneWidget);
      },
    );

    testWidgets(
      '7. Active cases section hides when empty and shows when there are active cases',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fakeFav = FakeFavoritesRepository();

        // Phần A: chưa có hồ sơ nào
        await tester.pumpWidget(
          _buildHome(fav: fakeFav, cases: EmptyFakeMyCasesRepository()),
        );

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(AppStrings.activeTrackedCases), findsNothing);

        // Gỡ cây cũ để Trang chủ được dựng lại từ đầu ở phần B
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        // Phần B: có hồ sơ đang theo dõi
        await tester.pumpWidget(
          _buildHome(fav: fakeFav, cases: MockMyCasesRepository()),
        );

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(AppStrings.activeTrackedCases), findsOneWidget);
        expect(find.text(TrangThaiHoSo.dangChuanBi.displayName), findsWidgets);
      },
    );

    testWidgets(
      '8. Back button from procedure detail opened from Chat tab returns to Chat tab',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({
          kOnboardingSeenKey: true,
          AppConstants.kAuthGateSeenKey: true,
        });
        final prefs = await SharedPreferences.getInstance();
        final fakeStorage = FakeTokenStorage();
        final authRepo = MockAuthRepository(tokenStorage: fakeStorage);
        final fakeFav = FakeFavoritesRepository();
        final mockMyCases = MockMyCasesRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              tokenStorageProvider.overrideWithValue(fakeStorage),
              authRepositoryProvider.overrideWithValue(authRepo),
              favoritesRepositoryProvider.overrideWithValue(fakeFav),
                            myCasesRepositoryProvider.overrideWithValue(mockMyCases),
              reminderServiceProvider.overrideWithValue(FakeReminderService()),
            ],
            child: const DvcGuideApp(),
          ),
        );

        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(seconds: 1));

        // Chuyển sang tab Hỏi trợ lý AI
        await tester.tap(find.text(AppStrings.navAssistant));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text(AppStrings.aiAssistantTitle), findsOneWidget);

        // Mở chi tiết thủ tục bằng context.push từ tab này
        final chatElement = tester.element(
          find.text(AppStrings.aiAssistantTitle),
        );
        chatElement.push(AppRoutes.procedureDetailPath(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(ProcedureDetailScreen), findsOneWidget);

        // Bấm nút Back
        final backBtn = find.byType(BackButton);
        expect(backBtn, findsOneWidget);
        await tester.tap(backBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Quay về tab Hỏi trợ lý AI
        expect(find.byType(ProcedureDetailScreen), findsNothing);
        expect(find.text(AppStrings.aiAssistantTitle), findsOneWidget);
      },
    );
  });
}
