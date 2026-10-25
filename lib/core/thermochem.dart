import 'dart:math' as math;

import 'bi.dart';
import 'chem/equation.dart';
import 'chem/formula.dart';
import 'constants.dart';

part 'thermo_data.dart';

enum ThermoSource { codata, crc, nbs, janaf }

/// Standard molar enthalpy of formation and entropy at 298.15 K, 1 bar.
class ThermoEntry {
  const ThermoEntry(this.formula, this.state, this.dfH, this.s, this.uH, this.uS, this.source,
      {this.note});

  /// Formula with charge in caret notation (`CO3^2-`).
  final String formula;

  /// `s`, `l`, `g` or `aq`.
  final String state;

  /// ΔfH° in kJ/mol.
  final double dfH;

  /// S° in J/(K·mol).
  final double s;

  /// Stated uncertainties (CODATA only; 0 when not given).
  final double uH;
  final double uS;

  final ThermoSource source;

  /// Crystal form or isomer, e.g. calcite, graphite.
  final Bi? note;

  String get pretty => '${prettyFormula(formula)}($state)';

  String label(String lang) => note == null ? pretty : '$pretty, ${note!.of(lang)}';
}

/// Parsed data entries, built lazily.
final Map<ThermoEntry, ChemicalFormula> _parsed = {
  for (final e in thermoData) e: ChemicalFormula.parse(e.formula),
};

bool _sameAtoms(ChemicalFormula a, ChemicalFormula b) {
  if (a.charge != b.charge || a.atoms.length != b.atoms.length) return false;
  for (final e in a.atoms.entries) {
    if ((b.atoms[e.key] ?? -1) != e.value) return false;
  }
  return true;
}

String _bare(String formula) => formula.replaceAll(RegExp(r'\^.*$'), '').replaceAll(' ', '');

/// Table entries for [species]: same atoms and charge (and state when
/// given). The most likely choice comes first: the formula as typed
/// (C2H5OH before (CH3)2O), then the usual state at 25 °C for a neutral
/// substance (s, l, g, aq), CODATA before other sources.
List<ThermoEntry> thermoCandidates(Species species) {
  final list = [
    for (final e in thermoData)
      if ((species.stateSymbol.isEmpty || species.stateSymbol == e.state) &&
          _sameAtoms(_parsed[e]!, species.formula))
        e,
  ];
  const order = ['s', 'l', 'g', 'aq'];
  final typed = _bare(species.text);
  int score(ThermoEntry e) =>
      (_bare(e.formula) == typed ? 0 : 1000) + order.indexOf(e.state) * 10 + e.source.index;
  final indexed = {for (var i = 0; i < list.length; i++) list[i]: i};
  list.sort((a, b) {
    final c = score(a).compareTo(score(b));
    return c != 0 ? c : indexed[a]!.compareTo(indexed[b]!);
  });
  return list;
}

enum ThermoErrorKind { unbalanced, missing }

class ThermoException implements Exception {
  const ThermoException(this.kind, [this.detail = '']);

  final ThermoErrorKind kind;
  final String detail;
}

/// Reaction with the coefficients K and ΔG refer to.
class ThermoReaction {
  const ThermoReaction(this.species, this.nu, {required this.autoBalanced});

  final List<Species> species;

  /// Signed coefficients: negative for reactants.
  final List<double> nu;
  final bool autoBalanced;
}

/// Reads [input]; written coefficients are kept, an equation without any is
/// balanced automatically.
ThermoReaction parseThermoReaction(String input) {
  final w = parseWrittenEquation(input);
  if (w.isBalanced) {
    return ThermoReaction(
      w.species,
      [for (var i = 0; i < w.species.length; i++) i < w.reactants.length ? -w.coefficients[i] : w.coefficients[i]],
      autoBalanced: false,
    );
  }
  if (w.hasCoefficients) throw const ThermoException(ThermoErrorKind.unbalanced);
  final b = balanceEquation(input);
  return ThermoReaction(
    b.species,
    [for (var i = 0; i < b.species.length; i++) (b.isReactant(i) ? -1.0 : 1.0) * b.coefficients[i]],
    autoBalanced: true,
  );
}

class ThermoResult {
  const ThermoResult(this.entries, this.nu);

  final List<ThermoEntry> entries;
  final List<double> nu;

  /// ΔH° in kJ/mol of reaction.
  double get deltaH {
    var s = 0.0;
    for (var i = 0; i < nu.length; i++) {
      s += nu[i] * entries[i].dfH;
    }
    return s;
  }

  /// ΔS° in J/(K·mol).
  double get deltaS {
    var s = 0.0;
    for (var i = 0; i < nu.length; i++) {
      s += nu[i] * entries[i].s;
    }
    return s;
  }

  /// Standard uncertainties of ΔH° and ΔS° from CODATA, or null when a
  /// species has no stated uncertainty.
  (double, double)? get uncertainty {
    var h = 0.0, s = 0.0;
    for (var i = 0; i < nu.length; i++) {
      final e = entries[i];
      if (e.source != ThermoSource.codata) return null;
      h += math.pow(nu[i] * e.uH, 2);
      s += math.pow(nu[i] * e.uS, 2);
    }
    return (math.sqrt(h), math.sqrt(s));
  }

  /// ΔG° (kJ/mol) at [t] kelvin, taking ΔH° and ΔS° as constant.
  double deltaG([double t = 298.15]) => deltaH - t * deltaS / 1000;

  /// log₁₀ K at [t] kelvin.
  double log10K([double t = 298.15]) => -deltaG(t) * 1000 / (gasConstant * t * math.ln10);

  /// Temperature (K) at which ΔG° changes sign, if any.
  double? get crossover {
    if (deltaS == 0) return null;
    final t = deltaH * 1000 / deltaS;
    return t > 0 ? t : null;
  }
}
