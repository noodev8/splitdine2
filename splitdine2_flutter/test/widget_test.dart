// This is a basic Flutter widget test for SplitDine app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splitdine2_flutter/main.dart';

void main() {
  testWidgets('SplitDine app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SplitDineApp());

    // Verify that the app loads and shows welcome screen
    expect(find.text('Split Dine'), findsOneWidget);
    expect(find.text('Welcome to Split Dine!'), findsOneWidget);
    expect(find.text('Your collaborative bill splitting app'), findsOneWidget);

    // Check for the restaurant icon
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });

  testWidgets('HomePage displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SplitDineApp());

    // Verify the home page elements
    expect(find.text('Welcome to Split Dine!'), findsOneWidget);
    expect(find.text('Your collaborative bill splitting app'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant), findsOneWidget);

    // Verify the app bar
    expect(find.text('Split Dine'), findsOneWidget);
  });
}
