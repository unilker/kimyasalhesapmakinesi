import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/constants.dart';

double c(String key) => constantByKey(key)!.value;

void main() {
  test('constants are consistent with the SI 2019 definitions', () {
    expect(c('R'), c('NA') * c('kB'));
    expect(c('F'), c('NA') * c('qe'));
    expect(c('R'), closeTo(8.314462618, 1e-9)); // NIST's truncated listing
    expect(c('F'), closeTo(96485.33212, 1e-5));
    expect(c('Ratm'), closeTo(c('R') / 101.325, 1e-15));
    expect(c('Rcal'), closeTo(c('R') / 4.184, 1e-13));
    expect(c('Vm'), closeTo(c('R') * 273.15 / 101325 * 1000, 1e-8));
    expect(c('VmSTP'), closeTo(c('R') * 273.15 / 100000 * 1000, 1e-8));
    // Since 2019 the molar mass constant is only approximately 1 g/mol
    // (1.000 000 001 05 g/mol), so u ≈ 1 g/mol / N_A to ~1e-9.
    expect(c('u') / (1e-3 / c('NA')), closeTo(1, 2e-9));
  });

  test('CODATA 2022 values', () {
    expect(c('me'), 9.1093837139e-31);
    expect(c('mp'), 1.67262192595e-27);
    expect(c('mn'), 1.67492750056e-27);
    expect(c('u'), 1.66053906892e-27);
    expect(c('eps'), 8.8541878188e-12);
    expect(c('Ry'), 10973731.568157);
    expect(c('aB'), 5.29177210544e-11);
  });

  test('keys are unique', () {
    final keys = physicalConstants.map((c) => c.key).toList();
    expect(keys.toSet().length, keys.length);
  });
}
