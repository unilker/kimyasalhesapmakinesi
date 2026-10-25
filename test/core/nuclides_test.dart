import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/nuclides.dart';
import 'package:kimya_hesap/core/solver_catalog.dart';

NuclideData n(String key) => nuclideTable.firstWhere((x) => x.key == key);

void main() {
  test('table sanity', () {
    final keys = <String>{};
    for (final x in nuclideTable) {
      expect(keys.add(x.key), isTrue);
      expect((x.atomicMass - x.massNumber).abs(), lessThan(0.15), reason: x.key);
      expect(x.halfLifeSeconds, greaterThan(0), reason: x.key);
      expect(x.modes, isNotEmpty, reason: x.key);
      // e+ and EC are sub-branches of B+ (ε) in NUBASE
      final hasEps = x.modes.any((m) => m.$1 == 'B+');
      final exact = x.modes
          .where((m) => m.$2 == '=' && !(hasEps && (m.$1 == 'e+' || m.$1 == 'EC')))
          .fold(0.0, (a, m) => a + m.$3);
      expect(exact, lessThanOrEqualTo(100.01), reason: x.key); // e.g. ¹³⁴Cs: B- = 100 (rounded) + EC = 0.0003
    }
    expect(nuclideTable.length, 86);
  });

  test('NUBASE2020 values', () {
    expect(n('14C').halfLifeText, '5.70');
    expect(n('14C').unit, 'ky');
    expect(n('99mTc').label, '⁹⁹ᵐTc');
    expect(n('99mTc').halfLifeSeconds, closeTo(6.0066 * 3600, 1e-9));
    expect(n('40K').abundance, 0.0117);
    for (final x in nuclideTable) {
      // uncertainties are plain numbers in the half-life unit (or empty)
      expect(x.uncertainty.isEmpty || double.tryParse(x.uncertainty) != null, isTrue, reason: x.key);
    }
    expect(n('14C').atomicMass, closeTo(14.003241988, 1e-9)); // AME2020
    expect(n('238U').modes.first, ('A', '=', 100.0));
    expect(n('22Na').modes, [('B+', '=', 100.0), ('e+', '=', 90.57), ('EC', '=', 9.43)]);
    expect(decayModeLabel('e+'), 'β⁺');
  });

  test('specific activities: ²²⁶Ra ≈ 0.989 Ci/g (the curie), ¹⁴C ≈ 4.5 Ci/g', () {
    expect(n('226Ra').specificActivity / 3.7e10, closeTo(0.989, 0.002));
    expect(n('14C').specificActivity / 3.7e10, closeTo(4.48, 0.01));
    expect(n('131I').fractionAfter(8.0249 * 86400), closeTo(0.5, 1e-12));
    expect(n('60Co').lambda, closeTo(math.ln2 / (5.2714 * 365.2422 * 86400), 1e-20));
  });

  test('decay and activity presets equal the NUBASE2020 table', () {
    final keys = {'¹⁴C': '14C', '³H': '3H', '⁶⁰Co': '60Co', '¹³⁷Cs': '137Cs', '⁹⁰Sr': '90Sr',
        '²²⁶Ra': '226Ra', '²³⁸U': '238U', '⁴⁰K': '40K'};
    for (final eq in nuclearEquations) {
      for (final p in eq.presets) {
        final x = n(keys[p.label.en]!);
        // presets are entered in years
        expect(p.values['th']! * 365.2422 * 86400, closeTo(x.halfLifeSeconds, x.halfLifeSeconds * 1e-12),
            reason: '${eq.id} ${p.label.en}');
        if (p.values['M'] != null) expect(p.values['M'], closeTo(x.atomicMass, 1e-9), reason: p.label.en);
      }
    }
  });
}
