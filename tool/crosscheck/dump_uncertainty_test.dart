// Dumps random uncertainty propagations for tool/crosscheck/check_uncertainty.py.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/uncertainty.dart';

/// Random expression as (app syntax, Python syntax with `uncertainties`).
(String, String) _expr(Random rnd, int depth) {
  const vars = ['a', 'b', 'c', 'd'];
  if (depth == 0 || rnd.nextInt(4) == 0) {
    if (rnd.nextInt(5) == 0) {
      final k = (1 + rnd.nextInt(90)) / 10;
      return ('$k', '$k');
    }
    final v = vars[rnd.nextInt(vars.length)];
    return (v, v);
  }
  final (x, px) = _expr(rnd, depth - 1);
  final (y, py) = _expr(rnd, depth - 1);
  return switch (rnd.nextInt(10)) {
    0 => ('($x+$y)', '($px+$py)'),
    1 => ('($x-$y)', '($px-$py)'),
    2 || 3 => ('($x*$y)', '($px*$py)'),
    4 => ('($x/$y)', '($px/$py)'),
    5 => ('($x)^2', '($px)**2'),
    6 => ('sqrt($x*$y)', 'umath.sqrt($px*$py)'),
    7 => ('ln($x*$y)', 'umath.log($px*$py)'),
    8 => ('exp($x/($y+10))', 'umath.exp($px/($py+10))'),
    _ => ('sin($x)', 'umath.sin($px)'),
  };
}

void main() {
  test('dump', () {
    final rnd = Random(9);
    final out = <Map<String, Object>>[];
    while (out.length < 500) {
      final (e, pe) = _expr(rnd, 3);
      final inputs = [
        for (final n in ['a', 'b', 'c', 'd'])
          UncertainInput(n, 0.5 + rnd.nextDouble() * 4.5, 0),
      ];
      final withU = [for (final i in inputs) UncertainInput(i.name, i.value, i.value * (0.001 + rnd.nextDouble() * 0.05))];
      try {
        final p = propagate(e, withU);
        out.add({
          'expr': e,
          'py': pe,
          'vars': {for (final i in withU) i.name: [i.value, i.u]},
          'value': p.value,
          'u': p.u,
          'c': {for (final r in p.budget) r.name: r.sensitivity},
        });
      } on Object {
        continue; // domain error for this draw (e.g. ln of a negative product)
      }
    }
    File('tool/crosscheck/out_uncertainty.json').writeAsStringSync(jsonEncode(out));
  });
}
