import 'dart:math' as math;

/// Ion product of water at 25 °C.
const double _kw = 1e-14;

/// What is in the flask. The titrant is always a strong base for acids and
/// a strong acid for bases.
class Analyte {
  /// [pKas] are those of the fully protonated form HₙA, whose charge is
  /// [protonatedCharge]. A strong acid or base has no pKa values.
  /// [counterCation] is the concentration of spectator cations per mole of
  /// analyte (e.g. 2 for Na₂CO₃, 1 for NaOH).
  const Analyte._({
    required this.isAcid,
    required this.pKas,
    this.protonatedCharge = 0,
    this.counterCation = 0,
    this.counterAnion = 0,
  });

  /// HCl-like strong monoprotic acid.
  const Analyte.strongAcid() : this._(isAcid: true, pKas: const [], counterAnion: 1);

  /// NaOH-like strong monoprotic base.
  const Analyte.strongBase() : this._(isAcid: false, pKas: const [], counterCation: 1);

  /// Weak (possibly polyprotic) neutral acid HₙA, e.g. acetic or
  /// phosphoric acid.
  const Analyte.weakAcid(List<double> pKas) : this._(isAcid: true, pKas: pKas);

  /// Neutral weak base B with the pKa(s) of its conjugate acid(s) BHₙⁿ⁺,
  /// e.g. NH₃ (pKa of NH₄⁺ = 9.25).
  Analyte.weakBase(List<double> pKas)
      : this._(isAcid: false, pKas: pKas, protonatedCharge: pKas.length);

  /// Salt of a polyprotic acid, e.g. Na₂CO₃: fully deprotonated anion with
  /// [cations] sodium ions per formula unit.
  const Analyte.baseSalt(List<double> pKas, int cations)
      : this._(isAcid: false, pKas: pKas, counterCation: cations * 1.0);

  final bool isAcid;
  final List<double> pKas;
  final int protonatedCharge;
  final double counterCation;
  final double counterAnion;

  bool get isStrong => pKas.isEmpty;

  /// Protons released (acid) or taken up (base) per analyte unit at full
  /// titration — number of equivalence points.
  int get equivalents => isStrong ? 1 : pKas.length;
}

class TitrationPoint {
  const TitrationPoint(this.volume, this.pH);

  final double volume;
  final double pH;
}

/// Titration of [volume] (L) of analyte at [concentration] (mol/L) with a
/// strong titrant of [titrantConcentration] (mol/L), solved exactly from
/// the charge balance (25 °C, activities ≈ concentrations).
class Titration {
  const Titration({
    required this.analyte,
    required this.concentration,
    required this.volume,
    required this.titrantConcentration,
  });

  final Analyte analyte;
  final double concentration;
  final double volume;
  final double titrantConcentration;

  /// Titrant volumes (L) of the equivalence points.
  List<double> get equivalenceVolumes => [
        for (var k = 1; k <= analyte.equivalents; k++)
          k * concentration * volume / titrantConcentration,
      ];

  /// pH after adding [vt] litres of titrant.
  double pHAt(double vt) {
    final total = volume + vt;
    final ca = concentration * volume / total;
    final tc = titrantConcentration * vt / total;
    final a = analyte;
    final na = a.counterCation * ca + (a.isAcid ? tc : 0);
    final cl = a.counterAnion * ca + (a.isAcid ? 0 : tc);
    final logKas = [for (final p in a.pKas) -p * math.ln10];

    // Charge balance F(h) = h + Na − Kw/h − Cl + Σ charges of analyte
    // species; F increases monotonically with h.
    double f(double logH) {
      final h = math.exp(logH);
      var charge = 0.0;
      if (!a.isStrong) {
        // fraction of species HₙA, Hₙ₋₁A, … (log-space for stability)
        final n = logKas.length;
        final logBeta = List<double>.filled(n + 1, 0);
        for (var j = 1; j <= n; j++) {
          logBeta[j] = logBeta[j - 1] + logKas[j - 1] - logH;
        }
        final m = logBeta.reduce(math.max);
        var d = 0.0, weighted = 0.0;
        for (var j = 0; j <= n; j++) {
          final w = math.exp(logBeta[j] - m);
          d += w;
          weighted += w * (a.protonatedCharge - j);
        }
        charge = ca * weighted / d;
      }
      return h + na - _kw / h - cl + charge;
    }

    var lo = -18 * math.ln10, hi = 2 * math.ln10;
    for (var i = 0; i < 200; i++) {
      final mid = (lo + hi) / 2;
      if (f(mid) > 0) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return -((lo + hi) / 2) / math.ln10;
  }

  /// Curve from 0 to [maxVolume] (default 1.5 × last equivalence point).
  List<TitrationPoint> curve({double? maxVolume, int points = 400}) {
    final vmax = maxVolume ?? equivalenceVolumes.last * 1.5;
    return [
      for (var i = 0; i <= points; i++)
        TitrationPoint(vmax * i / points, pHAt(vmax * i / points)),
    ];
  }
}

/// Acid–base indicators with their colour-change pH ranges.
class Indicator {
  const Indicator(this.nameEn, this.nameTr, this.low, this.high);

  final String nameEn;
  final String nameTr;
  final double low;
  final double high;

  String name(String lang) => lang == 'tr' ? nameTr : nameEn;
}

const indicators = [
  Indicator('Thymol blue (acid range)', 'Timol mavisi (asidik aralık)', 1.2, 2.8),
  Indicator('Methyl orange', 'Metil oranj', 3.1, 4.4),
  Indicator('Bromocresol green', 'Bromkrezol yeşili', 3.8, 5.4),
  Indicator('Methyl red', 'Metil kırmızısı', 4.4, 6.2),
  Indicator('Bromothymol blue', 'Bromtimol mavisi', 6.0, 7.6),
  Indicator('Phenol red', 'Fenol kırmızısı', 6.8, 8.4),
  Indicator('Thymol blue (base range)', 'Timol mavisi (bazik aralık)', 8.0, 9.6),
  Indicator('Phenolphthalein', 'Fenolftalein', 8.2, 10.0),
  Indicator('Thymolphthalein', 'Timolftalein', 9.4, 10.6),
  Indicator('Alizarin yellow R', 'Alizarin sarısı R', 10.1, 12.0),
];

/// Indicators whose transition range contains [pH].
List<Indicator> indicatorsFor(double pH) =>
    [for (final i in indicators) if (pH >= i.low && pH <= i.high) i];
