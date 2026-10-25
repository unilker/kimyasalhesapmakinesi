import '../math/rational.dart';
import 'formula.dart';

enum EquationErrorKind {
  noArrow,
  emptySide,
  invalidSpecies,
  cannotBalance,
  multipleSolutions,
}

class EquationException implements Exception {
  const EquationException(this.kind, {this.detail = '', this.formulaError});

  final EquationErrorKind kind;
  final String detail;
  final FormulaException? formulaError;

  @override
  String toString() => 'EquationException($kind, $detail)';
}

class Species {
  const Species(this.text, this.formula, this.stateSymbol);

  /// Formula text as entered, without coefficient or state symbol.
  final String text;
  final ChemicalFormula formula;

  /// `aq`, `s`, `l`, `g` or empty.
  final String stateSymbol;

  String get pretty =>
      formula.pretty + (stateSymbol.isEmpty ? '' : '($stateSymbol)');
}

class BalancedEquation {
  const BalancedEquation(this.reactants, this.products, this.coefficients);

  final List<Species> reactants;
  final List<Species> products;

  /// Coefficients for reactants followed by products.
  final List<int> coefficients;

  List<Species> get species => [...reactants, ...products];

  int coefficientOf(int speciesIndex) => coefficients[speciesIndex];

  bool isReactant(int speciesIndex) => speciesIndex < reactants.length;

  String get pretty {
    String side(List<Species> list, int offset) => [
          for (var k = 0; k < list.length; k++)
            '${coefficients[offset + k] == 1 ? '' : coefficients[offset + k]}${list[k].pretty}',
        ].join(' + ');
    return '${side(reactants, 0)} → ${side(products, reactants.length)}';
  }

  String get plain {
    String side(List<Species> list, int offset) => [
          for (var k = 0; k < list.length; k++)
            '${coefficients[offset + k] == 1 ? '' : coefficients[offset + k]}${list[k].text}',
        ].join(' + ');
    return '${side(reactants, 0)} -> ${side(products, reactants.length)}';
  }
}

final _arrow = RegExp(r'<=>|<->|⇌|⟶|→|->|=>|=');
final _stateSuffix = RegExp(r'\((aq|s|l|g)\)$');
final _leadingCoef = RegExp(r'^\d+(\.\d+)?(?=[A-Z(\[{e])');

/// Parses and balances an equation like `Fe + O2 -> Fe2O3` or the ionic
/// `MnO4^- + Fe^2+ + H^+ -> Mn^2+ + Fe^3+ + H2O`.
BalancedEquation balanceEquation(String input) {
  final normalized = input.replaceAll('−', '-').replaceAll('–', '-');
  final m = _arrow.firstMatch(normalized);
  if (m == null) throw const EquationException(EquationErrorKind.noArrow);
  final left = _parseSide(normalized.substring(0, m.start));
  final right = _parseSide(normalized.substring(m.end));
  if (left.isEmpty || right.isEmpty) {
    throw const EquationException(EquationErrorKind.emptySide);
  }
  final all = [...left, ...right];

  final symbols = <String>[];
  var hasCharge = false;
  for (final sp in all) {
    for (final s in sp.formula.atoms.keys) {
      if (!symbols.contains(s)) symbols.add(s);
    }
    if (sp.formula.charge != 0) hasCharge = true;
  }

  final rows = <List<Rational>>[];
  for (final s in symbols) {
    rows.add([
      for (var j = 0; j < all.length; j++)
        Rational.fromDouble(all[j].formula.atoms[s] ?? 0) *
            (j < left.length ? Rational.one : -Rational.one),
    ]);
  }
  if (hasCharge) {
    rows.add([
      for (var j = 0; j < all.length; j++)
        Rational.fromInt(all[j].formula.charge) *
            (j < left.length ? Rational.one : -Rational.one),
    ]);
  }

  final basis = nullSpace(rows, all.length);
  if (basis.isEmpty) {
    throw const EquationException(EquationErrorKind.cannotBalance);
  }
  if (basis.length > 1) {
    throw const EquationException(EquationErrorKind.multipleSolutions);
  }
  final v = basis.first;
  var den = BigInt.one;
  for (final r in v) {
    den = lcm(den, r.denominator);
  }
  var ints = [for (final r in v) r.numerator * (den ~/ r.denominator)];
  var g = BigInt.zero;
  for (final n in ints) {
    g = g.gcd(n);
  }
  ints = [for (final n in ints) n ~/ g];
  if (ints.every((n) => n <= BigInt.zero)) {
    ints = [for (final n in ints) -n];
  }
  if (ints.any((n) => n <= BigInt.zero)) {
    throw const EquationException(EquationErrorKind.cannotBalance);
  }
  return BalancedEquation(left, right, [for (final n in ints) n.toInt()]);
}

/// An equation with the coefficients exactly as written (1 when omitted).
class WrittenEquation {
  const WrittenEquation(this.reactants, this.products, this.coefficients, this.hasCoefficients);

  final List<Species> reactants;
  final List<Species> products;
  final List<double> coefficients;

  /// Whether any coefficient was written explicitly.
  final bool hasCoefficients;

  List<Species> get species => [...reactants, ...products];

  /// Atoms and charge are conserved with the written coefficients.
  bool get isBalanced {
    final all = species;
    final net = <String, double>{};
    var charge = 0.0;
    for (var j = 0; j < all.length; j++) {
      final sign = j < reactants.length ? 1.0 : -1.0;
      all[j].formula.atoms.forEach((s, n) {
        net[s] = (net[s] ?? 0) + sign * coefficients[j] * n;
      });
      charge += sign * coefficients[j] * all[j].formula.charge;
    }
    return charge.abs() < 1e-9 && net.values.every((v) => v.abs() < 1e-9);
  }
}

/// Parses an equation keeping its written coefficients (decimals allowed,
/// e.g. `0.5N2 + 1.5H2 = NH3`) without balancing it.
WrittenEquation parseWrittenEquation(String input) {
  final normalized = input.replaceAll('−', '-').replaceAll('–', '-');
  final m = _arrow.firstMatch(normalized);
  if (m == null) throw const EquationException(EquationErrorKind.noArrow);
  final left = _parseSideWithCoefficients(normalized.substring(0, m.start));
  final right = _parseSideWithCoefficients(normalized.substring(m.end));
  if (left.isEmpty || right.isEmpty) {
    throw const EquationException(EquationErrorKind.emptySide);
  }
  final all = [...left, ...right];
  return WrittenEquation(
    [for (final e in left) e.$1],
    [for (final e in right) e.$1],
    [for (final e in all) e.$2 ?? 1],
    all.any((e) => e.$2 != null),
  );
}

List<Species> _parseSide(String side) =>
    [for (final e in _parseSideWithCoefficients(side)) e.$1];

List<(Species, double?)> _parseSideWithCoefficients(String side) {
  final parts = _splitSpecies(side.trim());
  final result = <(Species, double?)>[];
  for (var raw in parts) {
    raw = raw.replaceAll(' ', '');
    if (raw.isEmpty) continue;
    var state = '';
    final sm = _stateSuffix.firstMatch(raw);
    if (sm != null) {
      state = sm.group(1)!;
      raw = raw.substring(0, sm.start);
    }
    final cm = _leadingCoef.firstMatch(raw);
    final coefficient = cm == null ? null : double.parse(cm.group(0)!);
    if (coefficient != null && coefficient <= 0) {
      throw EquationException(EquationErrorKind.invalidSpecies, detail: raw);
    }
    raw = raw.replaceFirst(_leadingCoef, '');
    try {
      result.add((Species(raw, ChemicalFormula.parse(raw), state), coefficient));
    } on FormulaException catch (e) {
      throw EquationException(
        EquationErrorKind.invalidSpecies,
        detail: raw,
        formulaError: e,
      );
    }
  }
  return result;
}

/// Splits one side of an equation at `+` signs that separate species,
/// keeping `+` that are part of a charge (`Fe^3+`, `Na+`).
List<String> _splitSpecies(String side) {
  // When the user separates species with spaced pluses, trust that.
  if (RegExp(r'\s\+\s').hasMatch(side)) {
    return side
        .split(RegExp(r'\s+\+\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
  }
  final startsSpecies = RegExp(r'[A-Z(\[{0-9e]');
  final parts = <String>[];
  final b = StringBuffer();
  for (var i = 0; i < side.length; i++) {
    final c = side[i];
    if (c == '+') {
      final prev = _prevNonSpace(side, i);
      final next = _nextNonSpace(side, i);
      if (prev != null &&
          prev != '^' &&
          next != null &&
          startsSpecies.hasMatch(next)) {
        parts.add(b.toString());
        b.clear();
        continue;
      }
    }
    b.write(c);
  }
  parts.add(b.toString());
  return parts.where((p) => p.trim().isNotEmpty).toList();
}

String? _prevNonSpace(String s, int i) {
  for (var k = i - 1; k >= 0; k--) {
    if (s[k] != ' ') return s[k];
  }
  return null;
}

String? _nextNonSpace(String s, int i) {
  for (var k = i + 1; k < s.length; k++) {
    if (s[k] != ' ') return s[k];
  }
  return null;
}

/// Basis of the null space of the matrix [rows] (each of length [cols]).
List<List<Rational>> nullSpace(List<List<Rational>> rows, int cols) {
  final m = [for (final r in rows) List<Rational>.of(r)];
  final pivotCols = <int>[];
  var r = 0;
  for (var c = 0; c < cols && r < m.length; c++) {
    var p = -1;
    for (var k = r; k < m.length; k++) {
      if (!m[k][c].isZero) {
        p = k;
        break;
      }
    }
    if (p < 0) continue;
    final tmp = m[p];
    m[p] = m[r];
    m[r] = tmp;
    final pv = m[r][c];
    for (var j = c; j < cols; j++) {
      m[r][j] = m[r][j] / pv;
    }
    for (var k = 0; k < m.length; k++) {
      if (k == r || m[k][c].isZero) continue;
      final f = m[k][c];
      for (var j = c; j < cols; j++) {
        m[k][j] = m[k][j] - f * m[r][j];
      }
    }
    pivotCols.add(c);
    r++;
  }
  final free = [
    for (var c = 0; c < cols; c++)
      if (!pivotCols.contains(c)) c,
  ];
  return [
    for (final f in free)
      () {
        final v = List<Rational>.filled(cols, Rational.zero);
        v[f] = Rational.one;
        for (var k = 0; k < pivotCols.length; k++) {
          v[pivotCols[k]] = -m[k][f];
        }
        return v;
      }(),
  ];
}

/// Result of a stoichiometry calculation for one species.
class SpeciesAmount {
  const SpeciesAmount({
    required this.moles,
    required this.mass,
    this.isLimiting = false,
    this.excessMoles,
  });

  final double moles;
  final double mass;
  final bool isLimiting;

  /// For reactants that were given: moles left over after reaction.
  final double? excessMoles;
}

class StoichiometryResult {
  const StoichiometryResult(this.extent, this.amounts, this.limitingIndex);

  /// Reaction extent ξ in mol (moles of "reaction units").
  final double extent;

  /// Amount consumed (reactants) or produced (products) per species.
  final List<SpeciesAmount> amounts;
  final int limitingIndex;
}

/// Given moles available for some species (index → mol) of a balanced
/// [equation], determines the limiting reactant and the amounts consumed or
/// produced for every species.
///
/// If only product amounts are given, the extent is derived from the
/// smallest one (i.e. the amount needed to make that product).
StoichiometryResult stoichiometry(
  BalancedEquation equation,
  Map<int, double> givenMoles,
) {
  if (givenMoles.isEmpty) {
    throw ArgumentError('At least one amount is required');
  }
  final givenReactants = givenMoles.keys.where(equation.isReactant).toList();
  final keys = givenReactants.isNotEmpty ? givenReactants : givenMoles.keys;
  var limiting = -1;
  var extent = double.infinity;
  for (final k in keys) {
    final x = givenMoles[k]! / equation.coefficientOf(k);
    if (x < extent) {
      extent = x;
      limiting = k;
    }
  }
  final species = equation.species;
  return StoichiometryResult(extent, [
    for (var k = 0; k < species.length; k++)
      () {
        final mol = extent * equation.coefficientOf(k);
        final given = givenMoles[k];
        return SpeciesAmount(
          moles: mol,
          mass: mol * species[k].formula.molarMass,
          isLimiting: k == limiting && givenReactants.length > 1,
          excessMoles: equation.isReactant(k) && given != null
              ? (given - mol).clamp(0, double.infinity).toDouble()
              : null,
        );
      }(),
  ], limiting);
}
