/// Physical constants (CODATA 2018 recommended values; SI 2019 exact
/// values marked [exact]).
class PhysicalConstant {
  const PhysicalConstant({
    required this.key,
    required this.symbol,
    required this.value,
    required this.unit,
    required this.nameEn,
    required this.nameTr,
    this.exact = false,
  });

  /// Identifier usable in calculator expressions.
  final String key;
  final String symbol;
  final double value;
  final String unit;
  final String nameEn;
  final String nameTr;
  final bool exact;

  String name(String languageCode) => languageCode == 'tr' ? nameTr : nameEn;
}

const double avogadro = 6.02214076e23;
const double gasConstant = 8.314462618; // J/(mol·K)
const double faraday = 96485.33212; // C/mol
const double planck = 6.62607015e-34; // J·s
const double speedOfLight = 299792458; // m/s
const double boltzmann = 1.380649e-23; // J/K
const double elementaryCharge = 1.602176634e-19; // C
const double standardPressure = 101325; // Pa (1 atm)

const List<PhysicalConstant> physicalConstants = [
  PhysicalConstant(
    key: 'NA',
    symbol: 'Nₐ',
    value: avogadro,
    unit: 'mol⁻¹',
    nameEn: 'Avogadro constant',
    nameTr: 'Avogadro sabiti',
    exact: true,
  ),
  PhysicalConstant(
    key: 'R',
    symbol: 'R',
    value: gasConstant,
    unit: 'J·mol⁻¹·K⁻¹',
    nameEn: 'Gas constant',
    nameTr: 'Gaz sabiti',
    exact: true,
  ),
  PhysicalConstant(
    key: 'Ratm',
    symbol: 'R',
    value: 0.082057366080960,
    unit: 'L·atm·mol⁻¹·K⁻¹',
    nameEn: 'Gas constant (L·atm)',
    nameTr: 'Gaz sabiti (L·atm)',
    exact: true,
  ),
  PhysicalConstant(
    key: 'Rcal',
    symbol: 'R',
    value: 1.98720425864083,
    unit: 'cal·mol⁻¹·K⁻¹',
    nameEn: 'Gas constant (cal)',
    nameTr: 'Gaz sabiti (cal)',
    exact: true,
  ),
  PhysicalConstant(
    key: 'F',
    symbol: 'F',
    value: faraday,
    unit: 'C·mol⁻¹',
    nameEn: 'Faraday constant',
    nameTr: 'Faraday sabiti',
    exact: true,
  ),
  PhysicalConstant(
    key: 'kB',
    symbol: 'k_B',
    value: boltzmann,
    unit: 'J·K⁻¹',
    nameEn: 'Boltzmann constant',
    nameTr: 'Boltzmann sabiti',
    exact: true,
  ),
  PhysicalConstant(
    key: 'h',
    symbol: 'h',
    value: planck,
    unit: 'J·s',
    nameEn: 'Planck constant',
    nameTr: 'Planck sabiti',
    exact: true,
  ),
  PhysicalConstant(
    key: 'c',
    symbol: 'c',
    value: speedOfLight,
    unit: 'm·s⁻¹',
    nameEn: 'Speed of light in vacuum',
    nameTr: 'Işığın boşluktaki hızı',
    exact: true,
  ),
  PhysicalConstant(
    key: 'qe',
    symbol: 'e',
    value: elementaryCharge,
    unit: 'C',
    nameEn: 'Elementary charge',
    nameTr: 'Temel yük',
    exact: true,
  ),
  PhysicalConstant(
    key: 'me',
    symbol: 'mₑ',
    value: 9.1093837015e-31,
    unit: 'kg',
    nameEn: 'Electron mass',
    nameTr: 'Elektron kütlesi',
  ),
  PhysicalConstant(
    key: 'mp',
    symbol: 'mₚ',
    value: 1.67262192369e-27,
    unit: 'kg',
    nameEn: 'Proton mass',
    nameTr: 'Proton kütlesi',
  ),
  PhysicalConstant(
    key: 'mn',
    symbol: 'mₙ',
    value: 1.67492749804e-27,
    unit: 'kg',
    nameEn: 'Neutron mass',
    nameTr: 'Nötron kütlesi',
  ),
  PhysicalConstant(
    key: 'u',
    symbol: 'u',
    value: 1.66053906660e-27,
    unit: 'kg',
    nameEn: 'Atomic mass constant',
    nameTr: 'Atomik kütle sabiti',
  ),
  PhysicalConstant(
    key: 'Vm',
    symbol: 'Vₘ',
    value: 22.41396954,
    unit: 'L·mol⁻¹ (0 °C, 1 atm)',
    nameEn: 'Molar volume of ideal gas',
    nameTr: 'İdeal gazın molar hacmi',
    exact: true,
  ),
  PhysicalConstant(
    key: 'VmSTP',
    symbol: 'Vₘ',
    value: 22.71095464,
    unit: 'L·mol⁻¹ (0 °C, 1 bar)',
    nameEn: 'Molar volume (IUPAC STP)',
    nameTr: 'Molar hacim (IUPAC STP)',
    exact: true,
  ),
  PhysicalConstant(
    key: 'eps',
    symbol: 'ε₀',
    value: 8.8541878128e-12,
    unit: 'F·m⁻¹',
    nameEn: 'Vacuum permittivity',
    nameTr: 'Boşluğun elektriksel geçirgenliği',
  ),
  PhysicalConstant(
    key: 'Ry',
    symbol: 'R∞',
    value: 10973731.568160,
    unit: 'm⁻¹',
    nameEn: 'Rydberg constant',
    nameTr: 'Rydberg sabiti',
  ),
  PhysicalConstant(
    key: 'aB',
    symbol: 'a₀',
    value: 5.29177210903e-11,
    unit: 'm',
    nameEn: 'Bohr radius',
    nameTr: 'Bohr yarıçapı',
  ),
  PhysicalConstant(
    key: 'g',
    symbol: 'g',
    value: 9.80665,
    unit: 'm·s⁻²',
    nameEn: 'Standard gravity',
    nameTr: 'Standart yerçekimi ivmesi',
    exact: true,
  ),
];

PhysicalConstant? constantByKey(String key) {
  for (final c in physicalConstants) {
    if (c.key == key) return c;
  }
  return null;
}
