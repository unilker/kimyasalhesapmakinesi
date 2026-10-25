import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/math/expression.dart';
import 'package:kimya_hesap/core/uncertainty.dart';

void main() {
  test('molarity c = m/(M·V): relative uncertainties add in quadrature', () {
    const inputs = [
      UncertainInput('m', 0.2502, 0.0002),
      UncertainInput('M', 58.44, 0.002),
      UncertainInput('V', 0.1, 0.00008),
    ];
    final p = propagate('m/(M*V)', inputs);
    expect(p.value, closeTo(0.2502 / (58.44 * 0.1), 1e-15));
    final rel = math.sqrt(math.pow(0.0002 / 0.2502, 2) + math.pow(0.002 / 58.44, 2) + math.pow(0.00008 / 0.1, 2));
    expect(p.relative, closeTo(rel, rel * 1e-8));
    expect(p.budget.fold(0.0, (a, r) => a + r.share), closeTo(1, 1e-12));
    // V dominates
    expect(p.budget.reduce((a, b) => a.share > b.share ? a : b).name, 'V');
  });

  test('powers, logs and trigonometric functions match the analytic derivatives', () {
    var p = propagate('a^2*b', const [UncertainInput('a', 3, 0.1), UncertainInput('b', 7, 0.2)]);
    expect(p.u, closeTo(math.sqrt(math.pow(2 * 3 * 7 * 0.1, 2) + math.pow(9 * 0.2, 2)), 1e-9));
    p = propagate('ln(x)', const [UncertainInput('x', 0.0125, 0.0003)]);
    expect(p.u, closeTo(0.0003 / 0.0125, 1e-10));
    p = propagate('-log(h)', const [UncertainInput('h', 1.8e-5, 0.1e-5)]);
    expect(p.u, closeTo(0.1e-5 / (1.8e-5 * math.ln10), 1e-10)); // pH
    p = propagate('A/(ε*l)', const [
      UncertainInput('A', 0.452, 0.004),
      UncertainInput('ε', 6220, 50),
      UncertainInput('l', 1, 0),
    ]);
    expect(p.relative, closeTo(math.sqrt(math.pow(0.004 / 0.452, 2) + math.pow(50 / 6220, 2)), 1e-9));
    p = propagate('sin(t)', const [UncertainInput('t', 0.7, 0.01)]);
    expect(p.u, closeTo(math.cos(0.7) * 0.01, 1e-12));
    p = propagate('sin(t)', const [UncertainInput('t', 30, 0.5)], angleMode: AngleMode.degrees);
    expect(p.u, closeTo(math.cos(math.pi / 6) * 0.5 * math.pi / 180, 1e-12));
  });

  test('variables override constants; invalid names are rejected', () {
    final p = propagate('P*V/(R*T)', const [
      UncertainInput('P', 101325, 50),
      UncertainInput('V', 0.0224, 0.0001),
      UncertainInput('R', 8.314462618, 0),
      UncertainInput('T', 273.15, 0.1),
    ]);
    expect(p.value, closeTo(101325 * 0.0224 / (8.314462618 * 273.15), 1e-12));
    expect(isValidVariableName('m'), isTrue);
    expect(isValidVariableName('ε'), isTrue);
    expect(isValidVariableName('x1'), isFalse);
    expect(isValidVariableName('sin'), isFalse);
    expect(isValidVariableName('e'), isFalse);
    expect(isValidVariableName(''), isFalse);
  });

  test('Monte Carlo agrees for linear models and catches first-order failure', () {
    final lin = monteCarlo('a+b', const [UncertainInput('a', 10, 0.3), UncertainInput('b', 5, 0.4)], trials: 40000);
    expect(lin.mean, closeTo(15, 0.01));
    expect(lin.sd, closeTo(0.5, 0.01));
    expect(lin.high - lin.low, closeTo(2 * 1.959964 * 0.5, 0.03));
    // y = x² at x = 0 ± 1: GUM first order gives u = 0, the true sd is √2
    final first = propagate('x^2', const [UncertainInput('x', 0, 1)]);
    expect(first.u, closeTo(0, 1e-12));
    final mc = monteCarlo('x^2', const [UncertainInput('x', 0, 1)], trials: 40000);
    expect(mc.mean, closeTo(1, 0.03));
    expect(mc.sd, closeTo(math.sqrt2, 0.05));
  });
}
