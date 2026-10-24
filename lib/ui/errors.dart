import 'package:flutter/widgets.dart';

import '../core/chem/equation.dart';
import '../core/chem/formula.dart';
import '../core/math/expression.dart';
import 'common.dart';
import 'strings.dart';

String formulaErrorText(BuildContext context, FormulaException e) =>
    context.t(switch (e.kind) {
      FormulaErrorKind.empty => S.errEmptyFormula,
      FormulaErrorKind.unknownElement => S.errUnknownElement(e.detail),
      FormulaErrorKind.unexpectedCharacter => S.errUnexpectedChar(e.detail),
      FormulaErrorKind.unbalancedBracket => S.errBrackets,
      FormulaErrorKind.invalidNumber => S.errInvalidNumber(e.detail),
    });

String equationErrorText(BuildContext context, EquationException e) {
  switch (e.kind) {
    case EquationErrorKind.noArrow:
      return context.t(S.errNoArrow);
    case EquationErrorKind.emptySide:
      return context.t(S.errEmptySide);
    case EquationErrorKind.invalidSpecies:
      final inner = e.formulaError;
      return inner == null || inner.kind == FormulaErrorKind.empty
          ? context.t(S.errInvalidSpecies(e.detail))
          : '${context.t(S.errInvalidSpecies(e.detail))} – ${formulaErrorText(context, inner)}';
    case EquationErrorKind.cannotBalance:
      return context.t(S.errCannotBalance);
    case EquationErrorKind.multipleSolutions:
      return context.t(S.errMultipleSolutions);
  }
}

String expressionErrorText(BuildContext context, ExpressionException e) =>
    context.t(switch (e.kind) {
      ExpressionErrorKind.empty || ExpressionErrorKind.syntax => S.errSyntax,
      ExpressionErrorKind.unknownName => S.errUnknownName,
      ExpressionErrorKind.divisionByZero => S.errDivZero,
      ExpressionErrorKind.domain => S.errDomain,
      ExpressionErrorKind.overflow => S.errOverflow,
    });
