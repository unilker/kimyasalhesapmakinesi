import 'dart:math' as math;

import '../constants.dart';

enum AngleMode { degrees, radians }

enum ExpressionErrorKind {
  empty,
  syntax,
  unknownName,
  divisionByZero,
  domain,
  overflow,
}

class ExpressionException implements Exception {
  const ExpressionException(this.kind, [this.detail = '']);

  final ExpressionErrorKind kind;
  final String detail;

  @override
  String toString() => 'ExpressionException($kind, $detail)';
}

/// Functions understood by [evaluateExpression]. Names are what the user
/// types (or what calculator keys insert).
const expressionFunctions = <String>{
  'sin', 'cos', 'tan', 'asin', 'acos', 'atan', //
  'sinh', 'cosh', 'tanh', 'asinh', 'acosh', 'atanh', //
  'ln', 'log', 'exp', 'sqrt', 'cbrt', 'abs', //
};

/// Evaluates a calculator expression.
///
/// Supports `+ - × ÷ * / ^`, parentheses, implicit multiplication (`2π`,
/// `3(4+1)`), postfix `!` and `%`, scientific `E` notation (`6.022E23`),
/// `√`, `π`, `e`, `Ans`, the functions in [expressionFunctions] and the
/// named constants in [physicalConstants] (by their [PhysicalConstant.key]).
///
/// Both `.` and `,` are accepted as decimal separators.
double evaluateExpression(
  String input, {
  AngleMode angleMode = AngleMode.degrees,
  double? ans,
}) {
  final tokens = _tokenize(input);
  if (tokens.isEmpty) throw const ExpressionException(ExpressionErrorKind.empty);
  final p = _Parser(tokens, angleMode, ans);
  final v = p.parseExpression();
  if (!p.atEnd) {
    throw ExpressionException(ExpressionErrorKind.syntax, p.peek.text);
  }
  if (v.isNaN) throw const ExpressionException(ExpressionErrorKind.domain);
  if (v.isInfinite) throw const ExpressionException(ExpressionErrorKind.overflow);
  return v;
}

/// Parses a numeric text field. Accepts plain numbers in either decimal
/// convention as well as small expressions (`25+273.15`, `1.5e-3`).
/// Returns null for empty or invalid input.
double? parseNumberInput(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final direct = double.tryParse(t.replaceAll(',', '.'));
  if (direct != null) return direct;
  try {
    return evaluateExpression(t, angleMode: AngleMode.radians);
  } on ExpressionException {
    return null;
  }
}

enum _T { number, ident, op, lparen, rparen, postfix }

class _Token {
  const _Token(this.type, this.text, [this.value = 0]);
  final _T type;
  final String text;
  final double value;
}

List<_Token> _tokenize(String raw) {
  final s = raw
      .replaceAll('×', '*')
      .replaceAll('·', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll('–', '-')
      .replaceAll('π', ' pi ')
      .replaceAll('√', ' sqrt ')
      .replaceAll('∛', ' cbrt ')
      .replaceAll(',', '.');
  final out = <_Token>[];
  var i = 0;
  bool isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  bool isLetter(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 65 && u <= 90) ||
        (u >= 97 && u <= 122) ||
        c == '_' ||
        (u > 127 && c != '²' && c != '³');
  }

  while (i < s.length) {
    final c = s[i];
    if (c == ' ') {
      i++;
      continue;
    }
    if (isDigit(c) || (c == '.' && i + 1 < s.length && isDigit(s[i + 1]))) {
      final start = i;
      while (i < s.length && isDigit(s[i])) {
        i++;
      }
      if (i < s.length && s[i] == '.') {
        i++;
        while (i < s.length && isDigit(s[i])) {
          i++;
        }
      }
      // exponent: E or e followed by optional sign and digits
      if (i < s.length && (s[i] == 'E' || s[i] == 'e')) {
        var j = i + 1;
        if (j < s.length && (s[j] == '+' || s[j] == '-')) j++;
        if (j < s.length && isDigit(s[j])) {
          i = j;
          while (i < s.length && isDigit(s[i])) {
            i++;
          }
        }
      }
      final text = s.substring(start, i);
      final v = double.tryParse(text);
      if (v == null) throw ExpressionException(ExpressionErrorKind.syntax, text);
      out.add(_Token(_T.number, text, v));
      continue;
    }
    if (isLetter(c)) {
      final start = i;
      while (i < s.length && isLetter(s[i])) {
        i++;
      }
      out.add(_Token(_T.ident, s.substring(start, i)));
      continue;
    }
    if ('+-*/^'.contains(c)) {
      out.add(_Token(_T.op, c));
    } else if (c == '(') {
      out.add(const _Token(_T.lparen, '('));
    } else if (c == ')') {
      out.add(const _Token(_T.rparen, ')'));
    } else if (c == '!' || c == '%') {
      out.add(_Token(_T.postfix, c));
    } else if (c == '²' || c == '³') {
      out.add(const _Token(_T.op, '^'));
      out.add(_Token(_T.number, c, c == '²' ? 2 : 3));
    } else {
      throw ExpressionException(ExpressionErrorKind.syntax, c);
    }
    i++;
  }
  return out;
}

class _Parser {
  _Parser(this.tokens, this.angleMode, this.ans);

  final List<_Token> tokens;
  final AngleMode angleMode;
  final double? ans;
  int pos = 0;

  bool get atEnd => pos >= tokens.length;
  _Token get peek => tokens[pos];

  bool _isOp(String op) =>
      !atEnd && peek.type == _T.op && peek.text == op;

  // expression := term (('+'|'-') term)*
  double parseExpression() {
    var v = parseTerm();
    while (_isOp('+') || _isOp('-')) {
      final op = tokens[pos++].text;
      final r = parseTerm();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  // term := unary (('*'|'/') unary | implicit-unary)*
  double parseTerm() {
    var v = parseUnary();
    while (true) {
      if (_isOp('*') || _isOp('/')) {
        final op = tokens[pos++].text;
        final r = parseUnary();
        if (op == '/') {
          if (r == 0) {
            throw const ExpressionException(ExpressionErrorKind.divisionByZero);
          }
          v = v / r;
        } else {
          v = v * r;
        }
      } else if (!atEnd &&
          (peek.type == _T.number ||
              peek.type == _T.ident ||
              peek.type == _T.lparen)) {
        // implicit multiplication: 2π, 3(4), (1)(2), 2sin(30)
        v = v * parsePower();
      } else {
        return v;
      }
    }
  }

  // unary := ('-'|'+') unary | power
  double parseUnary() {
    if (_isOp('-')) {
      pos++;
      return -parseUnary();
    }
    if (_isOp('+')) {
      pos++;
      return parseUnary();
    }
    return parsePower();
  }

  // power := postfix ('^' unary)?   (right associative)
  double parsePower() {
    final base = parsePostfix();
    if (_isOp('^')) {
      pos++;
      final exp = parseUnary();
      final r = math.pow(base, exp).toDouble();
      if (r.isNaN) throw const ExpressionException(ExpressionErrorKind.domain);
      return r;
    }
    return base;
  }

  double parsePostfix() {
    var v = parsePrimary();
    while (!atEnd && peek.type == _T.postfix) {
      final op = tokens[pos++].text;
      v = op == '!' ? _factorial(v) : v / 100;
    }
    return v;
  }

  double parsePrimary() {
    if (atEnd) throw const ExpressionException(ExpressionErrorKind.syntax);
    final t = tokens[pos++];
    switch (t.type) {
      case _T.number:
        return t.value;
      case _T.lparen:
        final v = parseExpression();
        // Auto-close missing trailing parentheses, like most calculators.
        if (!atEnd && peek.type == _T.rparen) pos++;
        return v;
      case _T.ident:
        return _identifier(t.text);
      default:
        throw ExpressionException(ExpressionErrorKind.syntax, t.text);
    }
  }

  double _identifier(String name) {
    if (expressionFunctions.contains(name)) {
      // The argument binds tighter than ^ so that sin(30)^2 = (sin 30)².
      final arg = parsePostfix();
      return _apply(name, arg);
    }
    switch (name) {
      case 'pi':
        return math.pi;
      case 'e':
        return math.e;
      case 'Ans':
      case 'ans':
        return ans ?? 0;
    }
    final c = constantByKey(name);
    if (c != null) return c.value;
    throw ExpressionException(ExpressionErrorKind.unknownName, name);
  }

  double _toRad(double x) =>
      angleMode == AngleMode.degrees ? x * math.pi / 180 : x;
  double _fromRad(double x) =>
      angleMode == AngleMode.degrees ? x * 180 / math.pi : x;

  double _apply(String f, double x) {
    double domain(bool ok, double Function() fn) {
      if (!ok) throw const ExpressionException(ExpressionErrorKind.domain);
      return fn();
    }

    switch (f) {
      case 'sin':
        return _clean(math.sin(_toRad(x)));
      case 'cos':
        return _clean(math.cos(_toRad(x)));
      case 'tan':
        final c = _clean(math.cos(_toRad(x)));
        return domain(c != 0, () => _clean(math.tan(_toRad(x))));
      case 'asin':
        return domain(x.abs() <= 1, () => _fromRad(math.asin(x)));
      case 'acos':
        return domain(x.abs() <= 1, () => _fromRad(math.acos(x)));
      case 'atan':
        return _fromRad(math.atan(x));
      case 'sinh':
        return (math.exp(x) - math.exp(-x)) / 2;
      case 'cosh':
        return (math.exp(x) + math.exp(-x)) / 2;
      case 'tanh':
        final a = math.exp(2 * x);
        return a.isInfinite ? 1 : (a - 1) / (a + 1);
      case 'asinh':
        return math.log(x + math.sqrt(x * x + 1));
      case 'acosh':
        return domain(x >= 1, () => math.log(x + math.sqrt(x * x - 1)));
      case 'atanh':
        return domain(x.abs() < 1, () => 0.5 * math.log((1 + x) / (1 - x)));
      case 'ln':
        return domain(x > 0, () => math.log(x));
      case 'log':
        return domain(x > 0, () => _log10(x));
      case 'exp':
        return math.exp(x);
      case 'sqrt':
        return domain(x >= 0, () => math.sqrt(x));
      case 'cbrt':
        return x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();
      case 'abs':
        return x.abs();
    }
    throw ExpressionException(ExpressionErrorKind.unknownName, f);
  }
}

/// log10 that returns exact integers for exact powers of ten.
double _log10(double x) {
  final r = math.log(x) / math.ln10;
  final rounded = r.roundToDouble();
  if ((r - rounded).abs() < 1e-12 && math.pow(10, rounded) == x) return rounded;
  return r;
}

/// Removes floating point noise such as sin(180°) = 1.2e-16.
double _clean(double v) => v.abs() < 1e-15 ? 0 : v;

double _factorial(double n) {
  if (n < 0 || n != n.roundToDouble()) {
    throw const ExpressionException(ExpressionErrorKind.domain);
  }
  if (n > 170) throw const ExpressionException(ExpressionErrorKind.overflow);
  var r = 1.0;
  for (var i = 2; i <= n; i++) {
    r *= i;
  }
  return r;
}
