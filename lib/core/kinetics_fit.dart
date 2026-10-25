import 'dart:math' as math;

import 'stats.dart';

/// Linear fit of one integrated rate law to concentration–time data.
class OrderFit {
  OrderFit._(this.order, this.line);

  /// Reaction order: 0 ([A] vs t), 1 (ln[A] vs t) or 2 (1/[A] vs t).
  final int order;

  /// The straight-line fit of the linearised data.
  final Calibration line;

  /// Rate constant: −slope for orders 0 and 1, slope for order 2.
  double get k => order == 2 ? line.slope : -line.slope;

  /// Standard deviation of k (that of the slope).
  double get sK => line.sSlope;

  double get rSquared => line.rSquared;

  /// [A]₀ from the intercept.
  double get c0 => switch (order) {
        0 => line.intercept,
        1 => math.exp(line.intercept),
        _ => 1 / line.intercept,
      };

  /// First half-life starting from the fitted [A]₀.
  double get halfLife => switch (order) {
        0 => c0 / (2 * k),
        1 => math.ln2 / k,
        _ => 1 / (k * c0),
      };

  /// Concentration predicted by the fitted law at time [t].
  double concentrationAt(double t) => switch (order) {
        0 => line.intercept - k * t,
        1 => math.exp(line.intercept - k * t),
        _ => 1 / (line.intercept + k * t),
      };
}

/// Fits zero-, first- and second-order integrated rate laws to the data
/// (needs ≥ 3 points, distinct times and positive concentrations). The
/// returned list is ordered by order; [bestFit] picks the largest R².
List<OrderFit> fitRateLaws(List<double> t, List<double> c) {
  if (t.length != c.length || t.length < 3) throw ArgumentError('Need at least 3 (t, [A]) pairs');
  if (c.any((v) => !(v > 0))) throw ArgumentError('Concentrations must be positive');
  return [
    OrderFit._(0, Calibration.fit(t, c)),
    OrderFit._(1, Calibration.fit(t, [for (final v in c) math.log(v)])),
    OrderFit._(2, Calibration.fit(t, [for (final v in c) 1 / v])),
  ];
}

OrderFit bestFit(List<OrderFit> fits) => fits.reduce((a, b) => b.rSquared > a.rSquared ? b : a);

/// Method of initial rates: rate = k·Π[Xᵢ]^mᵢ fitted by least squares on
/// log rate = log k + Σ mᵢ·log[Xᵢ].
class InitialRates {
  InitialRates._(this.orders, this.logK, this.concentrations, this.rates);

  /// Fitted (non-rounded) orders, one per reactant column.
  final List<double> orders;

  /// Natural log of k from the same fit.
  final double logK;
  final List<List<double>> concentrations;
  final List<double> rates;

  /// Orders rounded to the nearest half.
  List<double> get roundedOrders => [for (final m in orders) (m * 2).round() / 2];

  /// k from every experiment with the [roundedOrders]: mean and standard
  /// deviation (the textbook way of reporting k).
  ({double mean, double sd}) get kRounded {
    final ks = <double>[];
    for (var e = 0; e < rates.length; e++) {
      var d = 1.0;
      for (var i = 0; i < orders.length; i++) {
        d *= math.pow(concentrations[e][i], roundedOrders[i]);
      }
      ks.add(rates[e] / d);
    }
    final mean = ks.reduce((a, b) => a + b) / ks.length;
    final sd = ks.length < 2
        ? 0.0
        : math.sqrt(ks.fold(0.0, (a, k) => a + (k - mean) * (k - mean)) / (ks.length - 1));
    return (mean: mean, sd: sd);
  }

  /// Overall order with the rounded orders.
  double get overallOrder => roundedOrders.fold(0.0, (a, b) => a + b);
}

/// [concentrations][experiment][reactant] and the initial [rates]; needs
/// at least one more experiment than reactants, positive values and
/// concentrations that vary independently.
InitialRates fitInitialRates(List<List<double>> concentrations, List<double> rates) {
  final n = rates.length;
  if (n == 0 || concentrations.length != n) throw ArgumentError('No data');
  final p = concentrations.first.length;
  if (p < 1 || concentrations.any((row) => row.length != p) || n < p + 1) {
    throw ArgumentError('Need more experiments than reactants');
  }
  if (rates.any((r) => !(r > 0)) || concentrations.any((row) => row.any((c) => !(c > 0)))) {
    throw ArgumentError('Values must be positive');
  }
  // Normal equations (XᵀX)β = Xᵀy with columns [1, ln c₁ … ln c_p].
  final m = p + 1;
  final a = List.generate(m, (_) => List<double>.filled(m + 1, 0));
  for (var e = 0; e < n; e++) {
    final x = [1.0, for (final c in concentrations[e]) math.log(c)];
    final y = math.log(rates[e]);
    for (var i = 0; i < m; i++) {
      for (var j = 0; j < m; j++) {
        a[i][j] += x[i] * x[j];
      }
      a[i][m] += x[i] * y;
    }
  }
  // Gaussian elimination with partial pivoting.
  for (var c = 0; c < m; c++) {
    var piv = c;
    for (var r = c + 1; r < m; r++) {
      if (a[r][c].abs() > a[piv][c].abs()) piv = r;
    }
    if (a[piv][c].abs() < 1e-12 * (1 + a[c][c].abs())) {
      throw ArgumentError('Concentrations do not vary independently');
    }
    final tmp = a[c];
    a[c] = a[piv];
    a[piv] = tmp;
    for (var r = 0; r < m; r++) {
      if (r == c) continue;
      final f = a[r][c] / a[c][c];
      for (var k = c; k <= m; k++) {
        a[r][k] -= f * a[c][k];
      }
    }
  }
  final beta = [for (var i = 0; i < m; i++) a[i][m] / a[i][i]];
  return InitialRates._(beta.sublist(1), beta.first, concentrations, rates);
}
