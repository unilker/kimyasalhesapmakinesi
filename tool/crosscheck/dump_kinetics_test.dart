// Dumps random kinetic data sets for tool/crosscheck/check_kinetics.py.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/kinetics_fit.dart';

void main() {
  test('dump', () {
    final rnd = Random(17);
    double lu(double a, double b) => exp(log(a) + rnd.nextDouble() * (log(b) - log(a)));
    final integrated = <Map<String, Object>>[];
    for (var s = 0; s < 200; s++) {
      final n = 3 + rnd.nextInt(10);
      final order = rnd.nextInt(3);
      final k = lu(1e-4, 1), c0 = lu(1e-3, 2);
      final tmax = 3 / (k * (order == 2 ? c0 : 1)) * (order == 0 ? c0 / 2 : 1);
      final t = [for (var i = 0; i < n; i++) tmax * i / n];
      final c = [
        for (final x in t)
          (switch (order) { 0 => max(c0 - k * x, c0 * 0.05), 1 => c0 * exp(-k * x), _ => 1 / (1 / c0 + k * x) }) *
              (1 + 0.03 * (rnd.nextDouble() - 0.5)),
      ];
      final fits = fitRateLaws(t, c);
      integrated.add({
        't': t,
        'c': c,
        'fits': [for (final f in fits) [f.k, f.sK, f.rSquared, f.c0, f.halfLife]],
        'best': bestFit(fits).order,
      });
    }
    final initial = <Map<String, Object>>[];
    for (var s = 0; s < 200; s++) {
      final p = 1 + rnd.nextInt(3);
      final n = p + 1 + rnd.nextInt(4);
      final conc = [for (var e = 0; e < n; e++) [for (var i = 0; i < p; i++) lu(1e-3, 1)]];
      final rates = [for (var e = 0; e < n; e++) lu(1e-6, 1)];
      final r = fitInitialRates(conc, rates);
      initial.add({'conc': conc, 'rates': rates, 'orders': r.orders, 'logK': r.logK});
    }
    File('tool/crosscheck/out_kinetics.json')
        .writeAsStringSync(jsonEncode({'integrated': integrated, 'initial': initial}));
  });
}
