import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/formula.dart';

/// (name, formula as a chemist writes it, PubChem Hill formula, PubChem
/// molecular weight, decimals PubChem reports, PubChem multiplier).
/// Source: PubChem PUG REST, retrieved 2026-10-25.
const _pubchem = [
  ('water', 'H2O', 'H2O', 18.015, 3, 1),
  ('sodium chloride', 'NaCl', 'ClNa', 58.44, 2, 1),
  ('sulfuric acid', 'H2SO4', 'H2O4S', 98.08, 2, 1),
  ('glucose', 'C6H12O6', 'C6H12O6', 180.16, 2, 1),
  ('copper(II) sulfate pentahydrate', 'CuSO4·5H2O', 'CuH10O9S', 249.69, 2, 1),
  ('calcium hydroxide', 'Ca(OH)2', 'CaH2O2', 74.09, 2, 1),
  ('potassium permanganate', 'KMnO4', 'KMnO4', 158.034, 3, 1),
  ('potassium ferrocyanide', 'K4[Fe(CN)6]', 'C6FeK4N6', 368.34, 2, 1),
  ('ethanol', 'C2H5OH', 'C2H6O', 46.07, 2, 1),
  ('ammonium sulfate', '(NH4)2SO4', 'H8N2O4S', 132.14, 2, 1),
  ('aluminium sulfate', 'Al2(SO4)3', 'Al2O12S3', 342.2, 1, 1),
  ('calcium sulfate hemihydrate', 'CaSO4·0.5H2O', 'Ca2H2O9S2', 290.3, 1, 2),
  ('caffeine', 'C8H10N4O2', 'C8H10N4O2', 194.19, 2, 1),
  ('aspirin', 'C9H8O4', 'C9H8O4', 180.16, 2, 1),
  ('sodium bicarbonate', 'NaHCO3', 'CHNaO3', 84.007, 3, 1),
  ('potassium dichromate', 'K2Cr2O7', 'Cr2K2O7', 294.18, 2, 1),
  ('magnesium sulfate heptahydrate', 'MgSO4·7H2O', 'H14MgO11S', 246.48, 2, 1),
  ('barium hydroxide octahydrate', 'Ba(OH)2·8H2O', 'BaH18O10', 315.46, 2, 1),
  ('iron(III) chloride hexahydrate', 'FeCl3·6H2O', 'Cl3FeH12O6', 270.29, 2, 1),
  ('silver nitrate', 'AgNO3', 'AgNO3', 169.873, 3, 1),
  ('acetic acid', 'CH3COOH', 'C2H4O2', 60.05, 2, 1),
  ('benzene', 'C6H6', 'C6H6', 78.11, 2, 1),
  ('sucrose', 'C12H22O11', 'C12H22O11', 342.3, 1, 1),
  ('calcium phosphate', 'Ca3(PO4)2', 'Ca3O8P2', 310.18, 2, 1),
  ('ammonium dichromate', '(NH4)2Cr2O7', 'Cr2H8N2O7', 252.07, 2, 1),
  ('sodium thiosulfate pentahydrate', 'Na2S2O3·5H2O', 'H10Na2O8S2', 248.19, 2, 1),
  ('EDTA', 'C10H16N2O8', 'C10H16N2O8', 292.24, 2, 1),
  ('cholesterol', 'C27H46O', 'C27H46O', 386.7, 1, 1),
  ('potassium hydrogen phthalate', 'KHC8H4O4', 'C8H5KO4', 204.22, 2, 1),
  ('uranium hexafluoride', 'UF6', 'F6U', 352.0193, 4, 1),
  // PubChem lists 331.0 because it rounds Pb (an interval element since
  // 2020) to 207.0; the conventional value Pb = 207.2 gives 331.2.
  ('lead(II) nitrate', 'Pb(NO3)2', 'N2O6Pb', 331.2, 1, 1),
  ('mercury(II) chloride', 'HgCl2', 'Cl2Hg', 271.5, 1, 1),
  ('tris(hydroxymethyl)aminomethane', 'C4H11NO3', 'C4H11NO3', 121.14, 2, 1),
  ('hexaamminecobalt(III) chloride', '[Co(NH3)6]Cl3', 'Cl3CoH18N6', 267.47, 2, 1),
  ('cisplatin', 'Pt(NH3)2Cl2', 'Cl2H6N2Pt', 300.05, 2, 1),
  ('sodium dodecyl sulfate', 'C12H25NaO4S', 'C12H25NaO4S', 288.38, 2, 1),
  ('argon', 'Ar', 'Ar', 39.9, 1, 1),
  ('xenon tetrafluoride', 'XeF4', 'F4Xe', 207.29, 2, 1),
  ('gadolinium(III) oxide', 'Gd2O3', 'Gd2O3', 362.5, 1, 1),
];

void main() {
  test('molar masses agree with PubChem', () {
    for (final (name, formula, hill, mw, decimals, mult) in _pubchem) {
      final ours = ChemicalFormula.parse(formula);
      final theirs = ChemicalFormula.parse(hill);
      // Same atoms, whichever way the formula is written.
      for (final s in {...ours.atoms.keys, ...theirs.atoms.keys}) {
        expect((ours.atoms[s] ?? 0) * mult, closeTo(theirs.atoms[s] ?? 0, 1e-9), reason: '$name $s');
      }
      // PubChem rounds; allow half a unit in its last digit plus 0.02 % for
      // interval elements (e.g. PubChem uses S = 32.07, IUPAC's conventional
      // value is 32.06; both lie in the CIAAW interval [32.059, 32.076]).
      final tol = 0.5 * pow(10, -decimals) + 2e-4 * mw;
      expect(ours.molarMass * mult, closeTo(mw, tol), reason: name);
    }
  });
}
