import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/ui/tools/uncertainty_screen.dart';

void main() {
  test('value ± u rounded to two significant digits of u (GUM 7.2.6)', () {
    expect(roundedWithUncertainty(0.04281314168, 4.844e-5, '.'), '0.042813 ± 0.000048');
    expect(roundedWithUncertainty(1.5, 0.25, ','), '1,50 ± 0,25');
    expect(roundedWithUncertainty(12345.6, 23, '.'), '12346 ± 23');
    expect(roundedWithUncertainty(-3.14159, 0.0021, '.'), '−3.1416 ± 0.0021');
    expect(roundedWithUncertainty(1234, 150, '.'), isNull); // would need rounding left of the point
    expect(roundedWithUncertainty(1, 0, '.'), isNull);
  });
}
