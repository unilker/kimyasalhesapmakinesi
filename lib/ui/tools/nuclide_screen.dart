import 'package:flutter/material.dart';

import '../../core/chem/element.dart';
import '../../core/math/expression.dart';
import '../../core/nuclides.dart';
import '../common.dart';
import '../layout/adaptive.dart' show MaxWidth;
import '../strings.dart';
import 'registry.dart';

const _timeUnits = <String, double>{
  's': 1,
  'min': 60,
  'h': 3600,
  'd': 86400,
  'y': 365.2422 * 86400,
};

String _unitText(String unit, String lang) => switch (unit) {
      'ky' => lang == 'tr' ? 'bin yıl' : 'kyr',
      'My' => lang == 'tr' ? 'milyon yıl' : 'Myr',
      'Gy' => lang == 'tr' ? 'milyar yıl' : 'Gyr',
      'Ty' => lang == 'tr' ? 'trilyon yıl' : 'Tyr',
      'y' => lang == 'tr' ? 'yıl' : 'y',
      'd' => lang == 'tr' ? 'gün' : 'd',
      'h' => lang == 'tr' ? 'saat' : 'h',
      'm' => 'min',
      'us' => 'µs',
      _ => unit,
    };

class NuclideScreen extends StatefulWidget {
  const NuclideScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<NuclideScreen> createState() => _NuclideScreenState();
}

class _NuclideScreenState extends State<NuclideScreen> {
  NuclideData _n = nuclideTable.firstWhere((x) => x.key == '14C');
  final _t = TextEditingController();
  final _a0 = TextEditingController();
  String _unit = 'y';
  double? _seconds;

  @override
  void dispose() {
    _t.dispose();
    _a0.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final x = await Navigator.of(context)
        .push<NuclideData>(MaterialPageRoute(builder: (_) => const NuclidePicker()));
    if (x == null) return;
    setState(() {
      _n = x;
      _seconds = null;
    });
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final t = parseNumberInput(_t.text);
    if (t == null || t < 0) return setState(() => _seconds = null);
    final s = t * _timeUnits[_unit]!;
    final nf = context.nf;
    context.app.addHistory(
      toolId: widget.tool.id,
      input: '${_n.label}, t = ${nf.format(t)} $_unit',
      result: '${context.t(S.remainingFraction)}: ${nf.format(_n.fractionAfter(s) * 100, digits: 5)} %',
    );
    setState(() => _seconds = s);
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final inputs = <Widget>[
      FormulaBanner(color: tool.color, formula: 'N = N₀·(½)^(t/t½)   A = λN', note: context.t(S.nuclideNote)),
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
          title: Text(
            '${_n.label}  ${PeriodicTable.bySymbol(_n.symbol)?.name(lang) ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          subtitle: Text('t½ = ${_halfLife(lang)}'),
          trailing: const Icon(Icons.edit_rounded),
          onTap: _pick,
        ),
      ),
      NumberField(
        controller: _t,
        label: context.t(S.elapsedTime),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _calculate(),
        onChanged: (_) => setState(() => _seconds = null),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final u in _timeUnits.keys)
            ChoiceChip(
              label: Text(u == 'y' ? (lang == 'tr' ? 'yıl' : 'y') : u),
              selected: _unit == u,
              onSelected: (_) => setState(() {
                _unit = u;
                _seconds = null;
              }),
            ),
        ],
      ),
      NumberField(
        controller: _a0,
        label: context.t(S.initialAmountOptional),
        onChanged: (_) => setState(() {}),
      ),
      FilledButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate_rounded),
        label: Text(context.t(S.calculate)),
        style: FilledButton.styleFrom(backgroundColor: tool.color, foregroundColor: Colors.white),
      ),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: _results(lang),
    );
  }

  /// Half-life with the digits NUBASE prints and its absolute uncertainty.
  String _halfLife(String lang) {
    String dec(String v) => lang == 'tr' ? v.replaceAll('.', ',') : v;
    final unc = double.tryParse(_n.uncertainty) == null ? '' : ' ± ${dec(_n.uncertainty)}';
    return '${dec(_n.halfLifeText)}$unc ${_unitText(_n.unit, lang)}';
  }

  List<Widget> _results(String lang) {
    final nf = context.nf;
    final x = _n;
    final s = _seconds;
    final a0 = parseNumberInput(_a0.text);
    final modes = [
      for (final (code, rel, pct) in x.modes)
        '${decayModeLabel(code)} ${rel == '=' ? '' : rel}${nf.format(pct, digits: 4)} %',
    ].join(' · ');
    return [
      ResultCard(
        color: widget.tool.color,
        label: '${x.label} · ${context.t(S.halfLife)}',
        value: _halfLife(lang),
        children: [
          const Divider(height: 18),
          InfoRow(context.t(S.decayModes), modes),
          InfoRow(context.t(S.decayConstant), '${nf.format(x.lambda, digits: 5)} s⁻¹'),
          InfoRow(context.t(S.meanLife), '${nf.format(1 / x.lambda / _timeUnits[_unit]!, digits: 5)} ${_unit == 'y' && lang == 'tr' ? 'yıl' : _unit}'),
          InfoRow(context.t(S.specificActivity),
              '${nf.format(x.specificActivity, digits: 4)} Bq/g\n${nf.format(x.specificActivity / 3.7e10, digits: 4)} Ci/g'),
          InfoRow(context.t(S.atomicMassLabel), '${nf.format(x.atomicMass, digits: 10)} u'),
          if (x.abundance != null) InfoRow(context.t(S.naturalAbundance), '${nf.format(x.abundance!)} %'),
          if (s != null) ...[
            const Divider(height: 18),
            InfoRow(context.t(S.elapsedTime), context.t(S.halfLivesElapsed(nf.format(s / x.halfLifeSeconds, digits: 5)))),
            InfoRow(context.t(S.remainingFraction), '${nf.format(x.fractionAfter(s) * 100, digits: 5)} %'),
            InfoRow(context.t(S.decayedFraction), '${nf.format((1 - x.fractionAfter(s)) * 100, digits: 5)} %'),
            if (a0 != null) InfoRow(context.t(S.remainingAmount), nf.format(a0 * x.fractionAfter(s))),
          ],
        ],
      ),
    ];
  }
}

/// Searchable list of the radionuclides.
class NuclidePicker extends StatefulWidget {
  const NuclidePicker({super.key});

  @override
  State<NuclidePicker> createState() => _NuclidePickerState();
}

class _NuclidePickerState extends State<NuclidePicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final q = _q.trim().toLowerCase().replaceAll('-', '').replaceAll(' ', '');
    final list = [
      for (final x in nuclideTable)
        if (q.isEmpty ||
            x.key.toLowerCase().contains(q) ||
            '${x.symbol}${x.massNumber}'.toLowerCase().contains(q) ||
            (PeriodicTable.bySymbol(x.symbol)?.name(lang).toLowerCase().contains(q) ?? false))
          x,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(S.chooseNuclide)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              autocorrect: false,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: context.t(S.searchNuclide),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: MaxWidth(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final x = list[i];
              return ListTile(
                title: Text('${x.label}  ${PeriodicTable.bySymbol(x.symbol)?.name(lang) ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(x.modes.map((m) => decayModeLabel(m.$1)).take(3).join(', ')),
                trailing: Text(
                  '${lang == 'tr' ? x.halfLifeText.replaceAll('.', ',') : x.halfLifeText} ${_unitText(x.unit, lang)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.of(context).pop(x),
              );
            },
          ),
        ),
      ),
    );
  }
}
