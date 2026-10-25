import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/formula.dart';
import 'package:kimya_hesap/core/constants.dart';
import 'package:kimya_hesap/core/electrochem.dart';
import 'package:kimya_hesap/core/thermochem.dart';

ThermoResult run(String equation, [List<String?>? notes]) {
  final r = parseThermoReaction(equation);
  final entries = <ThermoEntry>[];
  for (var i = 0; i < r.species.length; i++) {
    final c = thermoCandidates(r.species[i]);
    expect(c, isNotEmpty, reason: r.species[i].text);
    final want = notes?[i];
    entries.add(want == null ? c.first : c.firstWhere((e) => e.note?.en == want));
  }
  return ThermoResult(entries, r.nu);
}

void main() {
  group('data table', () {
    test('every formula parses, states are valid, no duplicates', () {
      final seen = <String>{};
      for (final e in thermoData) {
        final f = ChemicalFormula.parse(e.formula);
        expect(['s', 'l', 'g', 'aq'], contains(e.state), reason: e.formula);
        expect(seen.add('${e.formula}|${e.state}|${e.note?.en}'), isTrue, reason: e.formula);
        if (e.state != 'aq') expect(f.charge, 0, reason: e.formula);
      }
      expect(thermoData.length, greaterThan(300));
    });

    test('elements in their reference state have ΔfH° = 0', () {
      for (final (f, st) in [('H2', 'g'), ('O2', 'g'), ('N2', 'g'), ('Cl2', 'g'), ('F2', 'g'),
          ('Na', 's'), ('Fe', 's'), ('Cu', 's'), ('Zn', 's'), ('C', 's'), ('S', 's')]) {
        final e = thermoData.firstWhere((e) => e.formula == f && e.state == st);
        expect(e.dfH, 0, reason: f);
      }
      expect(thermoData.firstWhere((e) => e.formula == 'Br2' && e.state == 'l').dfH, 0);
      expect(thermoData.firstWhere((e) => e.formula == 'Hg' && e.state == 'l').dfH, 0);
      expect(thermoData.firstWhere((e) => e.formula == 'I2' && e.state == 's').dfH, 0);
      expect(thermoData.firstWhere((e) => e.formula == 'H^+').dfH, 0);
      expect(thermoData.firstWhere((e) => e.formula == 'H^+').s, 0);
    });

    test('CODATA key values are used verbatim', () {
      final w = thermoData.firstWhere((e) => e.formula == 'H2O' && e.state == 'l');
      expect([w.dfH, w.s, w.uH, w.uS], [-285.830, 69.95, 0.040, 0.03]);
      expect(w.source, ThermoSource.codata);
      final co2 = thermoData.firstWhere((e) => e.formula == 'CO2' && e.state == 'g');
      expect([co2.dfH, co2.s], [-393.51, 213.785]);
    });
  });

  group('candidates', () {
    test('the usual state comes first and the typed formula wins over isomers', () {
      ThermoEntry first(String eq, int i) => thermoCandidates(parseThermoReaction(eq).species[i]).first;
      expect(first('H2 + O2 -> H2O', 2).state, 'l');
      expect(first('C2H5OH + O2 -> CO2 + H2O', 0).formula, 'C2H5OH');
      expect(first('C2H5OH + O2 -> CO2 + H2O', 0).state, 'l');
      expect(first('H2 + O2 -> H2O(g)', 2).state, 'g');
      expect(first('Na + H^+ -> Na^+ + H2', 2).state, 'aq');
      // the stable polymorph at 25 °C is the default
      expect(first('CaCO3 -> CaO + CO2', 0).note?.en, 'calcite');
    });
  });

  group('literature values', () {
    test('H2 + ½O2 → H2O(l): ΔfG° = −237.14 kJ/mol', () {
      final r = run('H2 + 0.5O2 -> H2O(l)');
      expect(r.deltaH, closeTo(-285.83, 1e-9));
      expect(r.deltaS, closeTo(69.95 - 130.680 - 0.5 * 205.152, 1e-9));
      expect(r.deltaG(), closeTo(-237.14, 0.01));
      final u = r.uncertainty!;
      expect(u.$1, closeTo(0.040, 1e-9));
    });

    test('CH4 combustion: ΔH° = −890.6 kJ/mol', () {
      final r = run('CH4 + O2 -> CO2 + H2O(l)');
      expect(r.deltaH, closeTo(-890.57, 0.01));
      expect(r.uncertainty, isNull); // CH4 is not a CODATA key value
    });

    test('Haber process: ΔG° = −32.8 kJ, K ≈ 5.6 × 10⁵ at 25 °C', () {
      final r = run('N2 + 3H2 -> 2NH3');
      expect(r.deltaH, closeTo(-91.88, 1e-9));
      expect(r.deltaS, closeTo(2 * 192.77 - 191.609 - 3 * 130.680, 1e-9));
      expect(r.deltaG(), closeTo(-32.81, 0.01));
      expect(math.pow(10, r.log10K()), closeTo(5.6e5, 0.1e5));
    });

    test('limestone decomposition: ΔG° = 0 near 1118 K (845 °C)', () {
      final r = run('CaCO3(s) -> CaO(s) + CO2(g)', ['calcite', null, null]);
      expect(r.deltaH, closeTo(179.17, 0.01));
      expect(r.crossover!, closeTo(1118.5, 0.5));
      expect(r.deltaG(r.crossover!), closeTo(0, 1e-9));
    });

    test('AgCl solubility from thermodynamic data matches Ksp = 1.77 × 10⁻¹⁰', () {
      final r = run('AgCl(s) -> Ag^+ + Cl^-');
      final ksp = math.pow(10, r.log10K());
      expect(ksp, closeTo(1.77e-10, 0.05e-10));
    });

    test('Zn + Cu²⁺: ΔG° agrees with E° = 1.1037 V within the data uncertainty', () {
      final r = run('Zn(s) + Cu^2+ -> Zn^2+ + Cu(s)');
      final cell = galvanicCell(
        standardPotentials.firstWhere((h) => h.couple == 'Cu²⁺/Cu(s)'),
        standardPotentials.firstWhere((h) => h.couple == 'Zn²⁺/Zn(s)'),
      );
      expect(r.deltaG(), closeTo(cell.deltaG / 1000, 1.5));
    });

    test('ΔG° = −RT ln K is self-consistent', () {
      final r = run('2NO2 -> N2O4(g)');
      final k = math.pow(10, r.log10K()).toDouble();
      expect(-gasConstant * 298.15 * math.log(k) / 1000, closeTo(r.deltaG(), 1e-9));
      // Measured Kp of 2NO2 ⇌ N2O4 at 25 °C lies between about 6.7 and 8.7.
      expect(k, inInclusiveRange(6.0, 9.0));
    });
  });

  test('written coefficients must balance', () {
    expect(() => parseThermoReaction('H2 + O2 -> 2H2O'), throwsA(isA<ThermoException>()));
    expect(parseThermoReaction('H2 + O2 -> H2O').autoBalanced, isTrue);
  });
}
