import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/formula.dart';
import 'package:kimya_hesap/core/constants.dart';
import 'package:kimya_hesap/core/electrochem.dart';

HalfReaction find(String couple) => standardPotentials.firstWhere((h) => h.couple == couple);

/// Net atoms and charge: products minus reactants.
(Map<String, double>, double) balance(List<RedoxTerm> left, int electrons, List<RedoxTerm> right) {
  final atoms = <String, double>{};
  var charge = -electrons.toDouble();
  void add(List<RedoxTerm> side, double sign) {
    for (final (c, s) in side) {
      final f = ChemicalFormula.parse(s.formula);
      f.atoms.forEach((el, n) => atoms[el] = (atoms[el] ?? 0) + sign * c * n);
      charge += sign * c * f.charge;
    }
  }

  add(left, -1);
  add(right, 1);
  charge = -charge;
  return (atoms, charge);
}

void main() {
  test('every half-reaction conserves atoms and charge', () {
    for (final h in standardPotentials) {
      final (atoms, charge) = balance(h.oxidized, h.electrons, h.reduced);
      for (final e in atoms.entries) {
        expect(e.value, closeTo(0, 1e-12), reason: '${h.pretty}: ${e.key}');
      }
      // left charge − electrons = right charge
      var left = -h.electrons.toDouble(), right = 0.0;
      for (final (c, s) in h.oxidized) {
        left += c * ChemicalFormula.parse(s.formula).charge;
      }
      for (final (c, s) in h.reduced) {
        right += c * ChemicalFormula.parse(s.formula).charge;
      }
      expect(left, right, reason: h.pretty);
      expect(charge.isFinite, isTrue);
    }
  });

  test('the table is sorted by potential and has no duplicate reactions', () {
    final seen = <String>{};
    for (var i = 0; i < standardPotentials.length; i++) {
      expect(seen.add(standardPotentials[i].pretty), isTrue);
      if (i > 0) {
        expect(standardPotentials[i].e0, greaterThanOrEqualTo(standardPotentials[i - 1].e0),
            reason: standardPotentials[i].pretty);
      }
    }
  });

  test('reference values (Vanýsek, CRC Handbook)', () {
    expect(find('Cu²⁺/Cu(s)').e0, 0.3419);
    expect(find('Zn²⁺/Zn(s)').e0, -0.7618);
    expect(find('AgCl(s)/Ag(s)').e0, 0.22233);
    expect(find('H⁺/H₂(g)').e0, 0);
    expect(find('Cl₂(g)/Cl⁻').e0, 1.35827);
    expect(find('F₂(g)/F⁻').e0, 2.866);
    expect(find('Li⁺/Li(s)').e0, -3.0401);
  });

  test('Daniell cell Zn | Zn²⁺ ‖ Cu²⁺ | Cu: 1.1037 V, ΔG° = −213.0 kJ', () {
    final c = galvanicCell(find('Cu²⁺/Cu(s)'), find('Zn²⁺/Zn(s)'));
    expect(c.e0, closeTo(1.1037, 1e-12));
    expect(c.electrons, 2);
    expect(c.equation, 'Cu²⁺ + Zn(s) → Cu(s) + Zn²⁺');
    expect(c.deltaG / 1000, closeTo(-212.98, 0.01));
    // log K = nE°/0.05916 = 37.31
    expect(c.log10K, closeTo(2 * 1.1037 / (gasConstant * 298.15 * 2.302585092994046 / faraday), 1e-9));
    expect(c.log10K, closeTo(37.31, 0.01));
    expect(c.spontaneous, isTrue);
    // Nernst: [Zn²⁺]/[Cu²⁺] = 10 → E = 1.1037 − 0.02958 = 1.0741 V
    expect(c.potentialAt(10), closeTo(1.07412, 1e-5));
  });

  test('permanganate oxidises iron(II): n = 5, balanced overall reaction', () {
    final c = galvanicCell(find('MnO₄⁻/Mn²⁺'), find('Fe³⁺/Fe²⁺'));
    expect(c.e0, closeTo(0.736, 1e-12));
    expect(c.electrons, 5);
    expect(c.equation, 'MnO₄⁻ + 8H⁺ + 5Fe²⁺ → Mn²⁺ + 4H₂O(l) + 5Fe³⁺');
    final (atoms, charge) = balance(c.reactants, 0, c.products);
    expect(atoms.values.every((v) => v.abs() < 1e-12), isTrue);
    expect(charge, closeTo(0, 1e-12));
  });

  test('lead–acid battery: 2.0501 V, PbO₂ + Pb + 2SO₄²⁻ + 4H⁺ → 2PbSO₄ + 2H₂O', () {
    final c = galvanicCell(
      standardPotentials.firstWhere((h) => h.pretty.startsWith('PbO₂(s) + SO₄²⁻')),
      find('PbSO₄(s)/Pb(s)'),
    );
    expect(c.e0, closeTo(2.0501, 1e-12));
    expect(c.electrons, 2);
    expect(c.equation, 'PbO₂(s) + 2SO₄²⁻ + 4H⁺ + Pb(s) → 2PbSO₄(s) + 2H₂O(l)');
  });

  test('H₂/O₂ fuel cell matches ΔfG°(H₂O, l) = −237.13 kJ/mol', () {
    final c = galvanicCell(
      standardPotentials.firstWhere((h) => h.pretty == 'O₂(g) + 4H⁺ + 4e⁻ ⇌ 2H₂O(l)'),
      find('H⁺/H₂(g)'),
    );
    expect(c.e0, 1.229);
    expect(c.electrons, 4);
    expect(c.equation, 'O₂(g) + 2H₂(g) → 2H₂O(l)');
    // per mole of water
    expect(c.deltaG / 2 / 1000, closeTo(-237.13, 0.1));
  });

  test('every pair of half-reactions gives a balanced overall reaction', () {
    for (final a in standardPotentials) {
      for (final b in standardPotentials) {
        final c = galvanicCell(a, b);
        final (atoms, charge) = balance(c.reactants, 0, c.products);
        expect(atoms.values.every((v) => v.abs() < 1e-9), isTrue, reason: c.equation);
        expect(charge.abs(), lessThan(1e-9), reason: c.equation);
        expect(c.e0, closeTo(a.e0 - b.e0, 1e-15));
        expect(c.electrons % a.electrons, 0);
        expect(c.electrons % b.electrons, 0);
      }
    }
  });

  test('couple names are unique', () {
    final names = [for (final h in standardPotentials) h.couple];
    expect(names.toSet().length, names.length);
  });
}
