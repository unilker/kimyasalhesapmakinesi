import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/math/expression.dart';

void main() {
  double ev(String s, {AngleMode mode = AngleMode.degrees, double? ans}) =>
      evaluateExpression(s, angleMode: mode, ans: ans);

  test('arithmetic and precedence', () {
    expect(ev('1+2×3'), 7);
    expect(ev('(1+2)×3'), 9);
    expect(ev('2^3^2'), 512);
    expect(ev('-2^2'), -4);
    expect(ev('10÷4'), 2.5);
    expect(ev('2−5'), -3);
    expect(ev('5!'), 120);
    expect(ev('50%'), 0.5);
    expect(ev('3²'), 9);
  });

  test('implicit multiplication and constants', () {
    expect(ev('2π'), closeTo(2 * math.pi, 1e-12));
    expect(ev('3(4+1)'), 15);
    expect(ev('(1+1)(2+2)'), 8);
    expect(ev('2e'), closeTo(2 * math.e, 1e-12));
    expect(ev('NA'), 6.02214076e23);
    expect(ev('2R'), closeTo(16.628925236, 1e-9));
  });

  test('scientific notation and decimal comma', () {
    expect(ev('6.022E23'), 6.022e23);
    expect(ev('1,5E-3'), 0.0015);
    expect(ev('2,5×2'), 5);
  });

  test('functions', () {
    expect(ev('sin(30)'), closeTo(0.5, 1e-12));
    expect(ev('sin(180)'), 0);
    expect(ev('cos(90)'), 0);
    expect(ev('sin(30)^2'), closeTo(0.25, 1e-12));
    expect(ev('sin(pi/2)', mode: AngleMode.radians), closeTo(1, 1e-12));
    expect(ev('asin(1)'), closeTo(90, 1e-12));
    expect(ev('log(1000)'), 3);
    expect(ev('ln(e)'), closeTo(1, 1e-12));
    expect(ev('√16'), 4);
    expect(ev('sqrt(2)^2'), closeTo(2, 1e-12));
    expect(ev('2sin(30)'), closeTo(1, 1e-12));
    expect(ev('Ans×2', ans: 21), 42);
  });

  test('auto closes parentheses', () {
    expect(ev('(1+2'), 3);
    expect(ev('sin(30'), closeTo(0.5, 1e-12));
  });

  test('errors', () {
    expect(() => ev(''), throwsA(isA<ExpressionException>()));
    expect(() => ev('1/0'), throwsA(isA<ExpressionException>()));
    expect(() => ev('ln(0)'), throwsA(isA<ExpressionException>()));
    expect(() => ev('sqrt(-1)'), throwsA(isA<ExpressionException>()));
    expect(() => ev('tan(90)'), throwsA(isA<ExpressionException>()));
    expect(() => ev('1+'), throwsA(isA<ExpressionException>()));
    expect(() => ev('foo'), throwsA(isA<ExpressionException>()));
    expect(() => ev('2.5!'), throwsA(isA<ExpressionException>()));
  });

  test('parseNumberInput', () {
    expect(parseNumberInput('12,5'), 12.5);
    expect(parseNumberInput(' 3 '), 3);
    expect(parseNumberInput('25+273.15'), closeTo(298.15, 1e-9));
    expect(parseNumberInput('1.5e-3'), 0.0015);
    expect(parseNumberInput('−4'), -4);
    expect(parseNumberInput(''), isNull);
    expect(parseNumberInput('abc'), isNull);
  });
}
