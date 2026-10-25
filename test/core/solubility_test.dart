import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/ice.dart';
import 'package:kimya_hesap/core/solubility.dart';
import 'package:kimya_hesap/core/thermochem.dart';

SaltData salt(String f) => kspTable.firstWhere((s) => s.formula == f);

void main() {
  test('every dissolution equation is balanced and the ICE solver gives s', () {
    expect(kspTable.length, 120);
    for (final s in kspTable) {
      final r = parseIceReaction(s.equation);
      expect(r.autoBalanced, isFalse, reason: s.formula);
      expect(r.species.first.inQ, isFalse, reason: s.formula);
      final res = solveIce(r.species, [0, 0, 0], s.ksp);
      // two independent routes: numeric ICE extent vs the closed form
      expect(res.extent, closeTo(s.molarSolubility, s.molarSolubility * 1e-9), reason: s.formula);
      expect(res.equilibrium[1], closeTo(s.cations * s.molarSolubility, s.molarSolubility * 1e-8));
    }
  });

  test('textbook molar solubilities', () {
    expect(salt('AgCl').molarSolubility, closeTo(1.330e-5, 0.001e-5));
    expect(salt('CaF2').molarSolubility, closeTo(math.pow(3.45e-11 / 4, 1 / 3), 1e-15));
    expect(salt('Ca3(PO4)2').molarSolubility, closeTo(math.pow(2.07e-33 / 108, 1 / 5), 1e-20));
    expect(salt('Hg2Cl2').cation, 'Hg2^2+');
    expect(salt('Hg2Cl2').anions, 2);
  });

  test('CRC Ksp agrees with Ksp from CODATA/CRC thermodynamic data', () {
    double thermoKsp(SaltData s) {
      ThermoEntry find(String f, String st) => thermoData.firstWhere(
          (e) => e.formula == f && e.state == st && (e.note == null || e.note!.en == 'calcite'));
      final solid = find(s.formula, 's'), c = find(s.cation, 'aq'), a = find(s.anion, 'aq');
      final dh = s.cations * c.dfH + s.anions * a.dfH - solid.dfH;
      final ds = s.cations * c.s + s.anions * a.s - solid.s;
      final dg = dh - 298.15 * ds / 1000;
      return math.exp(-dg * 1000 / (8.314462618 * 298.15));
    }

    for (final f in ['AgCl', 'AgBr', 'CaF2', 'Hg2Cl2', 'Hg2SO4', 'CaCO3', 'Ca(OH)2', 'PbCl2', 'CaSO4', 'Mg(OH)2']) {
      final s = salt(f);
      final ratio = math.log(thermoKsp(s) / s.ksp) / math.ln10;
      expect(ratio.abs(), lessThan(0.15), reason: '$f: log10(thermo/CRC) = $ratio');
    }
  });
}
