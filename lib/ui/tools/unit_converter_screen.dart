import 'package:flutter/material.dart';

import '../../core/math/expression.dart';
import '../../core/units.dart';
import '../common.dart';
import '../strings.dart';
import 'registry.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  Quantity _q = Quantity.pressure;
  final _value = TextEditingController(text: '1');
  final Map<Quantity, Unit> _from = {};
  final Map<Quantity, Unit> _to = {};

  Unit get _fromUnit => _from[_q] ?? units[_q]!.first;
  Unit get _toUnit => _to[_q] ?? units[_q]![1];

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _save(double v, double r) {
    context.app.addHistory(
      toolId: widget.tool.id,
      input: '${context.nf.format(v)} ${_fromUnit.symbol}',
      result: '${context.nf.format(r)} ${_toUnit.symbol}',
    );
    showInfo(context, context.t(S.savedToHistory));
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final v = parseNumberInput(_value.text);
    final result = v == null ? null : convert(v, _fromUnit, _toUnit);

    final inputs = <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final q in converterQuantities)
            ChoiceChip(
              label: Text(S.quantityName(q).of(lang)),
              selected: q == _q,
              onSelected: (_) => setState(() => _q = q),
            ),
        ],
      ),
      NumberField(
        controller: _value,
        label: context.t(S.value),
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        trailing: UnitDropdown(
          quantity: _q,
          unit: _fromUnit,
          onChanged: (u) => setState(() => _from[_q] = u),
        ),
      ),
      Center(
        child: IconButton.filledTonal(
          tooltip: '⇅',
          onPressed: () => setState(() {
            final a = _fromUnit, b = _toUnit;
            _from[_q] = b;
            _to[_q] = a;
          }),
          icon: const Icon(Icons.swap_vert_rounded),
        ),
      ),
      if (result != null)
        ResultCard(
          color: tool.color,
          label: '${context.nf.format(v!)} ${_fromUnit.symbol} =',
          value: context.nf.format(result, digits: 8),
          copyValue: context.nf.plain(result, digits: 8),
          trailing: UnitDropdown(
            quantity: _q,
            unit: _toUnit,
            onChanged: (u) => setState(() => _to[_q] = u),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _save(v, result),
                icon: const Icon(Icons.bookmark_add_rounded),
                label: Text(context.t(S.saveToHistory)),
              ),
            ),
          ],
        ),
    ];

    final results = <Widget>[
      if (v != null) ...[
        SectionTitle(S.quantityName(_q).of(lang)),
        Card(
          child: Column(
            children: [
              for (final u in units[_q]!)
                ListTile(
                  dense: true,
                  title: Text(
                    context.nf.format(convert(v, _fromUnit, u), digits: 8),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  trailing: Text(u.symbol,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: context.colors.primary)),
                  onTap: () => copyText(context, context.nf.plain(convert(v, _fromUnit, u), digits: 8)),
                ),
            ],
          ),
        ),
        Text(context.t(S.tapToCopy),
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
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
}
