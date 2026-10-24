import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/equation.dart';

void main() {
  List<int> coefs(String s) => balanceEquation(s).coefficients;

  test('balances common equations', () {
    expect(coefs('H2 + O2 -> H2O'), [2, 1, 2]);
    expect(coefs('Fe + O2 = Fe2O3'), [4, 3, 2]);
    expect(coefs('C3H8 + O2 → CO2 + H2O'), [1, 5, 3, 4]);
    expect(coefs('KMnO4 + HCl -> KCl + MnCl2 + H2O + Cl2'), [2, 16, 2, 2, 8, 5]);
    expect(coefs('Al + H2SO4 -> Al2(SO4)3 + H2'), [2, 3, 1, 3]);
    expect(coefs('C6H12O6+O2->CO2+H2O'), [1, 6, 6, 6]);
    expect(coefs('CuSO4·5H2O -> CuSO4 + H2O'), [1, 1, 5]);
  });

  test('ignores given coefficients and state symbols', () {
    final eq = balanceEquation('3H2(g) + 7N2(g) -> NH3(g)');
    expect(eq.coefficients, [3, 1, 2]);
    expect(eq.reactants.first.stateSymbol, 'g');
    expect(eq.pretty, '3H₂(g) + N₂(g) → 2NH₃(g)');
  });

  test('balances ionic equations with charge', () {
    expect(
      coefs('MnO4^- + Fe^2+ + H^+ -> Mn^2+ + Fe^3+ + H2O'),
      [1, 5, 8, 1, 5, 4],
    );
    expect(coefs('Fe^3+ + e- -> Fe^2+'), [1, 1, 1]);
    expect(coefs('Cu + Ag+ -> Cu^2+ + Ag'), [1, 2, 1, 2]);
    expect(coefs('Na++Cl- -> NaCl'), [1, 1, 1]);
  });

  test('errors', () {
    expect(() => balanceEquation('H2 + O2'),
        throwsA(isA<EquationException>().having((e) => e.kind, 'k', EquationErrorKind.noArrow)));
    expect(() => balanceEquation('H2 -> O2'),
        throwsA(isA<EquationException>().having((e) => e.kind, 'k', EquationErrorKind.cannotBalance)));
    expect(() => balanceEquation('H2 + O2 -> H2O + H2O2'),
        throwsA(isA<EquationException>().having((e) => e.kind, 'k', EquationErrorKind.multipleSolutions)));
    expect(() => balanceEquation('H2 + Xy -> H2O'),
        throwsA(isA<EquationException>().having((e) => e.kind, 'k', EquationErrorKind.invalidSpecies)));
  });

  test('stoichiometry with limiting reactant', () {
    final eq = balanceEquation('H2 + O2 -> H2O');
    // 4 g H2 (1.984 mol) and 16 g O2 (0.5 mol): O2 limits
    final r = stoichiometry(eq, {0: 4 / 2.016, 1: 16 / 31.998});
    expect(r.limitingIndex, 1);
    expect(r.amounts[1].isLimiting, isTrue);
    expect(r.amounts[2].moles, closeTo(16 / 31.998 * 2, 1e-9));
    expect(r.amounts[2].mass, closeTo(18.016, 0.001));
    expect(r.amounts[0].excessMoles, closeTo(4 / 2.016 - 16 / 31.998 * 2, 1e-9));
  });

  test('stoichiometry from a product amount', () {
    final eq = balanceEquation('N2 + H2 -> NH3');
    final r = stoichiometry(eq, {2: 2});
    expect(r.amounts[0].moles, closeTo(1, 1e-12));
    expect(r.amounts[1].moles, closeTo(3, 1e-12));
  });
}
