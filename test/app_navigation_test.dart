import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logic_circuit_builder/app.dart';
import 'package:logic_circuit_builder/core/theme/app_colors.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: LogicCircuitBuilderApp()),
  );
  await tester.pumpAndSettle();
}

void main() {
  // A phone-sized surface: the Home headline uses the smaller display cut
  // below 768px, and everything must still fit without overflow.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('boots to a themed Home', (tester) async {
    await _pumpApp(tester);

    expect(find.text('LOGIC'), findsOneWidget);
    expect(find.text('CIRCUIT'), findsOneWidget);
    expect(find.text('BUILDER'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Play'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.pumice);
  });

  testWidgets('Home -> Level Select -> Game -> back to Level Select',
      (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Play'));
    await tester.pumpAndSettle();
    expect(find.text('LEVELS'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Open level 1'));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL 1'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
    await tester.pumpAndSettle();
    expect(find.text('LEVELS'), findsOneWidget);
  });

  testWidgets('Home -> Settings -> back to Home', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Settings'));
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
    await tester.pumpAndSettle();
    expect(find.text('LOGIC'), findsOneWidget);
  });
}
