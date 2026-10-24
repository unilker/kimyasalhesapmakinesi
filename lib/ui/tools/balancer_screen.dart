import 'package:flutter/material.dart';

import '../../core/chem/equation.dart';
import '../../core/chem/formula.dart';
import '../../core/math/expression.dart';
import '../common.dart';
import '../errors.dart';
import '../strings.dart';
import 'registry.dart';

class BalancerScreen extends StatefulWidget {
  const BalancerScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<BalancerScreen> createState() => _BalancerScreenState();
}

class _BalancerScreenState extends State<BalancerScreen> {
  final _input = TextEditingController();
  BalancedEquation? _eq;
  String? _error;
  final List<TextEditingController> _amounts = [];
  final List<bool> _inGrams = [];
  StoichiometryResult? _stoich;
  String? _stoichError;

  static const _examples = [
    'H2 + O2 -> H2O',
    'Fe + O2 -> Fe2O3',
    'C3H8 + O2 -> CO2 + H2O',
    'Al + H2SO4 -> Al2(SO4)3 + H2',
    'KMnO4 + HCl -> KCl + MnCl2 + H2O + Cl2',
    'Cu + HNO3 -> Cu(NO3)2 + NO + H2O',
    'MnO4^- + Fe^2+ + H^+ -> Mn^2+ + Fe^3+ + H2O',
    'C6H12O6 + O2 -> CO2 + H2O',
  ];

  @override
  void dispose() {
    _input.dispose();
    for (final c in _amounts) {
      c.dispose();
    }
    super.dispose();
  }

  void _balance() {
    FocusScope.of(context).unfocus();
    try {
      final eq = balanceEquation(_input.text);
      for (final c in _amounts) {
        c.dispose();
      }
      _amounts
        ..clear()
        ..addAll([for (final _ in eq.species) TextEditingController()]);
      _inGrams
        ..clear()
        ..addAll([for (final _ in eq.species) true]);
      setState(() {
        _eq = eq;
        _error = null;
        _stoich = null;
        _stoichError = null;
      });
      context.app.addHistory(
        toolId: widget.tool.id,
        input: _input.text.trim(),
        result: eq.pretty,
      );
    } on EquationException catch (e) {
      setState(() {
        _eq = null;
        _error = equationErrorText(context, e);
      });
    }
  }

  void _computeStoich() {
    FocusScope.of(context).unfocus();
    final eq = _eq!;
    final given = <int, double>{};
    for (var i = 0; i < eq.species.length; i++) {
      final x = parseNumberInput(_amounts[i].text);
      if (x == null || x <= 0) continue;
      given[i] = _inGrams[i] ? x / eq.species[i].formula.molarMass : x;
    }
    if (given.isEmpty) {
      setState(() {
        _stoich = null;
        _stoichError = context.t(S.enterAmount);
      });
      return;
    }
    final r = stoichiometry(eq, given);
    final nf = context.nf;
    final species = eq.species;
    context.app.addHistory(
      toolId: widget.tool.id,
      input: '${eq.pretty}; ${[
        for (final e in given.entries)
          '${species[e.key].pretty}: ${nf.format(_inGrams[e.key] ? e.value * species[e.key].formula.molarMass : e.value)} ${_inGrams[e.key] ? 'g' : 'mol'}',
      ].join(', ')}',
      result: [
        for (var i = 0; i < species.length; i++)
          if (!eq.isReactant(i)) '${species[i].pretty}: ${nf.format(r.amounts[i].mass)} g',
      ].join(', '),
    );
    setState(() {
      _stoich = r;
      _stoichError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final inputs = <Widget>[
      TextField(
        controller: _input,
        autocorrect: false,
        enableSuggestions: false,
        minLines: 1,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _balance(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: context.t(S.equation),
          hintText: context.t(S.equationHint),
          prefixIcon: const Icon(Icons.balance_rounded),
        ),
      ),
      InsertBar(
        controller: _input,
        items: const [' → ', ' + ', '^', '(', ')', '·', '(aq)', '(s)', '(g)', '(l)'],
      ),
      FilledButton.icon(
        onPressed: _balance,
        icon: const Icon(Icons.auto_fix_high_rounded),
        label: Text(context.t(S.calculate)),
        style: FilledButton.styleFrom(backgroundColor: tool.color, foregroundColor: Colors.white),
      ),
      SectionTitle(context.t(S.examples)),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in _examples)
            ActionChip(
              label: Text(prettyEquation(e)),
              onPressed: () {
                _input.text = e;
                _balance();
              },
            ),
        ],
      ),
      Text(
        context.t(S.caseTip),
        style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
      ),
    ];

    final eq = _eq;
    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (eq != null) ...[
        ResultCard(
          color: tool.color,
          label: context.t(S.balanced),
          value: eq.pretty,
          copyValue: eq.pretty,
          children: [
            const Divider(height: 18),
            for (var i = 0; i < eq.species.length; i++)
              InfoRow(
                '${eq.coefficients[i]} × ${eq.species[i].pretty}'
                '  (${context.t(eq.isReactant(i) ? S.reactants : S.products)})',
                '${context.nf.format(eq.species[i].formula.molarMass)} g/mol',
              ),
          ],
        ),
        SectionTitle(context.t(S.stoichiometry)),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.t(S.stoichHint),
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                const SizedBox(height: 12),
                for (var i = 0; i < eq.species.length; i++) ...[
                  NumberField(
                    controller: _amounts[i],
                    label: eq.species[i].pretty,
                    onChanged: (_) {
                      if (_stoich != null) setState(() => _stoich = null);
                    },
                    trailing: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(value: true, label: Text('g')),
                        ButtonSegment(value: false, label: Text('mol')),
                      ],
                      selected: {_inGrams[i]},
                      onSelectionChanged: (s) => setState(() {
                        _inGrams[i] = s.first;
                        _stoich = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                FilledButton.tonalIcon(
                  onPressed: _computeStoich,
                  icon: const Icon(Icons.calculate_rounded),
                  label: Text(context.t(S.calculate)),
                ),
              ],
            ),
          ),
        ),
        if (_stoichError != null) ErrorBanner(_stoichError!),
        if (_stoich != null) _stoichTable(eq, _stoich!, lang),
      ],
    ];

    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  Widget _stoichTable(BalancedEquation eq, StoichiometryResult r, String lang) {
    final nf = context.nf;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < eq.species.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      eq.species[i].pretty,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                    ),
                  ),
                  if (r.amounts[i].isLimiting)
                    Chip(
                      label: Text(context.t(S.limiting)),
                      backgroundColor: widget.tool.color.withValues(alpha: 0.2),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              InfoRow(
                context.t(eq.isReactant(i) ? S.consumed : S.produced),
                '${nf.format(r.amounts[i].moles)} mol  ·  ${nf.format(r.amounts[i].mass)} g',
              ),
              if ((r.amounts[i].excessMoles ?? 0) > 1e-12)
                InfoRow(
                  context.t(S.leftOver),
                  '${nf.format(r.amounts[i].excessMoles!)} mol  ·  '
                  '${nf.format(r.amounts[i].excessMoles! * eq.species[i].formula.molarMass)} g',
                ),
              if (i < eq.species.length - 1) const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}
