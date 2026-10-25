import 'package:flutter/material.dart';

import '../../core/solubility.dart';
import '../common.dart';
import '../layout/adaptive.dart' show MaxWidth;
import '../strings.dart';

/// Searchable list of sparingly soluble salts with Ksp (CRC Handbook, 25 °C).
class SaltPicker extends StatefulWidget {
  const SaltPicker({super.key});

  @override
  State<SaltPicker> createState() => _SaltPickerState();
}

class _SaltPickerState extends State<SaltPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final q = _query.trim().toLowerCase();
    final list = [
      for (final s in kspTable)
        if (q.isEmpty ||
            s.name.en.toLowerCase().contains(q) ||
            s.name.tr.toLowerCase().contains(q) ||
            s.formula.toLowerCase().contains(q))
          s,
    ];
    final nf = context.nf;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(S.kspTableTitle)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              autocorrect: false,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: context.t(S.searchSalt),
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
                  child: Text(context.t(S.kspSource),
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                );
              }
              final s = list[i];
              return ListTile(
                title: Text(s.name.of(lang), style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(s.prettyEquation),
                trailing: Text('Ksp ${nf.format(s.ksp, digits: 3)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.of(context).pop(s),
              );
            },
          ),
        ),
      ),
    );
  }
}
