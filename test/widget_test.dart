// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Assuming ChessApp is in 'package:ajedrez_app/main.dart'
// The existing import 'package:ajedrez_app/main.dart' should provide ChessApp.
// If ChessApp is in a different file, this import path would need to be adjusted.
import 'package:ajedrez_app/main.dart'; 

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Changed MyApp() to ChessApp()
    await tester.pumpWidget(const ChessApp()); 

    // Verify that our counter starts at 0.
    // This part of the test will likely fail as ChessApp does not have a counter starting at 0.
    // This test should be updated to reflect ChessApp's actual UI.
    // For now, only changing MyApp to ChessApp as requested.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
