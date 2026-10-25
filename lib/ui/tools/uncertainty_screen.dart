import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/uncertainty.dart';
import '../common.dart';
import '../errors.dart';
import '../strings.dart';
import 'registry.dart';

/// `value ± u` with u to two significant digits and the value rounded to the
/// same decimal place (GUM 7.2.6); null when that needs more than 12
/// decimals or none at all fits.
String? roundedWithUncertainty(double value, double u, String decimalSeparator) {
  if (!(u > 0) || !value.isFinite) return null;
  final decimals = 1 - (math.log(u) / math.ln10).floor();
  if (decimals < 0 || decimals > 12) return null;
  String f(double v) => v.toStringAsFixed(decimals).replaceAll('.', decimalSeparator).replaceFirst('-', '−');
  return '${f(value)} ± ${f(u)}';
}

class _Row {
  _Row(String name, String value, String u)
      : name = TextEditingController(text: name),
        value = TextEditingController(text: value),
        u = TextEditingController(text: u);

  final TextEditingController name, value, u;

  void dispose() {
    name.dispose();
    value.dispose();
    u.dispose();
  }
}

class UncertaintyScreen extends StatefulWidget {
  const UncertaintyScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<UncertaintyScreen> createState() => _UncertaintyScreenState();
}

class _UncertaintyScreenState extends State<UncertaintyScreen> {
  final _expr = TextEditingController(text: 'm/(M*V)');
  final _rows = <_Row>[];
  bool _monteCarlo = false;
  bool _degrees = false;
  Propagation? _result;
  MonteCarloResult? _mc;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rows.isEmpty) {
      String d(String s) => context.lang == 'tr' ? s.replaceAll('.', ',') : s;
      _rows.addAll([
        _Row('m', d('0.2502'), d('0.0002')),
        _Row('M', d('58.44'), d('0.002')),
        _Row('V', d('0.1000'), d('0.00008')),
      ]);
    }
  }

  @override
  void dispose() {
    _expr.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {
        _result = null;
        _mc = null;
      });

  void _calculate() {
    FocusScope.of(context).unfocus();
    final inputs = <UncertainInput>[];
    for (final r in _rows) {
      final name = r.name.text.trim();
      if (name.isEmpty && r.value.text.trim().isEmpty) continue;
      if (!isValidVariableName(name) || inputs.any((i) => i.name == name)) {
        return setState(() {
          _result = null;
          _error = context.t(S.errVariableName);
        });
      }
      final v = parseNumberInput(r.value.text);
      final u = r.u.text.trim().isEmpty ? 0.0 : parseNumberInput(r.u.text);
      if (v == null || u == null || u < 0) {
        return setState(() {
          _result = null;
          _error = context.t(S.errVariableValue);
        });
      }
      inputs.add(UncertainInput(name, v, u));
    }
    final mode = _degrees ? AngleMode.degrees : AngleMode.radians;
    try {
      final p = propagate(_expr.text, inputs, angleMode: mode);
      final mc = _monteCarlo ? monteCarlo(_expr.text, inputs, angleMode: mode) : null;
      final nf = context.nf;
      final sep = context.lang == 'tr' ? ',' : '.';
      context.app.addHistory(
        toolId: widget.tool.id,
        input: '${_expr.text}; ${inputs.map((i) => '${i.name} = ${nf.format(i.value)} ± ${nf.format(i.u)}').join(', ')}',
        result: roundedWithUncertainty(p.value, p.u, sep) ?? '${nf.format(p.value)} ± ${nf.format(p.u)}',
      );
      setState(() {
        _result = p;
        _mc = mc;
        _error = null;
      });
    } on ExpressionException catch (e) {
      setState(() {
        _result = null;
        _error = expressionErrorText(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final dense = const InputDecoration(isDense: true);
    final inputs = <Widget>[
      FormulaBanner(color: tool.color, formula: 'u²(y) = Σ (∂f/∂xᵢ)² u²(xᵢ)', note: context.t(S.uncNote)),
      TextField(
        controller: _expr,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (_) => _changed(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: context.t(S.uncExpression),
          prefixIcon: const Icon(Icons.functions_rounded),
        ),
      ),
      SectionTitle(context.t(S.uncVariables)),
      for (var i = 0; i < _rows.length; i++)
        Row(
          key: ObjectKey(_rows[i]),
          children: [
            SizedBox(
              width: 64,
              child: TextField(
                controller: _rows[i].name,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => _changed(),
                style: const TextStyle(fontWeight: FontWeight.w800),
                decoration: dense.copyWith(labelText: context.t(S.uncName)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _rows[i].value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                onChanged: (_) => _changed(),
                decoration: dense.copyWith(labelText: context.t(S.uncValue)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _rows[i].u,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _changed(),
                decoration: dense.copyWith(labelText: context.t(S.uncU)),
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              onPressed: _rows.length <= 1
                  ? null
                  : () => setState(() {
                        _rows.removeAt(i).dispose();
                        _result = null;
                      }),
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
          ],
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _rows.add(_Row('', '', ''))),
          icon: const Icon(Icons.add_rounded),
          label: Text(context.t(S.addVariable)),
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(context.t(S.monteCarloLabel)),
        value: _monteCarlo,
        onChanged: (v) => setState(() {
          _monteCarlo = v;
          _mc = null;
          _result = null;
        }),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(context.t(_degrees ? S.angleDeg : S.angleRad)),
        value: _degrees,
        onChanged: (v) => setState(() {
          _degrees = v;
          _result = null;
        }),
      ),
      FilledButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate_rounded),
        label: Text(context.t(S.calculate)),
        style: FilledButton.styleFrom(backgroundColor: tool.color, foregroundColor: Colors.white),
      ),
    ];
    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (_result != null) ..._results(_result!),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  List<Widget> _results(Propagation p) {
    final nf = context.nf;
    final sep = context.lang == 'tr' ? ',' : '.';
    final rounded = roundedWithUncertainty(p.value, p.u, sep);
    final mc = _mc;
    return [
      ResultCard(
        color: widget.tool.color,
        label: 'y = ${_expr.text}',
        value: rounded ?? '${nf.format(p.value)} ± ${nf.format(p.u, digits: 2)}',
        copyValue: rounded ?? '${nf.plain(p.value)} ± ${nf.plain(p.u, digits: 2)}',
        children: [
          const Divider(height: 18),
          InfoRow('y', nf.format(p.value, digits: 8)),
          InfoRow(context.t(S.combinedU), nf.format(p.u, digits: 4)),
          if (p.relative.isFinite) InfoRow(context.t(S.relativeU), '${nf.format(p.relative * 100, digits: 3)} %'),
          InfoRow(context.t(S.expandedU), nf.format(2 * p.u, digits: 3)),
          if (mc != null) ...[
            const Divider(height: 18),
            InfoRow(context.t(S.mcMeanSd), '${nf.format(mc.mean, digits: 6)} ± ${nf.format(mc.sd, digits: 3)}'),
            InfoRow(context.t(S.mcInterval), '[${nf.format(mc.low, digits: 6)}; ${nf.format(mc.high, digits: 6)}]'),
          ],
        ],
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.t(S.budgetTitle), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              for (final r in p.budget) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text('${r.name}  (∂y/∂${r.name} = ${nf.format(r.sensitivity, digits: 4)})',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text('${nf.format(r.share * 100, digits: 3)} %',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: r.share.clamp(0, 1).toDouble(),
                    minHeight: 8,
                    color: widget.tool.color,
                    backgroundColor: widget.tool.color.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    ];
  }
}
