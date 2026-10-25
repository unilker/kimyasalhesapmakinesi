import 'dart:math' as math;

import 'constants.dart';

part 'nuclide_data.dart';

/// Seconds per NUBASE half-life unit (1 y = 365.2422 d).
const Map<String, double> _unitSeconds = {
  'ys': 1e-24, 'zs': 1e-21, 'as': 1e-18, 'fs': 1e-15, 'ps': 1e-12, 'ns': 1e-9, 'us': 1e-6, 'ms': 1e-3,
  's': 1, 'm': 60, 'h': 3600, 'd': 86400,
  'y': 365.2422 * 86400, 'ky': 365.2422 * 86400 * 1e3, 'My': 365.2422 * 86400 * 1e6,
  'Gy': 365.2422 * 86400 * 1e9, 'Ty': 365.2422 * 86400 * 1e12, 'Py': 365.2422 * 86400 * 1e15,
  'Ey': 365.2422 * 86400 * 1e18,
};

/// A radionuclide with its NUBASE2020 half-life and decay modes.
class NuclideData {
  const NuclideData(this.symbol, this.massNumber, this.atomicNumber, this.isomer, this.atomicMass,
      this.halfLifeText, this.unit, this.uncertainty, this.modes, this.abundance);

  final String symbol;
  final int massNumber;
  final int atomicNumber;

  /// `m` for a metastable isomer (⁹⁹ᵐTc), else empty.
  final String isomer;

  /// Atomic mass in u.
  final double atomicMass;

  /// Half-life as printed in NUBASE, its unit and uncertainty (last digits).
  final String halfLifeText;
  final String unit;
  final String uncertainty;

  /// Decay modes: (NUBASE code, relation =, ~, <, >, branching %).
  final List<(String, String, double)> modes;

  /// Natural isotopic abundance (%), when the nuclide occurs in nature.
  final double? abundance;

  double get halfLifeSeconds => double.parse(halfLifeText) * _unitSeconds[unit]!;

  /// Decay constant λ = ln 2 / t½ (s⁻¹).
  double get lambda => math.ln2 / halfLifeSeconds;

  /// Activity of one gram of the pure nuclide (Bq/g).
  double get specificActivity => lambda * avogadro / atomicMass;

  /// Fraction left after [seconds].
  double fractionAfter(double seconds) => math.pow(0.5, seconds / halfLifeSeconds).toDouble();

  /// Name like ⁹⁹ᵐTc.
  String get label => '${_sup('$massNumber')}${isomer == 'm' ? 'ᵐ' : ''}$symbol';

  /// Plain search key like 99mTc.
  String get key => '$massNumber$isomer$symbol';

  static String _sup(String s) => s.split('').map((c) => '⁰¹²³⁴⁵⁶⁷⁸⁹'[int.parse(c)]).join();
}

/// Readable decay mode. In NUBASE `B+` is the sum of positron emission
/// (`e+`) and electron capture (`EC`), i.e. ε.
String decayModeLabel(String code) => switch (code) {
      'B-' => 'β⁻',
      'B+' => 'ε (β⁺ + EC)',
      'e+' => 'β⁺',
      'EC' => 'EC',
      'EC+B+' => 'ε (β⁺ + EC)',
      'A' => 'α',
      'IT' => 'IT',
      'SF' => 'SF',
      '2B-' => '2β⁻',
      'B-n' => 'β⁻n',
      '14C' => '¹⁴C',
      _ => code,
    };
