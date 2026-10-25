import 'element.dart';

enum FormulaErrorKind {
  empty,
  unknownElement,
  unexpectedCharacter,
  unbalancedBracket,
  invalidNumber,
}

class FormulaException implements Exception {
  const FormulaException(this.kind, {this.detail = '', this.position = -1});

  final FormulaErrorKind kind;

  /// Offending symbol or character, if any.
  final String detail;
  final int position;

  @override
  String toString() => 'FormulaException($kind, "$detail" at $position)';
}

/// Masses of hydrogen isotopes that may be written as their own symbols.
const Map<String, double> isotopeSymbols = {
  'D': 2.01410177812,
  'T': 3.0160492779,
};

double? symbolMass(String symbol) =>
    PeriodicTable.bySymbol(symbol)?.atomicMass ?? isotopeSymbols[symbol];

class ElementShare {
  const ElementShare(this.symbol, this.count, this.mass, this.massFraction);

  final String symbol;
  final double count;

  /// Total mass contribution in g/mol.
  final double mass;

  /// 0..1
  final double massFraction;
}

/// A parsed chemical formula such as `CuSO4·5H2O`, `Ca(OH)2` or `SO4^2-`.
class ChemicalFormula {
  ChemicalFormula._(this.input, this.atoms, this.charge, this.isElectron);

  /// Parses [input]. Throws [FormulaException] on invalid input.
  factory ChemicalFormula.parse(String input) {
    final p = _FormulaParser(input);
    return p.parse();
  }

  static ChemicalFormula? tryParse(String input) {
    try {
      return ChemicalFormula.parse(input);
    } on FormulaException {
      return null;
    }
  }

  final String input;

  /// Atom counts in order of first appearance.
  final Map<String, double> atoms;
  final int charge;

  /// True for the free electron species (`e-`), used in redox half reactions.
  final bool isElectron;

  /// This formula with [delta] atoms added (negative counts remove atoms)
  /// and [charge] as the new charge, e.g. M → [M+H]⁺. Null when more atoms
  /// would be removed than there are.
  ChemicalFormula? withAtoms(Map<String, double> delta, int charge) {
    final next = Map<String, double>.of(atoms);
    for (final e in delta.entries) {
      final n = (next[e.key] ?? 0) + e.value;
      if (n < -1e-9) return null;
      if (n.abs() < 1e-9) {
        next.remove(e.key);
      } else {
        next[e.key] = n;
      }
    }
    if (next.isEmpty) return null;
    return ChemicalFormula._(input, next, charge, false);
  }

  double get molarMass {
    var sum = 0.0;
    atoms.forEach((s, n) => sum += symbolMass(s)! * n);
    return sum;
  }

  List<ElementShare> get composition {
    final total = molarMass;
    return [
      for (final e in atoms.entries)
        ElementShare(
          e.key,
          e.value,
          symbolMass(e.key)! * e.value,
          total == 0 ? 0 : symbolMass(e.key)! * e.value / total,
        ),
    ];
  }

  double get totalAtoms => atoms.values.fold(0.0, (a, b) => a + b);

  /// Display form with Unicode subscripts, middle-dot adducts and
  /// superscript charge, e.g. `CuSO₄·5H₂O`, `SO₄²⁻`.
  String get pretty => prettyFormula(input);
}

class _FormulaParser {
  _FormulaParser(String raw) : s = _normalize(raw);

  final String s;
  int i = 0;

  static String _normalize(String raw) {
    const sub = '₀₁₂₃₄₅₆₇₈₉';
    const sup = '⁰¹²³⁴⁵⁶⁷⁸⁹';
    final b = StringBuffer();
    var inSup = false;
    for (final r in raw.trim().runes) {
      final ch = String.fromCharCode(r);
      final si = sub.indexOf(ch);
      final pi = sup.indexOf(ch);
      if (si >= 0) {
        b.write(si);
        inSup = false;
      } else if (pi >= 0 || ch == '⁺' || ch == '⁻') {
        if (!inSup) b.write('^');
        inSup = true;
        b.write(pi >= 0 ? '$pi' : (ch == '⁺' ? '+' : '-'));
      } else if (ch == ' ') {
        inSup = false;
      } else {
        inSup = false;
        b.write(switch (ch) {
          '•' || '∙' || '⋅' || '×' => '·',
          '−' || '–' => '-',
          _ => ch,
        });
      }
    }
    return b.toString();
  }

  bool get atEnd => i >= s.length;
  String get ch => s[i];

  ChemicalFormula parse() {
    if (s.isEmpty) throw const FormulaException(FormulaErrorKind.empty);
    if (s == 'e' || s == 'e-' || s == 'e^-' || s == 'e^1-') {
      return ChemicalFormula._(s, const {}, -1, true);
    }
    final atoms = <String, double>{};
    while (true) {
      final coef = _readCoefficient() ?? 1.0;
      final part = _parseSequence(closing: null);
      if (part.isEmpty) {
        throw FormulaException(
          atEnd ? FormulaErrorKind.empty : FormulaErrorKind.unexpectedCharacter,
          detail: atEnd ? '' : ch,
          position: i,
        );
      }
      part.forEach((k, v) => atoms[k] = (atoms[k] ?? 0) + v * coef);
      if (!atEnd && _isSeparator()) {
        i++;
        continue;
      }
      break;
    }
    final charge = _parseCharge();
    if (!atEnd) {
      throw FormulaException(
        FormulaErrorKind.unexpectedCharacter,
        detail: ch,
        position: i,
      );
    }
    return ChemicalFormula._(s, atoms, charge, false);
  }

  bool _isSeparator() {
    final c = ch;
    if (c == '·' || c == '*') return true;
    if (c == '.' && i + 1 < s.length) {
      final n = s[i + 1];
      return _isDigit(n) || _isUpper(n) || '([{'.contains(n);
    }
    return false;
  }

  /// Leading multiplier like the `5` in `5H2O` (may be decimal: `0.5H2O`).
  double? _readCoefficient() {
    if (atEnd || !_isDigit(ch)) return null;
    final start = i;
    while (!atEnd && _isDigit(ch)) {
      i++;
    }
    if (!atEnd && ch == '.' && i + 1 < s.length && _isDigit(s[i + 1])) {
      i++;
      while (!atEnd && _isDigit(ch)) {
        i++;
      }
    }
    final v = double.tryParse(s.substring(start, i));
    if (v == null || v <= 0) {
      throw FormulaException(
        FormulaErrorKind.invalidNumber,
        detail: s.substring(start, i),
        position: start,
      );
    }
    return v;
  }

  Map<String, double> _parseSequence({required String? closing}) {
    final result = <String, double>{};
    void add(Map<String, double> m, double mult) =>
        m.forEach((k, v) => result[k] = (result[k] ?? 0) + v * mult);

    while (!atEnd) {
      final c = ch;
      if (_isUpper(c)) {
        final sym = _readSymbol();
        add({sym: 1}, _readSubscript());
      } else if (c == '(' || c == '[' || c == '{') {
        final close = switch (c) { '(' => ')', '[' => ']', _ => '}' };
        final open = i;
        i++;
        final inner = _parseSequence(closing: close);
        if (atEnd || ch != close) {
          throw FormulaException(
            FormulaErrorKind.unbalancedBracket,
            detail: c,
            position: open,
          );
        }
        i++;
        if (inner.isEmpty) {
          throw FormulaException(
            FormulaErrorKind.unexpectedCharacter,
            detail: close,
            position: i - 1,
          );
        }
        add(inner, _readSubscript());
      } else if (c == ')' || c == ']' || c == '}') {
        if (closing == c) return result;
        throw FormulaException(
          FormulaErrorKind.unbalancedBracket,
          detail: c,
          position: i,
        );
      } else {
        break;
      }
    }
    if (closing != null) {
      throw FormulaException(
        FormulaErrorKind.unbalancedBracket,
        detail: closing,
        position: i,
      );
    }
    return result;
  }

  String _readSymbol() {
    final start = i;
    i++;
    while (!atEnd && _isLower(ch)) {
      i++;
    }
    final sym = s.substring(start, i);
    if (symbolMass(sym) == null) {
      throw FormulaException(
        FormulaErrorKind.unknownElement,
        detail: sym,
        position: start,
      );
    }
    return sym;
  }

  double _readSubscript() {
    if (atEnd || !_isDigit(ch)) return 1;
    final start = i;
    while (!atEnd && _isDigit(ch)) {
      i++;
    }
    var text = s.substring(start, i);
    // A decimal subscript is only accepted with a zero integer part
    // (Fe0.95O) so that `CuSO4.5H2O` keeps its hydrate meaning.
    if (text == '0' &&
        !atEnd &&
        ch == '.' &&
        i + 1 < s.length &&
        _isDigit(s[i + 1])) {
      i++;
      while (!atEnd && _isDigit(ch)) {
        i++;
      }
      text = s.substring(start, i);
    }
    final v = double.parse(text);
    if (v <= 0) {
      throw FormulaException(
        FormulaErrorKind.invalidNumber,
        detail: text,
        position: start,
      );
    }
    return v;
  }

  int _parseCharge() {
    if (atEnd) return 0;
    if (ch == '^') {
      i++;
      final start = i;
      var digits = '';
      while (!atEnd && _isDigit(ch)) {
        digits += ch;
        i++;
      }
      if (atEnd || (ch != '+' && ch != '-')) {
        throw FormulaException(
          FormulaErrorKind.unexpectedCharacter,
          detail: atEnd ? '^' : ch,
          position: start,
        );
      }
      final sign = ch == '+' ? 1 : -1;
      i++;
      if (digits.isEmpty) {
        // Forms like ^+, ^2+ handled above; also accept ^+3 and ^++.
        while (!atEnd && _isDigit(ch)) {
          digits += ch;
          i++;
        }
        var extra = 0;
        while (!atEnd && ch == (sign > 0 ? '+' : '-')) {
          extra++;
          i++;
        }
        if (digits.isNotEmpty) return sign * int.parse(digits);
        return sign * (1 + extra);
      }
      return sign * int.parse(digits);
    }
    if (ch == '+' || ch == '-') {
      final sign = ch;
      var n = 0;
      while (!atEnd && ch == sign) {
        n++;
        i++;
      }
      return sign == '+' ? n : -n;
    }
    return 0;
  }
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
bool _isUpper(String c) => c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90;
bool _isLower(String c) => c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122;

const _subDigits = '₀₁₂₃₄₅₆₇₈₉';
const _supDigits = '⁰¹²³⁴⁵⁶⁷⁸⁹';

String toSubscript(String digits) => digits
    .split('')
    .map((c) => _isDigit(c) ? _subDigits[int.parse(c)] : c)
    .join();

String toSuperscript(String text) => text.split('').map((c) {
      if (_isDigit(c)) return _supDigits[int.parse(c)];
      if (c == '+') return '⁺';
      if (c == '-') return '⁻';
      return c;
    }).join();

/// Formats a plain-text formula for display: `H2SO4` → `H₂SO₄`,
/// `CuSO4*5H2O` → `CuSO₄·5H₂O`, `Fe^3+` → `Fe³⁺`.
String prettyFormula(String input) {
  final s = input.trim();
  final b = StringBuffer();
  var prev = '';
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '^') {
      b.write(toSuperscript(s.substring(i + 1)));
      break;
    }
    if (_isDigit(c)) {
      final start = i;
      while (i < s.length && _isDigit(s[i])) {
        i++;
      }
      // decimal part of a coefficient (0.5H2O) or a zero subscript (Fe0.95O)
      if (i + 1 < s.length && s[i] == '.' && _isDigit(s[i + 1])) {
        final intPart = s.substring(start, i);
        final isSubscript = prev.isNotEmpty &&
            (_isLetter(prev) || ')]}'.contains(prev));
        if (!isSubscript || intPart == '0') {
          i++;
          while (i < s.length && _isDigit(s[i])) {
            i++;
          }
        }
      }
      final num = s.substring(start, i);
      final isSubscript =
          prev.isNotEmpty && (_isLetter(prev) || ')]}'.contains(prev));
      b.write(isSubscript ? toSubscript(num) : num);
      prev = num[num.length - 1];
      continue;
    }
    if (c == '*' || c == '·' || c == '•') {
      b.write('·');
    } else if (c == '.' &&
        i + 1 < s.length &&
        (_isDigit(s[i + 1]) || _isUpper(s[i + 1]) || '([{'.contains(s[i + 1]))) {
      b.write('·');
    } else if ((c == '+' || c == '-') && i > 0) {
      b.write(toSuperscript(s.substring(i)));
      break;
    } else {
      b.write(c);
    }
    prev = c == '.' ? '·' : c;
    i++;
  }
  return b.toString();
}

bool _isLetter(String c) => _isUpper(c) || _isLower(c);

/// Pretty prints a whole equation: `Fe + O2 -> Fe2O3` → `Fe + O₂ → Fe₂O₃`.
String prettyEquation(String input) {
  final arrow = RegExp(r'\s*(<=>|<->|⇌|⟶|→|->|=>|=)\s*');
  final m = arrow.firstMatch(input);
  String side(String s) =>
      s.split(RegExp(r'\s+\+\s+')).map((t) => prettyFormula(t.trim())).join(' + ');
  if (m == null) return side(input);
  final a = m.group(1)!;
  final shown = a == '<=>' || a == '<->' || a == '⇌' ? '⇌' : '→';
  return '${side(input.substring(0, m.start))} $shown ${side(input.substring(m.end))}';
}
