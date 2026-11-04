import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dvc_guide_mobile/app/app.dart';

void main() {
  testWidgets('DvcGuideApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DvcGuideApp()),
    );
    // App should render without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
