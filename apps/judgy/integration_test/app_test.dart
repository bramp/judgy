import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:judgy/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Judgy Integration Tests', () {
    testWidgets('App launches and displays', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify the app is running
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // TODO: Add navigation tests after UI is implemented
      // Example: Tap on a button and verify new screen appears
    });
  });
}
