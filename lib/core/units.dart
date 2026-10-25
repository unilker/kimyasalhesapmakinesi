/// Physical quantities and their units. Each unit converts to the
/// quantity's base unit via `base = value * factor + offset`.
enum Quantity {
  mass, // g
  volume, // L
  amount, // mol
  pressure, // Pa
  temperature, // K
  temperatureDifference, // K
  energy, // J
  length, // m
  time, // s
  concentration, // mol/L
  density, // g/mL
  molarMass, // g/mol
  molarEnergy, // J/mol
  molarEntropy, // J/(mol·K)
  specificHeat, // J/(g·K)
  current, // A
  charge, // C
  voltage, // V
  rateConstant, // 1/s (first order)
  zeroOrderRate, // mol/(L·s)
  secondOrderRate, // L/(mol·s)
  frequency, // Hz
  molality, // mol/kg
  absorptivity, // L/(mol·cm)
  cryoscopic, // K·kg/mol
  speed, // m/s
  activity, // Bq
  henry, // mol/(L·atm)
  vdwA, // L²·bar/mol²
  vdwB, // L/mol
  percent,
  dimensionless,
}

class Unit {
  const Unit(this.id, this.symbol, this.factor, [this.offset = 0]);

  final String id;
  final String symbol;
  final double factor;
  final double offset;

  double toBase(double v) => v * factor + offset;
  double fromBase(double v) => (v - offset) / factor;
}

const Map<Quantity, List<Unit>> units = {
  Quantity.mass: [
    Unit('g', 'g', 1),
    Unit('kg', 'kg', 1000),
    Unit('mg', 'mg', 1e-3),
    Unit('ug', 'µg', 1e-6),
    Unit('ng', 'ng', 1e-9),
    Unit('t', 't', 1e6),
    Unit('lb', 'lb', 453.59237),
    Unit('oz', 'oz', 28.349523125),
    Unit('u', 'u (Da)', 1.66053906892e-24),
  ],
  Quantity.volume: [
    Unit('L', 'L', 1),
    Unit('mL', 'mL', 1e-3),
    Unit('uL', 'µL', 1e-6),
    Unit('dL', 'dL', 0.1),
    Unit('m3', 'm³', 1000),
    Unit('cm3', 'cm³', 1e-3),
    Unit('dm3', 'dm³', 1),
    Unit('gal', 'gal (US)', 3.785411784),
  ],
  Quantity.amount: [
    Unit('mol', 'mol', 1),
    Unit('mmol', 'mmol', 1e-3),
    Unit('umol', 'µmol', 1e-6),
    Unit('nmol', 'nmol', 1e-9),
    Unit('kmol', 'kmol', 1000),
  ],
  Quantity.pressure: [
    Unit('atm', 'atm', 101325),
    Unit('Pa', 'Pa', 1),
    Unit('kPa', 'kPa', 1000),
    Unit('MPa', 'MPa', 1e6),
    Unit('bar', 'bar', 1e5),
    Unit('mbar', 'mbar', 100),
    Unit('mmHg', 'mmHg', 133.322387415),
    Unit('Torr', 'Torr', 101325 / 760),
    Unit('psi', 'psi', 6894.757293168),
  ],
  Quantity.temperature: [
    Unit('K', 'K', 1),
    Unit('C', '°C', 1, 273.15),
    Unit('F', '°F', 5 / 9, 273.15 - 32 * 5 / 9),
  ],
  Quantity.temperatureDifference: [
    Unit('K', 'K', 1),
    Unit('C', '°C', 1),
    Unit('F', '°F', 5 / 9),
  ],
  Quantity.energy: [
    Unit('J', 'J', 1),
    Unit('kJ', 'kJ', 1000),
    Unit('MJ', 'MJ', 1e6),
    Unit('cal', 'cal', 4.184),
    Unit('kcal', 'kcal', 4184),
    Unit('eV', 'eV', 1.602176634e-19),
    Unit('Wh', 'Wh', 3600),
    Unit('kWh', 'kWh', 3.6e6),
    Unit('Latm', 'L·atm', 101.325),
  ],
  Quantity.length: [
    Unit('m', 'm', 1),
    Unit('km', 'km', 1000),
    Unit('cm', 'cm', 0.01),
    Unit('mm', 'mm', 1e-3),
    Unit('um', 'µm', 1e-6),
    Unit('nm', 'nm', 1e-9),
    Unit('A', 'Å', 1e-10),
    Unit('pm', 'pm', 1e-12),
    Unit('in', 'in', 0.0254),
    Unit('ft', 'ft', 0.3048),
  ],
  Quantity.time: [
    Unit('s', 's', 1),
    Unit('ms', 'ms', 1e-3),
    Unit('min', 'min', 60),
    Unit('h', 'h', 3600),
    Unit('d', 'd', 86400),
    Unit('y', 'yr', 31557600),
  ],
  Quantity.concentration: [
    Unit('M', 'M (mol/L)', 1),
    Unit('mM', 'mM', 1e-3),
    Unit('uM', 'µM', 1e-6),
    Unit('nM', 'nM', 1e-9),
    Unit('molm3', 'mol/m³', 1e-3),
  ],
  Quantity.density: [
    Unit('gmL', 'g/mL', 1),
    Unit('gcm3', 'g/cm³', 1),
    Unit('kgL', 'kg/L', 1),
    Unit('gL', 'g/L', 1e-3),
    Unit('kgm3', 'kg/m³', 1e-3),
  ],
  Quantity.molarMass: [
    Unit('gmol', 'g/mol', 1),
    Unit('kgmol', 'kg/mol', 1000),
  ],
  Quantity.molarEnergy: [
    Unit('kJmol', 'kJ/mol', 1000),
    Unit('Jmol', 'J/mol', 1),
    Unit('kcalmol', 'kcal/mol', 4184),
    Unit('calmol', 'cal/mol', 4.184),
    Unit('eV', 'eV', 96485.33212331001), // = N_A·e
  ],
  Quantity.molarEntropy: [
    Unit('JmolK', 'J/(mol·K)', 1),
    Unit('kJmolK', 'kJ/(mol·K)', 1000),
    Unit('calmolK', 'cal/(mol·K)', 4.184),
  ],
  Quantity.specificHeat: [
    Unit('JgK', 'J/(g·K)', 1),
    Unit('JkgK', 'J/(kg·K)', 1e-3),
    Unit('calgK', 'cal/(g·K)', 4.184),
  ],
  Quantity.current: [
    Unit('A', 'A', 1),
    Unit('mA', 'mA', 1e-3),
  ],
  Quantity.charge: [
    Unit('C', 'C', 1),
    Unit('mAh', 'mAh', 3.6),
    Unit('Ah', 'Ah', 3600),
  ],
  Quantity.voltage: [
    Unit('V', 'V', 1),
    Unit('mV', 'mV', 1e-3),
  ],
  Quantity.rateConstant: [
    Unit('s-1', 's⁻¹', 1),
    Unit('min-1', 'min⁻¹', 1 / 60),
    Unit('h-1', 'h⁻¹', 1 / 3600),
    Unit('d-1', 'd⁻¹', 1 / 86400),
  ],
  Quantity.zeroOrderRate: [
    Unit('Ms', 'M·s⁻¹', 1),
    Unit('Mmin', 'M·min⁻¹', 1 / 60),
    Unit('Mh', 'M·h⁻¹', 1 / 3600),
  ],
  Quantity.secondOrderRate: [
    Unit('M-1s-1', 'M⁻¹·s⁻¹', 1),
    Unit('M-1min-1', 'M⁻¹·min⁻¹', 1 / 60),
    Unit('M-1h-1', 'M⁻¹·h⁻¹', 1 / 3600),
  ],
  Quantity.frequency: [
    Unit('Hz', 'Hz', 1),
    Unit('kHz', 'kHz', 1e3),
    Unit('MHz', 'MHz', 1e6),
    Unit('GHz', 'GHz', 1e9),
    Unit('THz', 'THz', 1e12),
  ],
  Quantity.molality: [
    Unit('molkg', 'mol/kg', 1),
    Unit('mmolkg', 'mmol/kg', 1e-3),
  ],
  Quantity.absorptivity: [
    Unit('Lmolcm', 'L·mol⁻¹·cm⁻¹', 1),
  ],
  Quantity.cryoscopic: [
    Unit('Kkgmol', 'K·kg/mol', 1),
  ],
  Quantity.speed: [
    Unit('ms', 'm/s', 1),
    Unit('kms', 'km/s', 1000),
    Unit('kmh', 'km/h', 1 / 3.6),
  ],
  Quantity.activity: [
    Unit('Bq', 'Bq', 1),
    Unit('kBq', 'kBq', 1e3),
    Unit('MBq', 'MBq', 1e6),
    Unit('GBq', 'GBq', 1e9),
    Unit('Ci', 'Ci', 3.7e10),
    Unit('mCi', 'mCi', 3.7e7),
    Unit('uCi', 'µCi', 3.7e4),
  ],
  Quantity.henry: [
    Unit('Matm', 'mol/(L·atm)', 1),
    Unit('Mbar', 'mol/(L·bar)', 1.01325),
  ],
  Quantity.vdwA: [
    Unit('L2barmol2', 'L²·bar/mol²', 1),
    Unit('L2atmmol2', 'L²·atm/mol²', 1.01325),
    Unit('Pam6mol2', 'Pa·m⁶/mol²', 10),
  ],
  Quantity.vdwB: [
    Unit('Lmol', 'L/mol', 1),
    Unit('cm3mol', 'cm³/mol', 1e-3),
    Unit('m3mol', 'm³/mol', 1000),
  ],
  Quantity.percent: [
    Unit('pct', '%', 1),
  ],
  Quantity.dimensionless: [
    Unit('1', '', 1),
  ],
};

/// Quantities offered in the unit converter, in display order.
const converterQuantities = [
  Quantity.mass,
  Quantity.volume,
  Quantity.amount,
  Quantity.pressure,
  Quantity.temperature,
  Quantity.energy,
  Quantity.length,
  Quantity.time,
  Quantity.concentration,
  Quantity.density,
  Quantity.molarEnergy,
  Quantity.frequency,
];

Unit unitById(Quantity q, String id) =>
    units[q]!.firstWhere((u) => u.id == id, orElse: () => units[q]!.first);

double convert(double value, Unit from, Unit to) =>
    to.fromBase(from.toBase(value));
