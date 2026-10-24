import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/element.dart';
import 'package:kimya_hesap/core/chem/formula.dart';

void main() {
  double mm(String f) => ChemicalFormula.parse(f).molarMass;

  test('periodic table has 118 consistent elements', () {
    expect(PeriodicTable.elements.length, 118);
    for (var i = 0; i < 118; i++) {
      expect(PeriodicTable.elements[i].number, i + 1);
    }
    final positions = <String>{};
    for (final e in PeriodicTable.elements) {
      final p = e.tablePosition;
      expect(positions.add('${p.column},${p.row}'), isTrue,
          reason: 'duplicate cell for ${e.symbol}');
      // electron count from configuration equals Z
      final core = {'He': 2, 'Ne': 10, 'Ar': 18, 'Kr': 36, 'Xe': 54, 'Rn': 86};
      var n = 0;
      for (final part in e.electronConfiguration.split(' ')) {
        if (part.startsWith('[')) {
          n += core[part.substring(1, part.length - 1)]!;
        } else {
          n += int.parse(part.substring(2));
        }
      }
      expect(n, e.number, reason: e.symbol);
    }
    expect(PeriodicTable.bySymbol('Fe')!.group, 8);
    expect(PeriodicTable.bySymbol('La')!.isFBlock, isTrue);
    expect(PeriodicTable.bySymbol('Hf')!.group, 4);
    expect(PeriodicTable.bySymbol('Og')!.tablePosition, (column: 18, row: 7));
  });

  test('simple molar masses', () {
    expect(mm('H2O'), closeTo(18.015, 0.001));
    expect(mm('CO2'), closeTo(44.009, 0.001));
    expect(mm('NaCl'), closeTo(58.44, 0.01));
    expect(mm('C6H12O6'), closeTo(180.156, 0.001));
    expect(mm('H2SO4'), closeTo(98.072, 0.001));
  });

  test('parentheses, brackets and hydrates', () {
    expect(mm('Ca(OH)2'), closeTo(74.092, 0.001));
    expect(mm('Al2(SO4)3'), closeTo(342.14, 0.01));
    expect(mm('K4[Fe(CN)6]'), closeTo(368.35, 0.01));
    expect(mm('CuSO4·5H2O'), closeTo(249.68, 0.01));
    expect(mm('CuSO4.5H2O'), closeTo(249.68, 0.01));
    expect(mm('CuSO4*5H2O'), closeTo(249.68, 0.01));
    expect(mm('CaSO4·0.5H2O'), closeTo(145.14, 0.01));
    expect(mm('(NH4)2SO4'), closeTo(132.14, 0.01));
    expect(mm('Fe0.95O'), closeTo(0.95 * 55.845 + 15.999, 1e-9));
    expect(mm('H₂O'), closeTo(18.015, 0.001));
    expect(mm('D2O'), closeTo(20.03, 0.01));
  });

  test('two-letter symbols are case sensitive', () {
    expect(ChemicalFormula.parse('Co').atoms, {'Co': 1});
    expect(ChemicalFormula.parse('CO').atoms, {'C': 1, 'O': 1});
  });

  test('charges', () {
    expect(ChemicalFormula.parse('SO4^2-').charge, -2);
    expect(ChemicalFormula.parse('Fe^3+').charge, 3);
    expect(ChemicalFormula.parse('Fe^+3').charge, 3);
    expect(ChemicalFormula.parse('NH4+').charge, 1);
    expect(ChemicalFormula.parse('Cl-').charge, -1);
    expect(ChemicalFormula.parse('SO₄²⁻').charge, -2);
    expect(ChemicalFormula.parse('e-').isElectron, isTrue);
  });

  test('composition', () {
    final c = ChemicalFormula.parse('H2O').composition;
    expect(c[0].symbol, 'H');
    expect(c[0].massFraction, closeTo(0.1119, 0.0001));
    expect(c[1].massFraction, closeTo(0.8881, 0.0001));
  });

  test('errors', () {
    expect(() => ChemicalFormula.parse(''), throwsA(isA<FormulaException>()));
    expect(
        () => ChemicalFormula.parse('Xx2'),
        throwsA(isA<FormulaException>()
            .having((e) => e.kind, 'kind', FormulaErrorKind.unknownElement)
            .having((e) => e.detail, 'detail', 'Xx')));
    expect(
        () => ChemicalFormula.parse('Ca(OH2'),
        throwsA(isA<FormulaException>()
            .having((e) => e.kind, 'kind', FormulaErrorKind.unbalancedBracket)));
    expect(() => ChemicalFormula.parse('h2o'), throwsA(isA<FormulaException>()));
    expect(() => ChemicalFormula.parse('H2O)'), throwsA(isA<FormulaException>()));
    expect(() => ChemicalFormula.parse('()'), throwsA(isA<FormulaException>()));
  });

  test('pretty formatting', () {
    expect(prettyFormula('H2SO4'), 'H₂SO₄');
    expect(prettyFormula('CuSO4*5H2O'), 'CuSO₄·5H₂O');
    expect(prettyFormula('CuSO4.5H2O'), 'CuSO₄·5H₂O');
    expect(prettyFormula('Fe^3+'), 'Fe³⁺');
    expect(prettyFormula('SO4^2-'), 'SO₄²⁻');
    expect(prettyFormula('NH4+'), 'NH₄⁺');
    expect(prettyFormula('Ca(OH)2'), 'Ca(OH)₂');
    expect(prettyFormula('CaSO4·0.5H2O'), 'CaSO₄·0.5H₂O');
    expect(prettyEquation('Fe + O2 -> Fe2O3'), 'Fe + O₂ → Fe₂O₃');
    expect(prettyEquation('MnO4^- + H^+ -> Mn^2+ + H2O'), 'MnO₄⁻ + H⁺ → Mn²⁺ + H₂O');
    expect(prettyEquation('N2 + 3H2 <=> 2NH3'), 'N₂ + 3H₂ ⇌ 2NH₃');
  });
}
