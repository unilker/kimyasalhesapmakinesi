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
