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
  'small phone landscape': Size(640, 320),
  'phone': Size(390, 844),
  'phone landscape': Size(844, 390),
  'fold cover': Size(344, 882),
  'fold cover landscape': Size(882, 344),
  'fold inner': Size(673, 841),
  'fold inner landscape': Size(841, 673),
  'tablet portrait': Size(800, 1280),
  'tablet landscape': Size(1280, 800),
};

/// Typical on-screen keyboard height for a screen of [size].
double keyboardHeight(Size size) =>
    size.width > size.height ? (size.height * 0.55).clamp(150, 260) : (size.height * 0.4).clamp(260, 380);

Future<AppState> pumpApp(WidgetTester tester, Size size,
    {String lang = 'tr', bool rotateButton = false}) async {
  // The floating rotate button is covered by its own tests; keep it out of
  // the way of taps elsewhere.
  SharedPreferences.setMockInitialValues({'lang': lang, 'rotateButton': rotateButton});
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

  // The focused text field must stay visible above the on-screen keyboard
  // in every tool, in portrait and landscape.
  for (final name in ['small phone', 'small phone landscape', 'phone', 'phone landscape',
      'fold cover landscape', 'tablet landscape']) {
    testWidgets('keyboard does not cover the focused field on $name', (tester) async {
      final size = sizes[name]!;
      await pumpApp(tester, size);
      final kb = keyboardHeight(size);
      final targets = <String, Finder>{
        for (final tool in tools) tool.id: find.byType(TextField),
      };
      for (final tool in tools) {
        await openTool(tester, tool.title.of('tr'));
        final fields = targets[tool.id]!.hitTestable();
        if (fields.evaluate().isNotEmpty) {
          // The last field of the form is the one most likely to be covered.
          // Pin the field by its controller: lazily built lists add/remove
          // fields while scrolling and rebuilds create new widget instances.
          final controller =
              (find.byType(TextField).evaluate().last.widget as TextField).controller;
          final field = find.byWidgetPredicate(
              (w) => w is TextField && w.controller == controller);
          await tester.ensureVisible(field);
          await tester.pumpAndSettle();
          await tester.tap(field);
          tester.view.viewInsets = FakeViewPadding(bottom: kb);
          await tester.pumpAndSettle();
          await tester.enterText(field, '12');
          await tester.pumpAndSettle();
          final rect = tester.getRect(field);
          expect(rect.bottom, lessThanOrEqualTo(size.height - kb + 0.5),
              reason: '${tool.id}: field bottom ${rect.bottom} hidden by keyboard at ${size.height - kb}');
          expect(rect.top, greaterThanOrEqualTo(0), reason: tool.id);
          expect(tester.takeException(), isNull, reason: tool.id);
          tester.view.viewInsets = FakeViewPadding.zero;
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        }
        final back = find.byType(BackButton);
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back.first);
          await tester.pumpAndSettle();
        }
      }
      // Search fields on the home and periodic table screens.
      for (final icon in [Icons.apps_outlined]) {
        await tester.tap(find.byIcon(icon).first);
        await tester.pumpAndSettle();
        final field = find.byType(TextField).hitTestable().first;
        await tester.tap(field);
        tester.view.viewInsets = FakeViewPadding(bottom: kb);
        await tester.pumpAndSettle();
        expect(tester.getRect(field).bottom, lessThanOrEqualTo(size.height - kb + 0.5));
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
      }
    });
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
