import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/speciation.dart';

void main() {
  test('monoprotic: α = ½ at pH = pKa, Henderson–Hasselbalch elsewhere', () {
    final a = speciesFractions([4.756], 4.756);
    expect(a[0], closeTo(0.5, 1e-15));
    for (final ph in [2.0, 4.0, 6.5, 10.0]) {
      final f = speciesFractions([4.756], ph);
      expect(math.log(f[1] / f[0]) / math.ln10, closeTo(ph - 4.756, 1e-12));
    }
  });

  test('phosphoric acid: fractions sum to 1, H2PO4⁻ peaks between pKa1 and pKa2', () {
    const pk = [2.16, 7.21, 12.32];
    for (var ph = -2.0; ph <= 16; ph += 0.25) {
      final a = speciesFractions(pk, ph);
      expect(a.reduce((x, y) => x + y), closeTo(1, 1e-12));
      expect(a.every((v) => v >= 0 && v <= 1), isTrue);
    }
    // maximum of α1 at (pKa1 + pKa2)/2
    const mid = (2.16 + 7.21) / 2;
    final peak = speciesFractions(pk, mid)[1];
    expect(speciesFractions(pk, mid - 0.01)[1], lessThan(peak));
    expect(speciesFractions(pk, mid + 0.01)[1], lessThan(peak));
    // α1 = α2 at pH = pKa2
    final at = speciesFractions(pk, 7.21);
    expect(at[1], closeTo(at[2], 1e-12));
    expect(meanDeprotonation(pk, 7.21), closeTo(1.5, 1e-3));
  });

  test('extreme pH does not overflow', () {
    final a = speciesFractions([1, 3, 5, 7], 200);
    expect(a.last, closeTo(1, 1e-12));
    final b = speciesFractions([1, 3, 5, 7], -200);
    expect(b.first, closeTo(1, 1e-12));
  });

  test('agrees with the direct textbook formula for carbonic acid', () {
    const k1 = 4.4668359215096305e-7, k2 = 4.677351412871981e-11; // 10^-6.35, 10^-10.33
    for (final ph in [4.0, 6.35, 8.3, 10.33, 12.0]) {
      final h = math.pow(10, -ph).toDouble();
      final d = h * h + k1 * h + k1 * k2;
      final want = [h * h / d, k1 * h / d, k1 * k2 / d];
      final got = speciesFractions([6.35, 10.33], ph);
      for (var j = 0; j < 3; j++) {
        expect(got[j], closeTo(want[j], 1e-12), reason: 'pH $ph α$j');
      }
    }
  });
}
