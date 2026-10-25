import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/stats.dart';

void main() {
  test('Student t quantiles match scipy.stats.t.ppf', () {
    const ref = {
      1: (12.706204736174694, 63.656741162871526, 6.313751514675037),
      2: (4.302652729749462, 9.924843200918287, 2.9199855803537242),
      3: (3.1824463052837078, 5.840909309733355, 2.3533634348018233),
      4: (2.7764451051977934, 4.604094871349992, 2.1318467863266495),
      5: (2.5705818356363146, 4.032142983555228, 2.0150483733330233),
      10: (2.228138851986274, 3.16927267261695, 1.8124611228116756),
      20: (2.085963447265864, 2.8453397097861077, 1.7247182429207866),
      30: (2.0422724563012378, 2.7499956535672254, 1.697260886593957),
      100: (1.9839715185235518, 2.6258905214380173, 1.6602343260853392),
    };
    ref.forEach((df, v) {
      expect(studentTQuantile(0.975, df.toDouble()), closeTo(v.$1, 1e-9), reason: 'df $df 97.5%');
      expect(studentTQuantile(0.995, df.toDouble()), closeTo(v.$2, 1e-8), reason: 'df $df 99.5%');
      expect(studentTQuantile(0.95, df.toDouble()), closeTo(v.$3, 1e-9), reason: 'df $df 95%');
      expect(tCritical(0.95, df.toDouble()), closeTo(v.$1, 1e-9));
    });
    expect(studentTQuantile(0.5, 7), 0);
    expect(studentTQuantile(0.025, 5), closeTo(-2.5705818356363146, 1e-9));
  });

  test('t CDF is a CDF', () {
    expect(studentTCdf(0, 4), closeTo(0.5, 1e-15));
    expect(studentTCdf(2.7764451051977934, 4), closeTo(0.975, 1e-12));
    // large df approaches the normal distribution
    expect(studentTCdf(1.959963984540054, 1e7), closeTo(0.975, 1e-6));
  });

  test('descriptive statistics', () {
    final s = Summary.of([10.08, 10.11, 10.09, 10.10, 10.12]);
    expect(s.n, 5);
    expect(s.mean, closeTo(10.10, 1e-12));
    expect(s.sd, closeTo(0.01581138830084156, 1e-12));
    expect(s.median, closeTo(10.10, 1e-12));
    expect(s.range, closeTo(0.04, 1e-12));
    expect(s.rsd, closeTo(0.01581138830084156 / 10.10 * 100, 1e-12));
    // 95 % CI: t(4) = 2.776 → ± 0.0196
    expect(s.confidenceHalfWidth(0.95), closeTo(2.7764451051977934 * 0.01581138830084156 / 2.2360679774997896, 1e-12));
    expect(Summary.of([1, 2, 3, 4]).median, 2.5);
  });

  test('Dixon Q test (Miller & Miller: 0.403, 0.410, 0.401, 0.380)', () {
    final q = dixonQ([0.403, 0.410, 0.401, 0.380], 0.95)!;
    expect(q.suspect, 0.380);
    expect(q.statistic, closeTo(0.7, 1e-12));
    expect(q.critical, 0.829);
    expect(q.isOutlier, isFalse);
    final q2 = dixonQ([0.403, 0.410, 0.401, 0.380, 0.400, 0.413, 0.408], 0.95)!;
    expect(q2.statistic, closeTo(0.020 / 0.033, 1e-12));
    expect(q2.isOutlier, isTrue); // > 0.568 for n = 7
    expect(dixonQ([1, 2], 0.95), isNull);
    expect(dixonQ([5, 5, 5], 0.95), isNull);
  });

  test('Grubbs critical values (two-sided, α = 0.05)', () {
    const table = {3: 1.155, 4: 1.481, 5: 1.715, 6: 1.887, 7: 2.020, 8: 2.126, 9: 2.215, 10: 2.290};
    table.forEach((n, g) => expect(grubbsCritical(n, 0.95), closeTo(g, 0.0015), reason: 'n $n'));
    final g = grubbs([0.403, 0.410, 0.401, 0.380, 0.400, 0.413, 0.408], 0.95)!;
    expect(g.suspect, 0.380);
    expect(g.statistic, closeTo(2.0343146071815426, 1e-12));
    expect(g.isOutlier, isTrue); // G_crit(7) = 2.020
  });

  test('linear calibration (Miller & Miller example 5.3.1)', () {
    final c = Calibration.fit([0, 2, 4, 6, 8, 10, 12], [2.1, 5.0, 9.0, 12.6, 17.3, 21.0, 24.7]);
    expect(c.slope, closeTo(1.930357142857143, 1e-12));
    expect(c.intercept, closeTo(1.5178571428571406, 1e-12));
    expect(c.r, closeTo(0.99887956534852, 1e-12));
    expect(c.syx, closeTo(0.43284771324005317, 1e-12));
    expect(c.sSlope, closeTo(0.040900264457004606, 1e-12));
    expect(c.sIntercept, closeTo(0.29493600135953485, 1e-12));
    expect(c.lod, closeTo(0.7399653784159279, 1e-12));
    expect(c.loq, closeTo(2.242319328533115, 1e-12));
    for (final (y0, x0, s) in [
      (2.9, 0.7160037002775218, 0.2645697709699052),
      (13.5, 6.207215541165588, 0.23975422270299107),
      (23.0, 11.128584643848288, 0.2631932592546461),
    ]) {
      final p = c.predictX(y0);
      expect(p.x0, closeTo(x0, 1e-12));
      expect(p.sx0, closeTo(s, 1e-12));
    }
    expect(() => Calibration.fit([1, 1, 1], [1, 2, 3]), throwsArgumentError);
    expect(() => Calibration.fit([1, 2], [1, 2]), throwsArgumentError);
  });

  test('number list parsing', () {
    expect(parseNumberList('1 2\n3;4'), [1, 2, 3, 4]);
    expect(parseNumberList('1,5 2,25'), [1.5, 2.25]);
    expect(parseNumberList('1, 2, 3'), [1, 2, 3]);
    expect(parseNumberList('1.5e-3'), [0.0015]);
    expect(parseNumberList(''), isEmpty);
    expect(parseNumberList('1 x 2'), isNull);
  });
}
