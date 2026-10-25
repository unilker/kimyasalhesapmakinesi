import 'package:flutter/material.dart';

import '../../core/chem/formula.dart';
import '../../core/math/expression.dart';
import '../../core/solver.dart';
import '../../core/units.dart';
import '../common.dart';
import '../errors.dart';
import '../strings.dart';
import 'registry.dart';

typedef ResultExtraBuilder = Widget? Function(
    BuildContext context, SolverEquation equation, Values values);

/// Generic screen for formula-based tools: pick an equation, choose the
/// unknown, enter the other values in any unit and get the answer.
class SolverScreen extends StatefulWidget {
  const SolverScreen({
    super.key,
    required this.tool,
    required this.equations,
    this.resultExtra,
  });

  final ToolInfo tool;
  final List<SolverEquation> equations;
  final ResultExtraBuilder? resultExtra;

  @override
  State<SolverScreen> createState() => _SolverScreenState();
}

class _SolverScreenState extends State<SolverScreen> {
  int _eqIndex = 0;
  final Map<String, String> _targets = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, TextEditingController> _formulaControllers = {};
  final Map<String, Unit> _units = {};
  final Map<String, Unit> _resultUnits = {};
  final Map<String, String?> _fieldErrors = {};
  SolveOutcome? _outcome;
  Values _solvedValues = const {};
  String? _error;

  SolverEquation get _eq => widget.equations[_eqIndex];

  String get _target =>
      _targets[_eq.id] ?? _eq.defaultTarget ?? _eq.solvers.keys.first;

  String _key(SolverVar v) => '${_eq.id}/${v.id}';

  TextEditingController _controller(SolverVar v) =>
      _controllers.putIfAbsent(_key(v), () {
        final d = v.defaultValue;
        return TextEditingController(
          text: d == null ? '' : context.nf.plain(d, digits: 10),
        );
      });

  TextEditingController _formulaController(SolverVar v) =>
      _formulaControllers.putIfAbsent(_key(v), TextEditingController.new);

  Unit _unit(SolverVar v) => _units[_key(v)] ?? v.defaultUnit;

  Unit _resultUnit(SolverVar v) => _resultUnits[_key(v)] ?? v.defaultUnit;

  @override
  void dispose() {
    for (final c in [..._controllers.values, ..._formulaControllers.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _invalidate() {
    if (_outcome != null || _error != null) {
      setState(() {
        _outcome = null;
        _error = null;
      });
    }
  }

  void _onFormulaChanged(SolverVar v, String text) {
    double? mm;
    String? error;
    if (text.trim().isNotEmpty) {
      try {
        mm = ChemicalFormula.parse(text.trim()).molarMass;
      } on FormulaException catch (e) {
        error = formulaErrorText(context, e);
      }
    }
    setState(() {
      _fieldErrors[_key(v)] = error;
      if (mm != null && mm > 0) {
        _controller(v).text = context.nf.plain(mm, digits: 8);
        _units[_key(v)] = v.defaultUnit;
      }
      _outcome = null;
      _error = null;
    });
  }

  String _sym(SolverVar v) => v.symbolOf(context.lang);

  /// Fills the preset's values (given in each variable's default unit).
  void _applyPreset(SolverPreset p) {
    setState(() {
      p.values.forEach((id, value) {
        final v = _eq.variable(id);
        _units[_key(v)] = v.defaultUnit;
        _controller(v).text = context.nf.plain(value, digits: 10);
        if (_target == id) {
          // The preset defines this value, so solve for something else.
          _targets[_eq.id] = _eq.solvable.firstWhere((s) => !p.values.containsKey(s.id)).id;
        }
      });
      _outcome = null;
      _error = null;
    });
  }

  /// `P · Pressure`, or just `pH` when the name repeats the symbol.
  String _label(String symbol, String name) => symbol == name ? symbol : '$symbol · $name';

  /// Formats a value in [unit]; percentages follow the locale (`%5` / `5%`).
  String _withUnit(double v, Unit unit, Quantity q, {String label = ''}) {
    if (q == Quantity.percent) return context.percent(v, digits: context.app.significantDigits);
    final u = q == Quantity.dimensionless ? label : unit.symbol;
    return u.isEmpty ? context.nf.format(v) : '${context.nf.format(v)} $u';
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final lang = context.lang;
    final inputs = <String, double>{};
    final parts = <String>[];
    for (final v in _eq.variables) {
      if (v.id == _target) continue;
      final raw = _controller(v).text;
      final x = parseNumberInput(raw);
      if (x == null) {
        setState(() {
          _outcome = null;
          _error = raw.trim().isEmpty
              ? context.t(S.errMissing(_sym(v)))
              : '${context.t(S.invalidNumber)}: ${_sym(v)}';
        });
        return;
      }
      final u = _unit(v);
      inputs[v.id] = u.toBase(x);
      final formula = _formulaController(v).text.trim();
      final us = v.unitLabel.isNotEmpty ? v.unitLabel : u.symbol;
      final unitText = us.isEmpty ? '' : ' $us';
      parts.add('${_sym(v)} = ${context.nf.format(x)}$unitText'
          '${v.molarMassFromFormula && formula.isNotEmpty ? ' (${prettyFormula(formula)})' : ''}');
    }
    final outcome = solveEquation(_eq, _target, inputs);
    if (!outcome.ok) {
      final v = outcome.errorVariable == null
          ? null
          : _eq.variable(outcome.errorVariable!);
      setState(() {
        _outcome = null;
        _error = switch (outcome.error!) {
          SolveError.missingInput => context.t(S.errMissing(_sym(v!))),
          SolveError.negativeInput => context.t(S.errNegative(_sym(v!))),
          SolveError.noSolution => context.t(S.errNoSolution),
        };
      });
      return;
    }
    final tv = _eq.variable(_target);
    final ru = _resultUnit(tv);
    final resultText =
        '${_sym(tv)} = ${_withUnit(ru.fromBase(outcome.value), ru, tv.quantity, label: tv.unitLabel)}';
    context.app.addHistory(
      toolId: widget.tool.id,
      input: '${_eq.title.of(lang)}: ${parts.join(', ')}',
      result: resultText,
    );
    setState(() {
      _error = null;
      _outcome = outcome;
      _solvedValues = {...inputs, _target: outcome.value};
    });
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final eq = _eq;
    final lang = context.lang;
    final color = tool.color;
    final others = eq.variables.where((v) => v.id != _target).toList();

    final inputs = <Widget>[
      if (widget.equations.length > 1)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < widget.equations.length; i++)
              ChoiceChip(
                label: Text(widget.equations[i].title.of(lang)),
                selected: i == _eqIndex,
                onSelected: (_) => setState(() {
                  _eqIndex = i;
                  _outcome = null;
                  _error = null;
                }),
              ),
          ],
        ),
      FormulaBanner(
        color: color,
        title: eq.title.of(lang),
        formula: eq.formulaOf(lang),
        note: eq.note?.of(lang),
      ),
      if (eq.presets.isNotEmpty) ...[
        SectionTitle(context.t(S.presets)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in eq.presets)
              ActionChip(
                avatar: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(p.label.of(lang)),
                onPressed: () => _applyPreset(p),
              ),
          ],
        ),
      ],
      SectionTitle(context.t(S.solveFor)),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in eq.solvable)
            ChoiceChip(
              avatar: v.id == _target ? const Icon(Icons.help_rounded, size: 18) : null,
              label: Text(_sym(v), style: const TextStyle(fontSize: 16)),
              tooltip: v.name.of(lang),
              selected: v.id == _target,
              onSelected: (_) => setState(() {
                _targets[eq.id] = v.id;
                _outcome = null;
                _error = null;
              }),
            ),
        ],
      ),
      for (var i = 0; i < others.length; i++) _field(others[i], i == others.length - 1),
      FilledButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate_rounded),
        label: Text(context.t(S.calculate)),
        style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      ),
    ];

    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (_outcome != null) ..._resultWidgets(),
    ];

    return ToolScaffold(
      title: tool.title.of(lang),
      color: color,
      icon: tool.icon,
      inputs: inputs,
      results: results.isEmpty ? [_placeholder()] : results,
    );
  }

  Widget _placeholder() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: widget.tool.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${context.t(S.solveFor)}: ${_label(_sym(_eq.variable(_target)), _eq.variable(_target).name.of(context.lang))}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(SolverVar v, bool last) {
    final lang = context.lang;
    final label = _label(_sym(v), v.name.of(lang));
    final numberField = NumberField(
      controller: _controller(v),
      label: label,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onChanged: (_) => _invalidate(),
      onSubmitted: last ? (_) => _calculate() : null,
      trailing: v.unitLabel.isNotEmpty
          ? _UnitText(v.unitLabel)
          : UnitDropdown(
              quantity: v.quantity,
              unit: _unit(v),
              onChanged: (u) => setState(() {
                _units[_key(v)] = u;
                _outcome = null;
              }),
            ),
    );
    if (!v.molarMassFromFormula) return numberField;
    final fc = _formulaController(v);
    final f = ChemicalFormula.tryParse(fc.text.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: fc,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          onChanged: (s) => _onFormulaChanged(v, s),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          decoration: InputDecoration(
            labelText: '${context.t(S.fromFormula)} → ${_sym(v)}',
            hintText: context.t(S.formulaHint),
            prefixIcon: const Icon(Icons.science_outlined),
            errorText: _fieldErrors[_key(v)],
            helperText: f != null && fc.text.trim().isNotEmpty ? f.pretty : null,
          ),
        ),
        const SizedBox(height: 10),
        numberField,
      ],
    );
  }

  List<Widget> _resultWidgets() {
    final lang = context.lang;
    final o = _outcome!;
    final tv = _eq.variable(_target);
    final ru = _resultUnit(tv);
    final shown = ru.fromBase(o.value);
    final extraRows = <Widget>[];
    for (var i = 0; i < _eq.extras.length; i++) {
      final e = _eq.extras[i];
      final x = o.extras[i];
      if (x == null) continue;
      final u = e.defaultUnit;
      extraRows.add(InfoRow(
        _label(e.symbol, e.name.of(lang)),
        _withUnit(u.fromBase(x), u, e.quantity, label: e.unitLabel),
      ));
    }
    final extraWidget = widget.resultExtra?.call(context, _eq, _solvedValues);
    return [
      ResultCard(
        color: widget.tool.color,
        label: _label(_sym(tv), tv.name.of(lang)),
        value: tv.quantity == Quantity.percent
            ? context.percent(shown, digits: context.app.significantDigits)
            : context.nf.format(shown),
        copyValue: context.nf.plain(shown),
        trailing: tv.unitLabel.isNotEmpty
            ? _UnitText(tv.unitLabel)
            : UnitDropdown(
                quantity: tv.quantity,
                unit: ru,
                onChanged: (u) => setState(() => _resultUnits[_key(tv)] = u),
              ),
        children: [
          if (extraRows.isNotEmpty) ...[
            const Divider(height: 18),
            ...extraRows,
          ],
        ],
      ),
      ?extraWidget,
    ];
  }
}

/// Fixed unit text shown where a unit dropdown would be.
class _UnitText extends StatelessWidget {
  const _UnitText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      );
}
