import 'package:flutter/material.dart';

import '../../core/acids.dart';
import '../../core/chem/formula.dart';
import '../common.dart';
import '../layout/adaptive.dart' show MaxWidth;
import '../strings.dart';

/// Searchable list of weak acids and bases (CRC Handbook, 25 °C).
class AcidPicker extends StatefulWidget {
  const AcidPicker({super.key});

  @override
  State<AcidPicker> createState() => _AcidPickerState();
}

class _AcidPickerState extends State<AcidPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final q = _query.trim().toLowerCase();
    final list = [
      for (final a in acidTable)
        if (q.isEmpty ||
            a.name.en.toLowerCase().contains(q) ||
            a.name.tr.toLowerCase().contains(q) ||
            a.formula.toLowerCase().contains(q))
          a,
    ];
    final nf = context.nf;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(S.acidTableTitle)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              autocorrect: false,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: context.t(S.searchAcid),
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
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i == list.length) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(context.t(S.acidTableSource),
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                );
              }
              final a = list[i];
              final values = a.isBase
                  ? 'pKb ${nf.format(a.pKb!)} · pKa(BH⁺) ${nf.format(a.pKas.first)}'
                  : 'pKa ${a.pKas.map(nf.format).join(' · ')}';
              return ListTile(
                title: Text('${a.name.of(lang)}  ${prettyFormula(a.formula)}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(values),
                trailing: Icon(a.isBase ? Icons.water_drop_outlined : Icons.science_outlined),
                onTap: () => Navigator.of(context).pop(a),
              );
            },
          ),
        ),
      ),
    );
  }
}
