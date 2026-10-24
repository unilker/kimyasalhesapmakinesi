import 'package:flutter/material.dart';

import '../../core/chem/empirical.dart';
import '../../core/chem/formula.dart';
import '../../core/math/expression.dart';
import '../common.dart';
import '../strings.dart';
import 'registry.dart';

class EmpiricalScreen extends StatefulWidget {
  const EmpiricalScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<EmpiricalScreen> createState() => _EmpiricalScreenState();
}

class _Row {
  final symbol = TextEditingController();
  final amount = TextEditingController();

  void dispose() {
    symbol.dispose();
    amount.dispose();
  }
}

class _EmpiricalScreenState extends State<EmpiricalScreen> {
  final List<_Row> _rows = [_Row(), _Row(), _Row()];
  final _molarMass = TextEditingController();
  EmpiricalResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rows[0].symbol.text = 'C';
    _rows[1].symbol.text = 'H';
    _rows[2].symbol.text = 'O';
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _molarMass.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final data = <String, double>{};
    for (final r in _rows) {
      final sym = r.symbol.text.trim();
      final amountText = r.amount.text.trim();
      if (sym.isEmpty && amountText.isEmpty) continue;
      final x = parseNumberInput(amountText);
      final normalized = sym.isEmpty
          ? sym
          : sym[0].toUpperCase() + sym.substring(1).toLowerCase();
      if (symbolMass(normalized) == null || x == null || x <= 0) {
        setState(() {
          _error = context.t(S.errElements);
          _result = null;
        });
        return;
      }
      data[normalized] = (data[normalized] ?? 0) + x;
    }
    if (data.isEmpty) {
      setState(() {
        _error = context.t(S.errElements);
        _result = null;
      });
      return;
    }
    final mm = parseNumberInput(_molarMass.text);
    final r = empiricalFormula(data, molarMass: mm);
    context.app.addHistory(
      toolId: widget.tool.id,
      input: [
        for (final e in data.entries) '${e.key}: ${context.nf.format(e.value)}',
        if (mm != null) 'M = ${context.nf.format(mm)} g/mol',
      ].join(', '),
      result: prettyFormula(r.formula),
    );
    setState(() {
      _result = r;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final inputs = <Widget>[
      FormulaBanner(
        color: tool.color,
        formula: 'n = m / M  →  ÷ n_min',
        note: context.t(S.empiricalHint),
      ),
      for (var i = 0; i < _rows.length; i++)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: TextField(
                controller: _rows[i].symbol,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                decoration: InputDecoration(labelText: context.t(S.symbol)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumberField(
                controller: _rows[i].amount,
                label: context.t(S.massOrPercent),
              ),
            ),
            IconButton(
              tooltip: context.t(S.delete),
              onPressed: _rows.length <= 1
                  ? null
                  : () => setState(() {
                        _rows.removeAt(i).dispose();
                      }),
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
          ],
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _rows.add(_Row())),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: Text(context.t(S.addElement)),
        ),
      ),
      NumberField(
        controller: _molarMass,
        label: context.t(S.optionalMolarMass),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _calculate(),
        trailing: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('g/mol', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
      FilledButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate_rounded),
        label: Text(context.t(S.calculate)),
        style: FilledButton.styleFrom(backgroundColor: tool.color, foregroundColor: Colors.white),
      ),
    ];

    final r = _result;
    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (r != null)
        ResultCard(
          color: tool.color,
          label: context.t(r.molecularMultiplier != null ? S.molecularFormula : S.empiricalFormula),
          value: prettyFormula(r.formula),
          copyValue: r.formula,
          children: [
            const Divider(height: 18),
            if (r.molecularMultiplier != null)
              InfoRow(
                context.t(S.empiricalFormula),
                '${prettyFormula(r.empirical)} · ${context.nf.format(r.empiricalMass)} g/mol',
              )
            else
              InfoRow(context.t(S.molarMass), '${context.nf.format(r.empiricalMass)} g/mol'),
            for (final e in r.moleRatios.entries)
              InfoRow('${context.t(S.moleRatio)} · ${e.key}', context.nf.format(e.value, digits: 4)),
          ],
        ),
    ];

    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }
}
