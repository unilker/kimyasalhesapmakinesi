import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/app.dart';
import 'package:kimya_hesap/state/app_state.dart';
import 'package:kimya_hesap/ui/home/home_screen.dart';
import 'package:kimya_hesap/ui/tools/registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen sizes (logical pixels) covering phones, foldables and tablets.
const sizes = <String, Size>{
  'small phone': Size(320, 640),
  'phone': Size(390, 844),
  'phone landscape': Size(844, 390),
  'fold cover': Size(344, 882),
  'fold inner': Size(673, 841),
  'tablet portrait': Size(800, 1280),
  'tablet landscape': Size(1280, 800),
};

Future<AppState> pumpApp(WidgetTester tester, Size size, {String lang = 'tr'}) async {
  SharedPreferences.setMockInitialValues({'lang': lang});
  final state = await AppState.create();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(state: state, child: const KimyaApp()));
  await tester.pumpAndSettle();
  return state;
}

Future<void> openTool(WidgetTester tester, String title) async {
  final card = find.descendant(of: find.byType(ToolCard), matching: find.text(title));
  final scrollable =
      find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(card, 300, scrollable: scrollable);
  await tester.ensureVisible(card.first);
  await tester.pumpAndSettle();
  await tester.tap(card.first);
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  for (final entry in sizes.entries) {
    for (final lang in ['tr', 'en']) {
      testWidgets('all screens render on ${entry.key} ($lang)', (tester) async {
        await pumpApp(tester, entry.value, lang: lang);
        // Home
        expect(find.byType(Scaffold), findsWidgets);
        // Every tool opens without layout errors.
        for (final tool in tools) {
          await openTool(tester, tool.title.of(lang));
          expect(tester.takeException(), isNull, reason: tool.id);
          // Press the main button, if any, to render results / errors too.
          final calc = find.byIcon(Icons.calculate_rounded);
          if (calc.evaluate().isNotEmpty) {
            await tester.ensureVisible(calc.first);
            await tester.pumpAndSettle();
            await tester.tap(calc.first);
            await tester.pumpAndSettle();
          }
          // Go back (compact) – list–detail layouts simply switch.
          final back = find.byType(BackButton);
          if (back.evaluate().isNotEmpty) {
            await tester.tap(back.first);
            await tester.pumpAndSettle();
          }

        }
        // Other tabs
        for (final icon in [Icons.calculate_outlined, Icons.apps_outlined, Icons.history_outlined]) {
          await tester.tap(find.byIcon(icon).first);
          await tester.pumpAndSettle();
        }
      });
    }
  }

  testWidgets('molar mass is calculated and saved to history', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'Mol Kütlesi');
    await tester.enterText(find.byType(TextField).first, 'H2SO4');
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    expect(find.text('98,072 g/mol'), findsOneWidget);
    expect(state.history.first.result, '98,072 g/mol');
  });

  testWidgets('calculator evaluates and records history', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844));
    await tester.tap(find.byIcon(Icons.calculate_outlined));
    await tester.pumpAndSettle();
    for (final k in ['2', '+', '3', '×', '4']) {
      await tester.tap(find.text(k).last);
    }
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();
    expect(find.text('= 14'), findsOneWidget);
    expect(state.history.first.input, '2+3×4');
  });

  testWidgets('solver: dilution volume', (tester) async {
    await pumpApp(tester, const Size(390, 844), lang: 'en');
    await openTool(tester, 'Dilution & Mixing');
    final fields = find.byType(TextField);
    // default target V1: inputs C1, C2, V2
    await tester.enterText(fields.at(0), '12');
    await tester.enterText(fields.at(1), '1');
    await tester.enterText(fields.at(2), '250');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(find.text('20.8333'), findsOneWidget);
  });

  testWidgets('history limit trims old entries', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844));
    state.setHistoryLimit(25);
    for (var i = 0; i < 40; i++) {
      state.addHistory(toolId: 'calculator', input: '$i', result: '$i');
    }
    expect(state.history.length, 25);
    expect(state.history.first.input, '39');
    state.clearHistory();
    expect(state.history, isEmpty);
  });
}
