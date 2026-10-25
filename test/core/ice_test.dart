import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/equation.dart';
import 'package:kimya_hesap/core/ice.dart';

Matcher rel(double v, [double tol = 1e-9]) => closeTo(v, v.abs() * tol);

void main() {
  group('reaction parsing', () {
    test('written coefficients are kept', () {
      final r = parseIceReaction('0.5N2 + 1.5H2 = NH3');
      expect([for (final s in r.species) s.nu], [-0.5, -1.5, 1]);
      expect(r.autoBalanced, isFalse);
      expect(r.equation, '0.5N₂ + 1.5H₂ ⇌ NH₃');
    });

    test('equation without coefficients is balanced', () {
      final r = parseIceReaction('N2 + H2 <=> NH3');
      expect([for (final s in r.species) s.nu], [-1, -3, 2]);
      expect(r.autoBalanced, isTrue);
    });

    test('wrong written coefficients are rejected', () {
      expect(() => parseIceReaction('N2 + 3H2 = NH3'),
          throwsA(isA<IceException>().having((e) => e.kind, 'kind', IceErrorKind.unbalanced)));
    });

    test('pure solids and liquids are left out of Q', () {
      final r = parseIceReaction('AgCl(s) = Ag^+ + Cl^-');
      expect([for (final s in r.species) s.inQ], [false, true, true]);
      expect(parseWrittenEquation('2H2O(l) = H3O^+ + OH^-').isBalanced, isTrue);
    });
  });

  group('textbook equilibria', () {
    test('H2 + I2 ⇌ 2HI, Kc = 54.3, 0.500 M each (Chang: 0.107 / 0.786 M)', () {
      final r = parseIceReaction('H2 + I2 = 2HI');
      final res = solveIce(r.species, [0.5, 0.5, 0], 54.3);
      expect(res.equilibrium[0], rel(0.10673664753034227));
      expect(res.equilibrium[2], rel(0.7865267049393154));
      expect(res.equilibrium[0].toStringAsFixed(3), '0.107');
      expect(res.equilibrium[2].toStringAsFixed(3), '0.787');
      expect(res.q0, 0);
    });

    test('the same equilibrium is reached from the product side', () {
      final r = parseIceReaction('H2 + I2 = 2HI');
      final res = solveIce(r.species, [0, 0, 1], 54.3);
      expect(res.extent, lessThan(0));
      expect(res.equilibrium[0], rel(0.10673664753034227));
      expect(res.equilibrium[2], rel(0.7865267049393154));
      expect(res.q0, double.infinity);
    });

    test('N2O4 ⇌ 2NO2, Kc = 4.63e-3, 0.0400 M N2O4', () {
      final r = parseIceReaction('N2O4 = 2NO2');
      final res = solveIce(r.species, [0.04, 0], 4.63e-3);
      expect(res.equilibrium[0], rel(0.03374977119182524));
      expect(res.equilibrium[1], rel(0.012500457616349523));
    });

    test('acetic acid, Ka = 1.8e-5, 0.10 M: exact quadratic root', () {
      final r = parseIceReaction('CH3COOH = H^+ + CH3COO^-');
      final res = solveIce(r.species, [0.1, 0, 0], 1.8e-5);
      expect(res.equilibrium[1], rel(0.001332670973077975));
      expect(-math.log(res.equilibrium[1]) / math.ln10, closeTo(2.8753, 1e-4));
    });

    test('AgCl solubility, Ksp = 1.77e-10, and the common-ion effect', () {
      final r = parseIceReaction('AgCl(s) = Ag^+ + Cl^-');
      final pure = solveIce(r.species, [0, 0, 0], 1.77e-10);
      expect(pure.equilibrium[1], rel(1.330413469565007e-05));
      final common = solveIce(r.species, [0, 0, 0.01], 1.77e-10);
      expect(common.equilibrium[1], rel(1.7699968671110904e-08));
      expect(common.equilibrium[2], rel(0.01 + 1.7699968671110904e-08));
    });

    test('N2 + 3H2 ⇌ 2NH3 with K = 0.5', () {
      final r = parseIceReaction('N2 + 3H2 = 2NH3');
      final res = solveIce(r.species, [1, 3, 0], 0.5);
      expect(res.equilibrium[0], rel(0.5142218635803564));
      expect(res.equilibrium[1], rel(1.542665590741069));
      expect(res.equilibrium[2], rel(0.9715562728392874));
    });
  });

  group('extreme constants keep full precision', () {
    test('K = 1e33: remaining H2 is 6.3246e-17 M', () {
      final r = parseIceReaction('H2 + Cl2 = 2HCl');
      final res = solveIce(r.species, [1, 1, 0], 1e33);
      expect(res.equilibrium[0], rel(6.324555320336759e-17, 1e-8));
      expect(res.equilibrium[2], rel(2, 1e-12));
    });

    test('K = 1e-40: tiny product amounts', () {
      final r = parseIceReaction('N2 + O2 = 2NO');
      final res = solveIce(r.species, [0.8, 0.2, 0], 1e-40);
      // [NO]² / (0.8·0.2) = 1e-40 → [NO] = 4e-21
      expect(res.equilibrium[2], rel(4e-21, 1e-8));
    });

    test('Q equals K at the computed equilibrium', () {
      final r = parseIceReaction('2SO2 + O2 = 2SO3');
      for (final k in [1e-12, 1e-3, 1.0, 280.0, 1e8]) {
        final res = solveIce(r.species, [0.3, 0.2, 0.05], k);
        final c = res.equilibrium;
        final lnQ = 2 * math.log(c[2]) - 2 * math.log(c[0]) - math.log(c[1]);
        expect(lnQ, closeTo(math.log(k), 1e-9), reason: 'K=$k');
        // mass balance: S and O atoms are conserved
        expect(c[0] + c[2], closeTo(0.35, 1e-14));
        expect(2 * c[0] + 2 * c[1] + 3 * c[2], closeTo(1.15, 1e-13));
      }
    });
  });

  group('invalid input', () {
    test('no reaction is possible without starting material', () {
      final r = parseIceReaction('H2 + I2 = 2HI');
      expect(() => solveIce(r.species, [0, 0.5, 0], 54.3),
          throwsA(isA<IceException>().having((e) => e.kind, 'kind', IceErrorKind.noReaction)));
    });

    test('K must be positive', () {
      final r = parseIceReaction('H2 + I2 = 2HI');
      expect(() => solveIce(r.species, [0.5, 0.5, 0], 0), throwsA(isA<IceException>()));
      expect(() => solveIce(r.species, [0.5, -1, 0], 2), throwsA(isA<IceException>()));
    });
  });
}
