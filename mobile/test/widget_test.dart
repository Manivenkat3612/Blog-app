// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:blog_platform_mobile/main.dart';

// Updated smoke test aligned with new app (splash -> auth flow)
void main() {
  testWidgets('Splash transitions to login (shows Sign in text)', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Nebula Blog'), findsOneWidget);
    // Advance time in small steps to let animations + navigation finish
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 1000)); // total 2500ms
    // Allow any pending microtasks / route transitions
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('Sign in'), findsOneWidget, reason: 'Login header should be visible after splash timeout');
  });
}
