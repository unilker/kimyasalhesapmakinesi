// Dumps random titration points for tool/crosscheck/check_titration.py.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/titration.dart';

void main() {
  test('dump', () {
    final rnd = Random(11);
    final out = <Map<String, Object>>[];
    for (var k = 0; k < 400; k++) {
      final kind = rnd.nextInt(5);
      final npk = 1 + rnd.nextInt(3);
      final pkas = [for (var i = 0; i < npk; i++) 1 + rnd.nextDouble() * 12]..sort();
      final Analyte a;
      var z0 = 0, cat = 0.0, an = 0.0;
      switch (kind) {
        case 0:
          a = const Analyte.strongAcid();
          an = 1;
        case 1:
          a = const Analyte.strongBase();
          cat = 1;
        case 2:
          a = Analyte.weakAcid(pkas);
        case 3:
          a = Analyte.weakBase(pkas);
          z0 = pkas.length;
        default:
          a = Analyte.baseSalt(pkas, pkas.length);
          cat = pkas.length.toDouble();
      }
      final c = exp(log(1e-4) + rnd.nextDouble() * (log(1) - log(1e-4)));
      final ct = exp(log(1e-4) + rnd.nextDouble() * (log(1) - log(1e-4)));
      final v = 0.01 + rnd.nextDouble() * 0.09;
      final t = Titration(analyte: a, concentration: c, volume: v, titrantConcentration: ct);
      final vt = t.equivalenceVolumes.last * rnd.nextDouble() * 1.6;
      out.add({
        'acid': a.isAcid, 'pkas': a.isStrong ? <double>[] : pkas, 'z0': z0, 'cat': cat, 'an': an,
        'c': c, 'v': v, 'ct': ct, 'vt': vt, 'pH': t.pHAt(vt),
      });
    }
    File('tool/crosscheck/out_titration.json').writeAsStringSync(jsonEncode(out));
  });
}
