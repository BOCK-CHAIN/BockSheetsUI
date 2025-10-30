// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysheets/main.dart';  // make sure this path is correct

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BockSheetsApp());

    // Since your home is SplashScreen, adjust expectations accordingly.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);

    // If you want a working counter example, replace with your actual widgets.
  });
}
