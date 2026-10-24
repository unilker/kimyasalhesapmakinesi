import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/empirical.dart';
import 'package:kimya_hesap/core/format.dart';
import 'package:kimya_hesap/core/solver.dart';
import 'package:kimya_hesap/core/solver_catalog.dart';
import 'package:kimya_hesap/core/units.dart';

SolverEquation eq(List<SolverEquation> list, String id) =>
    list.firstWhere((e) => e.id == id);

double solve(SolverEquation e, String target, Map<String, double> v) {
  final r = solveEquation(e, target, v);
  expect(r.ok, isTrue, reason: '${e.id}/$target: ${r.error}');
  return r.value;
}

void main() {
  test('every solver inverts its equation', () {
    final all = [
      ...gasEquations, ...moleEquations, ...solutionEquations,
      ...dilutionEquations, ...acidBaseEquations, ...thermoEquations,
      ...kineticsEquations, ...electroEquations, ...spectroEquations,
      ...colligativeEquations,
    ];
    final ids = <String>{};
    for (final e in all) {
      expect(ids.add(e.id), isTrue, reason: 'duplicate id ${e.id}');
      expect(e.solvers.keys.toSet(),
          everyElement(isIn(e.variables.map((v) => v.id))));
      if (e.defaultTarget != null) {
        expect(e.solvers.containsKey(e.defaultTarget), isTrue, reason: e.id);
      }
      // Pick plausible base values, solve for each variable in turn and make
      // sure solving back reproduces the inputs.
      final seed = <String, double>{};
      var k = 0;
      for (final v in e.variables) {
        seed[v.id] = switch (v.quantity) {
          Quantity.temperature => 300.0 + 10 * k,
          Quantity.dimensionless || Quantity.percent => 0.4 + 0.1 * k,
          _ => 1.0 + 0.5 * k,
        };
        k++;
      }
      final first = e.solvers.keys.first;
      final consistent = Map.of(seed)..remove(first);
      final r0 = solveEquation(e, first, consistent);
      if (!r0.ok) continue; // seed values outside the domain of this equation
      consistent[first] = r0.value;
      for (final target in e.solvers.keys) {
        final inputs = Map.of(consistent)..remove(target);
        final r = solveEquation(e, target, inputs);
        if (!r.ok) continue;
        expect(r.value, closeTo(consistent[target]!, consistent[target]!.abs() * 1e-6 + 1e-12),
            reason: '${e.id} solving for $target');
      }
    }
  });

  test('ideal gas: 1 mol at 0 °C and 1 atm is 22.414 L', () {
    final e = eq(gasEquations, 'idealGas');
    final v = solve(e, 'V', {'P': 101325, 'n': 1, 'T': 273.15});
    expect(v, closeTo(22.414, 0.001));
  });

  test('dilution', () {
    final e = eq(dilutionEquations, 'dilution');
    // 12 M stock to 250 mL of 1 M → 20.83 mL (base unit L)
    expect(solve(e, 'V1', {'C1': 12, 'C2': 1, 'V2': 0.25}), closeTo(0.020833, 1e-6));
  });

  test('acid–base', () {
    final weak = eq(acidBaseEquations, 'weakAcid');
    // 0.1 M acetic acid, Ka = 1.8e-5 → pH 2.87
    expect(solve(weak, 'pH', {'Ka': 1.8e-5, 'C': 0.1}), closeTo(2.875, 0.002));
    final strong = eq(acidBaseEquations, 'strongAcid');
    expect(solve(strong, 'pH', {'C': 0.01, 'k': 1}), closeTo(2.0, 1e-6));
    // very dilute: water dominates
    expect(solve(strong, 'pH', {'C': 1e-9, 'k': 1}), closeTo(6.998, 0.002));
    final base = eq(acidBaseEquations, 'strongBase');
    expect(solve(base, 'pH', {'C': 0.01, 'k': 1}), closeTo(12.0, 1e-6));
    final buffer = eq(acidBaseEquations, 'buffer');
    expect(solve(buffer, 'pH', {'pKa': 4.76, 'A': 0.1, 'HA': 0.1}), closeTo(4.76, 1e-9));
  });

  test('stock solution: 37% HCl', () {
    final e = eq(solutionEquations, 'stock');
    expect(solve(e, 'C', {'w': 37, 'rho': 1.19, 'M': 36.46}), closeTo(12.08, 0.01));
  });

  test('thermo and kinetics', () {
    final g = eq(thermoEquations, 'gibbs');
    expect(solve(g, 'G', {'H': -92200, 'T': 298.15, 'S': -198.7}), closeTo(-32957, 1));
    final cc = eq(thermoEquations, 'clausius');
    // Water: 1 atm at 100 °C, ΔHvap 40.7 kJ/mol → 99.8 mmHg at 50 °C
    final p2 = solve(cc, 'P2', {'P1': 101325, 'T1': 373.15, 'T2': 323.15, 'H': 40700});
    expect(p2 / 133.322387415, closeTo(99.84, 0.01));
    final fo = eq(kineticsEquations, 'halfLife');
    expect(solve(fo, 'th', {'k': 0.693147}), closeTo(1, 1e-5));
  });

  test('electrochemistry', () {
    final n = eq(electroEquations, 'nernst');
    // Daniell cell, Q = 10, n = 2 at 25 °C: 1.10 − 0.0296 = 1.0704 V
    expect(solve(n, 'E', {'E0': 1.10, 'n': 2, 'Q': 10, 'T': 298.15}), closeTo(1.0704, 1e-4));
    final f = eq(electroEquations, 'electrolysis');
    // 2 A for 1 h depositing Cu (63.546, n=2) → 2.371 g
    expect(solve(f, 'm', {'I': 2, 't': 3600, 'M': 63.546, 'n': 2}), closeTo(2.371, 0.001));
  });

  test('photon energy at 500 nm is 2.48 eV', () {
    final e = eq(spectroEquations, 'photon');
    final j = solve(e, 'E', {'l': 500e-9});
    expect(convert(j, unitById(Quantity.energy, 'J'), unitById(Quantity.energy, 'eV')),
        closeTo(2.4797, 1e-4));
  });

  test('validation', () {
    final e = eq(gasEquations, 'idealGas');
    expect(solveEquation(e, 'V', {'P': 1, 'n': 1}).error, SolveError.missingInput);
    expect(solveEquation(e, 'V', {'P': -1, 'n': 1, 'T': 300}).error,
        SolveError.negativeInput);
    expect(solveEquation(e, 'V', {'P': 0, 'n': 1, 'T': 300}).error,
        SolveError.noSolution);
  });

  test('units', () {
    final c = unitById(Quantity.temperature, 'C');
    final f = unitById(Quantity.temperature, 'F');
    final k = unitById(Quantity.temperature, 'K');
    expect(convert(100, c, f), closeTo(212, 1e-9));
    expect(convert(0, c, k), closeTo(273.15, 1e-9));
    expect(convert(1, unitById(Quantity.pressure, 'atm'), unitById(Quantity.pressure, 'Torr')),
        closeTo(760, 1e-9));
  });

  test('empirical formula', () {
    // 40.0% C, 6.7% H, 53.3% O → CH2O; M = 180 → C6H12O6
    expect(empiricalFormula({'C': 40.0, 'H': 6.7, 'O': 53.3}).formula, 'CH2O');
    final glucose = empiricalFormula({'C': 40.0, 'H': 6.7, 'O': 53.3}, molarMass: 180);
    expect(glucose.formula, 'C6H12O6');
    expect(glucose.molecularMultiplier, 6);
    // Fe 69.94%, O 30.06% → Fe2O3 (ratio 1.5)
    expect(empiricalFormula({'Fe': 69.94, 'O': 30.06}).formula, 'Fe2O3');
    // no carbon: alphabetical
    expect(empiricalFormula({'Na': 32.4, 'S': 22.6, 'O': 45.0}).formula, 'Na2O4S');
  });

  test('number formatting', () {
    const tr = NumberFormatter(significantDigits: 4, decimalSeparator: ',');
    expect(tr.format(22.41396954), '22,41');
    expect(tr.format(6.02214076e23), '6,022 × 10²³');
    expect(tr.format(-0.00001234), '−1,234 × 10⁻⁵');
    expect(tr.format(100), '100');
    expect(tr.plain(1.234e-5), '1,234E-5');
    expect(tr.plain(-1.234e-5), '-1,234E-5');
    const en = NumberFormatter(significantDigits: 6);
    expect(en.format(0.5), '0.5');
    expect(en.format(999999.9), '1 × 10⁶');
  });
}
