import 'package:flutter_test/flutter_test.dart';
import 'package:dvc_guide_mobile/features/procedure/data/repositories/mock_procedure_repository.dart';

void main() {
  late MockProcedureRepository repository;

  setUp(() {
    repository = MockProcedureRepository();
  });

  group('Procedure List Filtering Tests', () {
    test('Filtering by query "khai sinh" returns matching procedure', () async {
      final results = await repository.getProcedures(query: 'khai sinh');
      expect(results.isNotEmpty, true);
      expect(results.any((p) => p.ten.toLowerCase().contains('khai sinh')), true);
    });

    test('Filtering by query case-insensitively with diacritics', () async {
      final results = await repository.getProcedures(query: 'KẾT HÔN');
      expect(results.isNotEmpty, true);
      expect(results.any((p) => p.ten.toLowerCase().contains('kết hôn')), true);
    });

    test('Filtering by query without diacritics: "dang ky khai sinh" finds birth registration', () async {
      final results = await repository.getProcedures(query: 'dang ky khai sinh');
      expect(results.isNotEmpty, true);
      expect(results.any((p) => p.ten.toLowerCase().contains('khai sinh')), true);
    });

    test('Filtering by linhVucId 1 (Hộ tịch) returns only civil status procedures', () async {
      final results = await repository.getProcedures(linhVucId: 1);
      expect(results.isNotEmpty, true);
      for (final p in results) {
        expect(p.linhVuc.any((lv) => lv.id == 1), true);
      }
    });

    test('Combining query and linhVucId filtering', () async {
      final results = await repository.getProcedures(
        query: 'khai sinh',
        linhVucId: 1,
      );
      expect(results.length, 1);
      expect(results.first.ten.contains('khai sinh'), true);
    });

    test('Query for non-existent procedure returns empty list', () async {
      final results = await repository.getProcedures(query: 'không tồn tại 123456');
      expect(results.isEmpty, true);
    });
  });

  group('Paper Filtering by Case (TruongHop) Tests', () {
    test('When no case is selected (null), only general papers (truongHopId == null) are included', () async {
      final procedure = await repository.getProcedureDetail(1); // Đăng ký khai sinh
      const int? selectedCaseId = null;

      final filteredPapers = procedure.thanhPhanHoSo.where((paper) {
        if (selectedCaseId == null) {
          return paper.truongHopId == null;
        }
        return paper.truongHopId == null || paper.truongHopId == selectedCaseId;
      }).toList();

      // All returned papers must have truongHopId == null
      expect(filteredPapers.every((p) => p.truongHopId == null), true);
      // Case-specific papers (truongHopId = 1 or 2) must NOT be present
      expect(filteredPapers.any((p) => p.truongHopId != null), false);
    });

    test('When Case 1 (trong nước) is selected, general papers + Case 1 papers are included', () async {
      final procedure = await repository.getProcedureDetail(1);
      const int selectedCaseId = 1;

      final filteredPapers = procedure.thanhPhanHoSo.where((paper) {
        return paper.truongHopId == null || paper.truongHopId == selectedCaseId;
      }).toList();

      expect(filteredPapers.any((p) => p.truongHopId == null), true);
      expect(filteredPapers.any((p) => p.truongHopId == 1), true);
      // Papers of Case 2 must NOT be included
      expect(filteredPapers.any((p) => p.truongHopId == 2), false);
    });

    test('When Case 2 (yếu tố nước ngoài) is selected, general papers + Case 2 papers are included', () async {
      final procedure = await repository.getProcedureDetail(1);
      const int selectedCaseId = 2;

      final filteredPapers = procedure.thanhPhanHoSo.where((paper) {
        return paper.truongHopId == null || paper.truongHopId == selectedCaseId;
      }).toList();

      expect(filteredPapers.any((p) => p.truongHopId == null), true);
      expect(filteredPapers.any((p) => p.truongHopId == 2), true);
      // Papers of Case 1 must NOT be included
      expect(filteredPapers.any((p) => p.truongHopId == 1), false);
    });
  });
}
