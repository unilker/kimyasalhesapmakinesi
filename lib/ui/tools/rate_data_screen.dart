import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/kinetics_fit.dart';
import '../../core/stats.dart' show parseNumberList;
import '../common.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/xy_chart.dart';
import 'registry.dart';

/// 2NO2 → 2NO + O2 at 300 °C (Brown, LeMay et al., Chemistry: The Central Science).
const _example = '0 0.0100\n50 0.0079\n100 0.0065\n200 0.0048\n300 0.0038';

/// 2NO + O2 → 2NO2: [NO] [O2] initial rate (Chang, Chemistry).
const _exampleInitial =
    '0.0125 0.0253 0.0281\n0.0250 0.0253 0.112\n0.0125 0.0506 0.0561';

class RateDataScreen extends StatefulWidget {
  const RateDataScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<RateDataScreen> createState() => _RateDataScreenState();
}

class _RateDataScreenState extends State<RateDataScreen> {
  final _data = TextEditingController();
  final _rates = TextEditingController();
  bool _initial = false;
  String _unit = 's';
  List<OrderFit>? _fits;
  InitialRates? _ir;
  String? _error;

  @override
  void dispose() {
    _data.dispose();
    _rates.dispose();
    super.dispose();
  }

  void _calculateInitial() {
    final conc = <List<double>>[], rates = <double>[];
    for (final line in _rates.text.split('\n')) {
      if (line.trim().isEmpty) continue;
      final nums = parseNumberList(line);
      if (nums == null || nums.length < 2) {
        return setState(() {
          _ir = null;
          _error = context.t(S.errInitialRates);
        });
      }
      conc.add(nums.sublist(0, nums.length - 1));
      rates.add(nums.last);
    }
    try {
      final r = fitInitialRates(conc, rates);
      final nf = context.nf;
      context.app.addHistory(
        toolId: widget.tool.id,
        input: [
          for (var e = 0; e < rates.length; e++)
            '${conc[e].map(nf.format).join(', ')} → ${nf.format(rates[e])}',
        ].join('; '),
        result: '${_rateLaw(r)}, k = ${nf.format(r.kRounded.mean, digits: 4)}',
      );
      setState(() {
        _ir = r;
        _error = null;
      });
    } on ArgumentError {
      setState(() {
        _ir = null;
        _error = context.t(S.errInitialRates);
      });
    }
  }

  static const _letters = ['A', 'B', 'C', 'D'];

  String _rateLaw(InitialRates r) {
    final nf = context.nf;
    final terms = [
      for (var i = 0; i < r.orders.length; i++)
        if (r.roundedOrders[i] != 0)
          '[${_letters[i]}]${r.roundedOrders[i] == 1 ? '' : _sup(nf.format(r.roundedOrders[i]))}',
    ];
    return '${context.t(S.rateWord)} = k${terms.join()}';
  }

  static String _sup(String s) {
    const map = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      ',': '˙',
      '.': '˙',
      '−': '⁻',
      '-': '⁻',
    };
    return s.split('').map((c) => map[c] ?? c).join();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (_initial) return _calculateInitial();
    final t = <double>[], c = <double>[];
    for (final line in _data.text.split('\n')) {
      if (line.trim().isEmpty) continue;
      final nums = parseNumberList(line);
      if (nums == null || nums.length != 2) {
        return setState(() {
          _fits = null;
          _error = context.t(S.needPairs);
        });
      }
      t.add(nums[0]);
      c.add(nums[1]);
    }
    try {
      final fits = fitRateLaws(t, c);
      final best = bestFit(fits);
      final nf = context.nf;
      context.app.addHistory(
        toolId: widget.tool.id,
        input: [
          for (var i = 0; i < t.length; i++)
            '${nf.format(t[i])} $_unit: ${nf.format(c[i])} M',
        ].join('; '),
        result:
            '${context.t(S.orderName(best.order))}, k = ${nf.format(best.k, digits: 4)} ${_kUnit(best.order)}, '
            'R² = ${nf.format(best.rSquared, digits: 6)}',
      );
      setState(() {
        _fits = fits;
        _error = null;
      });
    } on ArgumentError {
      setState(() {
        _fits = null;
        _error = context.t(S.needPositive);
      });
    }
  }

  String _kUnit(int order) => switch (order) {
    0 => 'M/$_unit',
    1 => '$_unit⁻¹',
    _ => 'M⁻¹ $_unit⁻¹',
  };

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final inputs = <Widget>[
      FormulaBanner(
        color: tool.color,
        formula: _initial
            ? '${context.t(S.rateWord)} = k[A]ᵐ[B]ⁿ'
            : '[A] · ln[A] · 1/[A]  vs  t',
        note: context.t(_initial ? S.initialRatesNote : S.rateDataNote),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final initial in [false, true])
            ChoiceChip(
              label: Text(
                context.t(initial ? S.initialRatesMode : S.integratedLaw),
              ),
              selected: _initial == initial,
              onSelected: (_) => setState(() {
                _initial = initial;
                _error = null;
              }),
            ),
        ],
      ),
      if (_initial)
        TextField(
          controller: _rates,
          minLines: 4,
          maxLines: null,
          scrollPhysics: const NeverScrollableScrollPhysics(),
          keyboardType: TextInputType.multiline,
          onChanged: (_) => setState(() => _ir = null),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          decoration: InputDecoration(
            labelText: context.t(S.initialRatesData),
            hintText: '0,0125 0,0253 0,0281\n…',
            alignLabelWithHint: true,
          ),
        )
      else
        TextField(
          controller: _data,
          minLines: 5,
          maxLines: null,
          scrollPhysics: const NeverScrollableScrollPhysics(),
          keyboardType: TextInputType.multiline,
          onChanged: (_) => setState(() => _fits = null),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          decoration: InputDecoration(
            labelText: context.t(S.timeConcPairs),
            hintText: '0 0,0100\n50 0,0079\n…',
            alignLabelWithHint: true,
          ),
        ),
      if (!_initial) SectionTitle(context.t(S.timeUnit)),
      if (!_initial)
        Wrap(
          spacing: 8,
          children: [
            for (final u in ['s', 'min', 'h'])
              ChoiceChip(
                label: Text(u),
                selected: _unit == u,
                onSelected: (_) => setState(() => _unit = u),
              ),
          ],
        ),
      FilledButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate_rounded),
        label: Text(context.t(S.calculate)),
        style: FilledButton.styleFrom(
          backgroundColor: tool.color,
          foregroundColor: Colors.white,
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            if (_initial) {
              _rates.text = lang == 'tr'
                  ? _exampleInitial.replaceAll('.', ',')
                  : _exampleInitial;
            } else {
              _data.text = lang == 'tr'
                  ? _example.replaceAll('.', ',')
                  : _example;
            }
            _unit = 's';
            _calculate();
          },
          icon: const Icon(Icons.science_outlined),
          label: Text(context.t(S.exampleData)),
        ),
      ),
    ];
    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (!_initial && _fits != null) ..._results(_fits!),
      if (_initial && _ir != null) ..._initialResults(_ir!),
    ];
    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  List<Widget> _results(List<OrderFit> fits) {
    final nf = context.nf;
    final best = bestFit(fits);
    final sep = context.lang == 'tr' ? ',' : '.';
    final yLabel = switch (best.order) {
      0 => '[A]',
      1 => 'ln[A]',
      _ => '1/[A]',
    };
    final xs = best.line.xs, ys = best.line.ys;
    final x0 = xs.reduce((a, b) => a < b ? a : b),
        x1 = xs.reduce((a, b) => a > b ? a : b);
    return [
      ResultCard(
        color: widget.tool.color,
        label: context.t(S.suggestedOrder),
        value: context.t(S.orderName(best.order)),
        children: [
          const Divider(height: 18),
          InfoRow(
            context.t(S.rateConstant),
            '${nf.format(best.k, digits: 5)} ± ${nf.format(best.sK, digits: 2)} ${_kUnit(best.order)}',
          ),
          InfoRow(
            context.t(S.initialConc),
            '${nf.format(best.c0, digits: 5)} M',
          ),
          InfoRow(
            context.t(S.halfLifeLabel),
            '${nf.format(best.halfLife, digits: 4)} $_unit',
          ),
          InfoRow('R²', nf.format(best.rSquared, digits: 6)),
        ],
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
          child: XyChart(
            height: 240,
            xLabel: 't ($_unit)',
            yLabel: yLabel,
            formatter: NumberFormatter(
              significantDigits: 4,
              decimalSeparator: sep,
            ),
            series: [
              ChartSeries(
                points: [
                  Offset(x0, best.line.slope * x0 + best.line.intercept),
                  Offset(x1, best.line.slope * x1 + best.line.intercept),
                ],
                color: widget.tool.color.withValues(alpha: 0.6),
              ),
              ChartSeries(
                points: [
                  for (var i = 0; i < xs.length; i++) Offset(xs[i], ys[i]),
                ],
                color: Palette.indigo,
                line: false,
                dots: true,
              ),
            ],
          ),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.t(S.allOrders),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              for (final f in fits)
                InfoRow(
                  '${context.t(S.orderName(f.order))} (${switch (f.order) {
                    0 => '[A]',
                    1 => 'ln[A]',
                    _ => '1/[A]',
                  }})',
                  'R² = ${nf.format(f.rSquared, digits: 5)}',
                ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _initialResults(InitialRates r) {
    final nf = context.nf;
    final k = r.kRounded;
    final total = r.overallOrder;
    final kUnit = total == 1 ? 's⁻¹' : 'M${_sup(nf.format(1 - total))} s⁻¹';
    return [
      ResultCard(
        color: widget.tool.color,
        label: context.t(S.rateLaw),
        value: _rateLaw(r),
        children: [
          const Divider(height: 18),
          for (var i = 0; i < r.orders.length; i++)
            InfoRow(
              '${context.t(S.fittedOrders)}: [${_letters[i]}]',
              '${nf.format(r.orders[i], digits: 4)} → ${nf.format(r.roundedOrders[i])}',
            ),
          InfoRow(context.t(S.overallOrderLabel), nf.format(total)),
          InfoRow(
            'k',
            '${nf.format(k.mean, digits: 4)}${k.sd > 0 ? ' ± ${nf.format(k.sd, digits: 2)}' : ''} $kUnit',
          ),
        ],
      ),
    ];
  }
}
