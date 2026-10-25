// Dumps isotope patterns of random formulas for tool/crosscheck/check_isotopes.py.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/formula.dart';
import 'package:kimya_hesap/core/isotope_pattern.dart';

void main() {
  test('dump', () {
    final rnd = Random(3);
    const pool = ['C', 'H', 'N', 'O', 'S', 'Cl', 'Br', 'Si', 'P', 'F', 'I', 'B', 'Se', 'Sn', 'Fe', 'Cu',
        'Zn', 'K', 'Mg', 'Hg', 'Pt', 'Mo', 'Ge'];
    final out = <Map<String, Object>>[];
    for (var k = 0; k < 300; k++) {
      final n = 1 + rnd.nextInt(4);
      final els = <String, int>{};
      for (var i = 0; i < n; i++) {
        final e = pool[rnd.nextInt(pool.length)];
        els[e] = (els[e] ?? 0) + 1 + rnd.nextInt(e == 'C' || e == 'H' ? 30 : 4);
      }
      final z = rnd.nextInt(5) == 0 ? (rnd.nextBool() ? 1 : -1) * (1 + rnd.nextInt(2)) : 0;
      final text = els.entries.map((e) => '${e.key}${e.value}').join() +
          (z == 0 ? '' : '^${z.abs()}${z > 0 ? '+' : '-'}');
      final p = isotopePattern(ChemicalFormula.parse(text), minRelative: 0);
      out.add({
        'atoms': els,
        'z': z,
        'mono': p.monoisotopicMass,
        'avg': p.averageMass,
        'peaks': [for (final q in p.peaks) [q.nominal, q.mass, q.fraction]],
      });
    }
    File('tool/crosscheck/out_isotopes.json').writeAsStringSync(jsonEncode(out));
  });
}
