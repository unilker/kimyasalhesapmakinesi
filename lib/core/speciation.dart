import 'dart:math' as math;

/// Fractions αⱼ of HₙA, Hₙ₋₁A⁻, …, Aⁿ⁻ at a given pH for an acid with the
/// given pKa values (in increasing order):
/// αⱼ ∝ βⱼ·[H⁺]⁻ʲ with βⱼ = Ka₁·…·Kaⱼ, computed in log space so that
/// extreme pH values do not overflow.
List<double> speciesFractions(List<double> pKas, double pH) {
  final n = pKas.length;
  final logTerms = List<double>.filled(n + 1, 0);
  for (var j = 1; j <= n; j++) {
    // log10 of βⱼ/[H⁺]ʲ relative to the fully protonated form
    logTerms[j] = logTerms[j - 1] + (pH - pKas[j - 1]);
  }
  final m = logTerms.reduce(math.max);
  final w = [for (final l in logTerms) math.pow(10, l - m).toDouble()];
  final s = w.reduce((a, b) => a + b);
  return [for (final v in w) v / s];
}

/// Mean number of protons removed, Σ j·αⱼ (0 … n).
double meanDeprotonation(List<double> pKas, double pH) {
  final a = speciesFractions(pKas, pH);
  var s = 0.0;
  for (var j = 0; j < a.length; j++) {
    s += j * a[j];
  }
  return s;
}
