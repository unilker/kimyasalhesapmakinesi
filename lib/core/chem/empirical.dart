import 'formula.dart';

class EmpiricalResult {
  const EmpiricalResult({
    required this.counts,
    required this.moleRatios,
    required this.formula,
    required this.empirical,
    required this.empiricalMass,
    this.molecularMultiplier,
  });

  /// Integer subscripts of the empirical formula in input order.
  final Map<String, int> counts;

  /// Mole ratios relative to the smallest amount (before rounding).
  final Map<String, double> moleRatios;

  /// Empirical (or molecular, when a molar mass was given) formula text.
  final String formula;

  /// Empirical formula text (same as [formula] without a molar mass).
  final String empirical;
  final double empiricalMass;

  /// Molecular formula multiplier when a molar mass was supplied.
  final int? molecularMultiplier;
}

/// Determines the empirical formula from element masses or mass
/// percentages (both work, only ratios matter). When [molarMass] is given,
/// the molecular formula is derived too.
EmpiricalResult empiricalFormula(
  Map<String, double> massBySymbol, {
  double? molarMass,
}) {
  if (massBySymbol.isEmpty) throw ArgumentError('No elements given');
  final moles = <String, double>{};
  massBySymbol.forEach((sym, m) {
    final am = symbolMass(sym);
    if (am == null) throw ArgumentError('Unknown element $sym');
    if (m <= 0) throw ArgumentError('Mass must be positive');
    moles[sym] = m / am;
  });
  final minMol = moles.values.reduce((a, b) => a < b ? a : b);
  final ratios = {for (final e in moles.entries) e.key: e.value / minMol};

  // Smallest multiplier that makes every ratio (nearly) whole; the
  // tolerance grows slightly with k because measurement noise scales too.
  var multiplier = 1;
  for (var k = 1; k <= 12; k++) {
    final tolerance = 0.08 + 0.02 * k;
    if (ratios.values.every((r) => (r * k - (r * k).round()).abs() <= tolerance)) {
      multiplier = k;
      break;
    }
  }
  final counts = {
    for (final e in ratios.entries) e.key: (e.value * multiplier).round(),
  };
  var empMass = 0.0;
  counts.forEach((s, n) => empMass += symbolMass(s)! * n);

  int? molMult;
  var finalCounts = counts;
  if (molarMass != null && molarMass > 0) {
    molMult = (molarMass / empMass).round().clamp(1, 1000);
    finalCounts = {for (final e in counts.entries) e.key: e.value * molMult};
  }
  return EmpiricalResult(
    counts: finalCounts,
    moleRatios: ratios,
    formula: _hill(finalCounts),
    empirical: _hill(counts),
    empiricalMass: empMass,
    molecularMultiplier: molMult,
  );
}

/// Writes a formula in Hill order (C, H, then alphabetical).
String _hill(Map<String, int> counts) {
  final keys = counts.keys.toList();
  final hasC = keys.contains('C');
  keys.sort((a, b) {
    int rank(String s) => hasC ? (s == 'C' ? 0 : (s == 'H' ? 1 : 2)) : 2;
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : a.compareTo(b);
  });
  return keys.map((k) => counts[k] == 1 ? k : '$k${counts[k]}').join();
}
