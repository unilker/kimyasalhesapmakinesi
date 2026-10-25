import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/conductivity.dart';

/// Λ° per equivalent of a salt from the ionic values.
double salt(String cation, String anion) =>
    limitingEquivalentConductivity[cation]! + limitingEquivalentConductivity[anion]!;

void main() {
  test('ionic λ° add up to the measured Λ° of electrolytes (Kohlrausch)', () {
    // measured limiting equivalent conductivities at 25 °C, S cm² mol⁻¹
    final measured = {
      ('H⁺', 'Cl⁻'): 425.95,
      ('K⁺', 'Cl⁻'): 149.79,
      ('Na⁺', 'Cl⁻'): 126.39,
      ('Mg²⁺', 'Cl⁻'): 129.34,
      ('La³⁺', 'Cl⁻'): 145.9,
      ('Cu²⁺', 'SO₄²⁻'): 133.6,
      ('Zn²⁺', 'SO₄²⁻'): 132.7,
      ('K⁺', 'Fe(CN)₆⁴⁻'): 184.0,
      ('K⁺', 'Fe(CN)₆³⁻'): 174.5,
    };
    measured.forEach((k, v) => expect(salt(k.$1, k.$2), closeTo(v, v * 0.0015), reason: '$k'));
    // the Kohlrausch difference: Λ°(HAc) = Λ°(HCl) + Λ°(NaAc) − Λ°(NaCl) = 390.6
    expect(salt('H⁺', 'Cl⁻') + salt('Na⁺', 'CH₃COO⁻') - salt('Na⁺', 'Cl⁻'), closeTo(390.55, 0.01));
  });

  test('κ of dilute solutions', () {
    // 1 mM KCl: Λ°·c = 149.79 µS/cm; measured 147.0 µS/cm (Λ = 146.95)
    final k = kohlrauschConductivity([('K⁺', 1, 1e-3), ('Cl⁻', -1, 1e-3)])!;
    expect(k * 1e4, closeTo(149.79, 1e-9));
    expect(k * 1e4 / 146.95, closeTo(1, 0.025));
    // a 2:2 salt counts both charges: 1 mM MgSO4 → 2 × (53.0 + 80.0) µS/cm
    expect(kohlrauschConductivity([('Mg²⁺', 2, 1e-3), ('SO₄²⁻', -2, 1e-3)])! * 1e4, closeTo(266.0, 1e-9));
    // pure water at 25 °C: [H⁺] = [OH⁻] = 1.0e-7 M → 0.0548 µS/cm (18.2 MΩ cm)
    final w = kohlrauschConductivity([('H⁺', 1, 1.0e-7), ('OH⁻', -1, 1.0e-7)])!;
    // resistivity in MΩ·cm is the inverse of κ in µS/cm
    expect(1 / (w * 1e4), closeTo(18.2, 0.1));
    expect(kohlrauschConductivity([('Sc³⁺', 3, 1e-3)]), isNull);
  });

  test('transport numbers', () {
    final t = transportNumbers([('K⁺', 1, 0.01), ('Cl⁻', -1, 0.01)])!;
    // t(K⁺) in KCl at infinite dilution ≈ 0.4906
    expect(t[0], closeTo(0.4906, 0.0005));
    expect(t[0] + t[1], closeTo(1, 1e-15));
    // H⁺ carries 82 % of the current in HCl
    expect(transportNumbers([('H⁺', 1, 0.01), ('Cl⁻', -1, 0.01)])![0], closeTo(0.821, 0.001));
  });
}
