import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/acids.dart';
import 'package:kimya_hesap/core/chem/formula.dart';

AcidData by(String en) => acidTable.firstWhere((a) => a.name.en == en);

void main() {
  test('table integrity', () {
    final names = <String>{};
    for (final a in acidTable) {
      expect(names.add(a.name.en), isTrue);
      expect(a.pKas, isNotEmpty);
      for (var i = 0; i < a.pKas.length; i++) {
        expect(a.pKas[i], lessThan(14), reason: a.name.en);
        if (i > 0) expect(a.pKas[i], greaterThan(a.pKas[i - 1]), reason: a.name.en);
      }
      expect(ChemicalFormula.tryParse(a.formula), isNotNull, reason: a.formula);
      if (a.isBase) {
        expect(a.pKas.single, closeTo(14 - a.pKb!, 1e-9), reason: a.name.en);
      }
    }
    expect(acidTable.where((a) => !a.isBase).length, 37);
    expect(acidTable.where((a) => a.isBase).length, 13);
  });

  test('CRC values used by the presets', () {
    expect(by('Acetic acid').pKas, [4.756]);
    expect(by('Phosphoric acid').pKas, [2.16, 7.21, 12.32]);
    expect(by('Carbonic acid').pKas, [6.35, 10.33]);
    expect(by('Citric acid').pKas, [3.13, 4.76, 6.40]);
    expect(by('Ammonia').pKas.single, closeTo(9.25, 1e-9));
    expect(by('Pyridine').pKb, 8.77);
    // steps beyond pKa 14 are dropped (H2S pKa2 ≈ 19)
    expect(by('Hydrogen sulfide').pKas, [7.05]);
  });
}
