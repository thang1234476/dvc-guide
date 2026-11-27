import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/features/chat/data/models/chat_models.dart';
import 'package:dvc_guide_mobile/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:dvc_guide_mobile/features/chat/presentation/screens/chat_screen.dart';
import 'package:dvc_guide_mobile/features/chat/presentation/widgets/chat_message_item.dart';
import 'package:dvc_guide_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/models/my_case_models.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/mock_my_cases_repository.dart';
import 'package:dvc_guide_mobile/features/my_cases/data/repositories/my_cases_repository_provider.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/screens/my_case_check_screen.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/screens/my_case_detail_screen.dart';
import 'package:dvc_guide_mobile/features/my_cases/presentation/screens/my_cases_screen.dart';
import 'package:dvc_guide_mobile/features/procedure/data/mock/procedure_mock_data.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/fake_favorites_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/favorites_repository_provider.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/mock_procedure_repository.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/procedure_repository_provider.dart';
import 'package:dvc_guide_mobile/shared/enums/procedure_enums.dart';
import 'package:dvc_guide_mobile/app/router/app_router.dart';

void main() {
  group('Schema v3 Enums & JSON Tests', () {
    test(
      'TrangThaiHoSo JSON serialization & deserialization matches snake_case',
      () {
        expect(TrangThaiHoSo.dangChuanBi.toJson(), 'dang_chuan_bi');
        expect(TrangThaiHoSo.daNop.toJson(), 'da_nop');
        expect(TrangThaiHoSo.dangXuLy.toJson(), 'dang_xu_ly');
        expect(TrangThaiHoSo.canBoSung.toJson(), 'can_bo_sung');
        expect(TrangThaiHoSo.daNhanKetQua.toJson(), 'da_nhan_ket_qua');

        expect(
          TrangThaiHoSo.fromJson('dang_chuan_bi'),
          TrangThaiHoSo.dangChuanBi,
        );
        expect(TrangThaiHoSo.fromJson('da_nop'), TrangThaiHoSo.daNop);
        expect(TrangThaiHoSo.fromJson('dang_xu_ly'), TrangThaiHoSo.dangXuLy);
        expect(TrangThaiHoSo.fromJson('can_bo_sung'), TrangThaiHoSo.canBoSung);
        expect(
          TrangThaiHoSo.fromJson('da_nhan_ket_qua'),
          TrangThaiHoSo.daNhanKetQua,
        );
      },
    );

    test(
      'TrangThaiGiayTo JSON serialization & deserialization matches snake_case',
      () {
        expect(TrangThaiGiayTo.daCo.toJson(), 'da_co');
        expect(TrangThaiGiayTo.chuaCo.toJson(), 'chua_co');
        expect(TrangThaiGiayTo.chuaRo.toJson(), 'chua_ro');

        expect(TrangThaiGiayTo.fromJson('da_co'), TrangThaiGiayTo.daCo);
        expect(TrangThaiGiayTo.fromJson('chua_co'), TrangThaiGiayTo.chuaCo);
        expect(TrangThaiGiayTo.fromJson('chua_ro'), TrangThaiGiayTo.chuaRo);
      },
    );

    test(
      'NguonDiaChi JSON serialization & deserialization matches snake_case',
      () {
        expect(NguonDiaChi.duLieuGoc.toJson(), 'du_lieu_goc');
        expect(NguonDiaChi.ai.toJson(), 'ai');
        expect(NguonDiaChi.quanTri.toJson(), 'quan_tri');

        expect(NguonDiaChi.fromJson('du_lieu_goc'), NguonDiaChi.duLieuGoc);
        expect(NguonDiaChi.fromJson('ai'), NguonDiaChi.ai);
        expect(NguonDiaChi.fromJson('quan_tri'), NguonDiaChi.quanTri);
      },
    );

    test(
      'LoaiGopY JSON serialization & deserialization matches snake_case',
      () {
        expect(LoaiGopY.gopY.toJson(), 'gop_y');
        expect(LoaiGopY.baoLoi.toJson(), 'bao_loi');
        expect(LoaiGopY.saiDiaChi.toJson(), 'sai_dia_chi');

        expect(LoaiGopY.fromJson('gop_y'), LoaiGopY.gopY);
        expect(LoaiGopY.fromJson('bao_loi'), LoaiGopY.baoLoi);
        expect(LoaiGopY.fromJson('sai_dia_chi'), LoaiGopY.saiDiaChi);
      },
    );

    test(
      'CoQuan default nguonDiaChi is du_lieu_goc and daKiemChung is false',
      () {
        final json = {'id': 99, 'ten': 'Cơ quan thử nghiệm', 'cap': 'xa'};
        final cq = CoQuan.fromJson(json);
        expect(cq.nguonDiaChi, NguonDiaChi.duLieuGoc);
        expect(cq.daKiemChung, isFalse);
        expect(cq.kiemChungLuc, isNull);
        expect(cq.viDo, isNull);
        expect(cq.kinhDo, isNull);
        expect(cq.gioPhatSo, isNull);
      },
    );
  });

  group('HoSoCuaToi Legacy Data Compatibility Tests', () {
    test(
      'Loads legacy case format: checklist bool, han_tra_kq, missing ten_ho_so',
      () {
        final legacyJson = {
          'id': 'legacy-001',
          'thu_tuc': {
            'id': 1,
            'ma_thu_tuc': '1.000123.000.00.00.H56',
            'ten': 'Đăng ký khai sinh',
          },
          'truong_hop_id': 1,
          'co_quan_id': 1,
          'ngay_nop': '2026-03-01T08:00:00.000',
          'han_tra_kq': '2026-03-05T17:00:00.000',
          'checklist': {
            '1': true, // should map to da_co
            '2': false, // false should be omitted (chưa rõ)
          },
        };

        final hoSo = HoSoCuaToi.fromJson(legacyJson);

        // tenHoSo defaults to procedure name
        expect(hoSo.tenHoSo, 'Đăng ký khai sinh');

        // hanTraKq mapped to ngayHen
        expect(hoSo.ngayHen, DateTime.parse('2026-03-05T17:00:00.000'));
        expect(hoSo.hanTraKq, DateTime.parse('2026-03-05T17:00:00.000'));

        // checklist: true -> daCo, false -> missing key
        expect(hoSo.checklist[1], TrangThaiGiayTo.daCo);
        expect(hoSo.checklist.containsKey(2), isFalse);

        // default status is dangChuanBi
        expect(hoSo.trangThai, TrangThaiHoSo.dangChuanBi);

        // co_quan_id mapped to coQuanDuDinhId
        expect(hoSo.coQuanDuDinhId, 1);
        expect(hoSo.coQuanId, 1);
      },
    );
  });

  group('My Cases Repository & Domain Logic Tests', () {
    late MockMyCasesRepository repository;

    setUp(() {
      repository = MockMyCasesRepository();
    });

    test('Initial mock cases are loaded correctly with schema v3', () async {
      final cases = await repository.getMyCases();
      expect(cases.length, greaterThanOrEqualTo(2));
      expect(cases.any((c) => c.thuTuc.id == 1), isTrue); // Khai sinh
      expect(cases.any((c) => c.thuTuc.id == 4), isTrue); // Thường trú

      final case1 = cases.firstWhere((c) => c.id == 'case-001');
      expect(case1.trangThai, TrangThaiHoSo.dangChuanBi);
      expect(case1.maHoSo, isNotNull);
      expect(case1.ngayHen, isNotNull);
      expect(case1.checklist[1], TrangThaiGiayTo.daCo);
      expect(case1.checklist[2], TrangThaiGiayTo.chuaCo);
    });

    test(
      'addCase allows multiple cases for the same procedure with unique names and IDs',
      () async {
        final summary = mockProcedureSummaries[1]; // Đăng ký kết hôn (id = 2)

        final case1 = await repository.addCase(thuTuc: summary);
        expect(case1.thuTuc.id, 2);
        expect(case1.tenHoSo, summary.ten);

        final case2 = await repository.addCase(thuTuc: summary);
        expect(case2.thuTuc.id, 2);
        expect(case2.id, isNot(equals(case1.id)));
        expect(case2.tenHoSo, '${summary.ten} (2)');

        final case3 = await repository.addCase(thuTuc: summary);
        expect(case3.tenHoSo, '${summary.ten} (3)');

        final currentCases = await repository.getCasesByThuTuc(2);
        expect(currentCases.length, 3);
      },
    );

    // Test: đổi trạng thái hồ sơ tự do (kể cả quay lại bước trước) và được lưu
    test(
      'updateCase allows freely switching status forward and backward and persists',
      () async {
        final cases = await repository.getMyCases();
        final case1 = cases.firstWhere((c) => c.id == 'case-001');
        expect(case1.trangThai, TrangThaiHoSo.dangChuanBi);

        // Chuyển tới: dangXuLy
        await repository.updateCase(
          case1.id,
          trangThai: TrangThaiHoSo.dangXuLy,
        );
        var updated = await repository.getCaseById(case1.id);
        expect(updated?.trangThai, TrangThaiHoSo.dangXuLy);

        // Chuyển tới: daNhanKetQua
        await repository.updateCase(
          case1.id,
          trangThai: TrangThaiHoSo.daNhanKetQua,
        );
        updated = await repository.getCaseById(case1.id);
        expect(updated?.trangThai, TrangThaiHoSo.daNhanKetQua);

        // Quay lại bước trước tự do: canBoSung
        await repository.updateCase(
          case1.id,
          trangThai: TrangThaiHoSo.canBoSung,
        );
        updated = await repository.getCaseById(case1.id);
        expect(updated?.trangThai, TrangThaiHoSo.canBoSung);

        // Quay lại bước đầu tiên: dangChuanBi
        await repository.updateCase(
          case1.id,
          trangThai: TrangThaiHoSo.dangChuanBi,
        );
        updated = await repository.getCaseById(case1.id);
        expect(updated?.trangThai, TrangThaiHoSo.dangChuanBi);
      },
    );

    // Test: sửa tên hồ sơ
    test('updateCase edits tenHoSo and persists', () async {
      final cases = await repository.getMyCases();
      final case1 = cases.firstWhere((c) => c.id == 'case-001');

      await repository.updateCase(case1.id, tenHoSo: 'Hồ sơ khai sinh bé An');
      final updated = await repository.getCaseById(case1.id);
      expect(updated?.tenHoSo, 'Hồ sơ khai sinh bé An');
    });

    // Test: tóm tắt đếm đúng (giấy tờ không có dòng là Chưa rõ)
    test(
      'Summary counting treats papers without an explicit entry as Chưa rõ',
      () {
        final testPapers = [
          const ThanhPhanHoSo(id: 1, tenGiayTo: 'Giấy tờ 1', batBuoc: true),
          const ThanhPhanHoSo(id: 2, tenGiayTo: 'Giấy tờ 2', batBuoc: true),
          const ThanhPhanHoSo(id: 3, tenGiayTo: 'Giấy tờ 3', batBuoc: false),
          const ThanhPhanHoSo(id: 4, tenGiayTo: 'Giấy tờ 4', batBuoc: null),
        ];

        // Checklist only sets id 1 = daCo, id 2 = chuaCo.
        // ids 3 and 4 have no entry (defaulting to chuaRo).
        final checklist = <int, TrangThaiGiayTo>{
          1: TrangThaiGiayTo.daCo,
          2: TrangThaiGiayTo.chuaCo,
        };

        int daCo = 0;
        int chuaCo = 0;
        int chuaRo = 0;

        for (final p in testPapers) {
          final status = checklist[p.id] ?? TrangThaiGiayTo.chuaRo;
          switch (status) {
            case TrangThaiGiayTo.daCo:
              daCo++;
              break;
            case TrangThaiGiayTo.chuaCo:
              chuaCo++;
              break;
            case TrangThaiGiayTo.chuaRo:
              chuaRo++;
              break;
          }
        }

        expect(daCo, 1);
        expect(chuaCo, 1);
        expect(chuaRo, 2); // Both id 3 and id 4 are counted as Chưa rõ
      },
    );

    // Test: chọn Đã có / Chưa có / Chưa rõ cập nhật tóm tắt
    test(
      'setGiayToStatus updates checklist across daCo, chuaCo, and chuaRo',
      () async {
        final cases = await repository.getMyCases();
        final case1 = cases.firstWhere((c) => c.id == 'case-001');

        // Đặt là Đã có
        await repository.setGiayToStatus(case1.id, 20, TrangThaiGiayTo.daCo);
        var updated = await repository.getCaseById(case1.id);
        expect(updated?.checklist[20], TrangThaiGiayTo.daCo);

        // Chuyển sang Chưa có
        await repository.setGiayToStatus(case1.id, 20, TrangThaiGiayTo.chuaCo);
        updated = await repository.getCaseById(case1.id);
        expect(updated?.checklist[20], TrangThaiGiayTo.chuaCo);

        // Chuyển sang Chưa rõ (xóa khỏi map để biểu thị chưa rõ)
        await repository.setGiayToStatus(case1.id, 20, TrangThaiGiayTo.chuaRo);
        updated = await repository.getCaseById(case1.id);
        expect(updated?.checklist.containsKey(20), isFalse);
      },
    );

    // Test: xóa rồi hoàn tác
    test('deleteCase and restoreCase functionality', () async {
      final initialCases = await repository.getMyCases();
      final targetCase = initialCases.first;

      await repository.deleteCase(targetCase.id);
      final afterDelete = await repository.getMyCases();
      expect(afterDelete.any((c) => c.id == targetCase.id), isFalse);

      await repository.restoreCase(targetCase, 0);
      final afterRestore = await repository.getMyCases();
      expect(afterRestore.any((c) => c.id == targetCase.id), isTrue);
      expect(afterRestore.first.id, targetCase.id);
    });

    test('updateTruongHop retains checked paper status', () async {
      final cases = await repository.getMyCases();
      final case1 = cases.firstWhere((c) => c.id == 'case-001');
      expect(case1.truongHopId, 1);
      expect(case1.checklist[1], TrangThaiGiayTo.daCo);

      await repository.updateTruongHop('case-001', 2);
      final updated = await repository.getCaseById('case-001');
      expect(updated?.truongHopId, 2);
      expect(updated?.checklist[1], TrangThaiGiayTo.daCo);
    });
  });

  group('Favorites & Chat Tests', () {
    test('FavoritesRepository toggle and isFavorite work correctly', () async {
      final favRepo = FakeFavoritesRepository();

      expect(await favRepo.isFavorite(1), isFalse);
      expect((await favRepo.getFavoriteIds()).isEmpty, isTrue);

      final added = await favRepo.toggle(1);
      expect(added, isTrue);
      expect(await favRepo.isFavorite(1), isTrue);
      expect((await favRepo.getFavoriteIds()).contains(1), isTrue);

      final removed = await favRepo.toggle(1);
      expect(removed, isFalse);
      expect(await favRepo.isFavorite(1), isFalse);
      expect((await favRepo.getFavoriteIds()).contains(1), isFalse);
    });

    test(
      'setFeedback overwrites existing feedback for the same message',
      () async {
        final chatRepo = MockChatRepository();

        await chatRepo.setFeedback(1, true);
        expect(chatRepo.feedbacks.where((f) => f.tinNhanId == 1).length, 1);
        expect(
          chatRepo.feedbacks.firstWhere((f) => f.tinNhanId == 1).huuIch,
          isTrue,
        );

        await chatRepo.setFeedback(1, false);
        expect(chatRepo.feedbacks.where((f) => f.tinNhanId == 1).length, 1);
        expect(
          chatRepo.feedbacks.firstWhere((f) => f.tinNhanId == 1).huuIch,
          isFalse,
        );
      },
    );
  });

  group('My Cases Widget Tests', () {
    // Test: thẻ danh sách hiện chip trạng thái, tiến độ, nhãn ngày hẹn và ẩn nhãn khi đã nhận kết quả
    testWidgets(
      'MyCasesScreen renders case cards with status chip, progress, deadline badge, and hides deadline badge on da_nhan_ket_qua',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = MockMyCasesRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [myCasesRepositoryProvider.overrideWith((ref) => repo)],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('vi')],
              home: MyCasesScreen(),
            ),
          ),
        );

        // Let mock delay finish (200ms)
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 100));

        // Case names (tenHoSo) & codes
        expect(find.textContaining('Đăng ký khai sinh'), findsWidgets);
        expect(find.textContaining('Đăng ký thường trú'), findsWidgets);
        expect(find.textContaining('1.000123'), findsOneWidget);
        expect(find.textContaining('1.002345'), findsOneWidget);

        // Status chips
        expect(find.text(AppStrings.statusCasePreparing), findsOneWidget);
        expect(find.text(AppStrings.statusCaseProcessing), findsOneWidget);

        // Progress text
        expect(find.textContaining(AppStrings.papersReadySuffix), findsWidgets);

        // Deadline badges: case-001 is Remaining 2 days, case-002 is Overdue
        expect(
          find.textContaining(AppStrings.remainingDaysPrefix),
          findsOneWidget,
        );
        expect(find.text(AppStrings.overdueBadge), findsOneWidget);

        // Now update case-001 to daNhanKetQua -> deadline badge should be HIDDEN
        await tester.runAsync(
          () => repo.updateCase(
            'case-001',
            trangThai: TrangThaiHoSo.daNhanKetQua,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        await tester.pumpWidget(
          const SizedBox.shrink(),
        ); // gỡ cây cũ để dựng lại từ đầu
        await tester.pump();

        // Rebuild widget with updated repo
        await tester.pumpWidget(
          ProviderScope(
            overrides: [myCasesRepositoryProvider.overrideWith((ref) => repo)],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('vi')],
              home: MyCasesScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 100));

        // Case-001's deadline badge "Còn ... ngày" is hidden because trangThai is daNhanKetQua!
        expect(
          find.textContaining(AppStrings.remainingDaysPrefix),
          findsNothing,
        );
      },
    );

    // Test: chi tiết hồ sơ (dựng lại, không có checklist trên màn này, có thanh trạng thái, tóm tắt)
    testWidgets(
      'MyCaseDetailScreen renders header, procedure card, 5 status steps, summary card, and no paper checklist',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myCasesRepositoryProvider.overrideWith(
                (ref) => MockMyCasesRepository(),
              ),
              procedureRepositoryProvider.overrideWith(
                (ref) => MockProcedureRepository(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('vi')],
              home: MyCaseDetailScreen(id: 'case-001'),
            ),
          ),
        );

        // Let mock delay finish (150ms + 300ms)
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Case title in AppBar
        expect(find.textContaining('Đăng ký khai sinh'), findsWidgets);

        // Edit name pen icon
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

        // 5 horizontal status steps
        for (final step in TrangThaiHoSo.values) {
          expect(find.text(step.displayName), findsWidgets);
        }

        // Summary card & button to check papers
        expect(find.text(AppStrings.paperStatusSummary), findsOneWidget);
        expect(find.text(AppStrings.checkPapersAction), findsOneWidget);

        // Dates & Text fields
        expect(find.text(AppStrings.submittedDate), findsOneWidget);
        expect(find.text(AppStrings.expectedReturnDate), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'HSO-2026-000123'),
          findsOneWidget,
        );

        // "Hỏi AI về hồ sơ này" button
        expect(find.text(AppStrings.askAiAboutThisCase), findsOneWidget);

        // Checklist papers are NOT on this screen
        expect(find.text('Tờ khai đăng ký khai sinh'), findsNothing);
      },
    );

    // Test: sửa tên hồ sơ qua dialog trên MyCaseDetailScreen
    testWidgets('Editing case name via dialog updates title', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = MockMyCasesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myCasesRepositoryProvider.overrideWith((ref) => repo),
            procedureRepositoryProvider.overrideWith(
              (ref) => MockProcedureRepository(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('vi')],
            home: MyCaseDetailScreen(id: 'case-001'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Tap edit pen icon
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text(AppStrings.editCaseName), findsOneWidget);
      final field = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(field, findsOneWidget);

      // Enter new name
      await tester.enterText(field, 'Khai sinh cho bé Bắp');
      await tester.pump();

      // Tap Lưu
      await tester.tap(find.text(AppStrings.saveAction));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify name updated
      final updatedCase = await tester.runAsync(
        () => repo.getCaseById('case-001'),
      );
      expect(updatedCase?.tenHoSo, 'Khai sinh cho bé Bắp');
    });

    // Test: màn /my-cases/:id/check hiển thị danh sách giấy tờ và cập nhật SegmentedButton
    testWidgets(
      'MyCaseCheckScreen renders stats, disclaimer, and updates paper status via SegmentedButton',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = MockMyCasesRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myCasesRepositoryProvider.overrideWith((ref) => repo),
              procedureRepositoryProvider.overrideWith(
                (ref) => MockProcedureRepository(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('vi')],
              home: MyCaseCheckScreen(id: 'case-001'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Screen title and subtitle
        expect(find.text(AppStrings.checkPapersTitle), findsOneWidget);

        // Disclaimer banner
        expect(find.text(AppStrings.preparationDisclaimer), findsOneWidget);

        // Stat boxes (Đã có, Chưa có, Chưa rõ)
        expect(find.text(AppStrings.readyCountLabel), findsWidgets);
        expect(find.text(AppStrings.missingCountLabel), findsWidgets);
        expect(find.text(AppStrings.unknownCountLabel), findsWidgets);

        // Papers list with SegmentedButtons
        expect(find.byType(SegmentedButton<TrangThaiGiayTo>), findsWidgets);

        // Missing papers section at bottom
        expect(find.text(AppStrings.missingPapersTitle), findsOneWidget);
      },
    );

    // Test: thẻ câu hỏi làm rõ chỉ hiện khi thủ tục có từ 2 trường hợp
    testWidgets(
      'Determine case card only shows when procedure has 2 or more cases',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = MockMyCasesRepository();

        // Case 1: procedure 1 (Khai sinh) has 2 cases -> should show card
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myCasesRepositoryProvider.overrideWith((ref) => repo),
              procedureRepositoryProvider.overrideWith(
                (ref) => MockProcedureRepository(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('vi')],
              home: MyCaseCheckScreen(id: 'case-001'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.determineCaseTitle), findsOneWidget);

        // Now create a procedure with only 1 case
        final singleCaseProcedure = mockProcedureDetails[0].copyWith(
          id: 999,
          truongHop: [mockProcedureDetails[0].truongHop.first],
        );
        final singleCaseSummary = mockProcedureSummaries[0].copyWith(id: 999);
        final singleCase = HoSoCuaToi(
          id: 'case-single',
          tenHoSo: 'Thủ tục 1 trường hợp',
          thuTuc: singleCaseSummary,
          truongHopId: 1,
        );

        final customRepo = MockMyCasesRepository();
        await tester.runAsync(() => customRepo.restoreCase(singleCase, 0));

        // Create a fake procedure repo returning singleCaseProcedure
        final fakeProcRepo = _FakeSingleProcedureRepo(singleCaseProcedure);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              myCasesRepositoryProvider.overrideWith((ref) => customRepo),
              procedureRepositoryProvider.overrideWith((ref) => fakeProcRepo),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('vi')],
              home: MyCaseCheckScreen(id: 'case-single'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // When procedure has only 1 case, the card is NOT shown
        expect(find.text(AppStrings.determineCaseTitle), findsNothing);
      },
    );

    // Test: chọn trường hợp lọc lại danh sách và giữ trạng thái đã đánh dấu
    testWidgets(
      'Selecting a case filters the papers list and preserves marked status',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = MockMyCasesRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myCasesRepositoryProvider.overrideWith((ref) => repo),
              procedureRepositoryProvider.overrideWith(
                (ref) => MockProcedureRepository(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('vi')],
              home: MyCaseCheckScreen(id: 'case-001'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Initially case-001 has truongHopId = 1.
        // Paper 1 is marked daCo, paper 3 (truongHopId: 2) is NOT present.
        expect(find.text('Tờ khai đăng ký khai sinh theo mẫu'), findsOneWidget);
        expect(
          find.text('Văn bản thỏa thuận lựa chọn quốc tịch cho con của cha mẹ'),
          findsNothing,
        );

        // Tap "Đổi" to expand the case selection card
        final changeBtn = find.text(AppStrings.changeCaseShort);
        expect(changeBtn, findsOneWidget);
        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        // Tap on case 2 (id: 2)
        final case2Title =
            mockProcedureDetails[0].truongHop[1].cauHoiPhanLoai ??
            mockProcedureDetails[0].truongHop[1].ten;
        final case2Tile = find.text(case2Title);
        expect(case2Tile, findsOneWidget);
        await tester.tap(case2Tile);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Paper 3 is now shown for case 2!
        expect(
          find.text('Văn bản thỏa thuận lựa chọn quốc tịch cho con của cha mẹ'),
          findsWidgets,
        );

        // And paper 1's status is preserved as daCo
        final updatedCase = await tester.runAsync(
          () => repo.getCaseById('case-001'),
        );
        expect(updatedCase?.checklist[1], TrangThaiGiayTo.daCo);
      },
    );

    // Test: hồ sơ chưa chọn trường hợp chỉ hiện giấy tờ chung
    testWidgets(
      'Case with no truongHopId shows prominent banner and only general papers',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repo = MockMyCasesRepository();
        // Set truongHopId to null on case-001
        await tester.runAsync(() => repo.updateTruongHop('case-001', null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myCasesRepositoryProvider.overrideWith((ref) => repo),
              procedureRepositoryProvider.overrideWith(
                (ref) => MockProcedureRepository(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('vi')],
              home: MyCaseCheckScreen(id: 'case-001'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Prominent banner is rendered
        expect(find.text(AppStrings.noteSelectCaseForPapers), findsOneWidget);

        // Only general papers (truongHopId == null) are rendered
        expect(find.text('Tờ khai đăng ký khai sinh theo mẫu'), findsOneWidget);
        expect(
          find.text('Hộ chiếu hoặc Thẻ căn cước công dân của người đi đăng ký'),
          findsWidgets,
        );

        // Case-specific papers are NOT rendered
        expect(
          find.text('Văn bản thỏa thuận lựa chọn quốc tịch cho con của cha mẹ'),
          findsNothing,
        );
      },
    );

    // Test: nút tải chỉ hiện khi có đường dẫn thật (example.com bị coi là mẫu)
    testWidgets(
      'Download form button only appears when real URL is present (example.com is ignored)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // In mockProcedureDetails[0], paper 1 has example.com URLs -> button should NOT appear
        final repo = MockMyCasesRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myCasesRepositoryProvider.overrideWith((ref) => repo),
              procedureRepositoryProvider.overrideWith(
                (ref) => MockProcedureRepository(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('vi')],
              home: MyCaseCheckScreen(id: 'case-001'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Paper 1 with example.com URLs has no "Tải biểu mẫu" button
        expect(find.text(AppStrings.downloadTemplateAction), findsNothing);

        // Now create a procedure with a real URL for paper
        final realFormProcedure = mockProcedureDetails[0].copyWith(
          id: 888,
          thanhPhanHoSo: [
            mockProcedureDetails[0].thanhPhanHoSo.first.copyWith(
              id: 101,
              bieuMau: const BieuMau(
                id: 1,
                ten: 'Mẫu thật',
                fileDocxUrl: 'https://dvc.hanoi.gov.vn/mau-that.docx',
              ),
            ),
          ],
        );
        final realCaseSummary = mockProcedureSummaries[0].copyWith(id: 888);
        final realCase = HoSoCuaToi(
          id: 'case-real-form',
          tenHoSo: 'Hồ sơ có biểu mẫu thật',
          thuTuc: realCaseSummary,
        );

        final customRepo = MockMyCasesRepository();
        await tester.runAsync(() => customRepo.restoreCase(realCase, 0));
        final fakeProcRepo = _FakeSingleProcedureRepo(realFormProcedure);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              myCasesRepositoryProvider.overrideWith((ref) => customRepo),
              procedureRepositoryProvider.overrideWith((ref) => fakeProcRepo),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [Locale('vi')],
              home: MyCaseCheckScreen(id: 'case-real-form'),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Now "Tải biểu mẫu" button DOES appear because of real URL
        expect(find.text(AppStrings.downloadTemplateAction), findsOneWidget);
      },
    );

    // Test: bấm "Hỏi trợ lý" mở chat với chip giấy tờ và câu hỏi điền sẵn nhưng chưa gửi
    testWidgets(
      'Tapping Ask Assistant on paper opens chat with paper chip and prefilled question (unsent)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final router = GoRouter(
          initialLocation: '/my-cases/case-001/check',
          routes: [
            GoRoute(
              path: '/my-cases/:id/check',
              builder: (context, state) =>
                  MyCaseCheckScreen(id: state.pathParameters['id'] ?? ''),
            ),
            GoRoute(
              path: AppRoutes.chat,
              name: 'chat',
              builder: (context, state) => ChatScreen(extra: state.extra),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myCasesRepositoryProvider.overrideWith(
                (ref) => MockMyCasesRepository(),
              ),
              procedureRepositoryProvider.overrideWith(
                (ref) => MockProcedureRepository(),
              ),
            ],
            child: MaterialApp.router(
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('vi')],
              routerConfig: router,
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Tap "Hỏi trợ lý" on the first paper
        final askAiButton = find.text(AppStrings.askAssistantAction).first;
        expect(askAiButton, findsOneWidget);
        await tester.tap(askAiButton);
        await tester.pumpAndSettle();

        // Navigated to ChatScreen
        expect(find.byType(ChatScreen), findsOneWidget);

        // Context paper chip is rendered
        expect(
          find.textContaining(AppStrings.contextAskingAboutPaper),
          findsOneWidget,
        );
        expect(find.textContaining('Tờ khai đăng ký khai sinh'), findsWidgets);

        // Suggested question is pre-filled in TextField
        const expectedQuestion =
            "Giấy tờ 'Tờ khai đăng ký khai sinh theo mẫu' là gì và cần chuẩn bị thế nào?";
        expect(
          find.widgetWithText(TextField, expectedQuestion),
          findsOneWidget,
        );

        // User message is NOT sent (only assistant welcome message exists)
        expect(
          find.text(expectedQuestion),
          findsOneWidget,
        ); // Only in the TextField
      },
    );

    // Test: Nút gate của chat mở Trang chủ với ô tìm kiếm đã điền
    testWidgets(
      'Chat gate card button navigates to Home with query prefilled in search field',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        const testQuestion = 'Làm căn cước công dân';

        final router = GoRouter(
          initialLocation: '/chat',
          routes: [
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) {
                final q = state.uri.queryParameters['q'];
                return HomeScreen(initialQuery: q);
              },
            ),
            GoRoute(
              path: AppRoutes.chat,
              name: 'chat',
              builder: (context, state) => Scaffold(
                body: ChatMessageItem(
                  message: TinNhan(
                    id: 1,
                    vaiTro: VaiTroTinNhan.assistant,
                    noiDung: AppStrings.gateFallbackAnswer,
                    trangThaiTraLoi: TrangThaiTraLoi.gate,
                    taoLuc: DateTime.now(),
                  ),
                  feedbackValue: null,
                  onToggleFeedback: (_, {note}) {},
                  lastUserQuestion: testQuestion,
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              favoritesRepositoryProvider.overrideWith(
                (ref) => FakeFavoritesRepository(),
              ),
              myCasesRepositoryProvider.overrideWith(
                (ref) => MockMyCasesRepository(),
              ),
              procedureRepositoryProvider.overrideWith(
                (ref) => MockProcedureRepository(),
              ),
            ],
            child: MaterialApp.router(
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('vi')],
              routerConfig: router,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Gate card button is rendered
        final gateButton = find.text(AppStrings.searchInProceduresAction);
        expect(gateButton, findsOneWidget);

        // Tap the button
        await tester.tap(gateButton);
        await tester.pump();

        // Per rule: "test chạm Trang chủ pump thêm 1 giây ở cuối, không dùng pumpAndSettle trên Trang chủ"
        await tester.pump(const Duration(seconds: 1));

        // Home Screen should be rendered
        expect(find.byType(HomeScreen), findsOneWidget);

        // Search TextField has the pre-filled question
        expect(find.widgetWithText(TextField, testQuestion), findsOneWidget);
      },
    );
  });
}

class _FakeSingleProcedureRepo extends MockProcedureRepository {
  final ThuTucDetail detail;
  _FakeSingleProcedureRepo(this.detail);

  @override
  Future<ThuTucDetail> getProcedureDetail(int id) async => detail;

  @override
  Future<ThuTucDetail?> getProcedureByMa(String maThuTuc) async => detail;
}
