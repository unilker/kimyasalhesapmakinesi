import 'bi.dart';
import 'units.dart';

/// Values of an equation's variables, in base units (see [Quantity]).
typedef Values = Map<String, double>;
typedef SolveFn = double Function(Values v);

class SolverVar {
  const SolverVar(
    this.id,
    this.symbol,
    this.name,
    this.quantity, {
    this.unit,
    this.allowNegative = false,
    this.defaultValue,
    this.molarMassFromFormula = false,
    this.symbolTr,
  });

  final String id;

  /// Display symbol, e.g. `P₁`.
  final String symbol;

  /// Turkish symbol when it differs (subscript words such as `m_çözücü`).
  final String? symbolTr;

  String symbolOf(String languageCode) =>
      languageCode == 'tr' ? (symbolTr ?? symbol) : symbol;
  final Bi name;
  final Quantity quantity;

  /// Default unit id; first unit of [quantity] when null.
  final String? unit;
  final bool allowNegative;

  /// Pre-filled value expressed in the default unit.
  final double? defaultValue;

  /// When true the UI offers a chemical formula field that fills this
  /// molar mass automatically.
  final bool molarMassFromFormula;

  Unit get defaultUnit => unit == null
      ? units[quantity]!.first
      : unitById(quantity, unit!);
}

/// An additional value derived from a solved equation (e.g. pOH next to pH).
class SolverExtra {
  const SolverExtra(
    this.symbol,
    this.name,
    this.quantity,
    this.compute, {
    this.unit,
    this.unitLabel = '',
  });

  final String symbol;
  final Bi name;
  final Quantity quantity;
  final String? unit;

  /// Unit text for dimensionless extras (e.g. `cm⁻¹`).
  final String unitLabel;
  final SolveFn compute;

  Unit get defaultUnit => unit == null
      ? units[quantity]!.first
      : unitById(quantity, unit!);
}

/// Ready-made values (e.g. van der Waals constants of a gas), expressed in
/// each variable's default unit.
class SolverPreset {
  const SolverPreset(this.label, this.values);

  final Bi label;
  final Map<String, double> values;
}

class SolverEquation {
  const SolverEquation({
    required this.id,
    required this.title,
    required this.formula,
    this.formulaTr,
    required this.variables,
    required this.solvers,
    this.extras = const [],
    this.note,
    this.defaultTarget,
    this.presets = const [],
  });

  final String id;
  final Bi title;

  /// Equation as displayed, e.g. `PV = nRT`.
  final String formula;
  final String? formulaTr;

  String formulaOf(String languageCode) =>
      languageCode == 'tr' ? (formulaTr ?? formula) : formula;
  final List<SolverVar> variables;

  /// Closed-form solution for each solvable variable id.
  final Map<String, SolveFn> solvers;
  final List<SolverExtra> extras;
  final Bi? note;
  final String? defaultTarget;
  final List<SolverPreset> presets;

  List<SolverVar> get solvable =>
      variables.where((v) => solvers.containsKey(v.id)).toList();

  SolverVar variable(String id) => variables.firstWhere((v) => v.id == id);
}

enum SolveError { missingInput, negativeInput, noSolution }

class SolveOutcome {
  const SolveOutcome.success(this.value, this.extras)
      : error = null,
        errorVariable = null;
  const SolveOutcome.failure(this.error, [this.errorVariable])
      : value = double.nan,
        extras = const [];

  final double value;
  final List<double?> extras;
  final SolveError? error;
  final String? errorVariable;

  bool get ok => error == null;
}

/// Solves [eq] for [target] given the other variables (base units).
SolveOutcome solveEquation(SolverEquation eq, String target, Values inputs) {
  final values = <String, double>{};
  for (final v in eq.variables) {
    if (v.id == target) continue;
    final x = inputs[v.id];
    if (x == null || x.isNaN) {
      return SolveOutcome.failure(SolveError.missingInput, v.id);
    }
    if (!v.allowNegative && x < 0) {
      return SolveOutcome.failure(SolveError.negativeInput, v.id);
    }
    values[v.id] = x;
  }
  final double result;
  try {
    result = eq.solvers[target]!(values);
  } catch (_) {
    return const SolveOutcome.failure(SolveError.noSolution);
  }
  final t = eq.variable(target);
  if (!result.isFinite || (!t.allowNegative && result < 0)) {
    return const SolveOutcome.failure(SolveError.noSolution);
  }
  values[target] = result;
  final extras = [
    for (final e in eq.extras)
      () {
        try {
          final r = e.compute(values);
          return r.isFinite ? r : null;
        } catch (_) {
          return null;
        }
      }(),
  ];
  return SolveOutcome.success(result, extras);
}
