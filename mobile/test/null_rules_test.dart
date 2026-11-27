import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dvc_guide_mobile/core/constants/app_strings.dart';
import 'package:dvc_guide_mobile/features/procedure/data/models/procedure_models.dart';
import 'package:dvc_guide_mobile/shared/widgets/info_row.dart';
import 'package:dvc_guide_mobile/shared/widgets/status_chip.dart';

void main() {
  group('Strict NULL Display Rules Tests', () {
    test('Fee formatting: mienPhi = true -> Miễn phí', () {
      const fee = LePhi(id: 1, mienPhi: true);
      expect(InfoRow.formatFee(fee), AppStrings.freeOfCharge);
    });

    test('Fee formatting: soTien has value with VND -> formatted with currency symbol', () {
      const fee = LePhi(id: 2, mienPhi: false, soTien: 1234000, tienTe: 'VND');
      expect(InfoRow.formatFee(fee), '1.234.000 đ');
    });

    test('Fee formatting: soTien has value with other currency (e.g. USD)', () {
      const fee = LePhi(id: 3, mienPhi: false, soTien: 50, tienTe: 'USD');
      expect(InfoRow.formatFee(fee), '50 USD');
    });

    test('Fee formatting: mienPhi = false and soTien = null -> Chưa có thông tin về lệ phí', () {
      const fee = LePhi(id: 4, mienPhi: false, soTien: null);
      expect(InfoRow.formatFee(fee), AppStrings.feeUnknown);
    });

    test('Timeline: thoiHanSo and thoiHanDonVi present -> "5 ngày làm việc"', () {
      final res = InfoRow.formatTimeline(
        thoiHanSo: 5.0,
        thoiHanDonVi: 'ngày làm việc',
        thoiHanGoc: 'Không quá 5 ngày',
      );
      expect(res, '5 ngày làm việc');
    });

    test('Timeline: thoiHanSo present, thoiHanDonVi null, thoiHanGoc present -> shows thoiHanGoc verbatim', () {
      final res = InfoRow.formatTimeline(
        thoiHanSo: 7.0,
        thoiHanDonVi: null,
        thoiHanGoc: 'Từ 7 đến 15 ngày tùy theo địa bàn tiếp nhận',
      );
      expect(res, 'Từ 7 đến 15 ngày tùy theo địa bàn tiếp nhận');
    });

    test('Timeline: thoiHanSo present, but both thoiHanDonVi and thoiHanGoc null -> Chưa có thông tin', () {
      final res = InfoRow.formatTimeline(
        thoiHanSo: 3.0,
        thoiHanDonVi: null,
        thoiHanGoc: null,
      );
      expect(res, AppStrings.timelineUnknown);
    });

    test('Timeline: all null -> Chưa có thông tin', () {
      final res = InfoRow.formatTimeline(
        thoiHanSo: null,
        thoiHanDonVi: null,
        thoiHanGoc: null,
      );
      expect(res, AppStrings.timelineUnknown);
    });

    testWidgets('Requirement badge: true -> Bắt buộc, false -> Tùy chọn, null -> SizedBox.shrink', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    StatusChip.requirementBadge(context, true),
                    StatusChip.requirementBadge(context, false),
                    StatusChip.requirementBadge(context, null),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.requiredBadge), findsOneWidget);
      expect(find.text(AppStrings.optionalBadge), findsOneWidget);
      // null badge should be SizedBox.shrink without any extra text
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
