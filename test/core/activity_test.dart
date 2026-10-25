import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/activity.dart';

double gamma(double log) => math.pow(10, log).toDouble();

void main() {
  test('water permittivity and density', () {
    expect(waterPermittivity(25), closeTo(78.30, 0.01));
    expect(waterPermittivity(0), closeTo(87.74, 1e-9));
    expect(waterDensity(25), closeTo(997.05, 0.01));
    expect(waterDensity(4), closeTo(999.97, 0.01));
    expect(waterDensity(100), closeTo(958.36, 0.05));
  });

  test('Debye–Hückel A on the molal scale follows Clarke & Glew (1980), 0–100 °C', () {
    // A_φ fit (J. Chem. Soc. Faraday Trans. 1 76, 1911); A_γ(log10) = 3 A_φ / ln 10
    double ref(double t) {
      final tk = t + 273.15;
      final aPhi = -16.39023 + 261.3371 / tk + 3.3689633 * math.log(tk) - 1.437167 * (tk / 100) + 0.111995 * math.pow(tk / 100, 2);
      return 3 * aPhi / math.ln10;
    }

    for (final t in <double>[0, 10, 25, 37, 50, 75, 100]) {
      expect(DebyeHuckel(t).aMolal / ref(t), closeTo(1, 0.003), reason: '$t °C');
    }
    // the familiar 25 °C constants: A = 0.51 (L/mol)^½, 1/B ≈ 305 pm (Harris)
    final dh = DebyeHuckel(25);
    expect(dh.a, closeTo(0.5116, 0.0002));
    expect(1 / dh.bPerPm, closeTo(304, 1.5));
  });

  test('ionic strength', () {
    expect(ionicStrength([(0.1, 1), (0.1, -1)]), closeTo(0.1, 1e-15));
    // 0.01 M MgSO4 → 0.04 M, 0.01 M Na2SO4 → 0.03 M
    expect(ionicStrength([(0.01, 2), (0.01, -2)]), closeTo(0.04, 1e-15));
    expect(ionicStrength([(0.02, 1), (0.01, -2)]), closeTo(0.03, 1e-15));
    expect(ionicStrength([(0.01, 3), (0.03, -1)]), closeTo(0.06, 1e-15));
  });

  test('extended Debye–Hückel reproduces Harris Table 7-1 (Kielland)', () {
    const ionic = [0.001, 0.005, 0.01, 0.05, 0.1];
    final table = <(int, double, List<double>)>[
      (1, 900, [0.967, 0.933, 0.914, 0.86, 0.83]),
      (1, 600, [0.965, 0.929, 0.907, 0.835, 0.80]),
      (1, 450, [0.964, 0.928, 0.902, 0.82, 0.775]),
      (1, 300, [0.964, 0.925, 0.899, 0.805, 0.755]),
      (1, 250, [0.964, 0.924, 0.898, 0.80, 0.75]),
      (2, 800, [0.872, 0.755, 0.69, 0.52, 0.45]),
      (2, 600, [0.870, 0.749, 0.675, 0.485, 0.405]),
      (2, 450, [0.867, 0.742, 0.665, 0.455, 0.37]),
      (2, 400, [0.867, 0.740, 0.660, 0.445, 0.355]),
      (3, 900, [0.738, 0.54, 0.445, 0.245, 0.18]),
      (3, 400, [0.725, 0.505, 0.395, 0.16, 0.095]),
      (4, 1100, [0.588, 0.35, 0.255, 0.10, 0.065]),
      (4, 500, [0.57, 0.31, 0.20, 0.048, 0.021]),
    ];
    final dh = DebyeHuckel(25);
    for (final (z, a, g) in table) {
      for (var k = 0; k < ionic.length; k++) {
        // the table itself was computed with rounded constants
        expect(gamma(dh.logExtended(z, a, ionic[k])), closeTo(g[k], 0.008), reason: 'z $z α $a I ${ionic[k]}');
        expect(gamma(dh.logExtended(-z, a, ionic[k])), closeTo(g[k], 0.008));
      }
    }
    // every ion of the app's list has the size of its Harris row
    expect(kiellandIon('Na⁺').sizePm, 450);
    expect(kiellandIon('SO₄²⁻').sizePm, 400);
    expect(kiellandIon('Fe(CN)₆⁴⁻').charge, -4);
  });

  test('mean activity coefficient of NaCl vs Robinson & Stokes (Davies, extended DH)', () {
    final dh = DebyeHuckel(25);
    // measured γ± (molal; same as molar within 0.3 % here)
    final measured = {0.001: 0.965, 0.005: 0.927, 0.01: 0.902, 0.05: 0.820, 0.1: 0.778};
    measured.forEach((m, ref) {
      final davies = gamma(dh.logDavies(1, m));
      expect(meanActivity(davies, 1, davies, 1), closeTo(ref, 0.006), reason: 'Davies $m');
      final ext = meanActivity(gamma(dh.logExtended(1, 450, m)), 1, gamma(dh.logExtended(-1, 300, m)), 1);
      expect(ext, closeTo(ref, 0.015), reason: 'extended $m');
    });
  });

  test('limits and identities', () {
    final dh = DebyeHuckel(25);
    expect(dh.logExtended(2, 400, 0), 0);
    expect(dh.logDavies(1, 0), 0);
    // α → 0 reduces to the limiting law; very dilute: all three agree
    expect(dh.logExtended(2, 0, 0.01), closeTo(dh.logLimiting(2, 0.01), 1e-15));
    final i = 1e-6;
    expect(dh.logDavies(3, i) / dh.logLimiting(3, i), closeTo(1, 2e-3));
    // z² scaling
    expect(dh.logDavies(2, 0.05), closeTo(4 * dh.logDavies(1, 0.05), 1e-15));
    // mean activity of a symmetric salt is the geometric mean
    expect(meanActivity(0.8, 1, 0.5, 1), closeTo(math.sqrt(0.4), 1e-15));
    expect(meanActivity(0.4, 1, 0.8, 2), closeTo(math.pow(0.4 * 0.64, 1 / 3), 1e-15));
  });
}
