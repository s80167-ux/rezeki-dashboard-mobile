// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';
import 'package:rezeki_dashboard_app/main.dart';

void main() {
  testWidgets('App renders login page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RezekiDashboardApp());

    // Verify that login page elements are present.
    expect(find.text('Rezeki Dashboard'), findsOneWidget);
    expect(find.text('Kempen Digital Untuk PMKS'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
