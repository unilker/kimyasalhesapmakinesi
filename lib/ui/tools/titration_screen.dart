import 'package:flutter/material.dart';

import '../../core/acids.dart';
import '../../core/format.dart';
import '../../core/math/expression.dart';
import '../../core/stats.dart' show parseNumberList;
import '../../core/titration.dart';
import '../common.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/xy_chart.dart';
import 'acid_picker.dart';
import 'ph_scale.dart';
import 'registry.dart';

class _Preset {
  const _Preset(this.label, this.isAcid, this.pKas, {this.salt = 0});

  final String label;
  final bool isAcid;
  final List<double> pKas;

  /// Spectator cations per formula unit (Na₂CO₃ → 2).
  final int salt;
}

const _presets = [
  _Preset('HCl', true, []),
  _Preset('CH₃COOH', true, [4.76]),
  _Preset('H₃PO₄', true, [2.16, 7.21, 12.32]),
  _Preset('NaOH', false, []),
  _Preset('NH₃', false, [9.25]),
  _Preset('Na₂CO₃', false, [6.35, 10.33], salt: 2),
];

class TitrationScreen extends StatefulWidget {
  const TitrationScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<TitrationScreen> createState() => _TitrationScreenState();
}

class _TitrationScreenState extends State<TitrationScreen> {
  bool _acid = true;
  int _salt = 0;
  final _pKas = TextEditingController(text: '4,76');
  final _ca = TextEditingController(text: '0,1');
  final _va = TextEditingController(text: '25');
  final _ct = TextEditingController(text: '0,1');
  final _vq = TextEditingController();
  Titration? _t;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.lang != 'tr' && _ca.text == '0,1') {
      _pKas.text = '4.76';
      _ca.text = '0.1';
      _ct.text = '0.1';
    }
  }

  @override
  void dispose() {
    for (final c in [_pKas, _ca, _va, _ct, _vq]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyPreset(_Preset p) {
    final dec = context.lang == 'tr' ? ',' : '.';
    setState(() {
      _acid = p.isAcid;
      _salt = p.salt;
      _pKas.text = p.pKas.map((v) => v.toString().replaceAll('.', dec)).join(' ');
      _t = null;
    });
  }

  Future<void> _pickFromTable() async {
    final a = await Navigator.of(context).push<AcidData>(
      MaterialPageRoute(builder: (_) => const AcidPicker()),
    );
    if (a == null || !mounted) return;
    final dec = context.lang == 'tr' ? ',' : '.';
    setState(() {
      _acid = !a.isBase;
      _salt = 0;
      _pKas.text = a.pKas.map((v) => v.toString().replaceAll('.', dec)).join(' ');
      _t = null;
    });
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final pkas = parseNumberList(_pKas.text);
    final ca = parseNumberInput(_ca.text);
    final va = parseNumberInput(_va.text);
    final ct = parseNumberInput(_ct.text);
    if (pkas == null || pkas.length > 6) {
      return setState(() => _error = context.t(S.invalidPKa));
    }
    if (ca == null || va == null || ct == null || ca <= 0 || va <= 0 || ct <= 0) {
      return setState(() => _error = context.t(S.errNoSolution));
    }
    pkas.sort();
    final Analyte a;
    if (pkas.isEmpty) {
      a = _acid ? const Analyte.strongAcid() : const Analyte.strongBase();
    } else if (_acid) {
      a = Analyte.weakAcid(pkas);
    } else if (_salt > 0) {
      a = Analyte.baseSalt(pkas, _salt);
    } else {
      a = Analyte.weakBase(pkas);
    }
    final t = Titration(
      analyte: a,
      concentration: ca,
      volume: va / 1000,
      titrantConcentration: ct,
    );
    final nf = context.nf;
    context.app.addHistory(
      toolId: widget.tool.id,
      input: '${context.t(_acid ? S.analyteAcid : S.analyteBase)}, pKa: '
          '${pkas.isEmpty ? '—' : pkas.map(nf.format).join(' ')}; '
          '${nf.format(ca)} M × ${nf.format(va)} mL, titrant ${nf.format(ct)} M',
      result: [
        for (final v in t.equivalenceVolumes)
          '${nf.format(v * 1000)} mL → pH ${nf.format(t.pHAt(v), digits: 4)}',
      ].join('; '),
    );
    setState(() {
      _t = t;
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
        formula: '[H⁺] + Σcations = [OH⁻] + Σanions',
        note: context.t(S.titrationNote),
      ),
      SectionTitle(context.t(S.examples)),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in _presets)
            ActionChip(label: Text(p.label), onPressed: () => _applyPreset(p)),
        ],
      ),
      OutlinedButton.icon(
        onPressed: _pickFromTable,
        icon: const Icon(Icons.menu_book_rounded),
        label: Text(context.t(S.pickFromTable)),
      ),
      SectionTitle(context.t(S.analyte)),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final acid in [true, false])
            ChoiceChip(
              label: Text(context.t(acid ? S.analyteAcid : S.analyteBase)),
              selected: _acid == acid,
              onSelected: (_) => setState(() {
                _acid = acid;
                _salt = 0;
                _t = null;
              }),
            ),
        ],
      ),
      TextField(
        controller: _pKas,
        keyboardType: TextInputType.text,
        onChanged: (_) => setState(() {
          _salt = 0;
          _t = null;
        }),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        decoration: InputDecoration(
          labelText: context.t(S.pKaList),
          helperText: context.t(S.pKaListHint),
          helperMaxLines: 3,
        ),
      ),
      NumberField(
        controller: _ca,
        label: context.t(S.analyteConc),
        onChanged: (_) => setState(() => _t = null),
        trailing: const _UnitLabel('M'),
      ),
      NumberField(
        controller: _va,
        label: context.t(S.analyteVol),
        onChanged: (_) => setState(() => _t = null),
        trailing: const _UnitLabel('mL'),
      ),
      NumberField(
        controller: _ct,
        label: context.t(S.titrantConc),
        onChanged: (_) => setState(() => _t = null),
        trailing: const _UnitLabel('M'),
      ),
      NumberField(
        controller: _vq,
        label: context.t(S.volumeQuery),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _calculate(),
        onChanged: (_) => setState(() {}),
        trailing: const _UnitLabel('mL'),
      ),
      FilledButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.show_chart_rounded),
        label: Text(context.t(S.calculate)),
        style: FilledButton.styleFrom(backgroundColor: tool.color, foregroundColor: Colors.white),
      ),
    ];

    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (_t != null) ..._results(_t!),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  List<Widget> _results(Titration t) {
    final nf = context.nf;
    final lang = context.lang;
    final eqs = t.equivalenceVolumes;
    final curve = t.curve();
    final vq = parseNumberInput(_vq.text);
    final markers = <ChartMarker>[
      for (var i = 0; i < eqs.length; i++)
        ChartMarker(
          Offset(eqs[i] * 1000, t.pHAt(eqs[i])),
          eqs.length > 1 ? 'EP${i + 1}' : 'EP',
          Palette.orange,
        ),
      if (vq != null && vq >= 0)
        ChartMarker(Offset(vq, t.pHAt(vq / 1000)), nf.format(t.pHAt(vq / 1000), digits: 3), Palette.indigo),
    ];
    return [
      if (vq != null && vq >= 0) PhScale(ph: t.pHAt(vq / 1000)),
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
          child: XyChart(
            height: 280,
            yMin: 0,
            yMax: 14,
            xLabel: context.t(S.titrantAdded),
            yLabel: 'pH',
            formatter: NumberFormatter(significantDigits: 4, decimalSeparator: lang == 'tr' ? ',' : '.'),
            series: [
              ChartSeries(
                points: [for (final p in curve) Offset(p.volume * 1000, p.pH)],
                color: widget.tool.color,
              ),
            ],
            markers: markers,
          ),
        ),
      ),
      ResultCard(
        color: widget.tool.color,
        label: context.t(S.initialPH),
        value: nf.format(t.pHAt(0), digits: 4),
        children: [
          const Divider(height: 18),
          for (var i = 0; i < eqs.length; i++) ...[
            InfoRow(
              '${context.t(S.equivalencePoint)}${eqs.length > 1 ? ' ${i + 1}' : ''}',
              '${nf.format(eqs[i] * 1000)} mL · pH ${nf.format(t.pHAt(eqs[i]), digits: 4)}',
            ),
            if (!t.analyte.isStrong)
              InfoRow(
                context.t(S.halfEquivalence),
                'pH ${nf.format(t.pHAt(eqs[i] - eqs.first / 2), digits: 4)}',
              ),
          ],
        ],
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t(S.indicatorsLabel),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              for (var i = 0; i < eqs.length; i++) ...[
                if (eqs.length > 1)
                  Text('EP${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Builder(builder: (context) {
                  final list = indicatorsFor(t.pHAt(eqs[i]));
                  return Text(
                    list.isEmpty
                        ? context.t(S.noIndicator)
                        : list
                            .map((ind) => '${ind.name(lang)} (${nf.format(ind.low)}–${nf.format(ind.high)})')
                            .join(', '),
                  );
                }),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
    ];
  }
}

class _UnitLabel extends StatelessWidget {
  const _UnitLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
      );
}
