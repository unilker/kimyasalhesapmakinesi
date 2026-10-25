import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/math/expression.dart';
import '../common.dart';
import '../errors.dart';
import '../layout/adaptive.dart';
import '../strings.dart';
import '../theme.dart';
import '../tools/constants_screen.dart';
import '../tools/registry.dart';

enum _KeyKind { digit, op, fn, action, equals, clear }

class _Key {
  const _Key(this.label, this.insert, this.kind, {this.second, this.secondInsert});

  final String label;
  final String insert;
  final _KeyKind kind;
  final String? second;
  final String? secondInsert;
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expr = '';
  double? _ans;
  String? _result;
  String? _error;
  bool _justEvaluated = false;
  bool _second = false;
  final List<(String, String)> _session = [];
  final _focus = FocusNode();
  final _exprScroll = ScrollController();

  @override
  void dispose() {
    _focus.dispose();
    _exprScroll.dispose();
    super.dispose();
  }

  NumberFormatter get _nf => NumberFormatter(
        significantDigits: 10,
        decimalSeparator: context.lang == 'tr' ? ',' : '.',
      );

  List<List<_Key>> _keys(String dec) => [
        [
          const _Key('2nd', '', _KeyKind.action),
          const _Key('DEG', '', _KeyKind.action),
          const _Key('sin', 'sin(', _KeyKind.fn, second: 'sin⁻¹', secondInsert: 'asin('),
          const _Key('cos', 'cos(', _KeyKind.fn, second: 'cos⁻¹', secondInsert: 'acos('),
          const _Key('tan', 'tan(', _KeyKind.fn, second: 'tan⁻¹', secondInsert: 'atan('),
        ],
        [
          const _Key('ln', 'ln(', _KeyKind.fn, second: 'eˣ', secondInsert: 'e^('),
          const _Key('log', 'log(', _KeyKind.fn, second: '10ˣ', secondInsert: '10^('),
          const _Key('√', '√(', _KeyKind.fn, second: '∛', secondInsert: '∛('),
          const _Key('x²', '²', _KeyKind.fn, second: 'x!', secondInsert: '!'),
          const _Key('xʸ', '^', _KeyKind.fn, second: '1/x', secondInsert: '^(−1)'),
        ],
        [
          const _Key('(', '(', _KeyKind.fn, second: '%', secondInsert: '%'),
          const _Key(')', ')', _KeyKind.fn, second: '|x|', secondInsert: 'abs('),
          const _Key('π', 'π', _KeyKind.fn),
          const _Key('e', 'e', _KeyKind.fn),
          const _Key('⚛', '', _KeyKind.action),
        ],
        [
          const _Key('7', '7', _KeyKind.digit),
          const _Key('8', '8', _KeyKind.digit),
          const _Key('9', '9', _KeyKind.digit),
          const _Key('⌫', '', _KeyKind.clear),
          const _Key('AC', '', _KeyKind.clear),
        ],
        [
          const _Key('4', '4', _KeyKind.digit),
          const _Key('5', '5', _KeyKind.digit),
          const _Key('6', '6', _KeyKind.digit),
          const _Key('×', '×', _KeyKind.op),
          const _Key('÷', '÷', _KeyKind.op),
        ],
        [
          const _Key('1', '1', _KeyKind.digit),
          const _Key('2', '2', _KeyKind.digit),
          const _Key('3', '3', _KeyKind.digit),
          const _Key('+', '+', _KeyKind.op),
          const _Key('−', '−', _KeyKind.op),
        ],
        [
          const _Key('0', '0', _KeyKind.digit),
          _Key(dec, dec, _KeyKind.digit),
          const _Key('EE', 'E', _KeyKind.digit),
          const _Key('Ans', 'Ans', _KeyKind.fn),
          const _Key('=', '', _KeyKind.equals),
        ],
      ];

  void _press(_Key k) {
    HapticFeedback.selectionClick();
    final app = context.app;
    switch (k.label) {
      case '2nd':
        setState(() => _second = !_second);
        return;
      case 'DEG':
        app.setAngleMode(
          app.angleMode == AngleMode.degrees ? AngleMode.radians : AngleMode.degrees,
        );
        return;
      case '⚛':
        _showConstants();
        return;
      case 'AC':
        setState(() {
          _expr = '';
          _result = null;
          _error = null;
          _justEvaluated = false;
        });
        return;
      case '⌫':
        _backspace();
        return;
      case '=':
        _evaluate();
        return;
    }
    final insert = _second && k.secondInsert != null ? k.secondInsert! : k.insert;
    _insert(insert, k.kind);
    if (_second) setState(() => _second = false);
  }

  void _insert(String s, _KeyKind kind) {
    setState(() {
      if (_justEvaluated) {
        // After "=", operators continue from the answer, anything else
        // starts a new expression.
        _expr = kind == _KeyKind.op || s == '²' || s == '^' || s == '!' || s == '%' || s.startsWith('^(')
            ? 'Ans'
            : '';
        _justEvaluated = false;
      }
      _expr += s;
      _result = null;
      _error = null;
    });
    _scrollToEnd();
  }

  void _backspace() {
    setState(() {
      if (_justEvaluated) {
        _justEvaluated = false;
        _result = null;
      }
      final m = RegExp(r'([A-Za-z]+\(?|.)$').firstMatch(_expr);
      _expr = m == null ? '' : _expr.substring(0, m.start);
      _error = null;
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_exprScroll.hasClients) {
        _exprScroll.jumpTo(_exprScroll.position.maxScrollExtent);
      }
    });
  }

  void _evaluate() {
    if (_expr.trim().isEmpty) return;
    try {
      final v = evaluateExpression(
        _expr,
        angleMode: context.app.angleMode,
        ans: _ans,
      );
      final text = _nf.format(v);
      context.app.addHistory(toolId: calculatorToolId, input: _expr, result: text);
      setState(() {
        _ans = v;
        _result = text;
        _error = null;
        _justEvaluated = true;
        _session.insert(0, (_expr, text));
        if (_session.length > 50) _session.removeLast();
      });
    } on ExpressionException catch (e) {
      setState(() {
        _error = expressionErrorText(context, e);
        _result = null;
      });
    }
  }

  String? get _preview {
    if (_justEvaluated || _expr.isEmpty) return null;
    try {
      final v = evaluateExpression(_expr, angleMode: context.app.angleMode, ans: _ans);
      return _nf.format(v);
    } on ExpressionException {
      return null;
    }
  }

  void _showConstants() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(ctx.t(S.constants), style: ctx.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final c in physicalConstants) ...[
              ConstantTile(
                constant: c,
                onTap: () {
                  Navigator.pop(ctx);
                  _insert(c.key, _KeyKind.fn);
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _evaluate();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.delete) {
      setState(() {
        _expr = '';
        _result = null;
        _error = null;
      });
      return KeyEventResult.handled;
    }
    final ch = event.character;
    if (ch == null || ch.isEmpty) return KeyEventResult.ignored;
    const map = {'*': '×', '/': '÷', '-': '−'};
    if (RegExp(r'^[0-9.,+\-*/^()!%E]$').hasMatch(ch)) {
      final s = map[ch] ?? ch;
      _insert(s, '+−×÷'.contains(s) ? _KeyKind.op : _KeyKind.digit);
      return KeyEventResult.handled;
    }
    if (ch == '=') {
      _evaluate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hinge = hingeOf(context);
    final landscape = size.width > size.height;
    final split = hinge != null || landscape;
    // Short landscape screens need every pixel for the keys.
    final short = size.height < 500;
    final display = _display(showSession: split || size.height > 760);
    final keypad = _keypad();

    return Scaffold(
      appBar: short ? null : AppBar(title: Text(context.t(S.navCalculator))),
      body: SafeArea(
        top: short,
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: split
              ? TwoPane(
                  minSplitWidth: 400,
                  firstFraction: 0.45,
                  allowTabletop: true,
                  first: display,
                  second: keypad,
                  compact: _portrait(display, keypad),
                )
              : _portrait(display, keypad),
        ),
      ),
    );
  }

  Widget _portrait(Widget display, Widget keypad) {
    return LayoutBuilder(builder: (context, c) {
      final preferred = math.max(c.maxHeight * 0.66, math.min(280.0, c.maxHeight * 0.8));
      final keypadHeight = math.min(preferred, c.maxWidth * 1.45);
      return Column(
        children: [
          Expanded(child: display),
          SizedBox(height: keypadHeight, child: keypad),
        ],
      );
    });
  }

  Widget _display({required bool showSession}) {
    final scheme = context.colors;
    final preview = _preview;
    final angle = context.app.angleMode == AngleMode.degrees ? 'DEG' : 'RAD';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _badge(angle, Palette.indigo),
                if (_second) ...[const SizedBox(width: 6), _badge('2nd', Palette.orange)],
                const Spacer(),
                if (_ans != null)
                  Text('Ans = ${_nf.format(_ans!)}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ],
            ),
            Expanded(
              child: showSession && _session.isNotEmpty
                  ? ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: _session.length,
                      itemBuilder: (context, i) {
                        final (e, r) = _session[i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() {
                            _expr = e;
                            _justEvaluated = false;
                            _result = null;
                          }),
                          onLongPress: () => copyText(context, r),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '$e = $r',
                              textAlign: TextAlign.end,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
                            ),
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            SingleChildScrollView(
              controller: _exprScroll,
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                _expr.isEmpty ? '0' : _expr,
                style: TextStyle(
                  fontSize: _justEvaluated ? 22 : 34,
                  fontWeight: FontWeight.w700,
                  color: _justEvaluated ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onLongPress: _result == null ? null : () => copyText(context, _result!),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _error != null
                    ? Text(_error!,
                        key: const ValueKey('err'),
                        textAlign: TextAlign.end,
                        style: TextStyle(color: scheme.error, fontWeight: FontWeight.w800, fontSize: 18))
                    : FittedBox(
                        key: ValueKey(_result ?? preview ?? ''),
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _result != null ? '= $_result' : (preview == null ? ' ' : '= $preview'),
                          style: TextStyle(
                            fontSize: _result != null ? 40 : 22,
                            fontWeight: FontWeight.w900,
                            color: _result != null ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
      );

  Widget _keypad() {
    final dec = context.lang == 'tr' ? ',' : '.';
    final rows = _keys(dec);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(
        children: [
          for (final row in rows)
            Expanded(
              child: Row(
                children: [for (final k in row) Expanded(child: _keyButton(k))],
              ),
            ),
        ],
      ),
    );
  }

  Widget _keyButton(_Key k) {
    final scheme = context.colors;
    final angleLabel = context.app.angleMode == AngleMode.degrees ? 'DEG' : 'RAD';
    final label = k.label == 'DEG'
        ? angleLabel
        : (_second && k.second != null ? k.second! : k.label);
    final (Color bg, Color fg, Gradient? gradient) = switch (k.kind) {
      _KeyKind.digit => (scheme.surfaceContainerHighest, scheme.onSurface, null),
      _KeyKind.op => (scheme.secondaryContainer, scheme.onSecondaryContainer, null),
      _KeyKind.fn => (scheme.surfaceContainer, scheme.primary, null),
      _KeyKind.action => (
          k.label == '2nd' && _second ? Palette.orange : scheme.tertiaryContainer,
          k.label == '2nd' && _second ? Colors.white : scheme.onTertiaryContainer,
          null,
        ),
      _KeyKind.clear => (scheme.errorContainer, scheme.onErrorContainer, null),
      _KeyKind.equals => (Colors.transparent, Colors.white, accentGradient(Palette.violet)),
    };
    final semantic = switch (k.label) {
      '⌫' => 'Backspace',
      '⚛' => context.t(S.constants),
      _ => label,
    };
    return Padding(
      padding: const EdgeInsets.all(3.5),
      child: Semantics(
        button: true,
        label: semantic,
        excludeSemantics: true,
        child: Material(
          color: gradient == null ? bg : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: gradient == null ? null : BoxDecoration(gradient: gradient),
            child: InkWell(
              onTap: () => _press(k),
              onLongPress: k.label == '⌫'
                  ? () => _press(const _Key('AC', '', _KeyKind.clear))
                  : null,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: k.label == '⚛' || k.label == '⌫'
                        ? Icon(
                            k.label == '⚛' ? Icons.push_pin_rounded : Icons.backspace_rounded,
                            color: fg,
                          )
                        : Text(
                            label,
                            style: TextStyle(
                              fontSize: k.kind == _KeyKind.digit || k.kind == _KeyKind.equals ? 26 : 19,
                              fontWeight: FontWeight.w800,
                              color: fg,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
