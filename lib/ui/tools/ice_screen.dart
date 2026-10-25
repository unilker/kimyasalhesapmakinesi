import 'package:flutter/material.dart';

import '../../core/chem/equation.dart';
import '../../core/chem/formula.dart';
import '../../core/ice.dart';
import '../../core/math/expression.dart';
import '../../core/solubility.dart';
import '../common.dart';
import '../errors.dart';
import '../strings.dart';
import 'registry.dart';
import 'salt_picker.dart';

class _Example {
  const _Example(this.equation, this.k, this.initial);

  final String equation;
  final String k;

  /// Initial values for the species in Q, in order.
  final List<String> initial;
}

const _examples = [
  _Example('H2 + I2 ⇌ 2HI', '54.3', ['0.5', '0.5', '0']),
  _Example('N2O4 ⇌ 2NO2', '4.63e-3', ['0.04', '0']),
  _Example('CH3COOH ⇌ H^+ + CH3COO^-', '1.8e-5', ['0.1', '0', '0']),
  _Example('NH3 + H2O(l) ⇌ NH4^+ + OH^-', '1.8e-5', ['0.1', '0', '0']),
  _Example('AgCl(s) ⇌ Ag^+ + Cl^-', '1.77e-10', ['0', '0.01']),
  _Example('N2 + 3H2 ⇌ 2NH3', '0.5', ['1', '3', '0']),
];

class IceScreen extends StatefulWidget {
  const IceScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<IceScreen> createState() => _IceScreenState();
}

class _IceScreenState extends State<IceScreen> {
  final _reaction = TextEditingController();
  final _k = TextEditingController();

  /// Initial-value fields by species label, kept while the equation is edited.
  final Map<String, TextEditingController> _initial = {};
  IceReaction? _parsed;
  IceResult? _result;
  IceReaction? _resultReaction;
  String? _error;

  @override
  void dispose() {
    _reaction.dispose();
    _k.dispose();
    for (final c in _initial.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _parse() {
    IceReaction? r;
    try {
      r = parseIceReaction(_reaction.text);
    } on Object {
      r = null;
    }
    setState(() {
      _parsed = r;
      _result = null;
      _error = null;
    });
  }

  TextEditingController _field(String label) =>
      _initial.putIfAbsent(label, TextEditingController.new);

  Future<void> _pickSalt() async {
    final s = await Navigator.of(context).push<SaltData>(MaterialPageRoute(builder: (_) => const SaltPicker()));
    if (s == null || !mounted) return;
    _reaction.text = s.equation;
    _k.text = context.nf.plain(s.ksp, digits: 4);
    _parse();
    for (final sp in _parsed!.species) {
      if (sp.inQ) _field(sp.label).text = '0';
    }
    _calculate();
  }

  void _applyExample(_Example e) {
    final dec = context.lang == 'tr' ? ',' : '.';
    _reaction.text = e.equation;
    _k.text = e.k.replaceAll('.', dec);
    _parse();
    final r = _parsed!;
    var j = 0;
    for (final s in r.species) {
      if (s.inQ) _field(s.label).text = e.initial[j++].replaceAll('.', dec);
    }
    _calculate();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final IceReaction r;
    try {
      r = parseIceReaction(_reaction.text);
    } on EquationException catch (e) {
      return setState(() {
        _result = null;
        _error = equationErrorText(context, e);
      });
    } on IceException catch (e) {
      return setState(() {
        _result = null;
        _error = _iceError(e);
      });
    }
    final k = parseNumberInput(_k.text);
    final c0 = [
      for (final s in r.species) s.inQ ? parseNumberInput(_field(s.label).text) ?? 0.0 : 0.0,
    ];
    try {
      if (k == null) throw const IceException(IceErrorKind.invalidInput);
      final res = solveIce(r.species, c0, k);
      final nf = context.nf;
      context.app.addHistory(
        toolId: widget.tool.id,
        input: '${r.equation}, K = ${nf.format(k)}; ${[
          for (var i = 0; i < r.species.length; i++)
            if (r.species[i].inQ) '${r.species[i].label}₀ = ${nf.format(c0[i])}',
        ].join(', ')}',
        result: [
          for (var i = 0; i < r.species.length; i++)
            if (r.species[i].inQ) '[${r.species[i].label}] = ${nf.format(res.equilibrium[i])}',
        ].join(', '),
      );
      setState(() {
        _parsed = r;
        _result = res;
        _resultReaction = r;
        _error = null;
      });
    } on IceException catch (e) {
      setState(() {
        _result = null;
        _error = _iceError(e);
      });
    }
  }

  String _iceError(IceException e) => context.t(switch (e.kind) {
        IceErrorKind.unbalanced => S.errUnbalancedWritten,
        IceErrorKind.noSpecies => S.errNoIceSpecies,
        IceErrorKind.noReaction => S.errNoReaction,
        IceErrorKind.invalidInput => S.errPositiveK,
      });

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final parsed = _parsed;
    final inputs = <Widget>[
      FormulaBanner(
        color: tool.color,
        formula: lang == 'tr' ? 'K = Π[ürün]^ν / Π[giren]^ν' : 'K = Π[products]^ν / Π[reactants]^ν',
        note: context.t(S.iceNote),
      ),
      TextField(
        controller: _reaction,
        autocorrect: false,
        enableSuggestions: false,
        minLines: 1,
        maxLines: 3,
        // Let vertical drags on the field scroll the page; the field still
        // follows the caret when an equation is longer than three lines.
        scrollPhysics: const NeverScrollableScrollPhysics(),
        onChanged: (_) => _parse(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: context.t(S.reactionLabel),
          hintText: context.t(S.iceReactionHint),
          prefixIcon: const Icon(Icons.sync_alt_rounded),
        ),
      ),
      InsertBar(
        controller: _reaction,
        onChanged: _parse,
        items: const [' ⇌ ', ' + ', '^', '(', ')', '(aq)', '(s)', '(g)', '(l)'],
      ),
      OutlinedButton.icon(
        onPressed: _pickSalt,
        icon: const Icon(Icons.menu_book_rounded),
        label: Text(context.t(S.pickSalt)),
      ),
      SectionTitle(context.t(S.examples)),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in _examples)
            ActionChip(label: Text(prettyEquation(e.equation)), onPressed: () => _applyExample(e)),
        ],
      ),
      if (parsed != null) ...[
        if (parsed.autoBalanced)
          Text(
            '${parsed.equation}\n${context.t(S.autoBalancedNote)}',
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        NumberField(
          controller: _k,
          label: context.t(S.equilibriumConstant),
          onChanged: (_) => setState(() => _result = null),
        ),
        SectionTitle(context.t(S.initialAmounts)),
        for (final s in parsed.species)
          if (s.inQ)
            NumberField(
              key: ValueKey('ice-${s.label}'),
              controller: _field(s.label),
              label: '[${s.label}]₀',
              onChanged: (_) => setState(() => _result = null),
            )
          else
            Text('${s.label}: ${context.t(S.pureSolidLiquid)}',
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
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
      if (_result != null && _resultReaction != null) ..._results(_resultReaction!, _result!),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  List<Widget> _results(IceReaction r, IceResult res) {
    final nf = context.nf;
    final k = parseNumberInput(_k.text) ?? 0;
    final q0 = res.q0;
    final direction = q0.isNaN
        ? null
        : (q0 - k).abs() <= 1e-9 * k
            ? S.atEquilibrium
            : (q0 < k ? S.shiftsRight : S.shiftsLeft);
    String signed(double v) => v > 0 ? '+${nf.format(v)}' : nf.format(v);
    return [
      ResultCard(
        color: widget.tool.color,
        label: context.t(S.equilibriumComposition),
        value: [
          for (var i = 0; i < r.species.length; i++)
            if (r.species[i].inQ) '[${r.species[i].label}] = ${nf.format(res.equilibrium[i])}',
        ].join('\n'),
        copyValue: [
          for (var i = 0; i < r.species.length; i++)
            if (r.species[i].inQ) '[${r.species[i].label}] = ${nf.plain(res.equilibrium[i])}',
        ].join('\n'),
        children: [
          const Divider(height: 18),
          InfoRow(context.t(S.reactionLabel), r.equation),
          InfoRow(context.t(S.extentLabel), nf.format(res.extent)),
          if (_solidMolarMass(r) case final mm? when res.extent > 0) ...[
            InfoRow(context.t(S.molarSolubilityLabel), '${nf.format(res.extent)} mol/L'),
            InfoRow(context.t(S.massSolubilityLabel), '${nf.format(res.extent * mm)} g/L'),
          ],
          InfoRow(context.t(S.initialQ), nf.format(q0)),
          if (direction != null) Text(context.t(direction)),
        ],
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < r.species.length; i++)
                if (r.species[i].inQ) ...[
                  Text(r.species[i].label,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  InfoRow(context.t(S.initialOf), nf.format(res.initial[i])),
                  InfoRow(
                    '${context.t(S.changeOf)} (${_coef(r.species[i].nu)}x)',
                    signed(r.species[i].nu * res.extent),
                  ),
                  InfoRow(context.t(S.equilibriumOf), nf.format(res.equilibrium[i])),
                  const Divider(),
                ],
            ],
          ),
        ),
      ),
    ];
  }

  String _coef(double nu) {
    final a = nu.abs();
    final s = a == a.roundToDouble() ? (a == 1 ? '' : '${a.toInt()}') : context.nf.format(a);
    return '${nu < 0 ? '−' : '+'}$s';
  }

  /// Molar mass of the salt when the reaction is the dissolution of a single
  /// pure solid (1 formula unit) into ions, else null.
  double? _solidMolarMass(IceReaction r) {
    final reactants = [for (final s in r.species) if (s.nu < 0) s];
    if (reactants.length != 1 || reactants.first.inQ || reactants.first.nu != -1) return null;
    try {
      return parseWrittenEquation(_reaction.text).reactants.first.formula.molarMass;
    } on Object {
      return null;
    }
  }
}
