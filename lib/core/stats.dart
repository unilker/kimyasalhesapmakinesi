import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Special functions
// ---------------------------------------------------------------------------

/// ln Γ(x) for x > 0 (Lanczos approximation as in Numerical Recipes,
/// 3rd ed., §6.1 — full double precision).
double lnGamma(double x) {
  const cof = [
    57.1562356658629235, -59.5979603554754912, 14.1360979747417471,
    -0.491913816097620199, .339946499848118887e-4, .465236289270485756e-4,
    -.983744753048795646e-4, .158088703224912494e-3, -.210264441724104883e-3,
    .217439618115212643e-3, -.164318106536763890e-3, .844182239838527433e-4,
    -.261908384015814087e-4, .368991826595316234e-5,
  ];
  if (x <= 0) throw ArgumentError('x must be positive');
  var y = x;
  var tmp = x + 5.24218750000000000;
  tmp = (x + 0.5) * math.log(tmp) - tmp;
  var ser = 0.999999999999997092;
  for (final c in cof) {
    ser += c / ++y;
  }
  return tmp + math.log(2.5066282746310005 * ser / x);
}

/// Regularized incomplete beta function I_x(a, b) (continued fraction,
/// Numerical Recipes §6.4).
double incompleteBeta(double x, double a, double b) {
  if (x <= 0) return 0;
  if (x >= 1) return 1;
  final lnFront = lnGamma(a + b) - lnGamma(a) - lnGamma(b) +
      a * math.log(x) + b * math.log(1 - x);
  if (x < (a + 1) / (a + b + 2)) {
    return math.exp(lnFront) * _betaCf(x, a, b) / a;
  }
  return 1 - math.exp(lnFront) * _betaCf(1 - x, b, a) / b;
}

double _betaCf(double x, double a, double b) {
  const tiny = 1e-300;
  final qab = a + b, qap = a + 1, qam = a - 1;
  var c = 1.0;
  var d = 1 - qab * x / qap;
  if (d.abs() < tiny) d = tiny;
  d = 1 / d;
  var h = d;
  for (var m = 1; m <= 300; m++) {
    final m2 = 2 * m;
    var aa = m * (b - m) * x / ((qam + m2) * (a + m2));
    d = 1 + aa * d;
    if (d.abs() < tiny) d = tiny;
    c = 1 + aa / c;
    if (c.abs() < tiny) c = tiny;
    d = 1 / d;
    h *= d * c;
    aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
    d = 1 + aa * d;
    if (d.abs() < tiny) d = tiny;
    c = 1 + aa / c;
    if (c.abs() < tiny) c = tiny;
    d = 1 / d;
    final del = d * c;
    h *= del;
    if ((del - 1).abs() < 1e-15) break;
  }
  return h;
}

/// Cumulative distribution function of Student's t with [df] degrees of
/// freedom.
double studentTCdf(double t, double df) {
  final x = df / (df + t * t);
  final tail = 0.5 * incompleteBeta(x, df / 2, 0.5);
  return t >= 0 ? 1 - tail : tail;
}

/// Quantile of Student's t: the t with P(T ≤ t) = [p].
double studentTQuantile(double p, double df) {
  if (p <= 0 || p >= 1) throw ArgumentError('p must be in (0, 1)');
  if (p == 0.5) return 0;
  if (p < 0.5) return -studentTQuantile(1 - p, df);
  var lo = 0.0, hi = 1.0;
  while (studentTCdf(hi, df) < p) {
    hi *= 2;
    if (hi > 1e12) return double.infinity;
  }
  for (var i = 0; i < 200; i++) {
    final mid = (lo + hi) / 2;
    if (studentTCdf(mid, df) < p) {
      lo = mid;
    } else {
      hi = mid;
    }
    if (hi - lo <= 1e-14 * hi) break;
  }
  return (lo + hi) / 2;
}

/// Two-sided critical t for a confidence [level] (e.g. 0.95).
double tCritical(double level, double df) => studentTQuantile(1 - (1 - level) / 2, df);

// ---------------------------------------------------------------------------
// Descriptive statistics
// ---------------------------------------------------------------------------

class Summary {
  Summary._(this.values, this.sorted, this.mean, this.sd);

  factory Summary.of(List<double> values) {
    if (values.isEmpty) throw ArgumentError('No values');
    final n = values.length;
    final mean = values.reduce((a, b) => a + b) / n;
    // two-pass algorithm for accuracy
    var ss = 0.0;
    for (final x in values) {
      ss += (x - mean) * (x - mean);
    }
    final sd = n > 1 ? math.sqrt(ss / (n - 1)) : double.nan;
    return Summary._(List.unmodifiable(values), [...values]..sort(), mean, sd);
  }

  final List<double> values;
  final List<double> sorted;
  final double mean;

  /// Sample standard deviation (n − 1).
  final double sd;

  int get n => values.length;
  double get variance => sd * sd;
  double get min => sorted.first;
  double get max => sorted.last;
  double get range => max - min;

  /// Relative standard deviation (coefficient of variation), %.
  double get rsd => sd / mean.abs() * 100;

  /// Standard error of the mean.
  double get sem => sd / math.sqrt(n);

  double get median {
    final m = n ~/ 2;
    return n.isOdd ? sorted[m] : (sorted[m - 1] + sorted[m]) / 2;
  }

  /// Half-width of the confidence interval of the mean, t·s/√n.
  double confidenceHalfWidth(double level) =>
      n > 1 ? tCritical(level, n - 1.0) * sem : double.nan;
}

// ---------------------------------------------------------------------------
// Outlier tests
// ---------------------------------------------------------------------------

/// Dixon's Q critical values (Rorabacher, Anal. Chem. 1991, 63, 139),
/// n = 3 … 10, for α = 0.10, 0.05, 0.01.
final Map<double, List<double>> dixonQTable = {
  0.90: [0.941, 0.765, 0.642, 0.560, 0.507, 0.468, 0.437, 0.412],
  0.95: [0.970, 0.829, 0.710, 0.625, 0.568, 0.526, 0.493, 0.466],
  0.99: [0.994, 0.926, 0.821, 0.740, 0.680, 0.634, 0.598, 0.568],
};

class OutlierResult {
  const OutlierResult(this.suspect, this.statistic, this.critical);

  /// The value tested (the one farthest from its neighbours / the mean).
  final double suspect;
  final double statistic;
  final double critical;

  bool get isOutlier => statistic > critical;
}

/// Dixon's Q test for the most extreme value; null when n is outside 3–10
/// or all values are equal.
OutlierResult? dixonQ(List<double> values, double level) {
  final n = values.length;
  final table = dixonQTable[level];
  if (table == null || n < 3 || n > 10) return null;
  final s = [...values]..sort();
  final range = s.last - s.first;
  if (range == 0) return null;
  final qLow = (s[1] - s[0]) / range;
  final qHigh = (s[n - 1] - s[n - 2]) / range;
  final crit = table[n - 3];
  return qHigh >= qLow
      ? OutlierResult(s[n - 1], qHigh, crit)
      : OutlierResult(s[0], qLow, crit);
}

/// Two-sided Grubbs test for the value farthest from the mean (n ≥ 3).
/// G_crit = (n−1)/√n · √(t² / (n − 2 + t²)), t = t(α/(2n), n − 2).
OutlierResult? grubbs(List<double> values, double level) {
  final n = values.length;
  if (n < 3) return null;
  final s = Summary.of(values);
  if (!(s.sd > 0)) return null;
  var suspect = values.first;
  for (final x in values) {
    if ((x - s.mean).abs() > (suspect - s.mean).abs()) suspect = x;
  }
  final g = (suspect - s.mean).abs() / s.sd;
  return OutlierResult(suspect, g, grubbsCritical(n, level));
}

double grubbsCritical(int n, double level) {
  final alpha = 1 - level;
  final t = studentTQuantile(1 - alpha / (2 * n), n - 2.0);
  return (n - 1) / math.sqrt(n) * math.sqrt(t * t / (n - 2 + t * t));
}

// ---------------------------------------------------------------------------
// Linear regression (calibration)
// ---------------------------------------------------------------------------

class Calibration {
  Calibration._({
    required this.xs,
    required this.ys,
    required this.slope,
    required this.intercept,
    required this.r,
    required this.syx,
    required this.sxx,
  });

  /// Least-squares fit y = slope·x + intercept (needs ≥ 3 points and
  /// distinct x values).
  factory Calibration.fit(List<double> xs, List<double> ys) {
    final n = xs.length;
    if (n != ys.length || n < 3) throw ArgumentError('Need at least 3 (x, y) pairs');
    final mx = xs.reduce((a, b) => a + b) / n;
    final my = ys.reduce((a, b) => a + b) / n;
    var sxx = 0.0, syy = 0.0, sxy = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = xs[i] - mx, dy = ys[i] - my;
      sxx += dx * dx;
      syy += dy * dy;
      sxy += dx * dy;
    }
    if (sxx == 0) throw ArgumentError('x values must not all be equal');
    final slope = sxy / sxx;
    final intercept = my - slope * mx;
    var ssRes = 0.0;
    for (var i = 0; i < n; i++) {
      final e = ys[i] - (slope * xs[i] + intercept);
      ssRes += e * e;
    }
    final r = syy == 0 ? 1.0 : sxy / math.sqrt(sxx * syy);
    return Calibration._(
      xs: List.unmodifiable(xs),
      ys: List.unmodifiable(ys),
      slope: slope,
      intercept: intercept,
      r: r,
      syx: math.sqrt(ssRes / (n - 2)),
      sxx: sxx,
    );
  }

  final List<double> xs;
  final List<double> ys;
  final double slope;
  final double intercept;

  /// Pearson correlation coefficient.
  final double r;

  /// Residual standard deviation s_y/x.
  final double syx;
  final double sxx;

  int get n => xs.length;
  double get rSquared => r * r;
  double get meanX => xs.reduce((a, b) => a + b) / n;
  double get meanY => ys.reduce((a, b) => a + b) / n;

  /// Standard deviations of slope and intercept.
  double get sSlope => syx / math.sqrt(sxx);
  double get sIntercept {
    final sumX2 = xs.fold(0.0, (a, x) => a + x * x);
    return syx * math.sqrt(sumX2 / (n * sxx));
  }

  /// Limits of detection and quantification (ICH Q2: 3.3σ/S and 10σ/S
  /// with σ = s_y/x).
  double get lod => 3.3 * syx / slope.abs();
  double get loq => 10 * syx / slope.abs();

  /// Concentration of an unknown from the mean signal [y0] of [k]
  /// replicate measurements, with its standard deviation
  /// (Miller & Miller, eq. 5.9).
  ({double x0, double sx0}) predictX(double y0, {int k = 1}) {
    final x0 = (y0 - intercept) / slope;
    final sx0 = syx /
        slope.abs() *
        math.sqrt(1 / k + 1 / n + math.pow(y0 - meanY, 2) / (slope * slope * sxx));
    return (x0: x0, sx0: sx0);
  }
}

/// Parses numbers separated by spaces, new lines, semicolons or tabs.
/// A comma is a decimal separator ("1,5"), and a trailing comma is
/// treated as a separator ("1, 2, 3").
List<double>? parseNumberList(String text) {
  final out = <double>[];
  for (var token in text.split(RegExp(r'[\s;]+'))) {
    token = token.trim();
    if (token.endsWith(',')) token = token.substring(0, token.length - 1);
    if (token.isEmpty) continue;
    final v = double.tryParse(token.replaceAll(',', '.'));
    if (v == null || !v.isFinite) return null;
    out.add(v);
  }
  return out;
}
