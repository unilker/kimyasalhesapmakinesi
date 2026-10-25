import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/formula.dart';
import 'package:kimya_hesap/core/chem/isotopes_data.dart';
import 'package:kimya_hesap/core/isotope_pattern.dart';

IsotopePattern pat(String f) => isotopePattern(ChemicalFormula.parse(f));

List<double> rel(IsotopePattern p) => [for (final k in p.peaks) k.relative];

void main() {
  test('every element’s isotopic composition sums to 1', () {
    for (final e in naturalIsotopes.entries) {
      final s = e.value.fold(0.0, (a, t) => a + t.$3);
      expect(s, closeTo(1, 2e-4), reason: e.key);
    }
  });

  test('Cl2: M : M+2 : M+4 = 100 : 64.0 : 10.2', () {
    final p = pat('Cl2');
    expect([for (final k in p.peaks) k.nominal], [70, 72, 74]);
    final r = 0.2424 / 0.7576;
    expect(p.peaks[1].relative, closeTo(200 * r, 1e-9));
    expect(p.peaks[2].relative, closeTo(100 * r * r, 1e-9));
    expect(p.peaks[1].relative.toStringAsFixed(1), '64.0');
  });

  test('Br2: 1 : 2 : 1 pattern with the M+2 peak largest', () {
    final p = pat('Br2');
    expect([for (final k in p.peaks) k.nominal], [158, 160, 162]);
    expect(p.peaks[1].relative, 100);
    expect(p.peaks[0].relative, closeTo(0.5069 * 0.5069 / (2 * 0.5069 * 0.4931) * 100, 1e-9));
    expect(p.peaks[2].relative, closeTo(0.4931 * 0.4931 / (2 * 0.5069 * 0.4931) * 100, 1e-9));
  });

  test('benzene M+1 = 6.56 %', () {
    final p = pat('C6H6');
    final m1 = 6 * 0.0107 / 0.9893 + 6 * 0.000115 / 0.999885;
    expect(p.peaks[1].relative, closeTo(100 * m1 + 0, 0.01));
  });

  test('monoisotopic masses match PubChem exact masses', () {
    expect(pat('C8H10N4O2').monoisotopicMass, closeTo(194.08037557, 1e-7)); // caffeine
    expect(pat('C6H12O6').monoisotopicMass, closeTo(180.06338810, 1e-7)); // glucose
    expect(pat('C9H8O4').monoisotopicMass, closeTo(180.04225873, 1e-7)); // aspirin
    expect(pat('CHCl3').monoisotopicMass, closeTo(117.914383, 1e-6)); // chloroform
    for (final f in ['C8H10N4O2', 'C8H11N4O2^+', 'B', 'D2O', 'SnCl4', 'Br2']) {
      final formula = ChemicalFormula.parse(f);
      expect(monoisotopicMass(formula), isotopePattern(formula).monoisotopicMass, reason: f);
    }
  });

  test('ions: [M+H]⁺ of caffeine at m/z 195.087652', () {
    final p = pat('C8H11N4O2^+');
    expect(p.charge, 1);
    expect(p.monoisotopicMass, closeTo(194.08037557 + 1.00782503223 - 5.485799090441e-4, 1e-8));
    expect(p.monoisotopicMass.toStringAsFixed(6), '195.087652');
    final d = pat('C8H12N4O2^2+');
    expect(d.monoisotopicMass, closeTo((194.08037557 + 2 * 1.00782503223 - 2 * 5.485799090441e-4) / 2, 1e-8));
  });

  test('average mass agrees with the molar mass, fractions sum to 1', () {
    for (final f in ['C8H10N4O2', 'C60', 'SnCl4', 'C20H25N3O', 'Fe2(SO4)3', 'C254H377N65O75S6']) {
      final formula = ChemicalFormula.parse(f);
      final p = isotopePattern(formula, minRelative: 0);
      // NIST representative compositions (C: 12.0107) vs CIAAW conventional
      // atomic weights (C: 12.011) differ by up to ~3e-5 relative.
      expect(p.averageMass, closeTo(formula.molarMass, formula.molarMass * 1e-4), reason: f);
      expect(p.peaks.fold(0.0, (a, k) => a + k.fraction), closeTo(1, 1e-12), reason: f);
    }
  });

  test('deuterium is a single isotope', () {
    final p = pat('D2O');
    expect(p.monoisotopicMass, closeTo(2 * 2.01410177812 + 15.99491461957, 1e-9));
    expect(p.peaks.first.nominal, 20);
  });

  test('elements without a natural composition are reported', () {
    expect(() => pat('TcO4^-'), throwsA(isA<IsotopeException>()));
  });

  test('boron: the most abundant isotope ¹¹B defines the monoisotopic mass', () {
    expect(pat('B').monoisotopicMass, closeTo(11.00930536, 1e-8));
    expect(rel(pat('B')), [closeTo(0.199 / 0.801 * 100, 1e-9), 100]);
    expect(pat('B').nominalMass, 11);
    expect(pat('Br2').nominalMass, 158);
    expect(pat('C8H10N4O2').nominalMass, 194);
  });

  test('gaps in an element’s isotopes give no empty peaks (Sn has no ¹¹³Sn)', () {
    final p = isotopePattern(ChemicalFormula.parse('Sn'), minRelative: 0);
    expect([for (final k in p.peaks) k.nominal], [112, 114, 115, 116, 117, 118, 119, 120, 122, 124]);
    for (final k in p.peaks) {
      expect(k.mass.isFinite, isTrue);
    }
  });
}
