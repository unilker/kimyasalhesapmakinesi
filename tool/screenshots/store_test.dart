// Renders the store screenshots at the pixel sizes Google Play and the
// App Store accept, in Turkish and English. Run with:
//   flutter test tool/screenshots/store_test.dart --update-goldens
// Output: docs/store/screenshots/<device>/<lang>/NN_<scene>.png
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/app.dart';
import 'package:kimya_hesap/state/app_state.dart';
import 'package:kimya_hesap/ui/common.dart' show ResultCard, ToolScaffold;
import 'package:kimya_hesap/ui/home/home_screen.dart';
import 'package:kimya_hesap/ui/strings.dart';
import 'package:kimya_hesap/ui/tools/registry.dart';
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
  const emoji = '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf';
  if (File(emoji).existsSync()) {
    final l = FontLoader('NotoColorEmoji')..addFont(Future.value(ByteData.sublistView(File(emoji).readAsBytesSync())));
    await l.load();
  }
  var dir = File(Platform.resolvedExecutable).parent;
  while (!File('${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').existsSync() &&
      dir.parent.path != dir.path) {
    dir = dir.parent;
  }
  final icons = File('${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
  await loader.load();
}

/// Logical size and pixel ratio of each store device class.
const _devices = {
  // Google Play: sides 320–3840 px, long side ≤ 2 × short side
  'play_phone': (Size(360, 700), 3.0), // 1080 × 2100
  'play_tablet_7': (Size(600, 960), 2.0), // 1200 × 1920
  'play_tablet_10': (Size(1280, 800), 2.0), // 2560 × 1600
  // App Store: 6.9" iPhone and 13" iPad
  'appstore_iphone_6_9': (Size(440, 956), 3.0), // 1320 × 2868
  'appstore_ipad_13': (Size(1376, 1032), 2.0), // 2752 × 2064
};

String _title(String id, String lang) => tools.firstWhere((t) => t.id == id).title.of(lang);

Future<void> _pump(WidgetTester t, Size size, double dpr, String lang, {String theme = 'light'}) async {
  SharedPreferences.setMockInitialValues({'lang': lang, 'theme': theme, 'rotateButton': false});
  final state = await AppState.create();
  t.view.physicalSize = size * dpr;
  t.view.devicePixelRatio = dpr;
  addTearDown(t.view.reset);
  await t.pumpWidget(AppScope(state: state, child: const KimyaApp()));
  await t.pumpAndSettle();
}

Future<void> _openTool(WidgetTester t, String id, String lang) async {
  final card = find.descendant(of: find.byType(ToolCard), matching: find.text(_title(id, lang)));
  await t.scrollUntilVisible(card, 300,
      scrollable: find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first);
  await t.ensureVisible(card.first);
  await t.pumpAndSettle();
  await t.tap(card.first);
  await t.pumpAndSettle();
}

/// Scrolls the open tool until [f] is built, then brings it into view.
Future<void> _seek(WidgetTester t, Finder f, {double align = 0.5}) async {
  final sc = find.descendant(of: find.byType(ToolScaffold), matching: find.byType(Scrollable)).first;
  for (var i = 0; i < 40 && f.evaluate().isEmpty; i++) {
    await t.drag(sc, const Offset(0, -200));
    await t.pumpAndSettle();
  }
  await Scrollable.ensureVisible(t.element(f.first), alignment: align);
  await t.pumpAndSettle();
}

/// The result card that contains [f].
Finder _card(Finder f) => find.ancestor(of: f, matching: find.byType(ResultCard));

Future<void> _tap(WidgetTester t, Finder f) async {
  await _seek(t, f);
  await t.tap(f.first);
  await t.pumpAndSettle();
}

typedef _Scene = Future<void> Function(WidgetTester t, String lang);

/// Scenes in store order; the theme is the second field.
final List<(String, String, _Scene)> _scenes = [
  ('home', 'light', (t, lang) async {}),
  ('molar_mass', 'light', (t, lang) async {
    await _openTool(t, 'molarMass', lang);
    await _tap(t, find.text('CuSO₄·5H₂O'));
    await _seek(t, _card(find.textContaining(' · CuSO₄·5H₂O')), align: 0);
  }),
  ('balancer', 'dark', (t, lang) async {
    await _openTool(t, 'balancer', lang);
    await _tap(t, find.text('C₃H₈ + O₂ → CO₂ + H₂O'));
    await _seek(t, _card(find.text(S.balanced.of(lang))), align: 0);
  }),
  ('titration', 'light', (t, lang) async {
    await _openTool(t, 'titration', lang);
    await _tap(t, find.text('H₃PO₄'));
    await _tap(t, find.text(S.calculate.of(lang)));
    await _seek(t, find.byType(XyChart), align: 0);
  }),
  ('periodic', 'light', (t, lang) async {
    await t.tap(find.byIcon(Icons.apps_outlined));
    await t.pumpAndSettle();
  }),
  ('calculator', 'light', (t, lang) async {
    await t.tap(find.byIcon(Icons.calculate_outlined));
    await t.pumpAndSettle();
    for (final k in ['2', '×', 'sin', '3', '0', ')', '+', '√', '2', '=']) {
      await t.tap(find.text(k).last);
      await t.pump();
    }
    await t.pumpAndSettle();
  }),
  ('nmr', 'light', (t, lang) async {
    await _openTool(t, 'nmr', lang);
    await _seek(t, _card(find.textContaining(S.referenceFrequency.of(lang))), align: 0);
  }),
  ('uncertainty', 'light', (t, lang) async {
    await _openTool(t, 'uncertainty', lang);
    await _tap(t, find.text(S.calculate.of(lang)));
    await _seek(t, find.text(S.budgetTitle.of(lang)), align: 0.3);
  }),
];

void main() {
  setUpAll(_loadFonts);

  _devices.forEach((device, spec) {
    final (size, dpr) = spec;
    for (final lang in ['tr', 'en']) {
      for (var i = 0; i < _scenes.length; i++) {
        final (name, theme, scene) = _scenes[i];
        testWidgets('$device $lang $name', (t) async {
          await _pump(t, size, dpr, lang, theme: theme);
          await scene(t, lang);
          final file = '../../docs/store/screenshots/$device/$lang/${(i + 1).toString().padLeft(2, '0')}_$name.png';
          await expectLater(find.byType(KimyaApp), matchesGoldenFile(file));
        });
      }
    }
  });
}
