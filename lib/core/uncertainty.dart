import 'dart:math' as math;

import 'math/expression.dart';

/// An input quantity x ± u (standard uncertainty).
class UncertainInput {
  const UncertainInput(this.name, this.value, this.u);

  final String name;
  final double value;
  final double u;
}

/// One row of the uncertainty budget.
class BudgetRow {
  const BudgetRow(this.name, this.sensitivity, this.contribution, this.share);

  final String name;

  /// Sensitivity coefficient cᵢ = ∂f/∂xᵢ.
  final double sensitivity;

  /// |cᵢ|·uᵢ.
  final double contribution;

  /// (cᵢuᵢ)² / u_c², as a fraction.
  final double share;
}

class Propagation {
  const Propagation(this.value, this.u, this.budget);

  final double value;

  /// Combined standard uncertainty u_c (GUM, first order, uncorrelated).
  final double u;
  final List<BudgetRow> budget;

  double get relative => value == 0 ? double.nan : (u / value).abs();
}

double _eval(String expr, Map<String, double> vars, AngleMode mode) =>
    evaluateExpression(expr, angleMode: mode, variables: vars);

/// ∂f/∂x by central differences with one Richardson step (error O(h⁴)).
double _derivative(String expr, Map<String, double> vars, String name, double h, AngleMode mode) {
  final x = vars[name]!;
  double d(double step) {
    final up = Map.of(vars)..[name] = x + step;
    final down = Map.of(vars)..[name] = x - step;
    return (_eval(expr, up, mode) - _eval(expr, down, mode)) / (2 * step);
  }

  final d1 = d(h), d2 = d(h / 2);
  return (4 * d2 - d1) / 3;
}

/// Law of propagation of uncertainty (GUM eq. 10) for independent inputs.
/// Throws [ExpressionException] for invalid expressions or inputs outside
/// the function's domain.
Propagation propagate(String expr, List<UncertainInput> inputs, {AngleMode angleMode = AngleMode.radians}) {
  final vars = {for (final i in inputs) i.name: i.value};
  final y = _eval(expr, vars, angleMode);
  final rows = <(String, double, double)>[];
  var variance = 0.0;
  for (final i in inputs) {
    if (i.u == 0) {
      rows.add((i.name, 0, 0));
      continue;
    }
    // h = 1e-5·|x| balances rounding (≈ ε·|f|/h) against truncation
    // (O(h⁴) after Richardson); 1e-4 lost accuracy near a sqrt singularity
    // and 1e-6 to rounding in the cross-check against automatic
    // differentiation. The derivative is local, so h does not depend on u
    // (except at x = 0).
    final h = i.value != 0 ? i.value.abs() * 1e-5 : i.u * 1e-3;
    final c = _derivative(expr, vars, i.name, h, angleMode);
    final contribution = (c * i.u).abs();
    variance += contribution * contribution;
    rows.add((i.name, c, contribution));
  }
  final u = math.sqrt(variance);
  return Propagation(y, u, [
    for (final (n, c, contribution) in rows)
      BudgetRow(n, c, contribution, variance == 0 ? 0 : contribution * contribution / variance),
  ]);
}

class MonteCarloResult {
  const MonteCarloResult(this.mean, this.sd, this.low, this.high, this.trials);

  final double mean;
  final double sd;

  /// Probabilistically symmetric 95 % coverage interval.
  final double low;
  final double high;
  final int trials;
}

/// GUM Supplement 1 style Monte Carlo with normally distributed inputs.
/// Draws that fall outside the function's domain are skipped.
MonteCarloResult monteCarlo(String expr, List<UncertainInput> inputs,
    {int trials = 20000, int seed = 1, AngleMode angleMode = AngleMode.radians}) {
  final rnd = math.Random(seed);
  double? spare;
  double normal() {
    if (spare != null) {
      final s = spare!;
      spare = null;
      return s;
    }
    // Box–Muller
    double u1;
    do {
      u1 = rnd.nextDouble();
    } while (u1 == 0);
    final u2 = rnd.nextDouble();
    final r = math.sqrt(-2 * math.log(u1));
    spare = r * math.sin(2 * math.pi * u2);
    return r * math.cos(2 * math.pi * u2);
  }

  final ys = <double>[];
  for (var t = 0; t < trials; t++) {
    final vars = {for (final i in inputs) i.name: i.value + i.u * normal()};
    try {
      ys.add(_eval(expr, vars, angleMode));
    } on ExpressionException {
      continue;
    }
  }
  if (ys.length < 2) throw const ExpressionException(ExpressionErrorKind.domain);
  ys.sort();
  final mean = ys.reduce((a, b) => a + b) / ys.length;
  final sd = math.sqrt(ys.fold(0.0, (a, y) => a + (y - mean) * (y - mean)) / (ys.length - 1));
  double q(double p) {
    final pos = p * (ys.length - 1);
    final i = pos.floor();
    final f = pos - i;
    return i + 1 < ys.length ? ys[i] * (1 - f) + ys[i + 1] * f : ys[i];
  }

  return MonteCarloResult(mean, sd, q(0.025), q(0.975), ys.length);
}
