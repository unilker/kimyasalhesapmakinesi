import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/titration.dart';

/// 50.0 mL of 0.100 M analyte titrated with 0.100 M titrant. Reference
/// values: the charge balance solved independently with scipy (brentq).
Titration t(Analyte a) =>
    Titration(analyte: a, concentration: 0.1, volume: 0.05, titrantConcentration: 0.1);

void main() {
  test('strong acid – strong base', () {
    final x = t(const Analyte.strongAcid());
    expect(x.pHAt(0), closeTo(1.0, 1e-9));
    expect(x.pHAt(0.025), closeTo(1.4771212547157537, 1e-9));
    expect(x.pHAt(0.05), closeTo(7.0, 1e-9));
    expect(x.pHAt(0.06), closeTo(11.958607314894325, 1e-9));
    expect(x.equivalenceVolumes, [closeTo(0.05, 1e-15)]);
  });

  test('strong base – strong acid', () {
    final x = t(const Analyte.strongBase());
    expect(x.pHAt(0.025), closeTo(12.522878745284245, 1e-9));
    expect(x.pHAt(0.05), closeTo(7.0, 1e-9));
  });

  test('acetic acid – NaOH', () {
    final x = t(const Analyte.weakAcid([4.756]));
    expect(x.pHAt(0), closeTo(2.8808757488262944, 1e-9));
    expect(x.pHAt(0.025), closeTo(4.756456525381417, 1e-9)); // ≈ pKa
    expect(x.pHAt(0.05), closeTo(8.727537982748947, 1e-9));
  });

  test('ammonia – HCl', () {
    final x = t(Analyte.weakBase([9.25]));
    expect(x.pHAt(0), closeTo(11.122104317703602, 1e-9));
    expect(x.pHAt(0.05), closeTo(5.275460798282086, 1e-9));
  });

  test('phosphoric acid – NaOH (three equivalence points)', () {
    final x = t(const Analyte.weakAcid([2.16, 7.21, 12.32]));
    expect(x.equivalenceVolumes.length, 3);
    expect(x.pHAt(0), closeTo(1.6369510084656667, 1e-9));
    expect(x.pHAt(0.05), closeTo(4.713298144350762, 1e-9));
    expect(x.pHAt(0.1), closeTo(9.658855159771765, 1e-9));
  });

  test('sodium carbonate – HCl', () {
    final x = t(const Analyte.baseSalt([6.35, 10.33], 2));
    expect(x.pHAt(0), closeTo(11.654962569897997, 1e-9));
    expect(x.pHAt(0.05), closeTo(8.33905653297718, 1e-9));
    expect(x.pHAt(0.1), closeTo(3.91435521797253, 1e-9));
  });

  test('curves are monotonic', () {
    for (final a in [
      const Analyte.strongAcid(),
      const Analyte.weakAcid([4.756]),
      const Analyte.weakAcid([2.16, 7.21, 12.32]),
    ]) {
      final c = t(a).curve();
      for (var i = 1; i < c.length; i++) {
        expect(c[i].pH, greaterThanOrEqualTo(c[i - 1].pH - 1e-9));
      }
    }
    final b = t(Analyte.weakBase([9.25])).curve();
    for (var i = 1; i < b.length; i++) {
      expect(b[i].pH, lessThanOrEqualTo(b[i - 1].pH + 1e-9));
    }
  });

  test('indicator suggestions', () {
    expect(indicatorsFor(8.73).map((i) => i.nameEn), containsAll(['Phenolphthalein']));
    expect(indicatorsFor(5.28).map((i) => i.nameEn), contains('Methyl red'));
    expect(indicatorsFor(7.0).map((i) => i.nameEn), contains('Bromothymol blue'));
  });
}
