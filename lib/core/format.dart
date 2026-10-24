import 'chem/formula.dart' show toSuperscript;

/// Number formatting used across the app.
class NumberFormatter {
  const NumberFormatter({this.significantDigits = 6, this.decimalSeparator = '.'});

  final int significantDigits;
  final String decimalSeparator;

  /// Display form, e.g. `1,2345 × 10⁻⁵` or `22,414`.
  String format(double v, {int? digits}) {
    final sig = digits ?? significantDigits;
    if (v.isNaN) return '—';
    if (v.isInfinite) return v > 0 ? '∞' : '−∞';
    if (v == 0) return '0';
    final a = double.parse(v.abs().toStringAsPrecision(sig));
    if (a >= 1e6 || a < 1e-3) {
      final (mant, exp) = _scientific(v, sig);
      final m = _sep(mant).replaceFirst('-', '−');
      if (exp == 0) return m;
      return '$m × 10${toSuperscript('$exp')}';
    }
    var s = v.toStringAsPrecision(sig);
    if (s.contains('e')) {
      s = double.parse(s).toString();
    }
    return _sep(_trimZeros(s)).replaceFirst('-', '−');
  }

  /// Text suitable for the clipboard and for re-entering in input fields,
  /// e.g. `1,2345E-5`.
  String plain(double v, {int? digits}) {
    final sig = digits ?? significantDigits;
    if (!v.isFinite) return '';
    if (v == 0) return '0';
    final a = double.parse(v.abs().toStringAsPrecision(sig));
    if (a >= 1e6 || a < 1e-3) {
      final (mant, exp) = _scientific(v, sig);
      return '${_sep(mant)}E$exp';
    }
    return _sep(_trimZeros(v.toStringAsPrecision(sig)));
  }

  (String, int) _scientific(double v, int sig) {
    final s = v.toStringAsExponential((sig - 1).clamp(0, 20));
    final parts = s.split('e');
    var mant = _trimZeros(parts[0]);
    var exp = int.parse(parts[1]);
    if (mant == '10' || mant == '-10') {
      mant = mant.startsWith('-') ? '-1' : '1';
      exp += 1;
    }
    return (mant, exp);
  }

  String _sep(String s) =>
      decimalSeparator == '.' ? s : s.replaceAll('.', decimalSeparator);

  static String _trimZeros(String s) {
    if (!s.contains('.')) return s;
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }
}
