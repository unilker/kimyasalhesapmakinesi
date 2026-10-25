import 'package:flutter/material.dart';

import '../../core/acids.dart';
import '../../core/format.dart';
import '../../core/math/expression.dart';
import '../../core/speciation.dart';
import '../../core/stats.dart' show parseNumberList;
import '../common.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/xy_chart.dart';
import 'acid_picker.dart';
import 'registry.dart';

const _colors = [Palette.red, Palette.orange, Palette.green, Palette.blue, Palette.violet];

/// HₙA, Hₙ₋₁A⁻ … Aⁿ⁻, or BH⁺ / B for a base with one pKa.
List<String> speciesLabels(int n, {bool base = false}) {
  if (base && n == 1) return ['BH⁺', 'B'];
  const sub = ['', '', '₂', '₃', '₄', '₅', '₆'];
  const sup = ['', '⁻', '²⁻', '³⁻', '⁴⁻', '⁵⁻', '⁶⁻'];
  return [
    for (var j = 0; j <= n; j++) '${n - j == 0 ? '' : 'H${sub[n - j]}'}A${sup[j]}',
  ];
}

class SpeciationScreen extends StatefulWidget {
  const SpeciationScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<SpeciationScreen> createState() => _SpeciationScreenState();
}

class _SpeciationScreenState extends State<SpeciationScreen> {
  final _pKas = TextEditingController(text: '2,16 7,21 12,32');
  final _ph = TextEditingController();
  String? _name = 'H₃PO₄';
  bool _base = false;
  List<double>? _shown;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.lang != 'tr' && _pKas.text == '2,16 7,21 12,32') _pKas.text = '2.16 7.21 12.32';
  }

  @override
  void dispose() {
    _pKas.dispose();
    _ph.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final a = await Navigator.of(context).push<AcidData>(MaterialPageRoute(builder: (_) => const AcidPicker()));
    if (a == null || !mounted) return;
    final dec = context.lang == 'tr' ? ',' : '.';
    _pKas.text = a.pKas.map((v) => v.toString().replaceAll('.', dec)).join(' ');
    _name = a.name.of(context.lang);
    _base = a.isBase;
    _calculate();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final p = parseNumberList(_pKas.text);
    if (p == null || p.isEmpty || p.length > 6) {
      return setState(() {
        _shown = null;
        _error = context.t(S.invalidPKa);
      });
    }
    p.sort();
    final ph = parseNumberInput(_ph.text);
    if (ph != null) {
      final a = speciesFractions(p, ph);
      final labels = speciesLabels(p.length, base: _base);
      final nf = context.nf;
      context.app.addHistory(
        toolId: widget.tool.id,
        input: 'pKa ${p.map(nf.format).join(' ')}, pH ${nf.format(ph)}',
        result: [for (var j = 0; j < a.length; j++) '${labels[j]} ${nf.format(a[j] * 100, digits: 4)} %'].join(', '),
      );
    }
    setState(() {
      _shown = p;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final inputs = <Widget>[
      FormulaBanner(color: tool.color, formula: 'αⱼ – pH', note: context.t(S.speciationNote)),
      OutlinedButton.icon(
        onPressed: _pick,
        icon: const Icon(Icons.menu_book_rounded),
        label: Text(context.t(S.pickFromTable)),
      ),
      TextField(
        controller: _pKas,
        onChanged: (_) => setState(() {
          _shown = null;
          _name = null;
          _base = false;
        }),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        decoration: InputDecoration(
          labelText: context.t(S.pKaList),
          helperText: _name,
        ),
      ),
      NumberField(
        controller: _ph,
        label: context.t(S.atPH),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _calculate(),
        onChanged: (_) => setState(() => _shown = null),
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
      if (_shown != null) ..._results(_shown!),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  List<Widget> _results(List<double> pKas) {
    final nf = context.nf;
    final sep = context.lang == 'tr' ? ',' : '.';
    final labels = speciesLabels(pKas.length, base: _base);
    final ph = parseNumberInput(_ph.text);
    final grid = [for (var i = 0; i <= 280; i++) i * 14 / 280];
    final curves = [for (final x in grid) speciesFractions(pKas, x)];
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
          child: Column(
            children: [
              XyChart(
                height: 260,
                yMin: 0,
                yMax: 1,
                xLabel: 'pH',
                yLabel: 'α',
                formatter: NumberFormatter(significantDigits: 3, decimalSeparator: sep),
                series: [
                  for (var j = 0; j <= pKas.length; j++)
                    ChartSeries(
                      points: [for (var i = 0; i < grid.length; i++) Offset(grid[i], curves[i][j])],
                      color: _colors[j % _colors.length],
                    ),
                ],
                markers: [
                  if (ph != null && ph >= 0 && ph <= 14)
                    for (final (j, a) in speciesFractions(pKas, ph).indexed)
                      if (a > 0.02) ChartMarker(Offset(ph, a), labels[j], _colors[j % _colors.length]),
                ],
              ),
              Wrap(
                spacing: 14,
                children: [
                  for (var j = 0; j <= pKas.length; j++)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 14, height: 4, color: _colors[j % _colors.length]),
                      const SizedBox(width: 6),
                      Text(labels[j], style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                ],
              ),
            ],
          ),
        ),
      ),
      if (ph != null)
        Builder(builder: (context) {
          final a = speciesFractions(pKas, ph);
          var dom = 0;
          for (var j = 1; j < a.length; j++) {
            if (a[j] > a[dom]) dom = j;
          }
          return ResultCard(
            color: widget.tool.color,
            label: '${context.t(S.dominantSpecies)} (pH ${nf.format(ph)})',
            value: labels[dom],
            children: [
              const Divider(height: 18),
              for (var j = 0; j < a.length; j++) InfoRow(labels[j], '${nf.format(a[j] * 100, digits: 5)} %'),
              if (!_base) InfoRow(context.t(S.meanProtonsRemoved), nf.format(meanDeprotonation(pKas, ph), digits: 4)),
            ],
          );
        }),
    ];
  }
}
