import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/dbe.dart';
import 'package:kimya_hesap/core/chem/formula.dart';

double? dbe(String f) => doubleBondEquivalents(ChemicalFormula.parse(f));

void main() {
  test('textbook degrees of unsaturation', () {
    expect(dbe('CH4'), 0);
    expect(dbe('C2H4'), 1);
    expect(dbe('C2H2'), 2);
    expect(dbe('C6H6'), 4); // benzene: 1 ring + 3 π
    expect(dbe('C6H12'), 1); // cyclohexane
    expect(dbe('C5H5N'), 4); // pyridine
    expect(dbe('C8H10N4O2'), 6); // caffeine
    expect(dbe('C6H12O6'), 1); // glucose (open chain C=O or ring)
    expect(dbe('C9H8O4'), 6); // aspirin
    expect(dbe('CHCl3'), 0);
    expect(dbe('C60'), 61); // 31 independent rings (E − V + 1) + 30 C=C
    expect(dbe('C6H5NO2'), 5); // nitrobenzene: ring + 3 C=C + N=O
    expect(dbe('C2H3N'), 2); // acetonitrile C≡N
  });

  test('ions and unsupported elements', () {
    expect(dbe('C8H11N4O2^+'), 5.5); // protonated caffeine (even-electron ion)
    expect(dbe('FeCl3'), isNull);
    expect(dbe('NaCl'), isNull);
  });
}
