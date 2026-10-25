import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/water.dart';

void main() {
  test('pKw reproduces the IAPWS R11-24 program-verification values (Table 2)', () {
    const cases = [
      (300.0, 1.0, 13.906672),
      (600.0, 0.07, 20.161651),
      (600.0, 0.7, 11.147093),
      (800.0, 0.2, 14.487671),
      (800.0, 1.2, 6.4058649),
      (1270.0, 0.0, 35.081557),
    ];
    for (final (t, rho, ref) in cases) {
      expect(pKwIapws(t, rho), closeTo(ref, 1e-6), reason: '$t K, $rho g/cm³');
    }
  });

  test('pKw of liquid water at 0.1 MPa matches IAPWS Table 3', () {
    final table = {0.0: 14.95, 25.0: 13.99, 50.0: 13.26, 75.0: 12.70, 100.0: 12.25};
    table.forEach((t, ref) => expect(pKwAt(t), closeTo(ref, 0.006), reason: '$t °C'));
    // neutral pH at 25 °C ≈ 7.00; at 37 °C pKw ≈ 13.62 → 6.81
    expect(pKwAt(25) / 2, closeTo(6.997, 0.002));
    expect(pKwAt(37) / 2, closeTo(6.81, 0.005));
  });

  test('vapour pressure (Wagner–Pruß) against IAPWS fixed points and IF97 test values', () {
    expect(waterVaporPressure(273.16), closeTo(611.657, 0.01));
    expect(waterVaporPressure(waterCriticalT), closeTo(waterCriticalP, 1e-3));
    expect(waterVaporPressure(373.15), closeTo(101418, 3));
    // IAPWS-IF97 region-4 verification values
    expect(waterVaporPressure(300) / 3536.58941, closeTo(1, 5e-4));
    expect(waterVaporPressure(500) / 2.63889776e6, closeTo(1, 5e-4));
    expect(waterVaporPressure(600) / 12.3443146e6, closeTo(1, 5e-4));
  });

  test('boiling point is the inverse of the vapour pressure', () {
    // normal boiling point on ITS-90
    expect(waterBoilingPoint(101325)! - 273.15, closeTo(99.974, 0.002));
    for (final t in <double>[280, 330, 400, 550, 640]) {
      expect(waterBoilingPoint(waterVaporPressure(t)), closeTo(t, 1e-9));
    }
    expect(waterBoilingPoint(100), isNull);
    expect(waterBoilingPoint(3e7), isNull);
  });

  test('density maximum near 4 °C', () {
    expect(waterDensity(3.98), greaterThan(waterDensity(2)));
    expect(waterDensity(3.98), greaterThan(waterDensity(6)));
    expect(waterDensity(3.98), closeTo(999.972, 0.002));
  });
}
