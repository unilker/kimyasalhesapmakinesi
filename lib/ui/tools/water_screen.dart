import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/water.dart';
import '../common.dart';
import '../strings.dart';
import 'registry.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _t = TextEditingController(text: '25');
  final _p = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_p.text.isEmpty) _p.text = context.lang == 'tr' ? '101,325' : '101.325';
  }

  @override
  void dispose() {
    _t.dispose();
    _p.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final t = parseNumberInput(_t.text);
    if (t == null || t < 0 || t > 100) return;
    final nf = context.nf;
    context.app.addHistory(
      toolId: widget.tool.id,
      input: '${nf.format(t)} °C',
      result: 'pKw = ${nf.format(pKwAt(t), digits: 5)}; ρ = ${nf.format(waterDensity(t) / 1000, digits: 6)} g/mL; '
          'p° = ${nf.format(waterVaporPressure(t + 273.15) / 1000, digits: 5)} kPa',
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    Widget unit(String u) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(u, style: const TextStyle(fontWeight: FontWeight.w800)),
        );
    final inputs = <Widget>[
      FormulaBanner(color: tool.color, formula: '2 H₂O ⇌ H₃O⁺ + OH⁻', note: context.t(S.waterNote)),
      NumberField(
        controller: _t,
        label: context.t(S.temperatureC),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        onChanged: (_) => setState(() {}),
        trailing: unit('°C'),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in [0, 20, 25, 37, 50, 100])
            ActionChip(label: Text('$t °C'), onPressed: () => setState(() => _t.text = '$t')),
        ],
      ),
      NumberField(
        controller: _p,
        label: context.t(S.pressureForBoiling),
        onChanged: (_) => setState(() {}),
        trailing: unit('kPa'),
      ),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.calculate_rounded),
        label: Text(context.t(S.calculate)),
        style: FilledButton.styleFrom(backgroundColor: tool.color, foregroundColor: Colors.white),
      ),
    ];
    final t = parseNumberInput(_t.text);
    final p = parseNumberInput(_p.text);
    final results = <Widget>[
      if (t == null || t < 0 || t > 100) ErrorBanner(context.t(S.errWaterTemperature)) else _atTemperature(t),
      _boiling(p),
      _table(),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  Widget _atTemperature(double t) {
    final nf = context.nf;
    final pkw = pKwAt(t);
    final ps = waterVaporPressure(t + 273.15);
    return ResultCard(
      color: widget.tool.color,
      label: '${context.t(S.neutralPh)} (${nf.format(t)} °C)',
      value: nf.format(pkw / 2, digits: 4),
      copyValue: nf.plain(pkw / 2, digits: 4),
      children: [
        const Divider(height: 18),
        InfoRow('pKw', nf.format(pkw, digits: 5)),
        InfoRow('Kw', '${nf.format(math.pow(10, -pkw).toDouble(), digits: 4)} (mol/kg)²'),
        InfoRow(context.t(S.densityWater), '${nf.format(waterDensity(t) / 1000, digits: 6)} g/mL'),
        InfoRow(context.t(S.vaporPressureLabel), '${nf.format(ps / 1000, digits: 5)} kPa'),
        InfoRow('', '${nf.format(ps / 101325 * 760, digits: 5)} mmHg'),
        InfoRow(context.t(S.permittivityLabel), nf.format(waterPermittivity(t), digits: 4)),
      ],
    );
  }

  Widget _boiling(double? kpa) {
    final nf = context.nf;
    final tb = kpa == null ? null : waterBoilingPoint(kpa * 1000);
    if (tb == null) return ErrorBanner(context.t(S.errBoilingPressure));
    return ResultCard(
      color: widget.tool.color,
      label: '${context.t(S.boilingPointAt)} ${nf.format(kpa!)} kPa',
      value: '${nf.format(tb - 273.15, digits: 5)} °C',
      copyValue: nf.plain(tb - 273.15, digits: 5),
      children: [
        const Divider(height: 18),
        InfoRow('T', '${nf.format(tb, digits: 6)} K'),
      ],
    );
  }

  Widget _table() {
    final sep = context.lang == 'tr' ? ',' : '.';
    String fixed(double v, int decimals) => v.toStringAsFixed(decimals).replaceAll('.', sep);
    const bold = TextStyle(fontWeight: FontWeight.w900);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.t(S.waterTable), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {0: FlexColumnWidth(0.8)},
              children: [
                const TableRow(children: [
                  Text('t / °C', style: bold),
                  Text('pKw', style: bold, textAlign: TextAlign.end),
                  Text('ρ / (g/mL)', style: bold, textAlign: TextAlign.end),
                  Text('p° / kPa', style: bold, textAlign: TextAlign.end),
                ]),
                for (var t = 0; t <= 100; t += 10)
                  TableRow(children: [
                    for (final (i, s) in [
                      '$t',
                      fixed(pKwAt(t.toDouble()), 3),
                      fixed(waterDensity(t.toDouble()) / 1000, 5),
                      fixed(waterVaporPressure(t + 273.15) / 1000, 3),
                    ].indexed)
                      InkWell(
                        onTap: () => setState(() => _t.text = '$t'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(s, textAlign: i == 0 ? TextAlign.start : TextAlign.end),
                        ),
                      ),
                  ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
