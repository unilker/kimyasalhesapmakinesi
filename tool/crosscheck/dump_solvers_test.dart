// Dumps solver results for random inputs so that an independent reference
// implementation (tool/crosscheck/check_solvers.py) can verify them.
//   flutter test tool/crosscheck/dump_solvers_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/solver.dart';
import 'package:kimya_hesap/core/solver_catalog.dart';
import 'package:kimya_hesap/core/units.dart';

/// Plausible base-unit ranges per quantity (log-uniform).
(double, double) _range(Quantity q, String id) => switch (q) {
      Quantity.pressure => (1e3, 1e7),
      Quantity.volume => (1e-3, 50),
      Quantity.amount => (1e-4, 10),
      Quantity.temperature => (200, 800),
      Quantity.temperatureDifference => (0.1, 80),
      Quantity.mass => (1e-3, 500),
      Quantity.concentration => (1e-6, 5),
      Quantity.density => (1e-4, 3),
      Quantity.molarMass => (2, 400),
      Quantity.molarEnergy => (1e3, 2e5),
      Quantity.molarEntropy => (1, 300),
      Quantity.specificHeat => (0.1, 5),
      Quantity.time => (1, 1e5),
      Quantity.rateConstant => (1e-5, 1),
      Quantity.zeroOrderRate => (1e-7, 1e-3),
      Quantity.secondOrderRate => (1e-4, 10),
      Quantity.voltage => (0.05, 2.5),
      Quantity.current => (0.01, 10),
      Quantity.length => (1e-9, 1e-2),
      Quantity.absorptivity => (10, 1e5),
      Quantity.molality => (1e-3, 5),
      Quantity.cryoscopic => (0.3, 30),
      Quantity.percent => (1, 99),
      Quantity.speed => (1, 3000),
      Quantity.activity => (1, 1e12),
      Quantity.henry => (1e-4, 0.1),
      Quantity.vdwA => (0.03, 20),
      Quantity.vdwB => (0.01, 0.15),
      _ => (0.1, 10),
    };

void main() {
  test('dump', () {
    final rnd = Random(42);
    final all = {
      'gas': gasEquations, 'moles': moleEquations, 'solutions': solutionEquations,
      'dilution': dilutionEquations, 'acidBase': acidBaseEquations,
      'thermo': thermoEquations, 'kinetics': kineticsEquations,
      'electro': electroEquations, 'spectro': spectroEquations,
      'colligative': colligativeEquations, 'realGas': realGasEquations,
      'equilibrium': equilibriumEquations, 'nuclear': nuclearEquations,
      'atomic': atomicEquations,
    };
    final out = <Map<String, Object?>>[];
    all.forEach((group, eqs) {
      for (final eq in eqs) {
        for (final target in eq.solvers.keys) {
          for (var trial = 0; trial < 40; trial++) {
            final inputs = <String, double>{};
            for (final v in eq.variables) {
              if (v.id == target) continue;
              final (lo, hi) = _range(v.quantity, v.id);
              var x = exp(log(lo) + rnd.nextDouble() * (log(hi) - log(lo)));
              if (v.allowNegative && rnd.nextBool() && v.quantity != Quantity.temperature) x = -x;
              inputs[v.id] = x;
            }
            final r = solveEquation(eq, target, inputs);
            out.add({
              'group': group,
              'eq': eq.id,
              'target': target,
              'inputs': inputs,
              'ok': r.ok,
              'targetNeg': eq.variable(target).allowNegative,
              'value': r.ok ? r.value : null,
              'extras': r.ok ? r.extras : null,
            });
          }
        }
      }
    });
    File('tool/crosscheck/out_solvers.json').writeAsStringSync(jsonEncode(out));
  });
}
