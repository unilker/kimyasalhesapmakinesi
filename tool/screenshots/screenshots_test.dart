// Renders app screens to PNG files (useful for store listings and visual
// review). Run with:
//   flutter test tool/screenshots/screenshots_test.dart --update-goldens
// Output: tool/screenshots/out/*.png
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/app.dart';
import 'package:kimya_hesap/state/app_state.dart';
import 'package:kimya_hesap/ui/common.dart' show ToolScaffold;
import 'package:kimya_hesap/ui/home/home_screen.dart';
import 'package:kimya_hesap/ui/widgets/xy_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final nunito = FontLoader('Nunito');
  for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
    nunito.addFont(rootBundle.load('assets/fonts/Nunito-$w.ttf'));
  }
  await nunito.load();
  for (final (family, files) in [
    ('NotoSansSymbols', ['NotoSansSymbols-Regular', 'NotoSansSymbols-Bold']),
    ('NotoSansMath', ['NotoSansMath-Regular']),
  ]) {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(rootBundle.load('assets/fonts/$f.ttf'));
    }
    await l.load();
  }
  // resolvedExecutable: <flutter>/bin/cache/dart-sdk/bin/dart (or similar)
  var dir = File(Platform.resolvedExecutable).parent;
  while (!File('${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').existsSync() &&
      dir.parent.path != dir.path) {
    dir = dir.parent;
  }
  final icons = File('${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
  await loader.load();
}

Future<void> _pump(WidgetTester tester, Size size, {String lang = 'tr', String theme = 'light'}) async {
  SharedPreferences.setMockInitialValues({'lang': lang, 'theme': theme});
  final state = await AppState.create();
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(state: state, child: const KimyaApp()));
  await tester.pumpAndSettle();
}

Future<void> _shot(String name) =>
    expectLater(find.byType(KimyaApp), matchesGoldenFile('out/$name.png'));

Future<void> _openTool(WidgetTester tester, String title) async {
  final card = find.descendant(of: find.byType(ToolCard), matching: find.text(title));
  await tester.scrollUntilVisible(card, 300,
      scrollable: find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first);
  await tester.ensureVisible(card.first);
  await tester.pumpAndSettle();
  await tester.tap(card.first);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  const phone = Size(390, 844);
  const tablet = Size(1280, 800);

  testWidgets('phone home', (t) async {
    await _pump(t, phone);
    await _shot('phone_home');
  });

  testWidgets('phone molar mass', (t) async {
    await _pump(t, phone);
    await _openTool(t, 'Mol Kütlesi');
    await _tapText(t, 'CuSO₄·5H₂O');
    await t.drag(find.byType(ListView).first, const Offset(0, -420));
    await t.pumpAndSettle();
    await _shot('phone_molar_mass');
  });

  testWidgets('phone acid base', (t) async {
    await _pump(t, phone);
    await _openTool(t, 'Asit, Baz ve pH');
    await _tapText(t, 'Zayıf asit');
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), '1,8e-5');
    await t.enterText(fields.at(1), '0,1');
    await _tapText(t, 'Hesapla');
    await t.drag(find.byType(ListView).first, const Offset(0, -400));
    await t.pumpAndSettle();
    await _shot('phone_acid_base');
  });

  testWidgets('phone balancer', (t) async {
    await _pump(t, phone, theme: 'dark');
    await _openTool(t, 'Denklem ve Stokiyometri');
    await _tapText(t, 'C₃H₈ + O₂ → CO₂ + H₂O');
    await t.drag(find.byType(ListView).first, const Offset(0, -520));
    await t.pumpAndSettle();
    await _shot('phone_balancer_dark');
  });

  testWidgets('phone calculator', (t) async {
    await _pump(t, phone);
    await t.tap(find.byIcon(Icons.calculate_outlined));
    await t.pumpAndSettle();
    for (final k in ['2', '×', 'sin', '3', '0', ')', '+', '√', '2', '=']) {
      await t.tap(find.text(k).last);
      await t.pump();
    }
    await t.pumpAndSettle();
    await _shot('phone_calculator');
  });

  testWidgets('phone periodic table', (t) async {
    await _pump(t, phone);
    await t.tap(find.byIcon(Icons.apps_outlined));
    await t.pumpAndSettle();
    await _shot('phone_periodic');
    await t.tap(find.text('Fe').first);
    await t.pumpAndSettle();
    await _shot('phone_element_fe');
  });

  testWidgets('tablet gas law', (t) async {
    await _pump(t, tablet);
    await _openTool(t, 'Gaz Yasaları');
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), '1');
    await t.enterText(fields.at(1), '1');
    await t.enterText(fields.at(2), '25');
    await _tapText(t, 'Hesapla');
    await _shot('tablet_gas');
  });

  testWidgets('tablet periodic dark', (t) async {
    await _pump(t, tablet, theme: 'dark', lang: 'en');
    await t.tap(find.byIcon(Icons.apps_outlined));
    await t.pumpAndSettle();
    await _shot('tablet_periodic_dark_en');
  });

  testWidgets('landscape solver with keyboard', (t) async {
    await _pump(t, const Size(844, 390));
    await _openTool(t, 'Seyreltme ve Karıştırma');
    final field = find.byType(TextField).last;
    await t.tap(field);
    t.view.viewInsets = const FakeViewPadding(bottom: 200 * 2);
    await t.pumpAndSettle();
    await _shot('landscape_keyboard');
  });

  Future<void> seekText(WidgetTester t, Finder f) async {
    final sc = find.descendant(of: find.byType(ToolScaffold), matching: find.byType(Scrollable)).first;
    for (var i = 0; i < 40 && f.evaluate().isEmpty; i++) {
      await t.drag(sc, const Offset(0, -200));
      await t.pumpAndSettle();
    }
    await t.ensureVisible(f.first);
    await t.pumpAndSettle();
  }

  testWidgets('phone titration H3PO4', (t) async {
    await _pump(t, phone);
    await _openTool(t, 'Titrasyon Eğrisi');
    await _tapText(t, 'H₃PO₄');
    await seekText(t, find.text('Hesapla'));
    await t.tap(find.text('Hesapla'));
    await t.pumpAndSettle();
    await seekText(t, find.byType(XyChart));
    await _shot('phone_titration');
  });

  testWidgets('tablet calibration', (t) async {
    await _pump(t, tablet);
    await _openTool(t, 'İstatistik ve Kalibrasyon');
    await _tapText(t, 'Kalibrasyon doğrusu');
    await _tapText(t, 'Örnek veri');
    await _tapText(t, 'Hesapla');
    await seekText(t, find.byType(XyChart));
    await _shot('tablet_calibration');
  });

  testWidgets('small phone ICE', (t) async {
    await _pump(t, const Size(320, 640));
    await _openTool(t, 'Denge Tablosu (ICE)');
    await seekText(t, find.text('H₂ + I₂ ⇌ 2HI'));
    await t.tap(find.text('H₂ + I₂ ⇌ 2HI'));
    await t.pumpAndSettle();
    await seekText(t, find.text('Denge bileşimi'));
    await _shot('small_ice');
  });

  testWidgets('phone cell', (t) async {
    await _pump(t, phone);
    await _openTool(t, 'Piller ve E° Tablosu');
    await _shot('phone_cell_inputs');
    await seekText(t, find.text('Hesapla'));
    await t.tap(find.text('Hesapla'));
    await t.pumpAndSettle();
    await seekText(t, find.text('1,1037 V'));
    await _shot('phone_cell');
    await seekText(t, find.text('E° tablosunu göster'));
    await t.tap(find.text('E° tablosunu göster'));
    await t.pumpAndSettle();
    await _shot('phone_cell_table');
  });

  testWidgets('phone hess', (t) async {
    await _pump(t, phone);
    await _openTool(t, 'Tepkime Termodinamiği');
    await seekText(t, find.text('CaCO₃(s) → CaO(s) + CO₂(g)'));
    await t.tap(find.text('CaCO₃(s) → CaO(s) + CO₂(g)'));
    await t.pumpAndSettle();
    await seekText(t, find.text('Türler ve tablo değerleri'));
    await _shot('phone_hess_inputs');
    await seekText(t, find.textContaining('ΔG° ('));
    await _shot('phone_hess');
  });

  testWidgets('phone mass spec', (t) async {
    await _pump(t, phone);
    await _openTool(t, 'Kütle Spektrometrisi');
    await seekText(t, find.text('C₆H₅Br'));
    await t.tap(find.text('C₆H₅Br'));
    await t.pumpAndSettle();
    await seekText(t, find.byType(XyChart));
    await _shot('phone_mass_spec');
  });

  testWidgets('phone rate data', (t) async {
    await _pump(t, phone);
    await _openTool(t, 'Veriden Hız Kanunu');
    await seekText(t, find.text('Örnek veri'));
    await t.tap(find.text('Örnek veri'));
    await t.pumpAndSettle();
    await seekText(t, find.byType(XyChart));
    await _shot('phone_rate_data');
  });

  testWidgets('landscape calculator', (t) async {
    await _pump(t, const Size(844, 390));
    await t.tap(find.byIcon(Icons.calculate_outlined));
    await t.pumpAndSettle();
    await _shot('landscape_calculator');
  });

  testWidgets('history and settings', (t) async {
    await _pump(t, phone);
    await _openTool(t, 'Mol Kütlesi');
    await _tapText(t, 'H₂SO₄');
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.history_outlined));
    await t.pumpAndSettle();
    await _shot('phone_history');
    await t.tap(find.byIcon(Icons.grid_view_outlined));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.settings_rounded).first);
    await t.pumpAndSettle();
    await _shot('phone_settings');
    await t.drag(find.byType(ListView).first, const Offset(0, -500));
    await t.pumpAndSettle();
    await _shot('phone_settings_orientation');
    await t.drag(find.byType(ListView).first, const Offset(0, -2000));
    await t.pumpAndSettle();
    await _shot('phone_settings_about');
  });
}
