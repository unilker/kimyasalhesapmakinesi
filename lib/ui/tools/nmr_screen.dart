import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/nmr.dart';
import '../common.dart';
import '../layout/adaptive.dart' show MaxWidth;
import '../strings.dart';
import 'registry.dart';

const _common = ['1H', '13C', '15N', '19F', '31P', '29Si', '11B', '2H'];

class NmrScreen extends StatefulWidget {
  const NmrScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<NmrScreen> createState() => _NmrScreenState();
}

class _NmrScreenState extends State<NmrScreen> {
  final _mhz = TextEditingController(text: '400');
  final _ppm = TextEditingController();
  NmrNucleus _n = nmrNuclei.firstWhere((x) => x.key == '13C');

  @override
  void dispose() {
    _mhz.dispose();
    _ppm.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final x = await Navigator.of(context).push<NmrNucleus>(
      MaterialPageRoute(builder: (_) => const NmrNucleusPicker()),
    );
    if (x != null) setState(() => _n = x);
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final mhz = parseNumberInput(_mhz.text);
    if (mhz == null || mhz <= 0) return;
    final nf = context.nf;
    context.app.addHistory(
      toolId: widget.tool.id,
      input: '${_n.label}, ¹H ${nf.format(mhz)} MHz',
      result: '${nf.format(_n.frequencyAt(mhz), digits: 9)} MHz',
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final inputs = <Widget>[
      FormulaBanner(color: tool.color, formula: 'ν(X) = Ξ · ν(¹H, TMS)', note: context.t(S.nmrNote)),
      NumberField(
        controller: _mhz,
        label: context.t(S.spectrometer),
        onChanged: (_) => setState(() {}),
        trailing: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('MHz', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final f in [300, 400, 500, 600, 800])
            ActionChip(label: Text('$f'), onPressed: () => setState(() => _mhz.text = '$f')),
        ],
      ),
      SectionTitle(context.t(S.nucleusLabel)),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final k in _common)
            Builder(builder: (context) {
              final x = nmrNuclei.firstWhere((n) => n.key == k);
              return ChoiceChip(
                label: Text(x.label),
                selected: _n == x,
                onSelected: (_) => setState(() => _n = x),
              );
            }),
          ActionChip(
            avatar: const Icon(Icons.list_rounded, size: 18),
            label: Text(context.t(S.moreNuclei)),
            onPressed: _pick,
          ),
        ],
      ),
      NumberField(
        controller: _ppm,
        label: context.t(S.shiftPpm),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        onChanged: (_) => setState(() {}),
      ),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.calculate_rounded),
        label: Text(context.t(S.calculate)),
        style: FilledButton.styleFrom(backgroundColor: tool.color, foregroundColor: Colors.white),
      ),
    ];
    final mhz = parseNumberInput(_mhz.text);
    final results = <Widget>[
      if (mhz == null || mhz <= 0) ErrorBanner(context.t(S.errSpectrometer)) else ..._results(mhz),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  List<Widget> _results(double mhz) {
    final nf = context.nf;
    final x = _n;
    final f = x.frequencyAt(mhz);
    final ppm = parseNumberInput(_ppm.text);
    final all = [...nmrNuclei]..sort((a, b) => b.xi.compareTo(a.xi));
    return [
      ResultCard(
        color: widget.tool.color,
        label: '${x.label} · ${context.t(S.referenceFrequency)}',
        value: '${nf.format(f, digits: 9)} MHz',
        copyValue: nf.plain(f, digits: 9),
        children: [
          const Divider(height: 18),
          if (ppm != null) InfoRow('${nf.format(ppm)} ppm', '${nf.format(ppmToHz(ppm, f), digits: 6)} Hz'),
          InfoRow(context.t(S.fieldLabel), '${nf.format(fieldForProtonMHz(mhz), digits: 5)} T'),
          InfoRow(context.t(S.spinLabel), '${x.spinText}${x.isQuadrupolar ? ' (${context.t(S.quadrupolar)})' : ''}'),
          InfoRow(context.t(S.naturalAbundance), '${nf.format(x.abundance)} %'),
          InfoRow('γ', '${nf.format(x.gamma, digits: 7)} × 10⁷ rad s⁻¹ T⁻¹'),
          InfoRow(context.t(S.receptivityH), nf.format(x.receptivityVsProton, digits: 3)),
          InfoRow(context.t(S.receptivityC), nf.format(x.receptivityVsCarbon, digits: 3)),
          InfoRow(context.t(S.referenceCompound), x.reference),
        ],
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.t(S.allAtField), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              for (final n in all)
                InfoRow('${n.label}  (I = ${n.spinText})', '${nf.format(n.frequencyAt(mhz), digits: 7)} MHz',
                    onTap: () => setState(() => _n = n)),
            ],
          ),
        ),
      ),
    ];
  }
}

/// Searchable list of the NMR nuclei.
class NmrNucleusPicker extends StatefulWidget {
  const NmrNucleusPicker({super.key});

  @override
  State<NmrNucleusPicker> createState() => _NmrNucleusPickerState();
}

class _NmrNucleusPickerState extends State<NmrNucleusPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = [
      for (final n in nmrNuclei)
        if (q.isEmpty || n.key.toLowerCase().contains(q) || '${n.symbol}${n.massNumber}'.toLowerCase().contains(q)) n,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(S.nucleusLabel)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              autocorrect: false,
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: '13C, Pt, 119 …', isDense: true),
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
              final n = list[i];
              return ListTile(
                title: Text('${n.label}   I = ${n.spinText}', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${context.nf.format(n.abundance)} % · ${n.reference}'),
                trailing: Text('Ξ ${context.nf.format(n.xi, digits: 8)} %'),
                onTap: () => Navigator.of(context).pop(n),
              );
            },
          ),
        ),
      ),
    );
  }
}
