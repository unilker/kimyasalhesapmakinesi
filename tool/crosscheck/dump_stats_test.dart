// Dumps statistics results for tool/crosscheck/check_stats.py.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/stats.dart';

void main() {
  test('dump', () {
    final quantiles = [
      for (var df = 1; df <= 200; df++)
        for (final p in [0.9, 0.95, 0.975, 0.99, 0.995, 0.999])
          {'df': df, 'p': p, 't': studentTQuantile(p, df.toDouble())},
    ];
    final grubbsCrit = [
      for (var n = 3; n <= 100; n++)
        for (final level in [0.90, 0.95, 0.99]) {'n': n, 'level': level, 'g': grubbsCritical(n, level)},
    ];
    final rnd = Random(3);
    final regressions = <Map<String, Object>>[];
    for (var k = 0; k < 300; k++) {
      final n = 3 + rnd.nextInt(15);
      final xs = [for (var i = 0; i < n; i++) rnd.nextDouble() * 100];
      final m = rnd.nextDouble() * 10 - 5, b = rnd.nextDouble() * 20 - 10;
      final ys = [for (final x in xs) m * x + b + (rnd.nextDouble() - 0.5) * 5];
      final c = Calibration.fit(xs, ys);
      final y0 = ys[rnd.nextInt(n)] + rnd.nextDouble();
      final p = c.predictX(y0, k: 1 + rnd.nextInt(4));
      final s = Summary.of(ys);
      regressions.add({
        'xs': xs, 'ys': ys, 'slope': c.slope, 'intercept': c.intercept, 'r': c.r,
        'syx': c.syx, 'sSlope': c.sSlope, 'sIntercept': c.sIntercept,
        'mean': s.mean, 'sd': s.sd, 'median': s.median, 'ci95': s.confidenceHalfWidth(0.95),
        'y0': y0, 'x0': p.x0,
      });
    }
    File('tool/crosscheck/out_stats.json').writeAsStringSync(
        jsonEncode({'quantiles': quantiles, 'grubbs': grubbsCrit, 'regressions': regressions}));
  });
}
