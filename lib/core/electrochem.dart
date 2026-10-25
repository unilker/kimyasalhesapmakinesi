import 'dart:math' as math;

import 'chem/formula.dart';
import 'constants.dart';

/// One species of a half-reaction, e.g. `4H2O(l)` → 4 × H2O, state l.
class RedoxSpecies {
  const RedoxSpecies(this.formula, this.state);

  /// Formula with charge in caret notation (`MnO4^-`).
  final String formula;

  /// `s`, `l`, `g`, `aq` or empty (aqueous ion).
  final String state;

  /// Key used to combine equal species of two half-reactions.
  String get key => state.isEmpty ? formula : '$formula($state)';

  String get pretty => prettyFormula(formula) + (state.isEmpty ? '' : '($state)');
}

typedef RedoxTerm = (double, RedoxSpecies);

final _term = RegExp(r'^(\d+)?\s*(.+?)(?:\((s|l|g|aq)\))?$');

List<RedoxTerm> _side(String s) => [
      for (final raw in s.split(' + '))
        () {
          final m = _term.firstMatch(raw.trim())!;
          return (
            double.parse(m.group(1) ?? '1'),
            RedoxSpecies(m.group(2)!, m.group(3) ?? ''),
          );
        }(),
    ];

/// A reduction half-reaction `oxidized + n e⁻ ⇌ reduced` with its standard
/// potential E° (V vs SHE, 25 °C).
class HalfReaction {
  HalfReaction(String oxidized, this.electrons, String reduced, this.e0)
      : oxidized = _side(oxidized),
        reduced = _side(reduced);

  final List<RedoxTerm> oxidized;
  final int electrons;
  final List<RedoxTerm> reduced;
  final double e0;

  static String _text(List<RedoxTerm> side) => [
        for (final (c, s) in side) '${c == 1 ? '' : _num(c)}${s.pretty}',
      ].join(' + ');

  String get pretty =>
      '${_text(oxidized)} + ${electrons == 1 ? '' : electrons}e⁻ ⇌ ${_text(reduced)}';

  /// Short couple name, e.g. `Cu²⁺/Cu`.
  String get couple => '${oxidized.first.$2.pretty}/${reduced.first.$2.pretty}';
}

String _num(double c) => c == c.roundToDouble() ? '${c.toInt()}' : '$c';

/// Standard reduction potentials at 25 °C and 1 atm from P. Vanýsek,
/// "Electrochemical Series", CRC Handbook of Chemistry and Physics.
final List<HalfReaction> standardPotentials = [
  HalfReaction('Li^+', 1, 'Li(s)', -3.0401),
  HalfReaction('Cs^+', 1, 'Cs(s)', -3.026),
  HalfReaction('Rb^+', 1, 'Rb(s)', -2.98),
  HalfReaction('K^+', 1, 'K(s)', -2.931),
  HalfReaction('Ba^2+', 2, 'Ba(s)', -2.912),
  HalfReaction('Sr^2+', 2, 'Sr(s)', -2.899),
  HalfReaction('Ca^2+', 2, 'Ca(s)', -2.868),
  HalfReaction('Na^+', 1, 'Na(s)', -2.71),
  HalfReaction('Mg^2+', 2, 'Mg(s)', -2.372),
  HalfReaction('Be^2+', 2, 'Be(s)', -1.847),
  HalfReaction('Al^3+', 3, 'Al(s)', -1.662),
  HalfReaction('Ti^2+', 2, 'Ti(s)', -1.630),
  HalfReaction('Zn(OH)2(s)', 2, 'Zn(s) + 2OH^-', -1.249),
  HalfReaction('Mn^2+', 2, 'Mn(s)', -1.185),
  HalfReaction('2H2O(l)', 2, 'H2(g) + 2OH^-', -0.8277),
  HalfReaction('Zn^2+', 2, 'Zn(s)', -0.7618),
  HalfReaction('Cr^3+', 3, 'Cr(s)', -0.744),
  HalfReaction('Fe^2+', 2, 'Fe(s)', -0.447),
  HalfReaction('Cr^3+', 1, 'Cr^2+', -0.407),
  HalfReaction('Cd^2+', 2, 'Cd(s)', -0.4030),
  HalfReaction('PbSO4(s)', 2, 'Pb(s) + SO4^2-', -0.3588),
  HalfReaction('Co^2+', 2, 'Co(s)', -0.28),
  HalfReaction('Ni^2+', 2, 'Ni(s)', -0.257),
  HalfReaction('V^3+', 1, 'V^2+', -0.255),
  HalfReaction('AgI(s)', 1, 'Ag(s) + I^-', -0.15224),
  HalfReaction('Sn^2+', 2, 'Sn(s)', -0.1375),
  HalfReaction('Pb^2+', 2, 'Pb(s)', -0.1262),
  HalfReaction('Fe^3+', 3, 'Fe(s)', -0.037),
  HalfReaction('2H^+', 2, 'H2(g)', 0),
  HalfReaction('AgBr(s)', 1, 'Ag(s) + Br^-', 0.07133),
  HalfReaction('HgO(s) + H2O(l)', 2, 'Hg(l) + 2OH^-', 0.0977),
  HalfReaction('Sn^4+', 2, 'Sn^2+', 0.151),
  HalfReaction('Cu^2+', 1, 'Cu^+', 0.153),
  HalfReaction('AgCl(s)', 1, 'Ag(s) + Cl^-', 0.22233),
  HalfReaction('Hg2Cl2(s)', 2, '2Hg(l) + 2Cl^-', 0.26808),
  HalfReaction('Cu^2+', 2, 'Cu(s)', 0.3419),
  HalfReaction('Ag2O(s) + H2O(l)', 2, '2Ag(s) + 2OH^-', 0.342),
  HalfReaction('[Fe(CN)6]^3-', 1, '[Fe(CN)6]^4-', 0.358),
  HalfReaction('O2(g) + 2H2O(l)', 4, '4OH^-', 0.401),
  HalfReaction('Cu^+', 1, 'Cu(s)', 0.521),
  HalfReaction('I2(s)', 2, '2I^-', 0.5355),
  HalfReaction('MnO4^-', 1, 'MnO4^2-', 0.558),
  HalfReaction('Hg2SO4(s)', 2, '2Hg(l) + SO4^2-', 0.6125),
  HalfReaction('O2(g) + 2H^+', 2, 'H2O2', 0.695),
  HalfReaction('Fe^3+', 1, 'Fe^2+', 0.771),
  HalfReaction('Hg2^2+', 2, '2Hg(l)', 0.7973),
  HalfReaction('Ag^+', 1, 'Ag(s)', 0.7996),
  HalfReaction('Hg^2+', 2, 'Hg(l)', 0.851),
  HalfReaction('Pd^2+', 2, 'Pd(s)', 0.951),
  HalfReaction('NO3^- + 4H^+', 3, 'NO(g) + 2H2O(l)', 0.957),
  HalfReaction('Br2(l)', 2, '2Br^-', 1.066),
  HalfReaction('IO3^- + 6H^+', 6, 'I^- + 3H2O(l)', 1.085),
  HalfReaction('Br2(aq)', 2, '2Br^-', 1.0873),
  HalfReaction('Pt^2+', 2, 'Pt(s)', 1.18),
  HalfReaction('2IO3^- + 12H^+', 10, 'I2(s) + 6H2O(l)', 1.195),
  HalfReaction('MnO2(s) + 4H^+', 2, 'Mn^2+ + 2H2O(l)', 1.224),
  HalfReaction('O2(g) + 4H^+', 4, '2H2O(l)', 1.229),
  HalfReaction('Cl2(g)', 2, '2Cl^-', 1.35827),
  HalfReaction('Cr2O7^2- + 14H^+', 6, '2Cr^3+ + 7H2O(l)', 1.36),
  HalfReaction('ClO4^- + 8H^+', 8, 'Cl^- + 4H2O(l)', 1.389),
  HalfReaction('BrO3^- + 6H^+', 6, 'Br^- + 3H2O(l)', 1.423),
  HalfReaction('PbO2(s) + 4H^+', 2, 'Pb^2+ + 2H2O(l)', 1.455),
  HalfReaction('Au^3+', 3, 'Au(s)', 1.498),
  HalfReaction('MnO4^- + 8H^+', 5, 'Mn^2+ + 4H2O(l)', 1.507),
  HalfReaction('MnO4^- + 4H^+', 3, 'MnO2(s) + 2H2O(l)', 1.679),
  HalfReaction('PbO2(s) + SO4^2- + 4H^+', 2, 'PbSO4(s) + 2H2O(l)', 1.6913),
  HalfReaction('Au^+', 1, 'Au(s)', 1.692),
  HalfReaction('Ce^4+', 1, 'Ce^3+', 1.72),
  HalfReaction('H2O2 + 2H^+', 2, '2H2O(l)', 1.776),
  HalfReaction('Co^3+', 1, 'Co^2+', 1.92),
  HalfReaction('Ag^2+', 1, 'Ag^+', 1.980),
  HalfReaction('S2O8^2-', 2, '2SO4^2-', 2.010),
  HalfReaction('O3(g) + 2H^+', 2, 'O2(g) + H2O(l)', 2.076),
  HalfReaction('F2(g)', 2, '2F^-', 2.866),
];

class CellResult {
  const CellResult({
    required this.e0,
    required this.electrons,
    required this.reactants,
    required this.products,
  });

  /// E°cell = E°cathode − E°anode (V).
  final double e0;

  /// Electrons transferred in the overall reaction (lcm of both).
  final int electrons;

  /// Overall reaction with common species cancelled.
  final List<RedoxTerm> reactants;
  final List<RedoxTerm> products;

  /// ΔG° = −nFE° in J/mol of reaction.
  double get deltaG => -electrons * faraday * e0;

  /// log₁₀ K = nFE° / (RT ln 10) at 298.15 K.
  double get log10K => electrons * faraday * e0 / (gasConstant * 298.15 * math.ln10);

  bool get spontaneous => e0 > 0;

  String get equation {
    String side(List<RedoxTerm> l) =>
        [for (final (c, s) in l) '${c == 1 ? '' : _num(c)}${s.pretty}'].join(' + ');
    return '${side(reactants)} → ${side(products)}';
  }

  /// Cell potential at 25 °C for reaction quotient [q] (Nernst).
  double potentialAt(double q) =>
      e0 - gasConstant * 298.15 / (electrons * faraday) * math.log(q);
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

/// Galvanic cell from the reduction at the [cathode] and the oxidation at
/// the [anode] (the anode half-reaction is reversed).
CellResult galvanicCell(HalfReaction cathode, HalfReaction anode) {
  final n = cathode.electrons * anode.electrons ~/ _gcd(cathode.electrons, anode.electrons);
  final fc = n / cathode.electrons, fa = n / anode.electrons;
  // net coefficient: + for products, − for reactants
  final net = <String, double>{};
  final species = <String, RedoxSpecies>{};
  void add(List<RedoxTerm> side, double f) {
    for (final (c, s) in side) {
      net[s.key] = (net[s.key] ?? 0) + f * c;
      species[s.key] = s;
    }
  }

  add(cathode.oxidized, -fc);
  add(cathode.reduced, fc);
  add(anode.reduced, -fa);
  add(anode.oxidized, fa);
  final reactants = <RedoxTerm>[], products = <RedoxTerm>[];
  net.forEach((k, v) {
    if (v.abs() < 1e-9) return;
    (v < 0 ? reactants : products).add((v.abs(), species[k]!));
  });
  return CellResult(
    e0: cathode.e0 - anode.e0,
    electrons: n,
    reactants: reactants,
    products: products,
  );
}
