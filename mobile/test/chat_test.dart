import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/features/chat/data/repositories/chat_repository_provider.dart';
import 'package:dvc_guide_mobile/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:dvc_guide_mobile/features/chat/presentation/screens/chat_screen.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/mock_procedure_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/procedure_repository_provider.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';

void main() {
  group('Chat Repository with Paper Context Tests', () {
    test('MockChatRepository returns answer mentioning paper name when thamSo provided', () async {
      final repo = MockChatRepository();
      final res = await repo.sendMessage(
        'Giấy tờ cần chuẩn bị thế nào?',
        maThuTucContext: '1.000123.000.00.00.H56',
        thamSo: {
          'ten_giay_to': 'Giấy chứng sinh',
          'thanh_phan_ho_so_id': 2,
        },
      );

      expect(res.vaiTro, VaiTroTinNhan.assistant);
      expect(res.noiDung, contains('Giấy chứng sinh'));
      expect(res.nguonTrichDan, contains('1.000123.000.00.00.H56'));
      expect(res.trangThaiTraLoi, TrangThaiTraLoi.answered);
    });
  });

  group('ChatScreen Paper Context Widget Tests', () {
    testWidgets('ChatScreen shows paper context chip and prefilled unsent question', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final mockChatRepo = MockChatRepository();
      const testPaperName = 'Tờ khai đăng ký khai sinh';
      const testQuestion = "Giấy tờ '$testPaperName' là gì và cần chuẩn bị thế nào?";

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWith((ref) => mockChatRepo),
            procedureRepositoryProvider.overrideWith((ref) => MockProcedureRepository()),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('vi')],
            home: ChatScreen(
              extra: {
                'maThuTuc': '1.000123.000.00.00.H56',
                'tenGiayTo': testPaperName,
                'thanhPhanHoSoId': 1,
                'initialQuestion': testQuestion,
              },
            ),
          ),
        ),
      );

      // Pump to let mock init finish (200ms)
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Procedure context chip is rendered
      expect(find.textContaining(AppStrings.contextAskingAbout), findsOneWidget);

      // Paper context chip is rendered
      expect(find.textContaining(AppStrings.contextAskingAboutPaper), findsOneWidget);
      expect(find.textContaining(testPaperName), findsWidgets);

      // TextField has the question prefilled
      expect(find.widgetWithText(TextField, testQuestion), findsOneWidget);

      // Message is NOT sent automatically (no user message bubble)
      expect(find.text(testQuestion), findsOneWidget); // Only inside the TextField
    });

    testWidgets('Removing paper context chip clears paper context', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final mockChatRepo = MockChatRepository();
      const testPaperName = 'Giấy chứng sinh';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWith((ref) => mockChatRepo),
            procedureRepositoryProvider.overrideWith((ref) => MockProcedureRepository()),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('vi')],
            home: ChatScreen(
              extra: {
                'maThuTuc': '1.000123.000.00.00.H56',
                'tenGiayTo': testPaperName,
                'thanhPhanHoSoId': 2,
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.textContaining(AppStrings.contextAskingAboutPaper), findsOneWidget);

      // Find delete button on paper chip
      final clearPaperBtn = find.byTooltip(AppStrings.clearPaperContext);
      expect(clearPaperBtn, findsOneWidget);
      await tester.tap(clearPaperBtn);
      await tester.pumpAndSettle();

      // Paper context chip is gone
      expect(find.textContaining(AppStrings.contextAskingAboutPaper), findsNothing);
    });
  });
}
