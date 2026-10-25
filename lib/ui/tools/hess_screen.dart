import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/chem/equation.dart';
import '../../core/chem/formula.dart';
import '../../core/bi.dart';
import '../../core/math/expression.dart';
import '../../core/thermochem.dart';
import '../common.dart';
import '../errors.dart';
import '../strings.dart';
import 'registry.dart';

const _examples = [
  'CH4 + O2 -> CO2 + H2O(l)',
  'C6H12O6(s) + O2 -> CO2 + H2O(l)',
  'C2H5OH(l) + O2 -> CO2 + H2O(l)',
  'N2 + 3H2 -> 2NH3',
  'CaCO3(s) -> CaO(s) + CO2(g)',
  'NH4NO3(s) -> NH4^+ + NO3^-',
  'AgCl(s) -> Ag^+ + Cl^-',
  '2NO2 -> N2O4(g)',
];

class HessScreen extends StatefulWidget {
  const HessScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<HessScreen> createState() => _HessScreenState();
}

class _HessScreenState extends State<HessScreen> {
  final _reaction = TextEditingController();
  final _t = TextEditingController(text: '298.15');
  ThermoReaction? _parsed;
  List<List<ThermoEntry>> _candidates = [];
  List<ThermoEntry?> _chosen = [];
  ThermoResult? _result;
  double? _resultT;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.lang == 'tr' && _t.text == '298.15') _t.text = '298,15';
  }

  @override
  void dispose() {
    _reaction.dispose();
    _t.dispose();
    super.dispose();
  }

  void _parse() {
    ThermoReaction? r;
    try {
      r = parseThermoReaction(_reaction.text);
    } on Object {
      r = null;
    }
    setState(() {
      _parsed = r;
      _candidates = r == null ? [] : [for (final s in r.species) thermoCandidates(s)];
      _chosen = [for (final c in _candidates) c.isEmpty ? null : c.first];
      _result = null;
      _error = null;
    });
  }

  void _example(String e) {
    _reaction.text = e;
    _parse();
    _calculate();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final ThermoReaction r;
    try {
      r = parseThermoReaction(_reaction.text);
    } on EquationException catch (e) {
      return setState(() {
        _result = null;
        _error = equationErrorText(context, e);
      });
    } on ThermoException {
      return setState(() {
        _result = null;
        _error = context.t(S.errUnbalancedThermo);
      });
    }
    if (_parsed == null || _parsed!.species.length != r.species.length) _parse();
    final missing = [
      for (var i = 0; i < r.species.length; i++)
        if (_chosen[i] == null) r.species[i].pretty,
    ];
    if (missing.isNotEmpty) {
      return setState(() {
        _result = null;
        _error = '${context.t(S.errNotInTable)}${missing.join(', ')}';
      });
    }
    final t = parseNumberInput(_t.text);
    if (t == null || t <= 0) {
      return setState(() {
        _result = null;
        _error = context.t(S.errNoSolution);
      });
    }
    final res = ThermoResult([for (final e in _chosen) e!], r.nu);
    final nf = context.nf;
    context.app.addHistory(
      toolId: widget.tool.id,
      input: _equationText(r),
      result: 'ΔH° = ${nf.format(res.deltaH, digits: 5)} kJ, ΔS° = ${nf.format(res.deltaS, digits: 5)} J/K, '
          'ΔG°(${nf.format(t)} K) = ${nf.format(res.deltaG(t), digits: 5)} kJ',
    );
    setState(() {
      _result = res;
      _resultT = t;
      _error = null;
    });
  }

  String _equationText(ThermoReaction r) {
    String coef(double c) => c == 1 ? '' : (c == c.roundToDouble() ? '${c.toInt()}' : context.nf.format(c));
    String side(bool reactants) => [
          for (var i = 0; i < r.species.length; i++)
            if ((r.nu[i] < 0) == reactants)
              '${coef(r.nu[i].abs())}${_chosen.length > i && _chosen[i] != null ? _chosen[i]!.pretty : r.species[i].pretty}',
        ].join(' + ');
    return '${side(true)} → ${side(false)}';
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final parsed = _parsed;
    final inputs = <Widget>[
      FormulaBanner(
        color: tool.color,
        formula: 'ΔG° = ΔH° − TΔS°',
        note: context.t(S.hessNote),
      ),
      TextField(
        controller: _reaction,
        autocorrect: false,
        enableSuggestions: false,
        minLines: 1,
        maxLines: 3,
        scrollPhysics: const NeverScrollableScrollPhysics(),
        onChanged: (_) => _parse(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: context.t(S.reactionLabel),
          hintText: 'CH4 + O2 -> CO2 + H2O(l)',
          prefixIcon: const Icon(Icons.local_fire_department_rounded),
        ),
      ),
      InsertBar(
        controller: _reaction,
        onChanged: _parse,
        items: const [' → ', ' + ', '^', '(', ')', '(s)', '(l)', '(g)', '(aq)'],
      ),
      SectionTitle(context.t(S.examples)),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in _examples)
            ActionChip(label: Text(prettyEquation(e)), onPressed: () => _example(e)),
        ],
      ),
      if (parsed != null) ...[
        if (parsed.autoBalanced)
          Text(
            '${_equationText(parsed)}\n${context.t(S.autoBalancedNote)}',
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        SectionTitle(context.t(S.speciesData)),
        for (var i = 0; i < parsed.species.length; i++) _speciesRow(i, lang),
        NumberField(
          controller: _t,
          label: context.t(S.temperatureK),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _calculate(),
          onChanged: (_) => setState(() => _result = null),
          trailing: const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('K', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        FilledButton.icon(
          onPressed: _calculate,
          icon: const Icon(Icons.calculate_rounded),
          label: Text(context.t(S.calculate)),
          style: FilledButton.styleFrom(backgroundColor: tool.color, foregroundColor: Colors.white),
        ),
      ],
    ];
    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (_result != null) ..._results(_result!, _resultT!),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  Widget _speciesRow(int i, String lang) {
    final species = _parsed!.species[i];
    final options = _candidates[i];
    final nf = context.nf;
    final chosen = _chosen[i];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (options.isEmpty)
              Text('${context.t(S.errNotInTable)}${species.pretty}',
                  style: TextStyle(color: context.colors.error, fontWeight: FontWeight.w700))
            else if (options.length == 1)
              Text(options.first.label(lang), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))
            else
              DropdownButton<ThermoEntry>(
                key: ValueKey('hess-$i'),
                isExpanded: true,
                value: chosen,
                underline: const SizedBox.shrink(),
                items: [
                  for (final e in options)
                    DropdownMenuItem(
                      value: e,
                      child: Text(e.label(lang),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                ],
                onChanged: (e) => setState(() {
                  _chosen[i] = e;
                  _result = null;
                }),
              ),
            if (chosen != null)
              Text(
                'ΔfH° = ${nf.format(chosen.dfH)} kJ/mol · S° = ${nf.format(chosen.s)} J/(K·mol) · '
                '${chosen.source.name.toUpperCase()}',
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(ThermoResult r, double t) {
    final nf = context.nf;
    final u = r.uncertainty;
    String pm(double v, double? unc, String unit) =>
        '${nf.format(v, digits: 5)}${unc == null ? '' : ' ± ${nf.format(unc, digits: 2)}'} $unit';
    String kText(double log10K) {
      if (log10K.abs() < 300) return nf.format(math.pow(10, log10K).toDouble(), digits: 4);
      final e = log10K.floor();
      return '${nf.format(math.pow(10, log10K - e).toDouble(), digits: 3)} × 10${toSuperscript('$e')}';
    }

    final h = r.deltaH, s = r.deltaS;
    final cross = r.crossover;
    final Bi verdict;
    if (h < 0 && s > 0) {
      verdict = S.alwaysSpontaneous;
    } else if (h > 0 && s < 0) {
      verdict = S.neverSpontaneous;
    } else if (cross != null) {
      final ct = '${nf.format(cross, digits: 5)} K (${nf.format(cross - 273.15, digits: 4)} °C)';
      verdict = h < 0 ? S.spontaneousBelow(ct) : S.spontaneousAbove(ct);
    } else {
      verdict = h < 0 ? S.alwaysSpontaneous : S.neverSpontaneous;
    }
    final at298 = (t - 298.15).abs() < 1e-9;
    return [
      ResultCard(
        color: widget.tool.color,
        label: 'ΔG° (${nf.format(298.15)} K)',
        value: '${nf.format(r.deltaG(), digits: 5)} kJ/mol',
        copyValue: nf.plain(r.deltaG(), digits: 5),
        children: [
          const Divider(height: 18),
          SelectableText(_equationText(_parsed!),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          InfoRow('ΔH°', pm(h, u?.$1, 'kJ/mol')),
          InfoRow('ΔS°', pm(s, u?.$2, 'J/(K·mol)')),
          InfoRow('K (${nf.format(298.15)} K)', kText(r.log10K())),
          if (!at298) ...[
            const Divider(height: 18),
            Text(context.t(S.atTemperature),
                style: const TextStyle(fontWeight: FontWeight.w900)),
            InfoRow('ΔG° (${nf.format(t)} K)', '${nf.format(r.deltaG(t), digits: 5)} kJ/mol'),
            InfoRow('K (${nf.format(t)} K)', kText(r.log10K(t))),
          ],
          const SizedBox(height: 6),
          Text(context.t(verdict)),
        ],
      ),
    ];
  }
}
