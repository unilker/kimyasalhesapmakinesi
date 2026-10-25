import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/electrochem.dart';
import '../../core/math/expression.dart';
import '../common.dart';
import '../layout/adaptive.dart' show MaxWidth;
import '../strings.dart';
import '../theme.dart';
import 'registry.dart';

class CellScreen extends StatefulWidget {
  const CellScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<CellScreen> createState() => _CellScreenState();
}

class _CellScreenState extends State<CellScreen> {
  HalfReaction _cathode = standardPotentials.firstWhere((h) => h.couple == 'Cu²⁺/Cu(s)');
  HalfReaction _anode = standardPotentials.firstWhere((h) => h.couple == 'Zn²⁺/Zn(s)');
  final _q = TextEditingController();
  CellResult? _result;
  String? _error;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _pick(bool cathode) async {
    final picked = await Navigator.of(context).push<HalfReaction>(
      MaterialPageRoute(builder: (_) => HalfReactionPicker(color: widget.tool.color, select: true)),
    );
    if (picked == null) return;
    setState(() {
      if (cathode) {
        _cathode = picked;
      } else {
        _anode = picked;
      }
      _result = null;
      _error = null;
    });
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (identical(_cathode, _anode)) {
      return setState(() {
        _result = null;
        _error = context.t(S.sameHalfReaction);
      });
    }
    final r = galvanicCell(_cathode, _anode);
    final nf = context.nf;
    context.app.addHistory(
      toolId: widget.tool.id,
      input: '${_cathode.couple} ‖ ${_anode.couple}',
      result: 'E° = ${nf.format(r.e0, digits: 5)} V; ${r.equation}',
    );
    setState(() {
      _result = r;
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
        formula: lang == 'tr' ? 'E°pil = E°katot − E°anot' : 'E°cell = E°cathode − E°anode',
        note: context.t(S.cellNote),
      ),
      _ElectrodeTile(
        label: context.t(S.cathodeLabel),
        reaction: _cathode,
        color: Palette.red,
        onTap: () => _pick(true),
      ),
      Center(
        child: IconButton.filledTonal(
          tooltip: context.t(S.swapElectrodes),
          onPressed: () => setState(() {
            final c = _cathode;
            _cathode = _anode;
            _anode = c;
            _result = null;
          }),
          icon: const Icon(Icons.swap_vert_rounded),
        ),
      ),
      _ElectrodeTile(
        label: context.t(S.anodeLabel),
        reaction: _anode,
        color: Palette.blue,
        onTap: () => _pick(false),
      ),
      NumberField(
        controller: _q,
        label: context.t(S.reactionQuotient),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _calculate(),
        onChanged: (_) => setState(() {}),
      ),
      FilledButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate_rounded),
        label: Text(context.t(S.calculate)),
        style: FilledButton.styleFrom(backgroundColor: tool.color, foregroundColor: Colors.white),
      ),
      TextButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HalfReactionPicker(color: tool.color, select: false)),
        ),
        icon: const Icon(Icons.table_rows_rounded),
        label: Text(context.t(S.showTable)),
      ),
    ];

    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (_result != null) ..._results(_result!),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  List<Widget> _results(CellResult r) {
    final nf = context.nf;
    final q = parseNumberInput(_q.text);
    final log10K = r.log10K;
    // K itself overflows a double beyond ~10³⁰⁸; show it as m × 10ᵉ.
    final exp10 = log10K.floor();
    final kText = log10K.abs() < 300
        ? nf.format(math.pow(10, log10K).toDouble())
        : '${nf.format(math.pow(10, log10K - exp10).toDouble(), digits: 4)} × 10${_sup(exp10)}';
    return [
      ResultCard(
        color: widget.tool.color,
        label: context.t(S.cellPotential),
        value: '${nf.format(r.e0, digits: 5)} V',
        copyValue: nf.plain(r.e0, digits: 5),
        children: [
          const Divider(height: 18),
          Text(context.t(S.overallReaction),
              style: TextStyle(color: context.colors.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          SelectableText(r.equation, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          InfoRow(context.t(S.electronsTransferred), '${r.electrons}'),
          InfoRow('ΔG° = −nFE°', '${nf.format(r.deltaG / 1000, digits: 5)} kJ/mol'),
          InfoRow('K (25 °C)', kText),
          InfoRow('log K', nf.format(log10K, digits: 5)),
          if (q != null && q > 0)
            InfoRow(context.t(S.cellPotentialAtQ), '${nf.format(r.potentialAt(q), digits: 5)} V'),
          const SizedBox(height: 6),
          Text(context.t(r.spontaneous ? S.spontaneousYes : S.spontaneousNo)),
        ],
      ),
    ];
  }
}

String _sup(int n) {
  const digits = '⁰¹²³⁴⁵⁶⁷⁸⁹';
  final s = n.abs().toString().split('').map((d) => digits[int.parse(d)]).join();
  return n < 0 ? '⁻$s' : s;
}

class _ElectrodeTile extends StatelessWidget {
  const _ElectrodeTile({
    required this.label,
    required this.reaction,
    required this.color,
    required this.onTap,
  });

  final String label;
  final HalfReaction reaction;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 48,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(color: context.colors.onSurfaceVariant, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(reaction.pretty, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('E° = ${context.nf.format(reaction.e0, digits: 6)} V'),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

/// Searchable table of standard reduction potentials. With [select] the
/// tapped half-reaction is returned.
class HalfReactionPicker extends StatefulWidget {
  const HalfReactionPicker({super.key, required this.color, required this.select});

  final Color color;
  final bool select;

  @override
  State<HalfReactionPicker> createState() => _HalfReactionPickerState();
}

class _HalfReactionPickerState extends State<HalfReactionPicker> {
  String _query = '';

  static String _plain(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[₀-₉]'), '')
      .replaceAll(RegExp('[⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻]'), '')
      .replaceAll(RegExp(r'[\^+\-()\s]'), '');

  bool _matches(HalfReaction h) {
    final q = _plain(_query);
    if (q.isEmpty) return true;
    final plainFormulas = [
      for (final (_, s) in [...h.oxidized, ...h.reduced]) _plain(s.formula.replaceAll(RegExp(r'\^.*'), '')),
    ];
    return plainFormulas.any((f) => f.startsWith(q)) || _plain(_subToDigits(h.pretty)).contains(q);
  }

  static String _subToDigits(String s) {
    const sub = '₀₁₂₃₄₅₆₇₈₉';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = sub.indexOf(ch);
      b.write(i >= 0 ? '$i' : ch);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final list = [for (final h in standardPotentials.reversed) if (_matches(h)) h];
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(widget.select ? S.chooseHalfReaction : S.potentialTable)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              autofocus: false,
              autocorrect: false,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: context.t(S.searchHalfReaction),
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
              final h = list[i];
              final positive = h.e0 > 0;
              return ListTile(
                title: Text(h.pretty, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (positive ? Palette.red : (h.e0 < 0 ? Palette.blue : Palette.green))
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${h.e0 > 0 ? '+' : ''}${context.nf.format(h.e0, digits: 6)} V',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                onTap: widget.select
                    ? () => Navigator.of(context).pop(h)
                    : () => copyText(context, '${h.pretty}  E° = ${context.nf.format(h.e0, digits: 6)} V'),
              );
            },
          ),
        ),
      ),
    );
  }
}
