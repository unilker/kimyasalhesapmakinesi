import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/solver.dart';
import 'package:kimya_hesap/core/solver_catalog.dart';

SolverEquation eq(String id) => [
      ...gasEquations, ...realGasEquations, ...moleEquations, ...solutionEquations,
      ...dilutionEquations, ...acidBaseEquations, ...thermoEquations,
      ...equilibriumEquations, ...nuclearEquations, ...atomicEquations,
      ...colligativeEquations,
    ].firstWhere((e) => e.id == id);

double solve(String id, String target, Map<String, double> v, {int extra = -1}) {
  final r = solveEquation(eq(id), target, v);
  expect(r.ok, isTrue, reason: '$id/$target ${r.error} ${r.errorVariable}');
  return extra < 0 ? r.value : r.extras[extra]!;
}

const year = 31557600.0; // Julian year, s

void main() {
  test('van der Waals: 1 mol N2 in 1 L at 300 K is 24.58 bar (ideal 25.94)', () {
    final p = solve('vdw', 'P', {'V': 1, 'n': 1, 'T': 300, 'a': 1.370, 'b': 0.0387});
    expect(p / 1e5, closeTo(24.5776, 1e-4));
    // and back: the gas-phase volume root reproduces 1 L
    expect(solve('vdw', 'V', {'P': p, 'n': 1, 'T': 300, 'a': 1.370, 'b': 0.0387}), closeTo(1, 1e-9));
    expect(solve('vdw', 'n', {'P': p, 'V': 1, 'T': 300, 'a': 1.370, 'b': 0.0387}), closeTo(1, 1e-9));
    expect(solve('vdw', 'T', {'P': p, 'V': 1, 'n': 1, 'a': 1.370, 'b': 0.0387}), closeTo(300, 1e-9));
  });

  test('van der Waals reduces to the ideal gas for a = b = 0', () {
    expect(solve('vdw', 'V', {'P': 101325, 'n': 1, 'T': 273.15, 'a': 0, 'b': 0}),
        closeTo(22.41396954, 1e-6));
  });

  test('van der Waals below Tc returns the gas (largest) root', () {
    // CO2 at 280 K (below Tc = 304 K), 30 bar, 1 mol: vapour V ≈ 0.53 L,
    // there are three real roots; the largest must be returned.
    final v = solve('vdw', 'V', {'P': 30e5, 'n': 1, 'T': 280, 'a': 3.640, 'b': 0.04267});
    expect(v, greaterThan(0.4));
    expect(v, lessThan(0.8));
  });

  test('molecular speeds of N2 at 25 °C', () {
    expect(solve('gasSpeed', 'u', {'T': 298.15, 'M': 28.0134}), closeTo(515.24, 0.01));
    expect(solve('gasSpeed', 'u', {'T': 298.15, 'M': 28.0134}, extra: 0), closeTo(474.7, 0.1));
    expect(solve('gasSpeed', 'u', {'T': 298.15, 'M': 28.0134}, extra: 1), closeTo(420.7, 0.1));
  });

  test('Kp = Kc (RT)^Δn', () {
    expect(solve('kpkc', 'Kp', {'Kc': 1, 'T': 500, 'dn': -2}), closeTo(5.9405e-4, 1e-8));
    expect(solve('kpkc', 'Kp', {'Kc': 3.7, 'T': 400, 'dn': 0}), 3.7);
  });

  test('Ksp ⇄ molar solubility', () {
    expect(solve('ksp', 's', {'Ksp': 1.77e-10, 'x': 1, 'y': 1}), closeTo(1.3304e-5, 1e-9));
    // CaF2: Ksp = 4s³
    expect(solve('ksp', 's', {'Ksp': 3.45e-11, 'x': 1, 'y': 2}), closeTo(2.05078e-4, 1e-9));
    // Ag2CrO4: Ksp = 4s³ too (x = 2)
    expect(solve('ksp', 'Ksp', {'s': 6.5e-5, 'x': 2, 'y': 1}), closeTo(4 * 6.5e-5 * 6.5e-5 * 6.5e-5, 1e-20));
    // Ca3(PO4)2: Ksp = 108 s⁵
    expect(solve('ksp', 'Ksp', {'s': 1e-7, 'x': 3, 'y': 2}), closeTo(108e-35, 1e-40));
  });

  test('radioactive decay and activity', () {
    expect(solve('decay', 'm', {'m0': 1, 't': 5700 * year, 'th': 5700 * year}), closeTo(0.5, 1e-12));
    expect(solve('decay', 't', {'m0': 1, 'm': 0.25, 'th': 5700 * year}) / year, closeTo(11400, 1e-6));
    // 1 g of radium-226 ≈ 1 Ci (3.66 × 10¹⁰ Bq)
    final a = solve('activity', 'A', {'th': 1600 * year, 'm': 1, 'M': 226.0254098});
    expect(a, closeTo(3.6576e10, 1e6));
    expect(a / 3.7e10, closeTo(0.99, 0.01));
  });

  test('hydrogen spectrum and energy levels', () {
    // Balmer Hα, vacuum wavelength 656.47 nm (NIST: 656.46 nm incl. fine structure)
    expect(solve('rydberg', 'l', {'n1': 2, 'n2': 3}) * 1e9, closeTo(656.47, 0.02));
    // Lyman α 121.57 nm
    expect(solve('rydberg', 'l', {'n1': 1, 'n2': 2}) * 1e9, closeTo(121.57, 0.01));
    expect(solve('rydberg', 'n2', {'n1': 2, 'l': 656.4696e-9}), closeTo(3, 1e-5));
    // E1 of hydrogen = −13.598 eV (NIST ionization energy 13.598 434 eV)
    expect(solve('bohr', 'E', {'n': 1, 'Z': 1}) / 1.602176634e-19, closeTo(-13.5983, 2e-4));
    // He+ (Z = 2), n = 1: four times larger
    expect(solve('bohr', 'E', {'n': 1, 'Z': 2}) / solve('bohr', 'E', {'n': 1, 'Z': 1}), closeTo(4, 1e-12));
  });

  test('de Broglie wavelength of an electron at 10⁶ m/s is 0.727 nm', () {
    final me = 9.1093837139e-28; // g
    expect(solve('deBroglie', 'l', {'m': me, 'v': 1e6}) * 1e9, closeTo(0.72739, 1e-5));
  });

  test('crystal density: NaCl 2.164, Cu 8.935 g/cm³', () {
    expect(solve('crystal', 'rho', {'Z': 4, 'M': 58.443, 'a': 564.02e-12}), closeTo(2.1635, 1e-4));
    expect(solve('crystal', 'rho', {'Z': 4, 'M': 63.546, 'a': 361.49e-12}), closeTo(8.9353, 1e-4));
    expect(solve('crystal', 'a', {'Z': 4, 'M': 63.546, 'rho': 8.9353}) * 1e12, closeTo(361.49, 0.01));
  });

  test('water of crystallisation of copper sulfate', () {
    expect(solve('hydrate', 'x', {'mh': 2.50, 'ma': 1.60, 'M': 159.61}), closeTo(4.98, 0.01));
  });

  test("Henry's law: O2 from air", () {
    // 0.21 atm O2, k_H = 1.3e-3 M/atm → 0.27 mM
    expect(solve('henry', 'C', {'kH': 1.3e-3, 'P': 0.21 * 101325}), closeTo(2.73e-4, 1e-9));
  });

  test('serial dilution', () {
    expect(solve('serial', 'Ck', {'C0': 1, 'DF': 10, 'k': 3}), closeTo(1e-3, 1e-15));
    expect(solve('serial', 'k', {'C0': 1, 'DF': 10, 'Ck': 1e-6}), closeTo(6, 1e-12));
  });

  test('acetate buffer recipe at pH = pKa', () {
    final v = {'pH': 4.76, 'pKa': 4.76, 'C': 0.1, 'V': 1.0, 'Mha': 60.052, 'Ma': 82.034};
    expect(solve('bufferPrep', 'mHA', v), closeTo(3.0026, 1e-4));
    expect(solve('bufferPrep', 'mHA', v, extra: 0), closeTo(4.1017, 1e-4));
  });

  test('final temperature of mixing', () {
    // 100 g water at 80 °C + 200 g water at 20 °C → 40 °C
    final tf = solve('mixTemp', 'Tf',
        {'m1': 100, 'c1': 4.184, 'T1': 353.15, 'm2': 200, 'c2': 4.184, 'T2': 293.15});
    expect(tf, closeTo(313.15, 1e-9));
  });

  test('every preset refers to variables of its equation', () {
    for (final e in [...realGasEquations, ...equilibriumEquations, ...nuclearEquations,
        ...atomicEquations, ...solutionEquations, ...acidBaseEquations, ...colligativeEquations]) {
      for (final p in e.presets) {
        for (final id in p.values.keys) {
          expect(e.variables.any((v) => v.id == id), isTrue, reason: '${e.id}: $id');
        }
        // a preset must leave at least one unknown to solve for
        expect(e.solvable.any((v) => !p.values.containsKey(v.id)), isTrue, reason: e.id);
      }
    }
  });
}
