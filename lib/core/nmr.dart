import 'dart:math' as math;

part 'nmr_data.dart';

/// NMR properties of one nucleus (IUPAC 2001).
class NmrNucleus {
  const NmrNucleus(this.massNumber, this.symbol, this.twiceSpin, this.abundance, this.gamma, this.xi,
      this.reference);

  final int massNumber;
  final String symbol;

  /// 2I, so that I = 1/2 is stored exactly as 1.
  final int twiceSpin;

  /// Natural abundance (%).
  final double abundance;

  /// Magnetogyric ratio γ in 10⁷ rad s⁻¹ T⁻¹.
  final double gamma;

  /// Ξ (%): frequency of the reference compound relative to TMS ¹H = 100 %.
  final double xi;
  final String reference;

  double get spin => twiceSpin / 2;

  String get spinText => twiceSpin.isOdd ? '$twiceSpin/2' : '${twiceSpin ~/ 2}';

  String get label => '${_sup('$massNumber')}$symbol';

  String get key => '$massNumber$symbol';

  bool get isQuadrupolar => twiceSpin > 1;

  /// Frequency (MHz) of the reference compound on a spectrometer whose TMS
  /// ¹H resonance is at [protonMHz].
  double frequencyAt(double protonMHz) => xi / 100 * protonMHz;

  /// Larmor frequency |γ|B₀/2π in MHz for a field [tesla] (bare nucleus).
  double larmorMHz(double tesla) => gamma.abs() * 1e7 * tesla / (2 * math.pi) / 1e6;

  /// Receptivity relative to ¹H, Dₚ = |γ|³·x·I(I+1) / (γ_H³·x_H·¾).
  double get receptivityVsProton {
    final h = nmrNuclei.first;
    return math.pow(gamma.abs(), 3) * abundance * spin * (spin + 1) /
        (math.pow(h.gamma, 3) * h.abundance * h.spin * (h.spin + 1));
  }

  /// Receptivity relative to ¹³C.
  double get receptivityVsCarbon {
    final c = nmrNuclei.firstWhere((n) => n.key == '13C');
    return receptivityVsProton / c.receptivityVsProton;
  }

  static String _sup(String s) => s.split('').map((c) => '⁰¹²³⁴⁵⁶⁷⁸⁹'[int.parse(c)]).join();
}

/// Magnetic field B₀ (T) of a spectrometer with the TMS ¹H line at
/// [protonMHz], from the proton magnetogyric ratio (shielding of TMS
/// protons, ~3e-5, neglected).
double fieldForProtonMHz(double protonMHz) => 2 * math.pi * protonMHz * 1e6 / (nmrNuclei.first.gamma * 1e7);

/// Chemical-shift difference in Hz for [ppm] on a spectrometer frequency
/// [nucleusMHz] of that nucleus.
double ppmToHz(double ppm, double nucleusMHz) => ppm * nucleusMHz;
