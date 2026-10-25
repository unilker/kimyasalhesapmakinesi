import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/empirical.dart';
import 'package:kimya_hesap/core/chem/formula.dart';

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

void main() {
  test('toluene 91.25 % C, 8.75 % H is C7H8 (not C6H7)', () {
    expect(empiricalFormula({'C': 91.25, 'H': 8.75}).formula, 'C7H8');
  });

  test('noisy lab data still give the simple formula', () {
    expect(empiricalFormula({'C': 40.2, 'H': 6.9, 'O': 52.9}).formula, 'CH2O');
    expect(empiricalFormula({'C': 85.5, 'H': 14.5}).formula, 'CH2');
  });

  test('2000 random formulas are recovered from 2-decimal mass percentages', () {
    final rnd = Random(1);
    const pool = ['C', 'H', 'N', 'O', 'S', 'Cl', 'Na', 'K', 'Fe', 'Cu', 'Ca', 'Mg', 'P'];
    for (var t = 0; t < 2000; t++) {
      final n = 2 + rnd.nextInt(3);
      final els = <String, int>{};
      while (els.length < n) {
        els[pool[rnd.nextInt(pool.length)]] = 1 + rnd.nextInt(10);
      }
      final g = els.values.fold(0, _gcd);
      final want = {for (final e in els.entries) e.key: e.value ~/ g};
      var total = 0.0;
      want.forEach((k, v) => total += symbolMass(k)! * v);
      final pct = {
        for (final e in want.entries)
          e.key: double.parse((symbolMass(e.key)! * e.value / total * 100).toStringAsFixed(2)),
      };
      final got = empiricalFormula(pct).counts;
      expect(got, want, reason: '$pct');
    }
  });
}
