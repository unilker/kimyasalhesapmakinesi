part 'elements_data.dart';

enum ElementCategory {
  alkaliMetal,
  alkalineEarthMetal,
  transitionMetal,
  postTransitionMetal,
  metalloid,
  nonmetal,
  halogen,
  nobleGas,
  lanthanide,
  actinide,
  unknown,
}

enum MatterState { solid, liquid, gas, unknown }

enum ElementBlock { s, p, d, f }

class ChemElement {
  const ChemElement(
    this.number,
    this.symbol,
    this.nameEn,
    this.nameTr,
    this.atomicMass,
    this.massIsMassNumber,
    this.category,
    this.electronegativity,
    this.electronConfiguration,
    this.state,
    this.group,
    this.period,
  );

  final int number;
  final String symbol;
  final String nameEn;
  final String nameTr;

  /// Standard atomic weight in g/mol (u).
  final double atomicMass;

  /// True when [atomicMass] is the mass number of the longest-lived isotope
  /// (element has no stable isotopes), conventionally written in brackets.
  final bool massIsMassNumber;
  final ElementCategory category;

  /// Pauling electronegativity, null when not determined.
  final double? electronegativity;

  /// Ground-state electron configuration in noble-gas shorthand.
  final String electronConfiguration;
  final MatterState state;

  /// IUPAC group (1–18); null for the f-block rows (La–Lu, Ac–Lr).
  final int? group;
  final int period;

  String name(String languageCode) => languageCode == 'tr' ? nameTr : nameEn;

  bool get isFBlock => group == null;

  ElementBlock get block {
    if (group == null) return ElementBlock.f;
    if (number == 2 || group! <= 2) return ElementBlock.s;
    if (group! <= 12) return ElementBlock.d;
    return ElementBlock.p;
  }

  /// Number of valence electrons for main-group elements (null for d/f block).
  int? get valenceElectrons {
    if (number == 2) return 2;
    final g = group;
    if (g == null || (g >= 3 && g <= 12)) return null;
    return g <= 2 ? g : g - 10;
  }

  /// Column (1–18) and row (1–10) of this element in the standard wide
  /// periodic table layout, where rows 9 and 10 hold the lanthanides and
  /// actinides.
  ({int column, int row}) get tablePosition {
    if (group != null) return (column: group!, row: period);
    final start = period == 6 ? 57 : 89;
    return (column: 3 + (number - start), row: period + 3);
  }
}

class PeriodicTable {
  PeriodicTable._();

  static const List<ChemElement> elements = _elementData;

  static final Map<String, ChemElement> _bySymbol = {
    for (final e in _elementData) e.symbol: e,
  };

  static ChemElement? bySymbol(String symbol) => _bySymbol[symbol];

  static ChemElement byNumber(int z) => _elementData[z - 1];

  static bool isSymbol(String symbol) => _bySymbol.containsKey(symbol);
}
