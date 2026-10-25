import 'chem/formula.dart';
import 'chem/isotopes_data.dart';
import 'constants.dart';

/// One unit-resolution peak: all isotopologues with the same nominal mass.
class IsotopePeak {
  const IsotopePeak(this.nominal, this.mass, this.fraction, this.relative);

  /// Sum of the mass numbers of the atoms (M, M+1, …).
  final int nominal;

  /// Abundance-weighted mean mass of the isotopologues in this peak (u),
  /// or m/z for an ion.
  final double mass;

  /// Fraction of all molecules.
  final double fraction;

  /// Intensity relative to the largest peak (%).
  final double relative;
}

class IsotopePattern {
  const IsotopePattern({
    required this.monoisotopicMass,
    required this.nominalMass,
    required this.averageMass,
    required this.charge,
    required this.peaks,
  });

  /// Mass of the isotopologue made of the most abundant isotope of every
  /// element (u), or its m/z for an ion.
  final double monoisotopicMass;

  /// Mass number of that isotopologue (the M of M+1, M+2 …).
  final int nominalMass;

  /// Mean mass over the isotopic distribution (u), or mean m/z.
  final double averageMass;
  final int charge;

  /// Peaks above the cut-off, in order of mass.
  final List<IsotopePeak> peaks;
}

class IsotopeException implements Exception {
  const IsotopeException(this.element);

  /// Element without a natural isotopic composition (e.g. Tc, Pm).
  final String element;
}

/// Natural isotopes of [symbol]; D and T count as pure ²H and ³H.
List<(int, double, double)>? _isotopes(String symbol) => switch (symbol) {
      'D' => const [(2, 2.01410177812, 1.0)],
      'T' => const [(3, 3.0160492779, 1.0)],
      _ => naturalIsotopes[symbol],
    };

/// Distribution over nominal mass: index = nominal − offset; each entry
/// holds probability p and p·mass.
class _Dist {
  _Dist(this.offset, this.p, this.pm);

  final int offset;
  final List<double> p;
  final List<double> pm;

  _Dist times(_Dist o, double cutoff) {
    final n = p.length + o.p.length - 1;
    final rp = List<double>.filled(n, 0), rpm = List<double>.filled(n, 0);
    for (var i = 0; i < p.length; i++) {
      if (p[i] == 0) continue;
      for (var j = 0; j < o.p.length; j++) {
        if (o.p[j] == 0) continue;
        rp[i + j] += p[i] * o.p[j];
        rpm[i + j] += pm[i] * o.p[j] + p[i] * o.pm[j];
      }
    }
    // Drop negligible tails so long chains stay small.
    var lo = 0, hi = n - 1;
    while (lo < hi && rp[lo] < cutoff) {
      lo++;
    }
    while (hi > lo && rp[hi] < cutoff) {
      hi--;
    }
    return _Dist(offset + o.offset + lo, rp.sublist(lo, hi + 1), rpm.sublist(lo, hi + 1));
  }
}

/// Monoisotopic mass (u) or m/z of [formula] without building the pattern.
double monoisotopicMass(ChemicalFormula formula) {
  var mono = 0.0;
  for (final e in formula.atoms.entries) {
    final iso = _isotopes(e.key);
    final n = e.value.round();
    if (iso == null || (e.value - n).abs() > 1e-9 || n < 0) throw IsotopeException(e.key);
    mono += n * iso.reduce((a, b) => b.$3 > a.$3 ? b : a).$2;
  }
  final z = formula.charge;
  return z == 0 ? mono : (mono - z * electronMassU) / z.abs();
}

/// Isotope pattern of [formula] at unit mass resolution. Peaks below
/// [minRelative] % of the largest one are left out of [IsotopePattern.peaks].
IsotopePattern isotopePattern(ChemicalFormula formula, {double minRelative = 0.01}) {
  const cutoff = 1e-30;
  var dist = _Dist(0, [1.0], [0.0]);
  var mono = 0.0;
  var nominal = 0;
  for (final e in formula.atoms.entries) {
    final iso = _isotopes(e.key);
    if (iso == null) throw IsotopeException(e.key);
    final n = e.value.round();
    if ((e.value - n).abs() > 1e-9 || n < 0) throw IsotopeException(e.key);
    if (n == 0) continue;
    final base = iso.map((t) => t.$1).reduce((a, b) => a < b ? a : b);
    final top = iso.map((t) => t.$1).reduce((a, b) => a > b ? a : b);
    final p = List<double>.filled(top - base + 1, 0), pm = List<double>.filled(top - base + 1, 0);
    var most = iso.first;
    for (final t in iso) {
      p[t.$1 - base] += t.$3;
      pm[t.$1 - base] += t.$3 * t.$2;
      if (t.$3 > most.$3) most = t;
    }
    mono += n * most.$2;
    nominal += n * most.$1;
    // binary exponentiation
    var acc = _Dist(0, [1.0], [0.0]);
    var sq = _Dist(base, p, pm);
    for (var k = n; k > 0; k >>= 1) {
      if (k & 1 == 1) acc = acc.times(sq, cutoff);
      if (k > 1) sq = sq.times(sq, cutoff);
    }
    dist = dist.times(acc, cutoff);
  }
  final z = formula.charge;
  double toMz(double m) => z == 0 ? m : (m - z * electronMassU) / z.abs();
  final total = dist.p.fold(0.0, (a, b) => a + b);
  final maxP = dist.p.reduce((a, b) => a > b ? a : b);
  var avg = 0.0;
  for (final v in dist.pm) {
    avg += v;
  }
  final peaks = <IsotopePeak>[
    for (var i = 0; i < dist.p.length; i++)
      if (dist.p[i] > 0 && dist.p[i] / maxP * 100 >= minRelative)
        IsotopePeak(
          dist.offset + i,
          toMz(dist.pm[i] / dist.p[i]),
          dist.p[i] / total,
          dist.p[i] / maxP * 100,
        ),
  ];
  return IsotopePattern(
    monoisotopicMass: toMz(mono),
    nominalMass: nominal,
    averageMass: toMz(avg / total),
    charge: z,
    peaks: peaks,
  );
}
