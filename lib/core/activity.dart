import 'dart:math' as math;

import 'constants.dart';

/// Ionic strength and single-ion activity coefficients in water
/// (Debye–Hückel family) on the molar concentration scale.
///
/// The Debye–Hückel constants are computed from first principles,
/// A = λ_B·κ₁ / (2 ln 10) and B = κ₁ with λ_B the Bjerrum length and κ₁ the
/// inverse Debye length at I = 1 mol/L, using the relative permittivity of
/// water from Malmberg & Maryott (J. Res. NBS 56, 1, 1956; 0–100 °C).

const double _vacuumPermittivity = 8.8541878188e-12; // F/m, CODATA 2022

/// Relative permittivity of water at [celsius] (Malmberg & Maryott 1956).
double waterPermittivity(double celsius) {
  final t = celsius;
  return 87.740 - 0.40008 * t + 9.398e-4 * t * t - 1.410e-6 * t * t * t;
}

/// Density of air-free water at 1 atm in kg/m³ (Kell, J. Chem. Eng. Data 20,
/// 97, 1975), used to convert to the molal scale.
double waterDensity(double celsius) {
  final t = celsius;
  return (999.83952 +
          16.945176 * t -
          7.9870401e-3 * t * t -
          46.170461e-6 * t * t * t +
          105.56302e-9 * t * t * t * t -
          280.54253e-12 * t * t * t * t * t) /
      (1 + 16.879850e-3 * t);
}

class DebyeHuckel {
  DebyeHuckel(this.celsius) {
    final kT = boltzmann * (celsius + 273.15);
    permittivity = waterPermittivity(celsius);
    final bjerrum =
        elementaryCharge * elementaryCharge / (4 * math.pi * _vacuumPermittivity * permittivity * kT);
    // κ² = 8π·λ_B·Nₐ·1000·I  (I in mol/L → mol/m³)
    final kappa1 = math.sqrt(8 * math.pi * bjerrum * avogadro * 1000);
    a = bjerrum * kappa1 / (2 * math.ln10);
    bPerPm = kappa1 * 1e-12;
  }

  final double celsius;
  late final double permittivity;

  /// A in (L/mol)^½, base-10 logarithm (0.5116 at 25 °C).
  late final double a;

  /// B in pm⁻¹ (L/mol)^½ (1/B = 304 pm at 25 °C).
  late final double bPerPm;

  /// A on the molal scale, (kg/mol)^½.
  double get aMolal => a * math.sqrt(waterDensity(celsius) / 1000);

  /// log₁₀ γ, limiting law (I ≲ 0.005 M).
  double logLimiting(int z, double i) => -a * z * z * math.sqrt(i);

  /// log₁₀ γ, extended Debye–Hückel with ion size [sizePm] (I ≲ 0.1 M).
  double logExtended(int z, double sizePm, double i) =>
      -a * z * z * math.sqrt(i) / (1 + bPerPm * sizePm * math.sqrt(i));

  /// log₁₀ γ, Davies equation (C. W. Davies, Ion Association, 1962;
  /// I ≲ 0.5 M).
  double logDavies(int z, double i) {
    final s = math.sqrt(i);
    return -a * z * z * (s / (1 + s) - 0.3 * i);
  }
}

/// I = ½ Σ cᵢ zᵢ².
double ionicStrength(Iterable<(double c, int z)> ions) {
  var s = 0.0;
  for (final (c, z) in ions) {
    s += c * z * z;
  }
  return s / 2;
}

/// Mean ionic activity coefficient of a salt M_p X_q from single-ion values.
double meanActivity(double gammaCation, int p, double gammaAnion, int q) =>
    math.pow(math.pow(gammaCation, p) * math.pow(gammaAnion, q), 1 / (p + q)).toDouble();

/// An ion with its Kielland size parameter (J. Am. Chem. Soc. 59, 1675,
/// 1937), as tabulated by Harris, Quantitative Chemical Analysis, Table 7-1.
class KiellandIon {
  const KiellandIon(this.formula, this.charge, this.sizePm);

  /// Display formula with superscript charge.
  final String formula;
  final int charge;
  final double sizePm;
}

const List<KiellandIon> kiellandIons = [
  // charge +1
  KiellandIon('H⁺', 1, 900),
  KiellandIon('Li⁺', 1, 600),
  KiellandIon('Na⁺', 1, 450),
  KiellandIon('(CH₃)₄N⁺', 1, 450),
  KiellandIon('CH₃NH₃⁺', 1, 350),
  KiellandIon('K⁺', 1, 300),
  KiellandIon('Rb⁺', 1, 250),
  KiellandIon('Cs⁺', 1, 250),
  KiellandIon('NH₄⁺', 1, 250),
  KiellandIon('Tl⁺', 1, 250),
  KiellandIon('Ag⁺', 1, 250),
  // charge −1
  KiellandIon('OH⁻', -1, 350),
  KiellandIon('F⁻', -1, 350),
  KiellandIon('Cl⁻', -1, 300),
  KiellandIon('Br⁻', -1, 300),
  KiellandIon('I⁻', -1, 300),
  KiellandIon('CN⁻', -1, 300),
  KiellandIon('NO₂⁻', -1, 300),
  KiellandIon('NO₃⁻', -1, 300),
  KiellandIon('SCN⁻', -1, 350),
  KiellandIon('OCN⁻', -1, 350),
  KiellandIon('HS⁻', -1, 350),
  KiellandIon('ClO₃⁻', -1, 350),
  KiellandIon('ClO₄⁻', -1, 350),
  KiellandIon('BrO₃⁻', -1, 350),
  KiellandIon('IO₄⁻', -1, 350),
  KiellandIon('MnO₄⁻', -1, 350),
  KiellandIon('HCOO⁻', -1, 350),
  KiellandIon('ClO₂⁻', -1, 450),
  KiellandIon('IO₃⁻', -1, 450),
  KiellandIon('HCO₃⁻', -1, 450),
  KiellandIon('H₂PO₄⁻', -1, 450),
  KiellandIon('HSO₃⁻', -1, 450),
  KiellandIon('H₂AsO₄⁻', -1, 450),
  KiellandIon('CH₃COO⁻', -1, 450),
  KiellandIon('ClCH₂COO⁻', -1, 450),
  KiellandIon('C₆H₅COO⁻', -1, 600),
  // charge +2
  KiellandIon('Mg²⁺', 2, 800),
  KiellandIon('Be²⁺', 2, 800),
  KiellandIon('Ca²⁺', 2, 600),
  KiellandIon('Cu²⁺', 2, 600),
  KiellandIon('Zn²⁺', 2, 600),
  KiellandIon('Sn²⁺', 2, 600),
  KiellandIon('Mn²⁺', 2, 600),
  KiellandIon('Fe²⁺', 2, 600),
  KiellandIon('Ni²⁺', 2, 600),
  KiellandIon('Co²⁺', 2, 600),
  KiellandIon('Sr²⁺', 2, 500),
  KiellandIon('Ba²⁺', 2, 500),
  KiellandIon('Cd²⁺', 2, 500),
  KiellandIon('Hg²⁺', 2, 500),
  KiellandIon('Pb²⁺', 2, 450),
  KiellandIon('Hg₂²⁺', 2, 400),
  // charge −2
  KiellandIon('S²⁻', -2, 500),
  KiellandIon('WO₄²⁻', -2, 500),
  KiellandIon('CO₃²⁻', -2, 450),
  KiellandIon('SO₃²⁻', -2, 450),
  KiellandIon('MoO₄²⁻', -2, 450),
  KiellandIon('C₂O₄²⁻', -2, 450),
  KiellandIon('SO₄²⁻', -2, 400),
  KiellandIon('S₂O₃²⁻', -2, 400),
  KiellandIon('S₂O₈²⁻', -2, 400),
  KiellandIon('SeO₄²⁻', -2, 400),
  KiellandIon('CrO₄²⁻', -2, 400),
  KiellandIon('HPO₄²⁻', -2, 400),
  // charge +3
  KiellandIon('Al³⁺', 3, 900),
  KiellandIon('Fe³⁺', 3, 900),
  KiellandIon('Cr³⁺', 3, 900),
  KiellandIon('Sc³⁺', 3, 900),
  KiellandIon('Y³⁺', 3, 900),
  KiellandIon('In³⁺', 3, 900),
  KiellandIon('La³⁺', 3, 900),
  KiellandIon('Ce³⁺', 3, 900),
  // charge −3
  KiellandIon('citrate³⁻', -3, 500),
  KiellandIon('PO₄³⁻', -3, 400),
  KiellandIon('Fe(CN)₆³⁻', -3, 400),
  // charge ±4
  KiellandIon('Th⁴⁺', 4, 1100),
  KiellandIon('Zr⁴⁺', 4, 1100),
  KiellandIon('Ce⁴⁺', 4, 1100),
  KiellandIon('Sn⁴⁺', 4, 1100),
  KiellandIon('Fe(CN)₆⁴⁻', -4, 500),
];

KiellandIon kiellandIon(String formula) => kiellandIons.firstWhere((x) => x.formula == formula);

/// A salt for quick entry: the ions it releases with their stoichiometry.
class SaltPreset {
  const SaltPreset(this.label, this.ions);

  final String label;
  final List<(String formula, int count)> ions;
}

const List<SaltPreset> saltPresets = [
  SaltPreset('NaCl', [('Na⁺', 1), ('Cl⁻', 1)]),
  SaltPreset('KCl', [('K⁺', 1), ('Cl⁻', 1)]),
  SaltPreset('KNO₃', [('K⁺', 1), ('NO₃⁻', 1)]),
  SaltPreset('HCl', [('H⁺', 1), ('Cl⁻', 1)]),
  SaltPreset('NaOH', [('Na⁺', 1), ('OH⁻', 1)]),
  SaltPreset('CaCl₂', [('Ca²⁺', 1), ('Cl⁻', 2)]),
  SaltPreset('MgCl₂', [('Mg²⁺', 1), ('Cl⁻', 2)]),
  SaltPreset('Na₂SO₄', [('Na⁺', 2), ('SO₄²⁻', 1)]),
  SaltPreset('K₂SO₄', [('K⁺', 2), ('SO₄²⁻', 1)]),
  SaltPreset('MgSO₄', [('Mg²⁺', 1), ('SO₄²⁻', 1)]),
  SaltPreset('CuSO₄', [('Cu²⁺', 1), ('SO₄²⁻', 1)]),
  SaltPreset('Na₂CO₃', [('Na⁺', 2), ('CO₃²⁻', 1)]),
  SaltPreset('AlCl₃', [('Al³⁺', 1), ('Cl⁻', 3)]),
  SaltPreset('LaCl₃', [('La³⁺', 1), ('Cl⁻', 3)]),
  SaltPreset('Na₃PO₄', [('Na⁺', 3), ('PO₄³⁻', 1)]),
  SaltPreset('K₄Fe(CN)₆', [('K⁺', 4), ('Fe(CN)₆⁴⁻', 1)]),
];
