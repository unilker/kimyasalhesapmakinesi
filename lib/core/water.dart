import 'dart:math' as math;

/// Properties of liquid water and its vapour pressure.

/// Relative permittivity of water at [celsius] (Malmberg & Maryott,
/// J. Res. NBS 56, 1, 1956; 0–100 °C).
double waterPermittivity(double celsius) {
  final t = celsius;
  return 87.740 - 0.40008 * t + 9.398e-4 * t * t - 1.410e-6 * t * t * t;
}

/// Density of air-free water at 1 atm in kg/m³ (Kell, J. Chem. Eng. Data 20,
/// 97, 1975; 0–100 °C).
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

/// pKw = −log₁₀ Kw (molal scale) at [kelvin] and water density [rho] in
/// g/cm³: IAPWS R11-24 (Bandura–Lvov form with the 2024 parameters of Arcis
/// et al., J. Phys. Chem. Ref. Data 53, 023103).
double pKwIapws(double kelvin, double rho) {
  const n = 6;
  const a0 = -0.702132, a1 = 8681.05, a2 = -24145.1;
  const b0 = 0.813876, b1 = -51.4471, b2 = -0.469920;
  const mw = 18.015268;
  final t = kelvin;
  final z = rho * math.exp(a0 + a1 / t + a2 * math.pow(rho, 2 / 3) / (t * t));
  final pkg = 0.61415 + 48251.33 / t - 67707.93 / (t * t) + 10102100 / (t * t * t);
  return -2 * n * (_log10(1 + z) - z / (z + 1) * rho * (b0 + b1 / t + b2 * rho)) + pkg + 2 * _log10(mw / 1000);
}

/// pKw of liquid water at 1 atm and [celsius] (0–100 °C).
double pKwAt(double celsius) => pKwIapws(celsius + 273.15, waterDensity(celsius) / 1000);

const double waterCriticalT = 647.096; // K
const double waterCriticalP = 22.064e6; // Pa
const double waterTripleT = 273.16; // K

/// Saturation vapour pressure of water in Pa at [kelvin] (Wagner & Pruß,
/// J. Phys. Chem. Ref. Data 22, 783, 1993; IAPWS SR1-86(1992); triple point
/// to critical point).
double waterVaporPressure(double kelvin) {
  final tau = 1 - kelvin / waterCriticalT;
  final s = -7.85951783 * tau +
      1.84408259 * math.pow(tau, 1.5) -
      11.7866497 * math.pow(tau, 3) +
      22.6807411 * math.pow(tau, 3.5) -
      15.9618719 * math.pow(tau, 4) +
      1.80122502 * math.pow(tau, 7.5);
  return waterCriticalP * math.exp(waterCriticalT / kelvin * s);
}

/// Boiling temperature in K at pressure [pascal]; null outside the
/// triple-point–critical-point range.
double? waterBoilingPoint(double pascal) {
  if (!(pascal >= waterVaporPressure(waterTripleT)) || pascal > waterCriticalP) return null;
  // p_sat is monotonic: bisect on ln p.
  var lo = waterTripleT, hi = waterCriticalT;
  final target = math.log(pascal);
  for (var i = 0; i < 100; i++) {
    final mid = (lo + hi) / 2;
    if (math.log(waterVaporPressure(mid)) < target) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

double _log10(double x) => math.log(x) / math.ln10;
