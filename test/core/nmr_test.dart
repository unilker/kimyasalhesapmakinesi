import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/nmr.dart';

NmrNucleus n(String key) => nmrNuclei.firstWhere((x) => x.key == key);

void main() {
  test('receptivities computed from γ, I and abundance match the printed IUPAC values', () {
    // Independent check of the transcribed γ, spin and abundance columns.
    const printed = {
      '13C': 1.70e-4, '15N': 3.84e-6, '19F': 0.834, '29Si': 3.68e-4, '31P': 6.65e-2,
      '2H': 1.11e-6, '7Li': 0.271, '11B': 0.132, '17O': 1.11e-5, '23Na': 9.27e-2,
      '27Al': 0.207, '51V': 0.383, '59Co': 0.278, '195Pt': 3.51e-3, '119Sn': 4.53e-3,
      '207Pb': 2.01e-3, '133Cs': 4.84e-2, '127I': 9.54e-2, '209Bi': 0.144, '57Fe': 7.24e-7,
    };
    printed.forEach((k, v) {
      // the paper gives three significant figures
      expect(n(k).receptivityVsProton, closeTo(v, v * 0.006), reason: k);
    });
    expect(n('13C').receptivityVsCarbon, closeTo(1, 1e-12));
    expect(n('1H').receptivityVsCarbon, closeTo(5.87e3, 0.01e3));
  });

  test('Ξ agrees with the γ ratio within the chemical-shift range of each reference', () {
    final h = n('1H');
    for (final x in nmrNuclei) {
      final ratio = x.xi / 100 / (x.gamma.abs() / h.gamma);
      expect((ratio - 1).abs(), lessThan(0.02), reason: x.key);
    }
  });

  test('table sanity: abundances per element ≤ 100 %, spins', () {
    final byElement = <String, double>{};
    for (final x in nmrNuclei) {
      byElement[x.symbol] = (byElement[x.symbol] ?? 0) + x.abundance;
    }
    byElement.forEach((el, s) => expect(s, lessThanOrEqualTo(100.0001), reason: el));
    expect(n('1H').spinText, '1/2');
    expect(n('14N').spinText, '1');
    expect(n('209Bi').spinText, '9/2');
    expect(n('13C').isQuadrupolar, isFalse);
    expect(n('17O').isQuadrupolar, isTrue);
  });

  test('frequencies on a 400 MHz spectrometer', () {
    expect(n('13C').frequencyAt(400), closeTo(100.58008, 1e-9));
    expect(n('31P').frequencyAt(400), closeTo(161.922968, 1e-9));
    expect(n('19F').frequencyAt(400), closeTo(376.376044, 1e-9));
    // 400 MHz ¹H ≈ 9.395 T; ¹³C Larmor there ≈ 100.6 MHz
    final b = fieldForProtonMHz(400);
    expect(b, closeTo(9.3946, 1e-4));
    expect(n('13C').larmorMHz(b), closeTo(100.6, 0.05));
    expect(n('1H').larmorMHz(b), closeTo(400, 1e-9));
    // 1 ppm of ¹³C at 100.58 MHz is 100.58 Hz
    expect(ppmToHz(2.5, n('13C').frequencyAt(400)), closeTo(251.4502, 1e-4));
  });
}
