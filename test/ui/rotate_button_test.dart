import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/state/app_state.dart';
import 'package:kimya_hesap/ui/rotate_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show pumpApp;

void main() {
  late List<List<String>> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        calls.add(List<String>.from(call.arguments as List));
      }
      return null;
    });
  });

  Finder button() => find.byKey(const ValueKey('rotateButton'));

  testWidgets('tap toggles between portrait and landscape', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844), rotateButton: true);
    expect(button(), findsOneWidget);
    expect(find.bySemanticsLabel('Ekranı döndür'), findsOneWidget);
    await tester.tap(button());
    await tester.pumpAndSettle();
    expect(state.orientation, OrientationPref.landscape);
    expect(calls.last, ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);
    expect(find.textContaining('Yatay konuma kilitlendi'), findsOneWidget);

    // Simulate the device having rotated, then rotate back.
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    await tester.tap(button());
    await tester.pumpAndSettle();
    expect(state.orientation, OrientationPref.portrait);
    expect(calls.last, ['DeviceOrientation.portraitUp']);
  });

  testWidgets('long-press offers auto-rotate and hiding', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844), rotateButton: true);
    state.setOrientation(OrientationPref.landscape);
    await tester.pumpAndSettle();
    await tester.longPress(button());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otomatik döndürme'));
    await tester.pumpAndSettle();
    expect(state.orientation, OrientationPref.auto);
    expect(calls.last.length, 4);

    await tester.longPress(button());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Düğmeyi gizle'));
    await tester.pumpAndSettle();
    expect(state.showRotateButton, isFalse);
    expect(button(), findsNothing);
  });

  testWidgets('button can be dragged to the other edge', (tester) async {
    final state = await pumpApp(tester, const Size(390, 844), rotateButton: true);
    await tester.drag(button(), const Offset(-300, 300));
    await tester.pumpAndSettle();
    expect(state.rotateButtonLeft, isTrue);
    expect(state.rotateButtonY, greaterThan(0.2));
    expect(find.byType(RotateButton), findsOneWidget);
    expect(tester.getTopLeft(button()).dx, lessThan(10));
  });

  testWidgets('hidden while the keyboard is open and on tablets', (tester) async {
    await pumpApp(tester, const Size(390, 844), rotateButton: true);
    expect(button(), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(button(), findsNothing);
    tester.view.viewInsets = FakeViewPadding.zero;
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(button(), findsNothing);
  });

  testWidgets('orientation preference is applied on start-up', (tester) async {
    SharedPreferences.setMockInitialValues({'orientation': 'landscape'});
    final state = await AppState.create();
    expect(state.orientation, OrientationPref.landscape);
    expect(calls.last, ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);
  });
}
