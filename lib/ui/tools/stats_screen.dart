import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/math/expression.dart';
import '../../core/stats.dart';
import '../common.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/xy_chart.dart';
import 'registry.dart';

/// Laboratory statistics: descriptive statistics with outlier tests, and
/// linear calibration with LOD/LOQ and unknown prediction.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.tool});

  final ToolInfo tool;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _calibration = false;
  double _level = 0.95;
  final _values = TextEditingController();
  final _pairs = TextEditingController();
  final _y0 = TextEditingController();
  final _k = TextEditingController(text: '1');
  Summary? _summary;
  Calibration? _cal;
  String? _error;

  @override
  void dispose() {
    for (final c in [_values, _pairs, _y0, _k]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    _summary = null;
    _cal = null;
    _error = null;
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    setState(_reset);
    final nf = context.nf;
    if (!_calibration) {
      final v = parseNumberList(_values.text);
      if (v == null) return setState(() => _error = context.t(S.invalidList));
      if (v.length < 2) return setState(() => _error = context.t(S.needTwo));
      final s = Summary.of(v);
      context.app.addHistory(
        toolId: widget.tool.id,
        input: v.map(nf.format).join('; '),
        result: '${context.t(S.mean)} = ${nf.format(s.mean)} ± '
            '${nf.format(s.confidenceHalfWidth(_level))} (${(_level * 100).round()} %), s = ${nf.format(s.sd)}',
      );
      setState(() => _summary = s);
      return;
    }
    final xs = <double>[], ys = <double>[];
    for (final line in _pairs.text.split('\n')) {
      if (line.trim().isEmpty) continue;
      final nums = parseNumberList(line);
      if (nums == null || nums.length != 2) {
        return setState(() => _error = context.t(S.needPairs));
      }
      xs.add(nums[0]);
      ys.add(nums[1]);
    }
    try {
      final c = Calibration.fit(xs, ys);
      final y0 = parseNumberInput(_y0.text);
      final k = (parseNumberInput(_k.text) ?? 1).round().clamp(1, 1000);
      var result = 'y = ${nf.format(c.slope)}·x ${c.intercept < 0 ? '−' : '+'} '
          '${nf.format(c.intercept.abs())}, R² = ${nf.format(c.rSquared, digits: 6)}';
      if (y0 != null) {
        final p = c.predictX(y0, k: k);
        result += '; x₀ = ${nf.format(p.x0)} ± ${nf.format(tCritical(_level, c.n - 2.0) * p.sx0)}';
      }
      context.app.addHistory(
        toolId: widget.tool.id,
        input: [for (var i = 0; i < xs.length; i++) '(${nf.format(xs[i])}, ${nf.format(ys[i])})'].join(' '),
        result: result,
      );
      setState(() => _cal = c);
    } on ArgumentError {
      setState(() => _error = context.t(S.needPairs));
    }
  }

  void _example() {
    setState(() {
      _reset();
      if (_calibration) {
        final dec = context.lang == 'tr' ? ',' : '.';
        _pairs.text = [
          '0 2${dec}1', '2 5${dec}0', '4 9${dec}0', '6 12${dec}6',
          '8 17${dec}3', '10 21${dec}0', '12 24${dec}7',
        ].join('\n');
        _y0.text = '13${dec}5';
      } else {
        _values.text = context.lang == 'tr'
            ? '0,403 0,410 0,401 0,380 0,400 0,413 0,408'
            : '0.403 0.410 0.401 0.380 0.400 0.413 0.408';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final lang = context.lang;
    final inputs = <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (cal, icon, label) in [
            (false, Icons.bar_chart_rounded, S.dataSet),
            (true, Icons.show_chart_rounded, S.calibrationLine),
          ])
            ChoiceChip(
              avatar: Icon(icon, size: 18),
              label: Text(context.t(label)),
              selected: _calibration == cal,
              onSelected: (_) => setState(() {
                _calibration = cal;
                _reset();
              }),
            ),
        ],
      ),
      if (!_calibration)
        TextField(
          controller: _values,
          minLines: 3,
          maxLines: null,
          // The field grows with the data and the page scrolls; vertical
          // drags on it must reach the page.
          scrollPhysics: const NeverScrollableScrollPhysics(),
          keyboardType: TextInputType.multiline,
          onChanged: (_) => setState(_reset),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          decoration: InputDecoration(
            labelText: context.t(S.data),
            helperText: context.t(S.dataHint),
            helperMaxLines: 3,
            alignLabelWithHint: true,
          ),
        )
      else ...[
        TextField(
          controller: _pairs,
          minLines: 4,
          maxLines: null,
          // The field grows with the data and the page scrolls; vertical
          // drags on it must reach the page.
          scrollPhysics: const NeverScrollableScrollPhysics(),
          keyboardType: TextInputType.multiline,
          onChanged: (_) => setState(_reset),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          decoration: InputDecoration(
            labelText: context.t(S.pairs),
            hintText: context.t(S.pairsHint),
            alignLabelWithHint: true,
          ),
        ),
        NumberField(controller: _y0, label: context.t(S.unknownSignal), onChanged: (_) => setState(_reset)),
        NumberField(
          controller: _k,
          label: context.t(S.replicates),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(_reset),
        ),
      ],
      SectionTitle(context.t(S.confidence)),
      Wrap(
        spacing: 8,
        children: [
          for (final l in [0.90, 0.95, 0.99])
            ChoiceChip(
              label: Text(context.percent(l * 100, digits: 2)),
              selected: _level == l,
              onSelected: (_) => setState(() {
                _level = l;
                if (_summary != null || _cal != null) _calculate();
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
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _example,
          icon: const Icon(Icons.science_outlined),
          label: Text(context.t(S.exampleData)),
        ),
      ),
      Text(context.t(S.statsSource),
          style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
    ];

    final results = <Widget>[
      if (_error != null) ErrorBanner(_error!),
      if (_summary != null) ..._summaryResults(_summary!),
      if (_cal != null) ..._calibrationResults(_cal!),
    ];

    return ToolScaffold(
      title: tool.title.of(lang),
      color: tool.color,
      icon: tool.icon,
      inputs: inputs,
      results: results,
    );
  }

  String _pct() => context.percent(_level * 100, digits: 2);

  List<Widget> _summaryResults(Summary s) {
    final nf = context.nf;
    final half = s.confidenceHalfWidth(_level);
    final q = dixonQ(s.values, _level);
    final g = grubbs(s.values, _level);
    Widget verdict(OutlierResult r) => Text(
          context.t(r.isOutlier ? S.outlierYes : S.outlierNo),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: r.isOutlier ? context.colors.error : Palette.green,
          ),
        );
    return [
      ResultCard(
        color: widget.tool.color,
        label: '${context.t(S.mean)} ± ${context.t(S.ci)} (${_pct()})',
        value: '${nf.format(s.mean)} ± ${nf.format(half)}',
        copyValue: nf.plain(s.mean),
        children: [
          const Divider(height: 18),
          InfoRow(context.t(S.count), '${s.n}'),
          InfoRow(context.t(S.median), nf.format(s.median)),
          InfoRow(context.t(S.sd), nf.format(s.sd)),
          InfoRow(context.t(S.variance), nf.format(s.variance)),
          InfoRow(context.t(S.rsd), context.percent(s.rsd)),
          InfoRow(context.t(S.sem), nf.format(s.sem)),
          InfoRow(context.t(S.range), '${nf.format(s.min)} – ${nf.format(s.max)}'),
        ],
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${context.t(S.qTest)} (${_pct()})',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              if (q == null)
                Text(context.t(S.qRange), style: TextStyle(color: context.colors.onSurfaceVariant))
              else ...[
                InfoRow(context.t(S.suspect), nf.format(q.suspect)),
                InfoRow(context.t(S.statistic), 'Q = ${nf.format(q.statistic, digits: 3)} / ${nf.format(q.critical, digits: 3)}'),
                verdict(q),
              ],
              const Divider(height: 24),
              Text('${context.t(S.grubbsTest)} (${_pct()})',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              if (g != null) ...[
                InfoRow(context.t(S.suspect), nf.format(g.suspect)),
                InfoRow(context.t(S.statistic), 'G = ${nf.format(g.statistic, digits: 4)} / ${nf.format(g.critical, digits: 4)}'),
                verdict(g),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _calibrationResults(Calibration c) {
    final nf = context.nf;
    final t = tCritical(_level, c.n - 2.0);
    final y0 = parseNumberInput(_y0.text);
    final k = (parseNumberInput(_k.text) ?? 1).round().clamp(1, 1000);
    final p = y0 == null ? null : c.predictX(y0, k: k);
    final xs = c.xs;
    final xMin = xs.reduce((a, b) => a < b ? a : b);
    final xMax = xs.reduce((a, b) => a > b ? a : b);
    final lineEnd = p == null ? xMax : (p.x0 > xMax ? p.x0 : xMax);
    final lineStart = p == null ? xMin : (p.x0 < xMin ? p.x0 : xMin);
    final sign = c.intercept < 0 ? '−' : '+';
    return [
      ResultCard(
        color: widget.tool.color,
        label: context.t(S.calibrationLine),
        value: 'y = ${nf.format(c.slope)}·x $sign ${nf.format(c.intercept.abs())}',
        children: [
          const Divider(height: 18),
          InfoRow(context.t(S.slope), '${nf.format(c.slope)} ± ${nf.format(c.sSlope)}'),
          InfoRow(context.t(S.intercept), '${nf.format(c.intercept)} ± ${nf.format(c.sIntercept)}'),
          InfoRow(context.t(S.correlation), '${nf.format(c.r, digits: 6)} / ${nf.format(c.rSquared, digits: 6)}'),
          InfoRow(context.t(S.syx), nf.format(c.syx)),
          InfoRow(context.t(S.lodLabel), nf.format(c.lod)),
          InfoRow(context.t(S.loqLabel), nf.format(c.loq)),
          if (p != null)
            InfoRow('${context.t(S.unknownX)} (${_pct()})', '${nf.format(p.x0)} ± ${nf.format(t * p.sx0)}'),
        ],
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
          child: XyChart(
            formatter: NumberFormatter(
              significantDigits: 4,
              decimalSeparator: context.lang == 'tr' ? ',' : '.',
            ),
            xLabel: 'x',
            yLabel: 'y',
            series: [
              ChartSeries(
                points: [
                  Offset(lineStart, c.slope * lineStart + c.intercept),
                  Offset(lineEnd, c.slope * lineEnd + c.intercept),
                ],
                color: widget.tool.color,
              ),
              ChartSeries(
                points: [for (var i = 0; i < xs.length; i++) Offset(xs[i], c.ys[i])],
                color: Palette.indigo,
                line: false,
                dots: true,
              ),
            ],
            markers: [
              if (p != null) ChartMarker(Offset(p.x0, y0!), 'x₀ = ${nf.format(p.x0, digits: 4)}', Palette.orange),
            ],
          ),
        ),
      ),
    ];
  }
}
