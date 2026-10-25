import 'dart:math' as math;

import 'bi.dart';
import 'chem/formula.dart';

part 'ksp_data.dart';

/// A sparingly soluble salt MₐXᵦ with its solubility product at 25 °C.
class SaltData {
  const SaltData(this.name, this.formula, this.cation, this.cations, this.anion, this.anions, this.ksp);

  final Bi name;
  final String formula;

  /// Cation formula in caret notation (`Hg2^2+`) and ions per formula unit.
  final String cation;
  final int cations;
  final String anion;
  final int anions;
  final double ksp;

  /// Dissolution equation in the app's input notation.
  String get equation => '$formula(s) ⇌ ${cations == 1 ? '' : cations}$cation + ${anions == 1 ? '' : anions}$anion';

  String get prettyEquation =>
      '${prettyFormula(formula)}(s) ⇌ ${cations == 1 ? '' : cations}${prettyFormula(cation)} + '
      '${anions == 1 ? '' : anions}${prettyFormula(anion)}';

  /// Molar solubility in pure water, s = (Ksp / (aᵃ·bᵇ))^(1/(a+b)),
  /// ignoring activity coefficients, ion pairing and hydrolysis.
  double get molarSolubility =>
      math.pow(ksp / (math.pow(cations, cations) * math.pow(anions, anions)), 1 / (cations + anions)).toDouble();
}
