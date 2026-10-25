// Dumps random ICE-table equilibria for tool/crosscheck/check_ice.py.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/ice.dart';

void main() {
  test('dump', () {
    final rnd = Random(5);
    final out = <Map<String, Object?>>[];
    double logUniform(double a, double b) => exp(log(a) + rnd.nextDouble() * (log(b) - log(a)));
    for (var n = 0; n < 1000; n++) {
      final nr = 1 + rnd.nextInt(3), np = 1 + rnd.nextInt(3);
      final species = [
        for (var i = 0; i < nr + np; i++)
          IceSpecies('S$i', (i < nr ? -1 : 1) * (rnd.nextInt(6) + 1) / (rnd.nextBool() ? 1 : 2),
              inQ: rnd.nextInt(8) != 0),
      ];
      final c0 = [for (final _ in species) rnd.nextInt(3) == 0 ? 0.0 : logUniform(1e-6, 10)];
      final k = logUniform(1e-30, 1e30);
      Map<String, Object?> r = {
        'nu': [for (final s in species) s.nu],
        'inQ': [for (final s in species) s.inQ],
        'c0': c0,
        'K': k,
      };
      try {
        final res = solveIce(species, c0, k);
        r['eq'] = res.equilibrium;
        r['x'] = res.extent;
      } on IceException catch (e) {
        r['error'] = e.kind.name;
      }
      out.add(r);
    }
    File('tool/crosscheck/out_ice.json').writeAsStringSync(jsonEncode(out));
  });
}
