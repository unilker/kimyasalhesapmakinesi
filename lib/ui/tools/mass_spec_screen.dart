import 'package:flutter/material.dart';

import '../../core/chem/formula.dart';
import '../../core/format.dart';
import '../../core/isotope_pattern.dart';
import '../common.dart';
import '../errors.dart';
import '../strings.dart';
import '../widgets/xy_chart.dart';
import 'registry.dart';

class _Ion {
  const _Ion(this.label, this.delta, this.charge);

  final String label;
  final Map<String, double> delta;
  final int charge;
}

const _ions = [
  _Ion('M', {}, 0),
  _Ion('[M+H]⁺', {'H': 1}, 1),
  _Ion('[M+Na]⁺', {'Na': 1}, 1),
  _Ion('[M+K]⁺', {'K': 1}, 1),
  _Ion('[M+NH₄]⁺', {'N': 1, 'H': 4}, 1),
  _Ion('[M+2H]²⁺', {'H': 2}, 2),
  _Ion('[M−H]⁻', {'H': -1}, -1),
  _Ion('[M+Cl]⁻', {'Cl': 1}, -1),
];

const _examples = ['C8H10N4O2', 'C9H8O4', 'CH2Cl2', 'C6H5Br', 'SnCl4', 'C60', 'C254H377N65O75S6'];

class MassSpecScreen extends StatefulWidget {
  const MassSpecScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<MassSpecScreen> createState() => _MassSpecScreenState();
}

class _MassSpecScreenState extends State<MassSpecScreen> {
  final _formula = TextEditingController();
  int _ion = 0;
  IsotopePattern? _pattern;
  String? _shown;
  String? _error;

  @override
  void dispose() {
    _formula.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final ChemicalFormula f;
    try {
      f = ChemicalFormula.parse(_formula.text);
    } on FormulaException catch (e) {
      return setState(() {
        _pattern = null;
        _error = formulaErrorText(context, e);
      });
    }
    final ion = _ions[_ion];
    final target = ion.charge == 0 && ion.delta.isEmpty ? f : f.withAtoms(ion.delta, f.charge + ion.charge);
    if (target == null) {
      return setState(() {
        _pattern = null;
        _error = context.t(S.errCannotRemove);
      });
    }
    try {
      final p = isotopePattern(target);
      final shown = ion.charge == 0 ? prettyFormula(_formula.text) : '${ion.label} (${prettyFormula(_formula.text)})';
      final nf = NumberFormatter(significantDigits: 10, decimalSeparator: context.lang == 'tr' ? ',' : '.');
      context.app.addHistory(
        toolId: widget.tool.id,
        input: shown,
        result: '${p.charge == 0 ? 'M' : 'm/z'} = ${nf.format(p.monoisotopicMass)}',
      );
      setState(() {
        _pattern = p;
        _shown = shown;
        _error = null;
      });
    } on IsotopeException catch (e) {
      setState(() {
        _pattern = null;
        _error = context.t(S.errNoIsotopes(e.element));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final inputs = <Widget>[
      FormulaBanner(color: tool.color, formula: 'm/z = (M − z·mₑ) / |z|', note: context.t(S.msNote)),
      TextField(
        controller: _formula,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _calculate(),
        onChanged: (_) => setState(() => _pattern = null),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: context.t(S.formulaOrIon),
          hintText: 'C8H10N4O2',
          prefixIcon: const Icon(Icons.science_rounded),
        ),
      ),
      SectionTitle(context.t(S.ionType)),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < _ions.length; i++)
            ChoiceChip(
              label: Text(i == 0 ? context.t(S.neutralMolecule) : _ions[i].label),
              selected: _ion == i,
              onSelected: (_) {
                setState(() => _ion = i);
                if (_pattern != null) _calculate();
              },
            ),
        ],
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
    ];
    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (_pattern != null) ..._results(_pattern!),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  List<Widget> _results(IsotopePattern p) {
    final sep = context.lang == 'tr' ? ',' : '.';
    String mass(double m) => m.toStringAsFixed(6).replaceAll('.', sep);
    final nf = context.nf;
    final peaks = p.peaks;
    final shownPeaks = [for (final k in peaks) if (k.relative >= 0.1) k];
    final lo = peaks.first.mass, hi = peaks.last.mass;
    final pad = ((hi - lo) * 0.08).clamp(0.6 / (p.charge == 0 ? 1 : p.charge.abs()), 50.0);
    return [
      ResultCard(
        color: widget.tool.color,
        label: context.t(p.charge == 0 ? S.monoisotopic : S.monoisotopicMz),
        value: mass(p.monoisotopicMass),
        copyValue: p.monoisotopicMass.toStringAsFixed(6),
        children: [
          const Divider(height: 18),
          Text(_shown ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          InfoRow(context.t(S.averageMass), mass(p.averageMass)),
          InfoRow(context.t(S.nominalMass), '${p.nominalMass}'),
        ],
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
          child: XyChart(
            height: 240,
            xMin: lo - pad,
            xMax: hi + pad,
            yMin: 0,
            yMax: 100,
            xLabel: 'm/z',
            yLabel: '%',
            formatter: NumberFormatter(significantDigits: 6, decimalSeparator: sep),
            series: [
              ChartSeries(
                points: [for (final k in peaks) Offset(k.mass, k.relative)],
                color: widget.tool.color,
                bars: true,
                width: 3,
              ),
            ],
          ),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.t(S.isotopePeaks), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              for (final k in shownPeaks)
                InfoRow(
                  '${_offset(k.nominal - p.nominalMass)}  ·  ${mass(k.mass)}',
                  '${nf.format(k.relative, digits: 4)} %',
                ),
            ],
          ),
        ),
      ),
    ];
  }

  static String _offset(int d) => d == 0 ? 'M' : (d > 0 ? 'M+$d' : 'M−${-d}');
}
