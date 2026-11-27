import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/core/services/url_launcher_service.dart';
import 'package:dvc_guide_mobile/features/chat/data/models/chat_models.dart';
import 'package:dvc_guide_mobile/features/chat/data/repositories/chat_repository_provider.dart';
import 'package:dvc_guide_mobile/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:dvc_guide_mobile/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:dvc_guide_mobile/features/chat/presentation/widgets/chat_message_item.dart';
import 'package:dvc_guide_mobile/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/mock_procedure_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/procedure_repository_provider.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

class _FakeCustomProcedureRepository extends MockProcedureRepository {
  final Map<String, ThuTucDetail> customProcedures;

  _FakeCustomProcedureRepository(this.customProcedures);

  @override
  Future<ThuTucDetail?> getProcedureByMa(String maThuTuc) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (customProcedures.containsKey(maThuTuc)) {
      return customProcedures[maThuTuc];
    }
    return super.getProcedureByMa(maThuTuc);
  }
}

void main() {
  group('Chat Answer State Mapper Unit & Widget Tests', () {
    testWidgets(
      'gate state renders gate card, no citations, search action button, and feedback buttons',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final message = TinNhan(
          id: 1,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung: AppStrings.gateFallbackAnswer,
          nguonTrichDan: const [
            '1.000123.000.00.00.H56',
          ], // Even if data had sources, gate must NOT display them
          trangThaiTraLoi: TrangThaiTraLoi.gate,
          taoLuc: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ChatMessageItem(
                  message: message,
                  feedbackValue: null,
                  onToggleFeedback: (_, {note}) {},
                  lastUserQuestion: 'hỏi gì đó',
                ),
              ),
            ),
          ),
        );

        // Gate card title must be visible
        expect(find.text(AppStrings.gateCardTitle), findsOneWidget);
        // Action button "Tìm trong danh sách thủ tục" must be present
        expect(find.text(AppStrings.searchInProceduresAction), findsOneWidget);
        // Citations header must NOT be visible in gate state
        expect(find.text(AppStrings.citationsLabel), findsNothing);
        // "Xem đầy đủ" must NOT be present in gate state
        expect(find.text(AppStrings.viewFullProcedure), findsNothing);

        // Feedback buttons must be present in gate state
        expect(
          find.widgetWithText(OutlinedButton, AppStrings.feedbackHelpful),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(OutlinedButton, AppStrings.feedbackNotCorrect),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'guard state renders guard card for out-of-scope question, without feedback buttons or view full button',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final message = TinNhan(
          id: 2,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung: AppStrings.guardCardTitle,
          trangThaiTraLoi: TrangThaiTraLoi.guard,
          taoLuc: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ChatMessageItem(
                  message: message,
                  feedbackValue: null,
                  onToggleFeedback: (_, {note}) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text(AppStrings.guardCardTitle), findsOneWidget);
        expect(find.text(AppStrings.guardCardSubtitle), findsOneWidget);

        // Guard must NOT have feedback buttons
        expect(
          find.widgetWithText(OutlinedButton, AppStrings.feedbackHelpful),
          findsNothing,
        );
        expect(
          find.widgetWithText(OutlinedButton, AppStrings.feedbackNotCorrect),
          findsNothing,
        );
        // Guard must NOT have "Xem đầy đủ" button
        expect(find.text(AppStrings.viewFullProcedure), findsNothing);
      },
    );

    testWidgets(
      'model state renders bubble with model disclaimer line and feedback buttons',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final message = TinNhan(
          id: 3,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung: 'Câu trả lời mô hình AI',
          trangThaiTraLoi: TrangThaiTraLoi.model,
          taoLuc: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ChatMessageItem(
                  message: message,
                  feedbackValue: null,
                  onToggleFeedback: (_, {note}) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Câu trả lời mô hình AI'), findsOneWidget);
        expect(find.text(AppStrings.modelDisclaimer), findsOneWidget);

        // Model state has feedback buttons
        expect(
          find.widgetWithText(OutlinedButton, AppStrings.feedbackHelpful),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(OutlinedButton, AppStrings.feedbackNotCorrect),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'answered state renders citations and toggles feedback buttons (text buttons instead of icons)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final message = TinNhan(
          id: 4,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung: 'Thủ tục đăng ký khai sinh',
          nguonTrichDan: const ['1.000123.000.00.00.H56'],
          trangThaiTraLoi: TrangThaiTraLoi.answered,
          taoLuc: DateTime.now(),
        );

        bool? feedbackToggled;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              procedureRepositoryProvider.overrideWithValue(
                MockProcedureRepository(),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ChatMessageItem(
                  message: message,
                  feedbackValue: true,
                  onToggleFeedback: (val, {note}) {
                    feedbackToggled = val;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Thủ tục đăng ký khai sinh'), findsOneWidget);
        expect(find.text(AppStrings.citationsLabel), findsOneWidget);

        // Text button "Hữu ích" triggers feedback
        final helpfulBtn = find.widgetWithText(
          OutlinedButton,
          AppStrings.feedbackHelpful,
        );
        expect(helpfulBtn, findsOneWidget);
        await tester.tap(helpfulBtn);
        expect(feedbackToggled, true);
      },
    );

    testWidgets(
      'TypingIndicator renders 3 bouncing dots',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TypingIndicator(),
            ),
          ),
        );

        expect(find.byType(TypingIndicator), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 200));
      },
    );

    testWidgets(
      '"Xem đầy đủ" button opens the first procedure in nguonTrichDan',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final message = TinNhan(
          id: 10,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung: 'Thông tin thủ tục khai sinh',
          nguonTrichDan: const [
            '1.000123.000.00.00.H56', // First procedure (id: 1)
            '1.000456.000.00.00.H56', // Second procedure (id: 2)
          ],
          trangThaiTraLoi: TrangThaiTraLoi.answered,
          taoLuc: DateTime.now(),
        );

        final router = GoRouter(
          initialLocation: '/chat',
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => Scaffold(
                body: ChatMessageItem(
                  message: message,
                  feedbackValue: null,
                  onToggleFeedback: (_, {note}) {},
                ),
              ),
            ),
            GoRoute(
              path: '/procedures/:id',
              builder: (context, state) => Scaffold(
                body: Text(
                  'PROCEDURE_DETAIL_${state.pathParameters['id']}',
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              procedureRepositoryProvider.overrideWithValue(
                MockProcedureRepository(),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Pump past FutureBuilder delay (200ms)
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final viewFullBtn = find.widgetWithText(
          FilledButton,
          AppStrings.viewFullProcedure,
        );
        expect(viewFullBtn, findsOneWidget);

        await tester.tap(viewFullBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // First procedure in nguonTrichDan is id 1
        expect(find.text('PROCEDURE_DETAIL_1'), findsOneWidget);
      },
    );

    testWidgets(
      '"Xem đầy đủ" button is disabled with caption when procedure code cannot be resolved',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final message = TinNhan(
          id: 11,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung: 'Thông tin thủ tục không tồn tại',
          nguonTrichDan: const ['MA_KHONG_TON_TAI_999'],
          trangThaiTraLoi: TrangThaiTraLoi.answered,
          taoLuc: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              procedureRepositoryProvider.overrideWithValue(
                MockProcedureRepository(),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ChatMessageItem(
                  message: message,
                  feedbackValue: null,
                  onToggleFeedback: (_, {note}) {},
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final viewFullBtnFinder = find.widgetWithText(
          FilledButton,
          AppStrings.viewFullProcedure,
        );
        expect(viewFullBtnFinder, findsOneWidget);

        final buttonWidget = tester.widget<FilledButton>(viewFullBtnFinder);
        // Nút bị vô hiệu
        expect(buttonWidget.onPressed, isNull);
        // Kèm chú thích "Nguồn không còn khả dụng"
        expect(find.text(AppStrings.sourceUnavailable), findsWidgets);
      },
    );

    test(
      'two feedback buttons: helpful then not correct overwrites, tapping same retains feedback',
      () async {
        final container = ProviderContainer(
          overrides: [
            chatRepositoryProvider.overrideWithValue(MockChatRepository()),
            procedureRepositoryProvider.overrideWithValue(
              MockProcedureRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(chatViewModelProvider(null).notifier);

        // 1. Bấm "Hữu ích"
        await notifier.toggleFeedback(1, true);
        expect(container.read(chatViewModelProvider(null)).feedbacks[1], true);
        final mockRepo =
            container.read(chatRepositoryProvider) as MockChatRepository;
        expect(
          mockRepo.feedbacks.where((f) => f.tinNhanId == 1).single.huuIch,
          true,
        );

        // 2. Bấm "Chưa đúng" -> GHI ĐÈ
        await notifier.toggleFeedback(1, false);
        expect(container.read(chatViewModelProvider(null)).feedbacks[1], false);
        expect(
          mockRepo.feedbacks.where((f) => f.tinNhanId == 1).single.huuIch,
          false,
        );

        // 3. Bấm lại "Chưa đúng" -> GIỮ NGUYÊN (không bỏ chọn được)
        await notifier.toggleFeedback(1, false);
        expect(container.read(chatViewModelProvider(null)).feedbacks[1], false);
        expect(
          mockRepo.feedbacks.where((f) => f.tinNhanId == 1).single.huuIch,
          false,
        );
      },
    );

    testWidgets(
      'download form button only appears when procedure has real url and opens via UrlLauncherService',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fakeLauncher = FakeUrlLauncherService();
        const realDocxUrl = 'https://dvc.gov.vn/forms/mau_don.docx';

        final testProcedureWithRealUrl = ThuTucDetail(
          id: 99,
          maThuTuc: 'TEST_REAL_FORM_PROC',
          ten: 'Thủ tục có biểu mẫu thật',
          thanhPhanHoSo: [
            const ThanhPhanHoSo(
              id: 1,
              tenGiayTo: 'Đơn đề nghị',
              bieuMau: BieuMau(
                id: 1,
                ten: 'Mẫu đơn đề nghị',
                fileDocxUrl: realDocxUrl,
              ),
            ),
          ],
        );

        final customRepo = _FakeCustomProcedureRepository({
          'TEST_REAL_FORM_PROC': testProcedureWithRealUrl,
        });

        final message = TinNhan(
          id: 20,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung: 'Thủ tục này có biểu mẫu tải về',
          nguonTrichDan: const ['TEST_REAL_FORM_PROC'],
          trangThaiTraLoi: TrangThaiTraLoi.answered,
          taoLuc: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              procedureRepositoryProvider.overrideWithValue(customRepo),
              urlLauncherServiceProvider.overrideWithValue(fakeLauncher),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ChatMessageItem(
                  message: message,
                  feedbackValue: null,
                  onToggleFeedback: (_, {note}) {},
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Nút "Tải biểu mẫu" hiện ra
        final downloadBtn = find.widgetWithText(
          OutlinedButton,
          AppStrings.downloadTemplateAction,
        );
        expect(downloadBtn, findsOneWidget);

        // Bấm nút -> gọi UrlLauncherService
        await tester.tap(downloadBtn);
        await tester.pump();

        expect(fakeLauncher.openedUris, [Uri.parse(realDocxUrl)]);

        // ── Kiểm tra trường hợp URL là example.com: Nút KHÔNG hiện ──
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        final testProcedureWithExampleUrl = ThuTucDetail(
          id: 98,
          maThuTuc: 'TEST_EXAMPLE_FORM_PROC',
          ten: 'Thủ tục biểu mẫu example.com',
          thanhPhanHoSo: [
            const ThanhPhanHoSo(
              id: 2,
              tenGiayTo: 'Giấy khai',
              bieuMau: BieuMau(
                id: 2,
                ten: 'Mẫu giấy khai',
                fileDocxUrl: 'https://example.com/forms/mau_khai.docx',
              ),
            ),
          ],
        );

        final customRepoExample = _FakeCustomProcedureRepository({
          'TEST_EXAMPLE_FORM_PROC': testProcedureWithExampleUrl,
        });

        final messageExample = TinNhan(
          id: 21,
          vaiTro: VaiTroTinNhan.assistant,
          noiDung: 'Thủ tục mẫu với link example.com',
          nguonTrichDan: const ['TEST_EXAMPLE_FORM_PROC'],
          trangThaiTraLoi: TrangThaiTraLoi.answered,
          taoLuc: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              procedureRepositoryProvider.overrideWithValue(customRepoExample),
              urlLauncherServiceProvider.overrideWithValue(fakeLauncher),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ChatMessageItem(
                  message: messageExample,
                  feedbackValue: null,
                  onToggleFeedback: (_, {note}) {},
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Nút "Tải biểu mẫu" KHÔNG hiện khi là example.com
        expect(
          find.widgetWithText(
            OutlinedButton,
            AppStrings.downloadTemplateAction,
          ),
          findsNothing,
        );
      },
    );
  });
}
