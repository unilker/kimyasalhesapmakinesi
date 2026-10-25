import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/app.dart';
import 'package:kimya_hesap/core/chem/formula.dart' show prettyEquation, prettyFormula;
import 'package:kimya_hesap/state/app_state.dart';
import 'package:kimya_hesap/ui/common.dart' show ErrorBanner, ToolScaffold;
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

/// Scrolls the open tool until [finder] is built and visible.
Future<void> seek(WidgetTester tester, Finder finder) async {
  final scrollable =
      find.descendant(of: find.byType(ToolScaffold), matching: find.byType(Scrollable)).first;
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
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
          final visibleBottom = size.height - kb + 0.5;
          if (rect.height <= (size.height - kb) * 0.5) {
            // Single-line fields must be entirely above the keyboard.
            expect(rect.bottom, lessThanOrEqualTo(visibleBottom),
                reason: '${tool.id}: field bottom ${rect.bottom} hidden by keyboard at ${size.height - kb}');
            expect(rect.top, greaterThanOrEqualTo(0), reason: tool.id);
          } else {
            // A multi-line field taller than the free space cannot fit; the
            // line being edited (the caret) must still be visible.
            final editable = tester
                .state<EditableTextState>(find.descendant(of: field, matching: find.byType(EditableText)))
                .renderEditable;
            final caret = editable.localToGlobal(
                editable.getLocalRectForCaret(editable.selection!.extent).bottomLeft);
            expect(caret.dy, lessThanOrEqualTo(visibleBottom), reason: '${tool.id}: caret hidden');
            expect(caret.dy, greaterThan(0), reason: tool.id);
          }
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

  testWidgets('molar mass also shows exact mass and DBE', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'Mol Kütlesi');
    await tester.enterText(find.byType(TextField).first, 'C8H10N4O2');
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    await seek(tester, find.text('194,080376'));
    expect(find.text('Halka + çift bağ (DBE)'), findsOneWidget);
    expect(find.text('6'), findsWidgets);
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

  testWidgets('statistics: example data gives mean and outlier verdicts', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'İstatistik ve Kalibrasyon');
    await tester.tap(find.text('Örnek veri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    // mean of 0.403 0.410 0.401 0.380 0.400 0.413 0.408 = 0.402143
    await seek(tester, find.textContaining('0,402143'));
    await seek(tester, find.text('Aykırı değer – atılabilir').last);
    expect(find.text('Aykırı değer – atılabilir'), findsNWidgets(2)); // Q and Grubbs at 95 %
    expect(state.history.first.toolId, 'stats');
  });

  testWidgets('statistics: calibration predicts the unknown', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'İstatistik ve Kalibrasyon');
    await tester.tap(find.text('Kalibrasyon doğrusu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Örnek veri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    await seek(tester, find.textContaining('1,93036')); // slope
    await seek(tester, find.textContaining('6,20722')); // x0 for y0 = 13.5
  });

  testWidgets('titration: acetic acid equivalence point', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'Titrasyon Eğrisi');
    await seek(tester, find.text('Hesapla'));
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    // 25 mL of 0.1 M HA (pKa 4.76) with 0.1 M NaOH → EP at 25 mL, pH 8.730
    await seek(tester, find.text('25 mL · pH 8,73'));
    await seek(tester, find.textContaining('Fenolftalein'));
  });

  testWidgets('ICE table: H2 + I2 ⇌ 2HI example', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'Denge Tablosu (ICE)');
    await seek(tester, find.text('H₂ + I₂ ⇌ 2HI'));
    await tester.tap(find.text('H₂ + I₂ ⇌ 2HI'));
    await tester.pumpAndSettle();
    // Kc = 54.3, 0.500 M each → [H2] = 0.106737, [HI] = 0.786527 (Chang)
    await seek(tester, find.textContaining('[HI] = 0,786527'));
    expect(find.textContaining('[H₂] = 0,106737'), findsWidgets);
    expect(state.history.first.toolId, 'ice');
  });

  for (final name in ['small phone', 'small phone landscape']) {
    testWidgets('ICE table: every example renders on $name', (tester) async {
      await pumpApp(tester, sizes[name]!);
      await openTool(tester, 'Denge Tablosu (ICE)');
      for (final eq in ['H2 + I2 ⇌ 2HI', 'N2O4 ⇌ 2NO2', 'CH3COOH ⇌ H^+ + CH3COO^-',
          'NH3 + H2O(l) ⇌ NH4^+ + OH^-', 'AgCl(s) ⇌ Ag^+ + Cl^-', 'N2 + 3H2 ⇌ 2NH3']) {
        final chip = find.widgetWithText(ActionChip, prettyEquation(eq));
        await seek(tester, chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        await seek(tester, find.text('Denge bileşimi'));
        expect(tester.takeException(), isNull);
        tester
            .state<ScrollableState>(
                find.descendant(of: find.byType(ToolScaffold), matching: find.byType(Scrollable)).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
      }
    });
  }

  for (final title in ['Denge Tablosu (ICE)', 'Denklem ve Stokiyometri', 'İstatistik ve Kalibrasyon']) {
    testWidgets('dragging on the equation field scrolls the page ($title)', (tester) async {
      await pumpApp(tester, sizes['small phone']!);
      await openTool(tester, title);
      final field = find.byType(TextField).first;
      await tester.enterText(field, 'NH3 + H2O(l) ⇌ NH4^+ + OH^- + CH3COOH');
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final page = tester.state<ScrollableState>(
          find.descendant(of: find.byType(ToolScaffold), matching: find.byType(Scrollable)).first);
      final before = page.position.pixels;
      await tester.dragFrom(tester.getCenter(field), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(page.position.pixels, greaterThan(before + 50));
    });
  }

  testWidgets('ICE table: typed reaction with a pure solid', (tester) async {
    await pumpApp(tester, const Size(390, 844), lang: 'en');
    await openTool(tester, 'ICE Table');
    await tester.enterText(find.byType(TextField).first, 'AgCl(s) = Ag+ + Cl-');
    await tester.pumpAndSettle();
    await seek(tester, find.textContaining('not in K'));
    Finder field(String label) => find.ancestor(of: find.text(label), matching: find.byType(TextField));
    await seek(tester, field('Equilibrium constant K'));
    await tester.enterText(field('Equilibrium constant K'), '1.77e-10');
    await seek(tester, field('[Cl⁻]₀'));
    await tester.enterText(field('[Cl⁻]₀'), '0');
    await seek(tester, find.text('Calculate'));
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await seek(tester, find.textContaining('= 1.33041 × 10⁻⁵'));
  });

  testWidgets('galvanic cell: Daniell cell, then permanganate via the picker', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'Piller ve E° Tablosu');
    await seek(tester, find.text('Hesapla'));
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    await seek(tester, find.text('1,1037 V'));
    expect(find.text('Cu²⁺ + Zn(s) → Cu(s) + Zn²⁺'), findsOneWidget);
    expect(state.history.first.toolId, 'cell');

    // Pick MnO4⁻/Mn²⁺ as the cathode by searching.
    for (var k = 0; k < 10; k++) {
      await tester.drag(find.descendant(of: find.byType(ToolScaffold), matching: find.byType(Scrollable)).first,
          const Offset(0, 400));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Cu²⁺ + 2e⁻ ⇌ Cu(s)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'MnO4');
    await tester.pumpAndSettle();
    await tester.tap(find.text('MnO₄⁻ + 8H⁺ + 5e⁻ ⇌ Mn²⁺ + 4H₂O(l)'));
    await tester.pumpAndSettle();
    await seek(tester, find.text('Hesapla'));
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    // E° = 1.507 − (−0.7618) = 2.2688 V, n = 10
    await seek(tester, find.text('2,2688 V'));
    expect(find.text('2MnO₄⁻ + 16H⁺ + 5Zn(s) → 2Mn²⁺ + 8H₂O(l) + 5Zn²⁺'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final name in ['small phone', 'small phone landscape']) {
    testWidgets('E° table opens and filters on $name', (tester) async {
      await pumpApp(tester, sizes[name]!);
      await openTool(tester, 'Piller ve E° Tablosu');
      await seek(tester, find.text('E° tablosunu göster'));
      await tester.tap(find.text('E° tablosunu göster'));
      await tester.pumpAndSettle();
      expect(find.text('F₂(g) + 2e⁻ ⇌ 2F⁻'), findsOneWidget); // highest E° first
      await tester.enterText(find.byType(TextField), 'Ag');
      await tester.pumpAndSettle();
      expect(find.text('AgCl(s) + e⁻ ⇌ Ag(s) + Cl⁻'), findsOneWidget);
      expect(find.text('F₂(g) + 2e⁻ ⇌ 2F⁻'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reaction thermodynamics: methane combustion and limestone', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'Tepkime Termodinamiği');
    final chip = find.widgetWithText(ActionChip, prettyEquation('CH4 + O2 -> CO2 + H2O(l)'));
    await seek(tester, chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    // ΔH° = −890.57 kJ, ΔG° = −817.9 kJ
    await seek(tester, find.text('−890,57 kJ/mol'));
    expect(state.history.first.toolId, 'hess');

    tester
        .state<ScrollableState>(
            find.descendant(of: find.byType(ToolScaffold), matching: find.byType(Scrollable)).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    final lime = find.widgetWithText(ActionChip, prettyEquation('CaCO3(s) -> CaO(s) + CO2(g)'));
    await seek(tester, lime);
    await tester.tap(lime);
    await tester.pumpAndSettle();
    // calcite is offered with aragonite; ΔH° = 179.17 kJ → T* = 1118 K
    await seek(tester, find.textContaining('1118,5 K'));
    expect(find.textContaining('istemli'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final name in ['small phone', 'small phone landscape']) {
    testWidgets('reaction thermodynamics: every example renders on $name', (tester) async {
      await pumpApp(tester, sizes[name]!);
      await openTool(tester, 'Tepkime Termodinamiği');
      for (final eq in ['CH4 + O2 -> CO2 + H2O(l)', 'C6H12O6(s) + O2 -> CO2 + H2O(l)',
          'C2H5OH(l) + O2 -> CO2 + H2O(l)', 'N2 + 3H2 -> 2NH3', 'CaCO3(s) -> CaO(s) + CO2(g)',
          'NH4NO3(s) -> NH4^+ + NO3^-', 'AgCl(s) -> Ag^+ + Cl^-', '2NO2 -> N2O4(g)']) {
        final chip = find.widgetWithText(ActionChip, prettyEquation(eq));
        await seek(tester, chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        await seek(tester, find.textContaining('ΔG° ('));
        expect(find.byType(ErrorBanner), findsNothing, reason: eq);
        expect(tester.takeException(), isNull);
        tester
            .state<ScrollableState>(
                find.descendant(of: find.byType(ToolScaffold), matching: find.byType(Scrollable)).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('mass spectrometry: caffeine [M+H]⁺ and examples on small screens', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'Kütle Spektrometrisi');
    await tester.enterText(find.byType(TextField).first, 'C8H10N4O2');
    await tester.tap(find.text('[M+H]⁺'));
    await tester.pumpAndSettle();
    await seek(tester, find.text('Hesapla'));
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    await seek(tester, find.text('195,087652'));
    expect(state.history.first.toolId, 'massSpec');
    // switching the ion recalculates: [M−H]⁻ = 194.080376 − 1.007825 + mₑ
    tester
        .state<ScrollableState>(
            find.descendant(of: find.byType(ToolScaffold), matching: find.byType(Scrollable)).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await seek(tester, find.text('[M−H]⁻'));
    await tester.tap(find.text('[M−H]⁻'));
    await tester.pumpAndSettle();
    await seek(tester, find.text('193,073099'));
  });

  for (final name in ['small phone', 'small phone landscape', 'tablet landscape']) {
    testWidgets('mass spectrometry examples render on $name', (tester) async {
      await pumpApp(tester, sizes[name]!);
      await openTool(tester, 'Kütle Spektrometrisi');
      for (final f in ['C8H10N4O2', 'C9H8O4', 'CH2Cl2', 'C6H5Br', 'SnCl4', 'C60', 'C254H377N65O75S6']) {
        final chip = find.widgetWithText(ActionChip, prettyFormula(f));
        await seek(tester, chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        await seek(tester, find.text('Monoizotopik (tam) kütle'));
        expect(tester.takeException(), isNull, reason: f);
        tester
            .state<ScrollableState>(
                find.descendant(of: find.byType(ToolScaffold), matching: find.byType(Scrollable)).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('titration: phosphoric acid from the CRC pKa table', (tester) async {
    await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'Titrasyon Eğrisi');
    await seek(tester, find.text('pKa tablosundan seç'));
    await tester.tap(find.text('pKa tablosundan seç'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fosforik');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Fosforik asit'));
    await tester.pumpAndSettle();
    expect(find.text('2,16 7,21 12,32'), findsOneWidget);
    await seek(tester, find.text('Hesapla'));
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    await seek(tester, find.text('Eşdeğerlik noktası 3'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rate law from data: NO2 example is second order', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844));
    await openTool(tester, 'Veriden Hız Kanunu');
    await seek(tester, find.text('Örnek veri'));
    await tester.tap(find.text('Örnek veri'));
    await tester.pumpAndSettle();
    await seek(tester, find.text('2. derece'));
    await seek(tester, find.textContaining('0,54445 ± 0,0014 M⁻¹ s⁻¹'));
    expect(state.history.first.toolId, 'rateData');
    expect(tester.takeException(), isNull);
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
