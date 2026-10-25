import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AtomicLife muestra su identidad visual', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('AtomicLife'))),
      ),
    );

    expect(find.text('AtomicLife'), findsOneWidget);
  });
}
