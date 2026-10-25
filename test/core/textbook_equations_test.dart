import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/equation.dart';

/// Reactions with their well-known smallest whole-number coefficients.
const _reactions = <(String, List<int>)>[
  ('CH4 + O2 -> CO2 + H2O', [1, 2, 1, 2]),
  ('C2H6 + O2 -> CO2 + H2O', [2, 7, 4, 6]),
  ('C4H10 + O2 -> CO2 + H2O', [2, 13, 8, 10]),
  ('C8H18 + O2 -> CO2 + H2O', [2, 25, 16, 18]),
  ('Fe2O3 + CO -> Fe + CO2', [1, 3, 2, 3]),
  ('Al + O2 -> Al2O3', [4, 3, 2]),
  ('NH3 + O2 -> NO + H2O', [4, 5, 4, 6]),
  ('Cu + HNO3 -> Cu(NO3)2 + NO + H2O', [3, 8, 3, 2, 4]),
  ('Cu + HNO3 -> Cu(NO3)2 + NO2 + H2O', [1, 4, 1, 2, 2]),
  ('KMnO4 + HCl -> KCl + MnCl2 + H2O + Cl2', [2, 16, 2, 2, 8, 5]),
  ('K2Cr2O7 + HCl -> KCl + CrCl3 + H2O + Cl2', [1, 14, 2, 2, 7, 3]),
  ('Ca3(PO4)2 + H2SO4 -> CaSO4 + H3PO4', [1, 3, 3, 2]),
  ('Na2CO3 + HCl -> NaCl + H2O + CO2', [1, 2, 2, 1, 1]),
  ('Al(OH)3 + H2SO4 -> Al2(SO4)3 + H2O', [2, 3, 1, 6]),
  ('P4 + O2 -> P4O10', [1, 5, 1]),
  ('FeS2 + O2 -> Fe2O3 + SO2', [4, 11, 2, 8]),
  ('C6H12O6 -> C2H5OH + CO2', [1, 2, 2]),
  ('NaOH + H2SO4 -> Na2SO4 + H2O', [2, 1, 1, 2]),
  ('Zn + HCl -> ZnCl2 + H2', [1, 2, 1, 1]),
  ('KClO3 -> KCl + O2', [2, 2, 3]),
  ('H2O2 -> H2O + O2', [2, 2, 1]),
  ('N2O5 -> NO2 + O2', [2, 4, 1]),
  ('Fe + Cl2 -> FeCl3', [2, 3, 2]),
  ('Pb(NO3)2 -> PbO + NO2 + O2', [2, 2, 4, 1]),
  ('Cr2O7^2- + Fe^2+ + H^+ -> Cr^3+ + Fe^3+ + H2O', [1, 6, 14, 2, 6, 7]),
  ('MnO4^- + C2O4^2- + H^+ -> Mn^2+ + CO2 + H2O', [2, 5, 16, 2, 10, 8]),
  ('Cu + Ag^+ -> Cu^2+ + Ag', [1, 2, 1, 2]),
  ('MnO4^- + I^- + H2O -> MnO2 + I2 + OH^-', [2, 6, 4, 2, 3, 8]),
  ('Zn + NO3^- + H^+ -> Zn^2+ + NH4^+ + H2O', [4, 1, 10, 4, 1, 3]),
  ('Ag + NO3^- + H^+ -> Ag^+ + NO + H2O', [3, 1, 4, 3, 1, 2]),
  ('As2S3 + HNO3 + H2O -> H3AsO4 + H2SO4 + NO', [3, 28, 4, 6, 9, 28]),
  ('(NH4)2Cr2O7 -> Cr2O3 + N2 + H2O', [1, 1, 1, 4]),
  ('CaCO3 + HCl -> CaCl2 + H2O + CO2', [1, 2, 1, 1, 1]),
  ('Ca(OH)2 + H3PO4 -> Ca3(PO4)2 + H2O', [3, 2, 1, 6]),
  ('C3H5(NO3)3 -> CO2 + H2O + N2 + O2', [4, 12, 10, 6, 1]),
  ('Na + H2O -> NaOH + H2', [2, 2, 2, 1]),
  ('Fe^3+ + Sn^2+ -> Fe^2+ + Sn^4+', [2, 1, 2, 1]),
  ('H2SO4 + HI -> H2S + I2 + H2O', [1, 8, 1, 4, 4]),
];

void main() {
  test('balances textbook reactions', () {
    for (final (text, expected) in _reactions) {
      final eq = balanceEquation(text);
      expect(eq.coefficients, expected, reason: text);
      // Independently re-check conservation of every element and of charge.
      final atoms = <String, double>{};
      var charge = 0.0;
      for (var i = 0; i < eq.species.length; i++) {
        final sign = eq.isReactant(i) ? 1 : -1;
        final f = eq.species[i].formula;
        f.atoms.forEach((s, n) => atoms[s] = (atoms[s] ?? 0) + sign * n * eq.coefficients[i]);
        charge += sign * f.charge * eq.coefficients[i];
      }
      atoms.forEach((s, n) => expect(n, 0, reason: '$text: $s'));
      expect(charge, 0, reason: '$text: charge');
    }
  });
}
