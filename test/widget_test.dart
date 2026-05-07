import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp smoke test — widget tree builds without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('RefereeIQ')),
        ),
      ),
    );

    expect(find.text('RefereeIQ'), findsOneWidget);
  });
}
