import 'bi.dart';

part 'acid_data.dart';

/// A weak acid HₙA, or a weak base B stored with the pKa of BH⁺.
class AcidData {
  const AcidData(this.name, this.formula, this.pKas, {this.isBase = false, this.pKb});

  final Bi name;

  /// Formula of the acid, or of the neutral base.
  final String formula;

  /// pKa values in increasing order (for a base: of its conjugate acid).
  final List<double> pKas;
  final bool isBase;

  /// Tabulated pKb of a base.
  final double? pKb;
}
