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

  // Pick the smallest multiplier k (1–12) whose rounded subscripts
  // reproduce every amount within its precision. For each k the amount of
  // one "formula unit" is fitted by least squares, and element i may then
  // deviate by 0.5 % plus the relative effect of rounding its mass
  // percentage pᵢ to two decimals (0.006/pᵢ) — so a trace of H in a heavy
  // compound is allowed its larger relative error. A k whose ratios are all
  // within ±0.1 of whole numbers is accepted too (noisy experimental
  // data); if none passes, k = 1. The tolerance must not
  // grow with k: with a growing tolerance C7H8 (8/7 = 1.143) was accepted
  // at k = 6 as C6H7.
  final totalMass = massBySymbol.values.fold(0.0, (a, b) => a + b);
  bool precise(int k) {
    final c = {for (final e in ratios.entries) e.key: (e.value * k).round()};
    if (c.values.any((n) => n < 1)) return false;
    var num = 0.0, den = 0.0;
    for (final e in c.entries) {
      num += moles[e.key]! * e.value;
      den += e.value * e.value;
    }
    final unit = num / den;
    return c.entries.every((e) {
      final pct = massBySymbol[e.key]! / totalMass * 100;
      final dev = (moles[e.key]! - unit * e.value).abs() / moles[e.key]!;
      return dev <= 0.005 + 0.006 / pct;
    });
  }

  bool nearlyWhole(int k) => ratios.values.every((r) => (r * k - (r * k).round()).abs() <= 0.1);

  var multiplier = 1;
  for (var k = 1; k <= 12; k++) {
    if (precise(k) || nearlyWhole(k)) {
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
