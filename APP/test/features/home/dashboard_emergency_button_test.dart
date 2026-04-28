import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/home/presentation/screens/home_screen.dart';

void main() {
  // Force a "desktop" viewport so DashboardPage does not render the mobile
  // AppBar (which depends on auth/router providers via the logout IconButton).
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1200, 1800);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Widget buildApp() {
    return const ProviderScope(
      child: MaterialApp(
        home: DashboardPage(),
      ),
    );
  }

  testWidgets('Emergency card is rendered on dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Emergencia'), findsOneWidget);
    expect(find.text('Contactar ayuda'), findsOneWidget);
  });

  testWidgets(
      'Tapping Emergency card opens confirmation dialog with Call/Cancel actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Emergencia'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('¿Llamar al 112?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Llamar'), findsOneWidget);
  });

  testWidgets('Cancel button dismisses the emergency dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Emergencia'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
