import 'package:flutter_test/flutter_test.dart';
import 'package:kimya_hesap/core/chem/element.dart';

/// Standard atomic weights from the IUPAC Commission on Isotopic
/// Abundances and Atomic Weights (CIAAW, https://ciaaw.org/atomic-weights.htm,
/// including the 2024 revisions of Gd, Lu and Zr): value and uncertainty.
const _ciaaw = <String, (double, double)>{
    'He': (4.002602, 2e-06),
    'Be': (9.0121831, 5e-07),
    'F': (18.998403162, 5e-09),
    'Ne': (20.1797, 6e-04),
    'Na': (22.98976928, 2e-08),
    'Al': (26.9815384, 3e-07),
    'P': (30.973761998, 5e-09),
    'K': (39.0983, 1e-04),
    'Ca': (40.078, 4e-03),
    'Sc': (44.955907, 4e-06),
    'Ti': (47.867, 1e-03),
    'V': (50.9415, 1e-04),
    'Cr': (51.9961, 6e-04),
    'Mn': (54.938043, 2e-06),
    'Fe': (55.845, 2e-03),
    'Co': (58.933194, 3e-06),
    'Ni': (58.6934, 4e-04),
    'Cu': (63.546, 3e-03),
    'Zn': (65.38, 2e-02),
    'Ga': (69.723, 1e-03),
    'Ge': (72.630, 8e-03),
    'As': (74.921595, 6e-06),
    'Se': (78.971, 8e-03),
    'Kr': (83.798, 2e-03),
    'Rb': (85.4678, 3e-04),
    'Sr': (87.62, 1e-02),
    'Y': (88.905838, 2e-06),
    'Zr': (91.222, 3e-03),
    'Nb': (92.90637, 1e-05),
    'Mo': (95.95, 1e-02),
    'Ru': (101.07, 2e-02),
    'Rh': (102.90549, 2e-05),
    'Pd': (106.42, 1e-02),
    'Ag': (107.8682, 2e-04),
    'Cd': (112.414, 4e-03),
    'In': (114.818, 1e-03),
    'Sn': (118.710, 7e-03),
    'Sb': (121.760, 1e-03),
    'Te': (127.60, 3e-02),
    'I': (126.90447, 3e-05),
    'Xe': (131.293, 6e-03),
    'Cs': (132.90545196, 6e-08),
    'Ba': (137.327, 7e-03),
    'La': (138.90547, 7e-05),
    'Ce': (140.116, 1e-03),
    'Pr': (140.90766, 1e-05),
    'Nd': (144.242, 3e-03),
    'Sm': (150.36, 2e-02),
    'Eu': (151.964, 1e-03),
    'Gd': (157.249, 2e-03),
    'Tb': (158.925354, 7e-06),
    'Dy': (162.500, 1e-03),
    'Ho': (164.930329, 5e-06),
    'Er': (167.259, 3e-03),
    'Tm': (168.934219, 5e-06),
    'Yb': (173.045, 1e-02),
    'Lu': (174.96669, 5e-05),
    'Hf': (178.486, 6e-03),
    'Ta': (180.94788, 2e-05),
    'W': (183.84, 1e-02),
    'Re': (186.207, 1e-03),
    'Os': (190.23, 3e-02),
    'Ir': (192.217, 2e-03),
    'Pt': (195.084, 9e-03),
    'Au': (196.966570, 4e-06),
    'Hg': (200.592, 3e-03),
    'Bi': (208.98040, 1e-05),
    'Th': (232.0377, 4e-04),
    'Pa': (231.03588, 1e-05),
    'U': (238.02891, 3e-05),
};

/// Elements whose standard atomic weight is an interval; the app uses the
/// IUPAC conventional value, which lies inside it up to its rounding
/// (e.g. Tl: 204.38 vs [204.382, 204.385]).
const _intervals = <String, (double, double)>{
    'H': (1.00784, 1.00811),
    'Li': (6.938, 6.997),
    'B': (10.806, 10.821),
    'C': (12.0096, 12.0116),
    'N': (14.00643, 14.00728),
    'O': (15.99903, 15.99977),
    'Mg': (24.304, 24.307),
    'Si': (28.084, 28.086),
    'S': (32.059, 32.076),
    'Cl': (35.446, 35.457),
    'Ar': (39.792, 39.963),
    'Br': (79.901, 79.907),
    'Tl': (204.382, 204.385),
    'Pb': (206.14, 207.94),
};

void main() {
  test('atomic weights agree with CIAAW', () {
    _ciaaw.forEach((sym, ref) {
      final e = PeriodicTable.bySymbol(sym)!;
      expect(e.massIsMassNumber, isFalse, reason: sym);
      expect(e.atomicMass, closeTo(ref.$1, ref.$2 + 1e-12), reason: sym);
    });
    _intervals.forEach((sym, range) {
      final m = PeriodicTable.bySymbol(sym)!.atomicMass;
      expect(m, inInclusiveRange(range.$1 - 0.005, range.$2 + 0.005), reason: sym);
    });
  });

  test('conventional values match the IUPAC table', () {
    const conventional = {
      'H': 1.008, 'Li': 6.94, 'B': 10.81, 'C': 12.011, 'N': 14.007, 'O': 15.999,
      'Mg': 24.305, 'Si': 28.085, 'S': 32.06, 'Cl': 35.45, 'Ar': 39.95,
      'Br': 79.904, 'Tl': 204.38, 'Pb': 207.2,
    };
    conventional.forEach((sym, v) => expect(PeriodicTable.bySymbol(sym)!.atomicMass, v, reason: sym));
    expect(conventional.keys.toSet(), _intervals.keys.toSet());
  });

  test('elements without a standard atomic weight are flagged', () {
    for (final e in PeriodicTable.elements) {
      final listed = _ciaaw.containsKey(e.symbol) || _intervals.containsKey(e.symbol);
      expect(e.massIsMassNumber, !listed, reason: e.symbol);
    }
  });
}
