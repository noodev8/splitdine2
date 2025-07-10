// This is a basic Flutter widget test for SplitDine app.

import 'package:flutter_test/flutter_test.dart';

import 'package:splitdine2_flutter/main.dart';

void main() {
  testWidgets('SplitDine app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SplitDineApp());

    // Verify that the app loads and shows authentication screen
    expect(find.text('Split Dine'), findsOneWidget);

    // Check for authentication elements
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('Authentication screen toggle test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SplitDineApp());

    // Initially should show Sign In
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text("Don't have an account? Sign up"), findsOneWidget);

    // Tap the toggle button
    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pump();

    // Should now show Sign Up
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Display Name'), findsOneWidget);
    expect(find.text("Already have an account? Sign in"), findsOneWidget);
  });
}
