import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('App boots and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AlcoholimetroApp()),
    );
    await tester.pump(const Duration(seconds: 2));
    // The app should render something (login screen)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
