import 'package:flutter/material.dart';

import '../../core/chem/dbe.dart';
import '../../core/chem/element.dart';
import '../../core/chem/formula.dart';
import '../../core/constants.dart';
import '../../core/isotope_pattern.dart';
import '../../core/math/expression.dart';
import '../common.dart';
import '../errors.dart';
import '../strings.dart';
import '../theme.dart';
import 'registry.dart';

class MolarMassScreen extends StatefulWidget {
  const MolarMassScreen({super.key, required this.tool, this.initialFormula});

  final ToolInfo tool;
  final String? initialFormula;

  @override
  State<MolarMassScreen> createState() => _MolarMassScreenState();
}

class _MolarMassScreenState extends State<MolarMassScreen> {
  late final TextEditingController _formula =
      TextEditingController(text: widget.initialFormula ?? '');
  final _mass = TextEditingController();
  final _moles = TextEditingController();
  ChemicalFormula? _result;
  String? _error;

  static const _examples = [
    'H2O', 'NaCl', 'H2SO4', 'C6H12O6', 'CuSO4·5H2O', 'Ca(OH)2', //
    'KMnO4', 'K4[Fe(CN)6]', 'C2H5OH', '(NH4)2SO4',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialFormula != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _calculate());
    }
  }

  @override
  void dispose() {
    _formula.dispose();
    _mass.dispose();
    _moles.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    try {
      final f = ChemicalFormula.parse(_formula.text);
      setState(() {
        _result = f;
        _error = null;
        _mass.clear();
        _moles.clear();
      });
      context.app.addHistory(
        toolId: widget.tool.id,
        input: f.pretty,
        result: '${context.nf.format(f.molarMass)} g/mol',
      );
    } on FormulaException catch (e) {
      setState(() {
        _result = null;
        _error = formulaErrorText(context, e);
      });
    }
  }

  void _massChanged(String s) {
    final m = parseNumberInput(s);
    final f = _result;
    if (f == null) return;
    setState(() {
      _moles.text = m == null ? '' : context.nf.plain(m / f.molarMass);
    });
  }

  void _molesChanged(String s) {
    final n = parseNumberInput(s);
    final f = _result;
    if (f == null) return;
    setState(() {
      _mass.text = n == null ? '' : context.nf.plain(n * f.molarMass);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final inputs = <Widget>[
      TextField(
        controller: _formula,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _calculate(),
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          labelText: context.t(S.formula),
          hintText: context.t(S.formulaHint),
          prefixIcon: const Icon(Icons.science_rounded),
          helperText: _formula.text.trim().isEmpty ? null : prettyFormula(_formula.text),
          helperStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          suffixIcon: _formula.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => setState(() {
                    _formula.clear();
                    _result = null;
                    _error = null;
                  }),
                ),
        ),
      ),
      InsertBar(
        controller: _formula,
        items: const ['·', '(', ')', '[', ']', '^', '+', '-'],
        onChanged: () => setState(() {}),
      ),
      FilledButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate_rounded),
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
              label: Text(prettyFormula(e)),
              onPressed: () {
                _formula.text = e;
                _calculate();
              },
            ),
        ],
      ),
      Text(
        context.t(S.caseTip),
        style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
      ),
    ];

    final f = _result;
    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (f != null) ...[
        ResultCard(
          color: tool.color,
          label: '${context.t(S.molarMass)} · ${f.pretty}',
          value: '${context.nf.format(f.molarMass)} g/mol',
          copyValue: context.nf.plain(f.molarMass),
          children: [
            InfoRow(context.t(S.totalAtoms), context.nf.format(f.totalAtoms)),
            if (f.charge != 0)
              InfoRow(context.t(S.charge), f.charge > 0 ? '+${f.charge}' : '${f.charge}'),
            if (_exactMass(f) case final m?)
              InfoRow(context.t(f.charge == 0 ? S.monoisotopic : S.monoisotopicMz),
                  m.toStringAsFixed(6).replaceAll('.', context.lang == 'tr' ? ',' : '.')),
            if (doubleBondEquivalents(f) case final d?)
              InfoRow(context.t(S.dbeLabel), context.nf.format(d)),
          ],
        ),
        SectionTitle(context.t(S.composition)),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            child: Column(
              children: [for (final share in f.composition) _shareRow(share, lang)],
            ),
          ),
        ),
        SectionTitle(context.t(S.massMoles)),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                NumberField(
                  controller: _mass,
                  label: context.t(S.mass),
                  onChanged: _massChanged,
                  trailing: const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('g', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 10),
                NumberField(
                  controller: _moles,
                  label: context.t(S.moles),
                  onChanged: _molesChanged,
                  textInputAction: TextInputAction.done,
                  trailing: const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('mol', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                if (parseNumberInput(_moles.text) != null)
                  InfoRow(
                    context.t(S.particles),
                    context.nf.format(parseNumberInput(_moles.text)! * avogadro),
                  ),
              ],
            ),
          ),
        ),
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

  Widget _shareRow(ElementShare share, String lang) {
    final el = PeriodicTable.bySymbol(share.symbol);
    final b = Theme.of(context).brightness;
    final bg = el == null ? Palette.violet : categoryColor(el.category, b);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text(
              share.symbol,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: onCategoryColor(b),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${el?.name(lang) ?? share.symbol} × ${context.nf.format(share.count)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      context.percent(share.massFraction * 100),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: share.massFraction,
                    minHeight: 8,
                    color: bg,
                    backgroundColor: context.colors.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.nf.format(share.mass)} g/mol',
                  style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Monoisotopic mass (or m/z), when every element has natural isotopes and
/// the counts are whole numbers.
double? _exactMass(ChemicalFormula f) {
  try {
    return monoisotopicMass(f);
  } on IsotopeException {
    return null;
  }
}
