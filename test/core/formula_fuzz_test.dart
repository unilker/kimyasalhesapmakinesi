import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/formula.dart';

/// Builds a random formula text together with its true atom counts.
class _Gen {
  _Gen(this.rnd);

  final Random rnd;
  static const els = ['H', 'C', 'N', 'O', 'S', 'Cl', 'Na', 'Fe', 'Cu', 'Br', 'Si', 'Mg', 'Ca', 'P', 'Pt'];

  (String, Map<String, int>) group(int depth) {
    final b = StringBuffer();
    final counts = <String, int>{};
    final parts = 1 + rnd.nextInt(3);
    for (var i = 0; i < parts; i++) {
      if (depth < 3 && rnd.nextInt(4) == 0) {
        final (inner, c) = group(depth + 1);
        final brackets = rnd.nextBool() ? ('(', ')') : ('[', ']');
        final n = 1 + rnd.nextInt(4);
        b.write('${brackets.$1}$inner${brackets.$2}${n == 1 ? '' : n}');
        c.forEach((k, v) => counts[k] = (counts[k] ?? 0) + v * n);
      } else {
        final e = els[rnd.nextInt(els.length)];
        final n = 1 + rnd.nextInt(12);
        b.write('$e${n == 1 ? '' : n}');
        counts[e] = (counts[e] ?? 0) + n;
      }
    }
    return (b.toString(), counts);
  }
}

void main() {
  test('5000 random nested formulas, hydrates and charges parse to the right atoms', () {
    final g = _Gen(Random(42));
    for (var t = 0; t < 5000; t++) {
      var (text, counts) = g.group(0);
      if (g.rnd.nextInt(4) == 0) {
        final n = 1 + g.rnd.nextInt(10);
        text = '$text·${n == 1 ? '' : n}H2O';
        counts['H'] = (counts['H'] ?? 0) + 2 * n;
        counts['O'] = (counts['O'] ?? 0) + n;
      }
      var z = 0;
      if (g.rnd.nextInt(4) == 0) {
        z = (g.rnd.nextBool() ? 1 : -1) * (1 + g.rnd.nextInt(3));
        text = '$text^${z.abs() == 1 ? '' : z.abs()}${z > 0 ? '+' : '-'}';
      }
      final f = ChemicalFormula.parse(text);
      expect(f.charge, z, reason: text);
      expect(f.atoms.length, counts.length, reason: text);
      for (final e in counts.entries) {
        expect(f.atoms[e.key], e.value.toDouble(), reason: '$text: ${e.key}');
      }
      var mass = 0.0;
      counts.forEach((k, v) => mass += symbolMass(k)! * v);
      expect(f.molarMass, closeTo(mass, mass * 1e-12), reason: text);
    }
  });
}
