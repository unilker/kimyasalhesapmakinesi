import 'formula.dart';

/// Usual valences of the elements for which the degree of unsaturation is
/// defined.
const Map<String, int> _valence = {
  'H': 1, 'D': 1, 'T': 1, 'F': 1, 'Cl': 1, 'Br': 1, 'I': 1,
  'O': 2, 'S': 2, 'Se': 2,
  'B': 3, 'N': 3, 'P': 3, 'As': 3,
  'C': 4, 'Si': 4, 'Ge': 4,
};

/// Double-bond equivalents (rings + π bonds), DBE = 1 + Σ nᵢ(vᵢ − 2)/2.
/// Null when the formula contains an element without a usual valence
/// (e.g. metals). Even-electron ions give half-integers.
double? doubleBondEquivalents(ChemicalFormula f) {
  var sum = 0.0;
  for (final e in f.atoms.entries) {
    final v = _valence[e.key];
    if (v == null) return null;
    sum += e.value * (v - 2);
  }
  return 1 + sum / 2;
}
