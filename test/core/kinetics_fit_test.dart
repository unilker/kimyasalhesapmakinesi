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
}
