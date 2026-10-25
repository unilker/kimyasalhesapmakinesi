import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/kinetics_fit.dart';

void main() {
  test('2NO2 → 2NO + O2 (Brown–LeMay): second order, k = 0.544 M⁻¹ s⁻¹', () {
    final fits = fitRateLaws([0, 50, 100, 200, 300], [0.0100, 0.0079, 0.0065, 0.0048, 0.0038]);
    final best = bestFit(fits);
    expect(best.order, 2);
    // scipy.stats.linregress on 1/[A] vs t
    expect(best.k, closeTo(0.5444518714608769, 1e-12));
    expect(best.sK, closeTo(0.001379915328629914, 1e-12));
    expect(best.rSquared, closeTo(0.9999807292430701, 1e-12));
    expect(fits[0].rSquared, closeTo(0.9286721162836822, 1e-12));
    expect(fits[1].rSquared, closeTo(0.9827436543870143, 1e-12));
    expect(fits[1].k, closeTo(0.0031738940095800837, 1e-15));
  });

  test('exact first-order data are recovered exactly', () {
    const k = 0.0231, c0 = 0.85;
    final t = [for (var i = 0; i < 8; i++) i * 15.0];
    final c = [for (final x in t) c0 * math.exp(-k * x)];
    final best = bestFit(fitRateLaws(t, c));
    expect(best.order, 1);
    expect(best.k, closeTo(k, 1e-12));
    expect(best.c0, closeTo(c0, 1e-12));
    expect(best.halfLife, closeTo(math.ln2 / k, 1e-9));
    expect(best.rSquared, closeTo(1, 1e-12));
    expect(best.concentrationAt(40), closeTo(c0 * math.exp(-k * 40), 1e-12));
  });

  test('exact zero- and second-order data', () {
    final t = <double>[0, 10, 20, 30, 40];
    final zero = bestFit(fitRateLaws(t, [for (final x in t) 2.0 - 0.03 * x]));
    expect(zero.order, 0);
    expect(zero.k, closeTo(0.03, 1e-12));
    expect(zero.halfLife, closeTo(2.0 / (2 * 0.03), 1e-9));
    final second = bestFit(fitRateLaws(t, [for (final x in t) 1 / (1 / 0.5 + 0.2 * x)]));
    expect(second.order, 2);
    expect(second.k, closeTo(0.2, 1e-12));
    expect(second.halfLife, closeTo(1 / (0.2 * 0.5), 1e-9));
  });

  test('invalid data', () {
    expect(() => fitRateLaws([0, 1], [1, 0.5]), throwsArgumentError);
    expect(() => fitRateLaws([0, 1, 2], [1, 0.5, 0]), throwsArgumentError);
  });

  group('method of initial rates', () {
    test('2NO + O2 (Chang): rate = k[NO]²[O2], k ≈ 7.1 × 10³ M⁻² s⁻¹', () {
      final r = fitInitialRates([
        [0.0125, 0.0253],
        [0.0250, 0.0253],
        [0.0125, 0.0506],
      ], [0.0281, 0.112, 0.0561]);
      expect(r.orders[0], closeTo(math.log(0.112 / 0.0281) / math.ln2, 1e-12));
      expect(r.orders[1], closeTo(math.log(0.0561 / 0.0281) / math.ln2, 1e-12));
      expect(r.roundedOrders, [2, 1]);
      expect(r.overallOrder, 3);
      expect(r.kRounded.mean, closeTo(7.1e3, 0.1e3));
    });

    test('over-determined synthetic data recover k and the orders', () {
      final conc = <List<double>>[
        [0.10, 0.10, 0.20],
        [0.20, 0.10, 0.20],
        [0.10, 0.30, 0.20],
        [0.10, 0.10, 0.50],
        [0.25, 0.40, 0.30],
      ];
      const k = 3.7;
      final rates = [for (final c in conc) k * c[0] * math.pow(c[1], 2) * math.sqrt(c[2])];
      final r = fitInitialRates(conc, rates);
      expect(r.orders[0], closeTo(1, 1e-12));
      expect(r.orders[1], closeTo(2, 1e-12));
      expect(r.orders[2], closeTo(0.5, 1e-12));
      expect(math.exp(r.logK), closeTo(k, 1e-10));
      expect(r.kRounded.mean, closeTo(k, 1e-10));
      expect(r.kRounded.sd, closeTo(0, 1e-10));
    });

    test('invalid designs are rejected', () {
      expect(() => fitInitialRates([[0.1], [0.1]], [1, 2]), throwsArgumentError); // [A] never changes
      expect(() => fitInitialRates([[0.1, 0.2]], [1]), throwsArgumentError);
      expect(() => fitInitialRates([[0.1], [0.2]], [1, -2]), throwsArgumentError);
    });
  });
}
