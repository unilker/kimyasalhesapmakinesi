// Evaluates tool/crosscheck/out_expr_in.json with the app's expression
// parser (see expressions.py).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/math/expression.dart';

void main() {
  test('evaluate', () {
    final cases = (jsonDecode(File('tool/crosscheck/out_expr_in.json').readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    for (final c in cases) {
      try {
        c['got'] = evaluateExpression(c['expr'] as String, angleMode: AngleMode.degrees);
      } on ExpressionException catch (e) {
        c['got'] = null;
        c['error'] = e.toString();
      }
    }
    File('tool/crosscheck/out_expr_out.json').writeAsStringSync(jsonEncode(cases));
  });
}
