/// Limiting ionic conductivities in water at 25 °C, per equivalent
/// (λ°(1/z Xᶻ), S cm² mol⁻¹), from P. Vanýsek, "Ionic conductivity and
/// diffusion at infinite dilution", CRC Handbook of Chemistry and Physics.
/// Only ions whose values agree with an independent compilation are listed.
const Map<String, double> limitingEquivalentConductivity = {
  'H⁺': 349.65,
  'Li⁺': 38.66,
  'Na⁺': 50.08,
  'K⁺': 73.48,
  'Rb⁺': 77.8,
  'Cs⁺': 77.2,
  'NH₄⁺': 73.5,
  'Ag⁺': 61.9,
  'Mg²⁺': 53.0,
  'Ca²⁺': 59.47,
  'Ba²⁺': 63.6,
  'Cu²⁺': 53.6,
  'Zn²⁺': 52.8,
  'La³⁺': 69.7,
  'OH⁻': 198,
  'F⁻': 55.4,
  'Cl⁻': 76.31,
  'Br⁻': 78.1,
  'I⁻': 76.8,
  'NO₃⁻': 71.42,
  'ClO₄⁻': 67.3,
  'HCO₃⁻': 44.5,
  'CH₃COO⁻': 40.9,
  'SO₄²⁻': 80.0,
  'HPO₄²⁻': 57,
  'Fe(CN)₆³⁻': 100.9,
  'Fe(CN)₆⁴⁻': 110.4,
};

/// Kohlrausch's law of independent migration at infinite dilution:
/// κ = Σ |zᵢ| λ°ᵢ cᵢ. Concentrations in mol/L; returns κ in S/m, or null
/// when an ion has no tabulated λ°.
double? kohlrauschConductivity(Iterable<(String formula, int z, double c)> ions) {
  var s = 0.0;
  for (final (f, z, c) in ions) {
    final l = limitingEquivalentConductivity[f];
    if (l == null) return null;
    // S cm² mol⁻¹ × mol L⁻¹ = 1e-4 m² × 1e3 m⁻³ S = 0.1 S/m
    s += z.abs() * l * c * 0.1;
  }
  return s;
}

/// Transport (transference) numbers tᵢ = |zᵢ|λ°ᵢcᵢ / Σ at infinite dilution.
List<double>? transportNumbers(List<(String formula, int z, double c)> ions) {
  final total = kohlrauschConductivity(ions);
  if (total == null || total == 0) return null;
  return [for (final (f, z, c) in ions) z.abs() * limitingEquivalentConductivity[f]! * c * 0.1 / total];
}
