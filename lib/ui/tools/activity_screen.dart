import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/activity.dart';
import '../../core/conductivity.dart';
import '../../core/math/expression.dart';
import '../common.dart';
import '../layout/adaptive.dart' show MaxWidth;
import '../strings.dart';
import 'registry.dart';

class _IonRow {
  _IonRow(this.ion, String c)
      : c = TextEditingController(text: c),
        z = TextEditingController(text: ion == null ? '' : '${ion.charge}'),
        size = TextEditingController(text: ion == null ? '' : ion.sizePm.toStringAsFixed(0));

  /// Null for an ion entered by hand (charge and size fields).
  KiellandIon? ion;
  final TextEditingController c, z, size;

  void dispose() {
    c.dispose();
    z.dispose();
    size.dispose();
  }
}

/// One ion of the computed solution.
class _Ion {
  const _Ion(this.label, this.c, this.z, this.sizePm);

  final String label;
  final double c;
  final int z;
  final double? sizePm;
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _t = TextEditingController(text: '25');
  final _saltC = TextEditingController();
  final _rows = <_IonRow>[];
  List<_Ion>? _ions;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rows.isEmpty) {
      String d(String s) => context.lang == 'tr' ? s.replaceAll('.', ',') : s;
      _saltC.text = d('0.01');
      _rows.addAll([
        _IonRow(kiellandIon('Mg²⁺'), d('0.01')),
        _IonRow(kiellandIon('SO₄²⁻'), d('0.01')),
      ]);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _saltC.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() => _ions = null);

  void _addSalt(SaltPreset s) {
    final c = parseNumberInput(_saltC.text);
    if (c == null || c <= 0) {
      setState(() => _error = context.t(S.errSaltConc));
      return;
    }
    final nf = context.nf;
    setState(() {
      for (final (f, n) in s.ions) {
        final ion = kiellandIon(f);
        final existing = _rows.where((r) => r.ion == ion).firstOrNull;
        if (existing != null) {
          final old = parseNumberInput(existing.c.text) ?? 0;
          existing.c.text = nf.plain(old + n * c);
        } else {
          _rows.add(_IonRow(ion, nf.plain(n * c)));
        }
      }
      _error = null;
      _ions = null;
    });
  }

  Future<void> _pick(_IonRow r) async {
    final x = await Navigator.of(context).push<Object>(
      MaterialPageRoute(builder: (_) => const KiellandIonPicker()),
    );
    if (x == null) return;
    setState(() {
      if (x is KiellandIon) {
        r.ion = x;
        r.z.text = '${x.charge}';
        r.size.text = x.sizePm.toStringAsFixed(0);
      } else {
        r.ion = null;
      }
      _ions = null;
    });
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final t = parseNumberInput(_t.text);
    if (t == null || t < 0 || t > 100) {
      return setState(() {
        _ions = null;
        _error = context.t(S.errWaterTemperature);
      });
    }
    final ions = <_Ion>[];
    for (final r in _rows) {
      if (r.c.text.trim().isEmpty) continue;
      final c = parseNumberInput(r.c.text);
      final z = r.ion?.charge ?? int.tryParse(r.z.text.trim().replaceFirst('+', '').replaceFirst('−', '-'));
      final size = r.ion?.sizePm ?? (r.size.text.trim().isEmpty ? null : parseNumberInput(r.size.text));
      if (c == null || c < 0 || z == null || z == 0 || z.abs() > 6 || (size != null && size <= 0)) {
        return setState(() {
          _ions = null;
          _error = context.t(S.errIonRow);
        });
      }
      ions.add(_Ion(r.ion?.formula ?? 'z = ${z > 0 ? '+' : ''}$z', c, z, size));
    }
    if (ions.isEmpty) {
      return setState(() {
        _ions = null;
        _error = context.t(S.errIonRow);
      });
    }
    final dh = DebyeHuckel(t);
    final i = ionicStrength(ions.map((x) => (x.c, x.z)));
    final nf = context.nf;
    context.app.addHistory(
      toolId: widget.tool.id,
      input: '${ions.map((x) => '${x.label} ${nf.format(x.c)} M').join(', ')}; ${nf.format(t)} °C',
      result: 'I = ${nf.format(i)} M; ${ions.map((x) => 'γ(${x.label}) = ${nf.format(_gamma(dh, x, i), digits: 3)}').join(', ')}',
    );
    setState(() {
      _error = null;
      _ions = ions;
    });
  }

  /// Extended Debye–Hückel when the ion size is known, otherwise Davies.
  double _gamma(DebyeHuckel dh, _Ion x, double i) =>
      math.pow(10, x.sizePm != null ? dh.logExtended(x.z, x.sizePm!, i) : dh.logDavies(x.z, i)).toDouble();

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    const dense = InputDecoration(isDense: true);
    final inputs = <Widget>[
      FormulaBanner(
        color: tool.color,
        formula: 'I = ½ Σ cᵢzᵢ²\nlog γ = −A z² √I / (1 + B α √I)',
        note: context.t(S.activityNote),
      ),
      NumberField(
        controller: _t,
        label: context.t(S.temperatureC),
        onChanged: (_) => _changed(),
        trailing: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('°C', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
      SectionTitle(context.t(S.ionsLabel)),
      for (var k = 0; k < _rows.length; k++)
        Builder(
          key: ObjectKey(_rows[k]),
          builder: (context) {
            final r = _rows[k];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 112,
                  child: OutlinedButton(
                    onPressed: () => _pick(r),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14)),
                    child: Text(
                      r.ion?.formula ?? context.t(S.customIon),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (r.ion == null) ...[
                  SizedBox(
                    width: 52,
                    child: TextField(
                      controller: r.z,
                      keyboardType: const TextInputType.numberWithOptions(signed: true),
                      onChanged: (_) => _changed(),
                      decoration: dense.copyWith(labelText: 'z'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: r.size,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _changed(),
                      decoration: dense.copyWith(labelText: 'α / pm'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextField(
                    controller: r.c,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _changed(),
                    decoration: dense.copyWith(labelText: 'c / (mol/L)'),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: _rows.length <= 1
                      ? null
                      : () => setState(() {
                            _rows.removeAt(k).dispose();
                            _ions = null;
                          }),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
              ],
            );
          },
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _rows.add(_IonRow(kiellandIon('Na⁺'), ''))),
          icon: const Icon(Icons.add_rounded),
          label: Text(context.t(S.addIon)),
        ),
      ),
      SectionTitle(context.t(S.addSalt)),
      NumberField(
        controller: _saltC,
        label: context.t(S.saltConcentration),
        trailing: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('mol/L', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in saltPresets)
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: Text(s.label),
              onPressed: () => _addSalt(s),
            ),
          ActionChip(
            avatar: const Icon(Icons.clear_all_rounded, size: 18),
            label: Text(context.t(S.clearIons)),
            onPressed: () => setState(() {
              for (final r in _rows) {
                r.dispose();
              }
              _rows
                ..clear()
                ..add(_IonRow(kiellandIon('Na⁺'), ''));
              _ions = null;
            }),
          ),
        ],
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
      if (_ions != null) ..._results(_ions!, parseNumberInput(_t.text)!),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  List<Widget> _results(List<_Ion> ions, double t) {
    final nf = context.nf;
    final dh = DebyeHuckel(t);
    final i = ionicStrength(ions.map((x) => (x.c, x.z)));
    final balance = ions.fold(0.0, (s, x) => s + x.c * x.z);
    final total = ions.fold(0.0, (s, x) => s + x.c * x.z.abs());
    String g(double log) => nf.format(math.pow(10, log).toDouble(), digits: 4);
    // λ° are tabulated at 25 °C only
    final migrating = [for (final x in ions) (x.label, x.z, x.c)];
    final kappa = (t - 25).abs() < 0.5 ? kohlrauschConductivity(migrating) : null;
    final transport = kappa == null ? null : transportNumbers(migrating);
    return [
      ResultCard(
        color: widget.tool.color,
        label: context.t(S.ionicStrength),
        value: '${nf.format(i)} mol/L',
        copyValue: nf.plain(i),
        children: [
          const Divider(height: 18),
          InfoRow('A', '${nf.format(dh.a, digits: 4)} √(L/mol)'),
          InfoRow('1/B', '${nf.format(1 / dh.bPerPm, digits: 4)} pm'),
          InfoRow('εᵣ (H₂O)', nf.format(dh.permittivity, digits: 4)),
          InfoRow('Σ cᵢzᵢ', '${nf.format(balance, digits: 4)} mol/L'),
          if (kappa != null) InfoRow(context.t(S.kohlrauschKappa), '${nf.format(kappa * 1e4, digits: 4)} µS/cm'),
        ],
      ),
      if (total > 0 && balance.abs() > 1e-6 * total) ErrorBanner(context.t(S.notNeutral)),
      if (i > 0.5)
        ErrorBanner(context.t(S.ionicTooHigh))
      else if (i > 0.1)
        ErrorBanner(context.t(S.ionicHigh)),
      for (final x in ions)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${x.label}   ${nf.format(x.c)} mol/L${x.sizePm != null ? '   α = ${nf.format(x.sizePm!)} pm' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (x.sizePm != null)
                  InfoRow(context.t(S.extendedDH), g(dh.logExtended(x.z, x.sizePm!, i))),
                InfoRow(context.t(S.daviesEq), g(dh.logDavies(x.z, i))),
                InfoRow(context.t(S.limitingDH), g(dh.logLimiting(x.z, i))),
                InfoRow(context.t(S.activityLabel), '${nf.format(_gamma(dh, x, i) * x.c, digits: 4)} mol/L'),
                if (x.label == 'H⁺' && x.c > 0) InfoRow('pH = −log a(H⁺)', nf.format(-math.log(_gamma(dh, x, i) * x.c) / math.ln10, digits: 4)),
                if (transport != null) ...[
                  InfoRow('λ°(1/|z| ${x.label})', '${nf.format(limitingEquivalentConductivity[x.label]!)} S cm² mol⁻¹'),
                  InfoRow(context.t(S.transportNumber), nf.format(transport[ions.indexOf(x)], digits: 3)),
                ],
              ],
            ),
          ),
        ),
    ];
  }
}

/// Searchable list of the Kielland ions; pops a [KiellandIon] or the
/// string `custom`.
class KiellandIonPicker extends StatefulWidget {
  const KiellandIonPicker({super.key});

  @override
  State<KiellandIonPicker> createState() => _KiellandIonPickerState();
}

class _KiellandIonPickerState extends State<KiellandIonPicker> {
  String _q = '';

  static String _plain(String s) {
    const sub = '₀₁₂₃₄₅₆₇₈₉⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻';
    const asc = '01234567890123456789+-';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final k = sub.indexOf(ch);
      b.write(k < 0 ? ch : asc[k]);
    }
    return b.toString().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final q = _plain(_q.trim());
    final list = [
      for (final x in kiellandIons)
        if (q.isEmpty || _plain(x.formula).contains(q)) x,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(S.ionsLabel)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              autocorrect: false,
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Na+, SO4, Fe …', isDense: true),
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
                return ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: Text(context.t(S.customIon), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(context.t(S.customIonHint)),
                  onTap: () => Navigator.of(context).pop('custom'),
                );
              }
              final x = list[i];
              return ListTile(
                title: Text(x.formula, style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: Text('α = ${context.nf.format(x.sizePm)} pm'),
                onTap: () => Navigator.of(context).pop(x),
              );
            },
          ),
        ),
      ),
    );
  }
}
