import 'dart:math' as math;

import 'bi.dart';
import 'constants.dart';
import 'solver.dart';
import 'units.dart';

const double _r = gasConstant;

/// Molar mass of water from the app's atomic weights (H 1.008, O 15.999).
const double _mWater = 2 * 1.008 + 15.999;
const double _f = faraday;

/// Ion product of water at 25 °C.
const double kw = 1e-14;

double _log10(double x) => math.log(x) / math.ln10;
double _pow10(double x) => math.pow(10, x).toDouble();

// ---------------------------------------------------------------------------
// Variable factories
// ---------------------------------------------------------------------------

SolverVar _p(String id, String sym,
        {Bi? name, String unit = 'atm', String? symTr}) =>
    SolverVar(id, sym, name ?? const Bi('Pressure', 'Basınç'),
        Quantity.pressure,
        unit: unit, symbolTr: symTr);
SolverVar _v(String id, String sym, {Bi? name, String unit = 'L'}) =>
    SolverVar(id, sym, name ?? const Bi('Volume', 'Hacim'), Quantity.volume,
        unit: unit);
SolverVar _t(String id, String sym, {Bi? name, String unit = 'K', double? def}) =>
    SolverVar(id, sym, name ?? const Bi('Temperature', 'Sıcaklık'),
        Quantity.temperature,
        unit: unit, defaultValue: def);
SolverVar _n(String id, String sym, {Bi? name, String unit = 'mol'}) =>
    SolverVar(id, sym, name ?? const Bi('Amount of substance', 'Madde miktarı'),
        Quantity.amount,
        unit: unit);
SolverVar _m(String id, String sym,
        {Bi? name, String unit = 'g', String? symTr}) =>
    SolverVar(id, sym, name ?? const Bi('Mass', 'Kütle'), Quantity.mass,
        unit: unit, symbolTr: symTr);
SolverVar _c(String id, String sym,
        {Bi? name, String unit = 'M', String? symTr}) =>
    SolverVar(id, sym, name ?? const Bi('Concentration', 'Derişim'),
        Quantity.concentration,
        unit: unit, symbolTr: symTr);
SolverVar _mm(String id, String sym, {Bi? name}) => SolverVar(
      id,
      sym,
      name ?? const Bi('Molar mass', 'Mol kütlesi'),
      Quantity.molarMass,
      molarMassFromFormula: true,
    );
SolverVar _num(String id, String sym, Bi name,
        {double? def, bool neg = false, String? symTr}) =>
    SolverVar(id, sym, name, Quantity.dimensionless,
        defaultValue: def, allowNegative: neg, symbolTr: symTr);
SolverVar _pct(String id, String sym, Bi name) =>
    SolverVar(id, sym, name, Quantity.percent);

const _molFrac = Bi('Mole fraction', 'Mol kesri');
const _vanHoffI = Bi("van 't Hoff factor", "van 't Hoff faktörü");
const _electrons = Bi('Electrons transferred', 'Aktarılan elektron sayısı');

/// Builds the solvers of a two-point equation of the form
/// ln(y2/y1) = −H/R · (1/T2 − 1/T1) (Clausius–Clapeyron, van 't Hoff,
/// two-point Arrhenius).
Map<String, SolveFn> _twoPoint(String y1, String y2, String h) {
  double inv(Values v) => 1 / v['T2']! - 1 / v['T1']!;
  return {
    y2: (v) => v[y1]! * math.exp(-v[h]! / _r * inv(v)),
    y1: (v) => v[y2]! / math.exp(-v[h]! / _r * inv(v)),
    h: (v) => -_r * math.log(v[y2]! / v[y1]!) / inv(v),
    'T2': (v) => 1 / (1 / v['T1']! - _r * math.log(v[y2]! / v[y1]!) / v[h]!),
    'T1': (v) => 1 / (1 / v['T2']! + _r * math.log(v[y2]! / v[y1]!) / v[h]!),
  };
}

// ---------------------------------------------------------------------------
// Gas laws
// ---------------------------------------------------------------------------

final gasEquations = <SolverEquation>[
  SolverEquation(
    id: 'idealGas',
    title: const Bi('Ideal gas law', 'İdeal gaz yasası'),
    formula: 'PV = nRT',
    defaultTarget: 'V',
    variables: [
      _p('P', 'P'),
      _v('V', 'V'),
      _n('n', 'n'),
      _t('T', 'T', unit: 'C'),
    ],
    solvers: {
      'P': (v) => v['n']! * _r * v['T']! / (v['V']! / 1000),
      'V': (v) => v['n']! * _r * v['T']! / v['P']! * 1000,
      'n': (v) => v['P']! * v['V']! / 1000 / (_r * v['T']!),
      'T': (v) => v['P']! * v['V']! / 1000 / (v['n']! * _r),
    },
  ),
  SolverEquation(
    id: 'combinedGas',
    title: const Bi('Combined gas law', 'Birleşik gaz yasası'),
    formula: 'P₁V₁ / T₁ = P₂V₂ / T₂',
    defaultTarget: 'V2',
    variables: [
      _p('P1', 'P₁', name: const Bi('Initial pressure', 'İlk basınç')),
      _v('V1', 'V₁', name: const Bi('Initial volume', 'İlk hacim')),
      _t('T1', 'T₁', name: const Bi('Initial temperature', 'İlk sıcaklık')),
      _p('P2', 'P₂', name: const Bi('Final pressure', 'Son basınç')),
      _v('V2', 'V₂', name: const Bi('Final volume', 'Son hacim')),
      _t('T2', 'T₂', name: const Bi('Final temperature', 'Son sıcaklık')),
    ],
    solvers: {
      'P1': (v) => v['P2']! * v['V2']! * v['T1']! / (v['T2']! * v['V1']!),
      'V1': (v) => v['P2']! * v['V2']! * v['T1']! / (v['T2']! * v['P1']!),
      'T1': (v) => v['P1']! * v['V1']! * v['T2']! / (v['P2']! * v['V2']!),
      'P2': (v) => v['P1']! * v['V1']! * v['T2']! / (v['T1']! * v['V2']!),
      'V2': (v) => v['P1']! * v['V1']! * v['T2']! / (v['T1']! * v['P2']!),
      'T2': (v) => v['P2']! * v['V2']! * v['T1']! / (v['P1']! * v['V1']!),
    },
    note: const Bi(
      'Set equal values for any quantity that stays constant (Boyle, Charles, Gay-Lussac).',
      'Sabit kalan nicelik için iki tarafa aynı değeri girin (Boyle, Charles, Gay-Lussac).',
    ),
  ),
  SolverEquation(
    id: 'gasDensity',
    title: const Bi('Gas density', 'Gaz yoğunluğu'),
    formula: 'd = PM / RT',
    defaultTarget: 'd',
    variables: [
      const SolverVar('d', 'd', Bi('Density', 'Yoğunluk'), Quantity.density,
          unit: 'gL'),
      _p('P', 'P'),
      _mm('M', 'M'),
      _t('T', 'T', unit: 'C'),
    ],
    solvers: {
      'd': (v) => v['P']! * v['M']! / (_r * v['T']!) / 1e6,
      'P': (v) => v['d']! * 1e6 * _r * v['T']! / v['M']!,
      'M': (v) => v['d']! * 1e6 * _r * v['T']! / v['P']!,
      'T': (v) => v['P']! * v['M']! / (_r * v['d']! * 1e6),
    },
  ),
  SolverEquation(
    id: 'dalton',
    title: const Bi("Dalton's partial pressure", 'Dalton kısmi basınç yasası'),
    formula: 'Pᵢ = xᵢ · P_total',
    formulaTr: 'Pᵢ = xᵢ · P_toplam',
    defaultTarget: 'Pi',
    variables: [
      _p('Pi', 'Pᵢ', name: const Bi('Partial pressure', 'Kısmi basınç')),
      _num('x', 'xᵢ', _molFrac),
      _p('Pt', 'P_total',
          symTr: 'P_toplam', name: const Bi('Total pressure', 'Toplam basınç')),
    ],
    solvers: {
      'Pi': (v) => v['x']! * v['Pt']!,
      'x': (v) => v['Pi']! / v['Pt']!,
      'Pt': (v) => v['Pi']! / v['x']!,
    },
  ),
  SolverEquation(
    id: 'graham',
    title: const Bi("Graham's law of effusion", 'Graham difüzyon yasası'),
    formula: 'r₁ / r₂ = √(M₂ / M₁)',
    defaultTarget: 'r1',
    variables: [
      _num('r1', 'r₁', const Bi('Rate of gas 1', '1. gazın hızı')),
      _num('r2', 'r₂', const Bi('Rate of gas 2', '2. gazın hızı')),
      _mm('M1', 'M₁', name: const Bi('Molar mass of gas 1', '1. gazın mol kütlesi')),
      _mm('M2', 'M₂', name: const Bi('Molar mass of gas 2', '2. gazın mol kütlesi')),
    ],
    solvers: {
      'r1': (v) => v['r2']! * math.sqrt(v['M2']! / v['M1']!),
      'r2': (v) => v['r1']! / math.sqrt(v['M2']! / v['M1']!),
      'M1': (v) => v['M2']! * math.pow(v['r2']! / v['r1']!, 2),
      'M2': (v) => v['M1']! * math.pow(v['r1']! / v['r2']!, 2),
    },
  ),
];

// ---------------------------------------------------------------------------
// Moles & yield
// ---------------------------------------------------------------------------

final moleEquations = <SolverEquation>[
  SolverEquation(
    id: 'massMoles',
    title: const Bi('Mass ⇄ moles', 'Kütle ⇄ mol'),
    formula: 'n = m / M',
    defaultTarget: 'n',
    variables: [_n('n', 'n'), _m('m', 'm'), _mm('M', 'M')],
    solvers: {
      'n': (v) => v['m']! / v['M']!,
      'm': (v) => v['n']! * v['M']!,
      'M': (v) => v['m']! / v['n']!,
    },
    extras: [
      SolverExtra('N', const Bi('Number of particles', 'Tanecik sayısı'),
          Quantity.dimensionless, (v) => v['n']! * avogadro),
    ],
  ),
  SolverEquation(
    id: 'particles',
    title: const Bi('Moles ⇄ particles', 'Mol ⇄ tanecik sayısı'),
    formula: 'N = n · Nₐ',
    defaultTarget: 'N',
    variables: [
      _num('N', 'N', const Bi('Number of particles', 'Tanecik sayısı')),
      _n('n', 'n'),
    ],
    solvers: {
      'N': (v) => v['n']! * avogadro,
      'n': (v) => v['N']! / avogadro,
    },
  ),
  SolverEquation(
    id: 'gasStp',
    title: const Bi('Gas volume at STP', 'NŞA’da gaz hacmi'),
    formula: 'n = V / 22.414 L·mol⁻¹',
    defaultTarget: 'V',
    variables: [_n('n', 'n'), _v('V', 'V')],
    solvers: {
      'n': (v) => v['V']! / molarVolumeAtm,
      'V': (v) => v['n']! * molarVolumeAtm,
    },
    note: const Bi('STP: 0 °C and 1 atm.', 'NŞA: 0 °C ve 1 atm.'),
  ),
  SolverEquation(
    id: 'hydrate',
    title: const Bi('Water of crystallisation', 'Kristal suyu sayısı'),
    formula: 'x = (m_water / M_H₂O) / (m_anhydrous / M)',
    formulaTr: 'x = (m_su / M_H₂O) / (m_susuz / M)',
    defaultTarget: 'x',
    variables: [
      _num('x', 'x', const Bi('Water molecules per formula unit', 'Formül başına su molekülü')),
      _m('mh', 'm_hydrate',
          symTr: 'm_hidrat', name: const Bi('Mass of hydrate', 'Hidrat kütlesi')),
      _m('ma', 'm_anhydrous',
          symTr: 'm_susuz', name: const Bi('Mass after heating', 'Isıtma sonrası kütle')),
      _mm('M', 'M', name: const Bi('Molar mass of anhydrous salt', 'Susuz tuzun mol kütlesi')),
    ],
    solvers: {
      'x': (v) => (v['mh']! - v['ma']!) / _mWater / (v['ma']! / v['M']!),
      'mh': (v) => v['ma']! * (1 + v['x']! * _mWater / v['M']!),
      'ma': (v) => v['mh']! / (1 + v['x']! * _mWater / v['M']!),
      'M': (v) => v['x']! * _mWater * v['ma']! / (v['mh']! - v['ma']!),
    },
    note: const Bi(
      'E.g. 2.50 g CuSO₄·xH₂O → 1.60 g CuSO₄ gives x ≈ 5.',
      'Ör. 2,50 g CuSO₄·xH₂O → 1,60 g CuSO₄ için x ≈ 5.',
    ),
  ),
  SolverEquation(
    id: 'percentYield',
    title: const Bi('Percent yield', 'Yüzde verim'),
    formula: '% yield = actual / theoretical × 100',
    formulaTr: '% verim = gerçek / teorik × 100',
    defaultTarget: 'y',
    variables: [
      _pct('y', '%', const Bi('Percent yield', 'Yüzde verim')),
      _m('a', 'm_actual',
          symTr: 'm_gerçek', name: const Bi('Actual yield', 'Gerçek verim')),
      _m('t', 'm_theoretical',
          symTr: 'm_teorik', name: const Bi('Theoretical yield', 'Teorik verim')),
    ],
    solvers: {
      'y': (v) => v['a']! / v['t']! * 100,
      'a': (v) => v['y']! / 100 * v['t']!,
      't': (v) => v['a']! / (v['y']! / 100),
    },
  ),
];

// ---------------------------------------------------------------------------
// Solutions & dilution
// ---------------------------------------------------------------------------

final solutionEquations = <SolverEquation>[
  SolverEquation(
    id: 'prep',
    title: const Bi('Prepare a solution', 'Çözelti hazırlama'),
    formula: 'm = C · V · M',
    defaultTarget: 'm',
    variables: [
      _m('m', 'm', name: const Bi('Mass of solute', 'Çözünen kütlesi')),
      _c('C', 'C', name: const Bi('Molarity', 'Molarite')),
      _v('V', 'V', name: const Bi('Solution volume', 'Çözelti hacmi'), unit: 'mL'),
      _mm('M', 'M'),
    ],
    solvers: {
      'm': (v) => v['C']! * v['V']! * v['M']!,
      'C': (v) => v['m']! / (v['V']! * v['M']!),
      'V': (v) => v['m']! / (v['C']! * v['M']!),
      'M': (v) => v['m']! / (v['C']! * v['V']!),
    },
    extras: [
      SolverExtra('n', const Bi('Moles of solute', 'Çözünen mol sayısı'),
          Quantity.amount, (v) => v['C']! * v['V']!),
    ],
  ),
  SolverEquation(
    id: 'molality',
    title: const Bi('Molality', 'Molalite'),
    formula: 'b = n / m_solvent',
    formulaTr: 'b = n / m_çözücü',
    defaultTarget: 'b',
    variables: [
      const SolverVar('b', 'b', Bi('Molality', 'Molalite'), Quantity.molality),
      _m('m', 'm', name: const Bi('Mass of solute', 'Çözünen kütlesi')),
      _mm('M', 'M'),
      _m('ms', 'm_solvent',
          symTr: 'm_çözücü',
          name: const Bi('Mass of solvent', 'Çözücü kütlesi'),
          unit: 'kg'),
    ],
    solvers: {
      'b': (v) => v['m']! / v['M']! / (v['ms']! / 1000),
      'm': (v) => v['b']! * v['M']! * v['ms']! / 1000,
      'M': (v) => v['m']! / (v['b']! * v['ms']! / 1000),
      'ms': (v) => v['m']! / v['M']! / v['b']! * 1000,
    },
  ),
  SolverEquation(
    id: 'stock',
    title: const Bi('% (w/w) → molarity', '% (k/k) → molarite'),
    formula: 'C = (w/100) · ρ · 1000 / M',
    defaultTarget: 'C',
    variables: [
      _c('C', 'C', name: const Bi('Molarity', 'Molarite')),
      _pct('w', 'w', const Bi('Mass percent', 'Kütlece yüzde')),
      const SolverVar('rho', 'ρ', Bi('Solution density', 'Çözelti yoğunluğu'),
          Quantity.density),
      _mm('M', 'M'),
    ],
    solvers: {
      'C': (v) => v['w']! / 100 * v['rho']! * 1000 / v['M']!,
      'w': (v) => v['C']! * v['M']! / (v['rho']! * 1000) * 100,
      'rho': (v) => v['C']! * v['M']! / (v['w']! / 100 * 1000),
      'M': (v) => v['w']! / 100 * v['rho']! * 1000 / v['C']!,
    },
    extras: [
      SolverExtra(
        'b',
        const Bi('Molality', 'Molalite'),
        Quantity.molality,
        (v) => (v['w']! / v['M']!) / ((100 - v['w']!) / 1000),
      ),
    ],
    note: const Bi(
      'Example: 37% HCl with ρ = 1.19 g/mL is about 12 M.',
      'Örnek: ρ = 1,19 g/mL olan %37’lik HCl yaklaşık 12 M’dir.',
    ),
  ),
  SolverEquation(
    id: 'henry',
    title: const Bi("Henry's law (gas solubility)", 'Henry yasası (gaz çözünürlüğü)'),
    formula: 'C = k_H · P',
    defaultTarget: 'C',
    variables: [
      _c('C', 'C', name: const Bi('Dissolved gas concentration', 'Çözünmüş gaz derişimi'), unit: 'mM'),
      const SolverVar('kH', 'k_H', Bi("Henry's constant", 'Henry sabiti'), Quantity.henry),
      _p('P', 'P', name: const Bi('Partial pressure of the gas', 'Gazın kısmi basıncı')),
    ],
    solvers: {
      'C': (v) => v['kH']! * v['P']! / standardPressure,
      'kH': (v) => v['C']! / (v['P']! / standardPressure),
      'P': (v) => v['C']! / v['kH']! * standardPressure,
    },
    note: const Bi(
      'Water at 25 °C (Sander, 2015): O₂ 1.3 × 10⁻³, N₂ 6.4 × 10⁻⁴, CO₂ 3.4 × 10⁻² mol/(L·atm).',
      'Su, 25 °C (Sander, 2015): O₂ 1,3 × 10⁻³, N₂ 6,4 × 10⁻⁴, CO₂ 3,4 × 10⁻² mol/(L·atm).',
    ),
    presets: const [
      SolverPreset(Bi('O₂ (25 °C)', 'O₂ (25 °C)'), {'kH': 1.3e-3}),
      SolverPreset(Bi('N₂ (25 °C)', 'N₂ (25 °C)'), {'kH': 6.4e-4}),
      SolverPreset(Bi('CO₂ (25 °C)', 'CO₂ (25 °C)'), {'kH': 3.4e-2}),
    ],
  ),
  SolverEquation(
    id: 'massPercent',
    title: const Bi('Mass percent', 'Kütlece yüzde'),
    formula: 'w = m_solute / m_solution × 100',
    formulaTr: 'w = m_çözünen / m_çözelti × 100',
    defaultTarget: 'w',
    variables: [
      _pct('w', 'w', const Bi('Mass percent', 'Kütlece yüzde')),
      _m('ms', 'm_solute',
          symTr: 'm_çözünen',
          name: const Bi('Mass of solute', 'Çözünen kütlesi')),
      _m('mt', 'm_solution',
          symTr: 'm_çözelti',
          name: const Bi('Mass of solution', 'Çözelti kütlesi')),
    ],
    solvers: {
      'w': (v) => v['ms']! / v['mt']! * 100,
      'ms': (v) => v['w']! / 100 * v['mt']!,
      'mt': (v) => v['ms']! / (v['w']! / 100),
    },
  ),
  SolverEquation(
    id: 'ppm',
    title: const Bi('Parts per million', 'Milyonda bir (ppm)'),
    formula: 'ppm = m_solute / m_solution × 10⁶',
    formulaTr: 'ppm = m_çözünen / m_çözelti × 10⁶',
    defaultTarget: 'ppm',
    variables: [
      _num('ppm', 'ppm', const Bi('Concentration (ppm)', 'Derişim (ppm)')),
      _m('ms', 'm_solute',
          symTr: 'm_çözünen',
          name: const Bi('Mass of solute', 'Çözünen kütlesi'),
          unit: 'mg'),
      _m('mt', 'm_solution',
          symTr: 'm_çözelti',
          name: const Bi('Mass of solution', 'Çözelti kütlesi'),
          unit: 'kg'),
    ],
    solvers: {
      'ppm': (v) => v['ms']! / v['mt']! * 1e6,
      'ms': (v) => v['ppm']! * v['mt']! / 1e6,
      'mt': (v) => v['ms']! / v['ppm']! * 1e6,
    },
    note: const Bi(
      'For dilute aqueous solutions 1 ppm ≈ 1 mg/L.',
      'Seyreltik sulu çözeltilerde 1 ppm ≈ 1 mg/L.',
    ),
  ),
];

final dilutionEquations = <SolverEquation>[
  SolverEquation(
    id: 'dilution',
    title: const Bi('Dilution', 'Seyreltme'),
    formula: 'C₁V₁ = C₂V₂',
    defaultTarget: 'V1',
    variables: [
      _c('C1', 'C₁', name: const Bi('Stock concentration', 'Stok derişim')),
      _v('V1', 'V₁', name: const Bi('Stock volume', 'Stok hacmi'), unit: 'mL'),
      _c('C2', 'C₂', name: const Bi('Final concentration', 'Son derişim')),
      _v('V2', 'V₂', name: const Bi('Final volume', 'Son hacim'), unit: 'mL'),
    ],
    solvers: {
      'C1': (v) => v['C2']! * v['V2']! / v['V1']!,
      'V1': (v) => v['C2']! * v['V2']! / v['C1']!,
      'C2': (v) => v['C1']! * v['V1']! / v['V2']!,
      'V2': (v) => v['C1']! * v['V1']! / v['C2']!,
    },
    extras: [
      SolverExtra('V₂ − V₁', const Bi('Solvent to add', 'Eklenecek çözücü'),
          Quantity.volume, (v) => v['V2']! - v['V1']!,
          unit: 'mL'),
      SolverExtra('SF', const Bi('Dilution factor', 'Seyreltme faktörü'),
          Quantity.dimensionless, (v) => v['V2']! / v['V1']!),
    ],
  ),
  SolverEquation(
    id: 'serial',
    title: const Bi('Serial dilution', 'Seri seyreltme'),
    formula: 'Cₖ = C₀ / SFᵏ',
    formulaTr: 'Cₖ = C₀ / SFᵏ',
    defaultTarget: 'Ck',
    variables: [
      _c('Ck', 'Cₖ', name: const Bi('Concentration after k steps', 'k adım sonraki derişim')),
      _c('C0', 'C₀', name: const Bi('Starting concentration', 'Başlangıç derişimi')),
      _num('DF', 'SF', const Bi('Dilution factor per step', 'Adım başına seyreltme faktörü'),
          def: 10),
      _num('k', 'k', const Bi('Number of steps', 'Adım sayısı'), def: 3),
    ],
    solvers: {
      'Ck': (v) => v['C0']! / math.pow(v['DF']!, v['k']!),
      'C0': (v) => v['Ck']! * math.pow(v['DF']!, v['k']!),
      'DF': (v) => math.pow(v['C0']! / v['Ck']!, 1 / v['k']!).toDouble(),
      'k': (v) => math.log(v['C0']! / v['Ck']!) / math.log(v['DF']!),
    },
    extras: [
      SolverExtra('SF_total', const Bi('Total dilution factor', 'Toplam seyreltme faktörü'),
          Quantity.dimensionless, (v) => v['C0']! / v['Ck']!),
    ],
    note: const Bi(
      'E.g. 1 mL + 9 mL solvent per step is a factor of 10.',
      'Ör. her adımda 1 mL + 9 mL çözücü, 10 katlık seyreltmedir.',
    ),
  ),
  SolverEquation(
    id: 'mixing',
    title: const Bi('Mixing two solutions', 'İki çözeltiyi karıştırma'),
    formula: 'C_final = (C₁V₁ + C₂V₂) / (V₁ + V₂)',
    formulaTr: 'C_son = (C₁V₁ + C₂V₂) / (V₁ + V₂)',
    defaultTarget: 'Cf',
    variables: [
      _c('Cf', 'C_final',
          symTr: 'C_son', name: const Bi('Final concentration', 'Son derişim')),
      _c('C1', 'C₁', name: const Bi('Concentration 1', '1. derişim')),
      _v('V1', 'V₁', name: const Bi('Volume 1', '1. hacim'), unit: 'mL'),
      _c('C2', 'C₂', name: const Bi('Concentration 2', '2. derişim')),
      _v('V2', 'V₂', name: const Bi('Volume 2', '2. hacim'), unit: 'mL'),
    ],
    solvers: {
      'Cf': (v) =>
          (v['C1']! * v['V1']! + v['C2']! * v['V2']!) / (v['V1']! + v['V2']!),
      'C1': (v) =>
          (v['Cf']! * (v['V1']! + v['V2']!) - v['C2']! * v['V2']!) / v['V1']!,
      'C2': (v) =>
          (v['Cf']! * (v['V1']! + v['V2']!) - v['C1']! * v['V1']!) / v['V2']!,
      'V1': (v) => v['V2']! * (v['Cf']! - v['C2']!) / (v['C1']! - v['Cf']!),
      'V2': (v) => v['V1']! * (v['C1']! - v['Cf']!) / (v['Cf']! - v['C2']!),
    },
  ),
];

// ---------------------------------------------------------------------------
// Acids & bases (25 °C)
// ---------------------------------------------------------------------------

SolverVar _ph() => _num('pH', 'pH', const Bi('pH', 'pH'), neg: true);

final acidBaseEquations = <SolverEquation>[
  SolverEquation(
    id: 'phH',
    title: const Bi('pH ⇄ [H⁺]', 'pH ⇄ [H⁺]'),
    formula: 'pH = −log[H⁺]',
    defaultTarget: 'pH',
    variables: [_ph(), _c('H', '[H⁺]')],
    solvers: {
      'pH': (v) => -_log10(v['H']!),
      'H': (v) => _pow10(-v['pH']!),
    },
    extras: [
      SolverExtra('pOH', const Bi('pOH', 'pOH'), Quantity.dimensionless,
          (v) => 14 - v['pH']!),
      SolverExtra('[OH⁻]', const Bi('Hydroxide concentration', 'Hidroksit derişimi'),
          Quantity.concentration, (v) => kw / v['H']!),
    ],
  ),
  SolverEquation(
    id: 'pohOH',
    title: const Bi('pOH ⇄ [OH⁻]', 'pOH ⇄ [OH⁻]'),
    formula: 'pOH = −log[OH⁻]',
    defaultTarget: 'pOH',
    variables: [
      _num('pOH', 'pOH', const Bi('pOH', 'pOH'), neg: true),
      _c('OH', '[OH⁻]'),
    ],
    solvers: {
      'pOH': (v) => -_log10(v['OH']!),
      'OH': (v) => _pow10(-v['pOH']!),
    },
    extras: [
      SolverExtra('pH', const Bi('pH', 'pH'), Quantity.dimensionless,
          (v) => 14 - v['pOH']!),
      SolverExtra('[H⁺]', const Bi('Hydrogen ion concentration', 'Hidrojen iyonu derişimi'),
          Quantity.concentration, (v) => kw / v['OH']!),
    ],
  ),
  SolverEquation(
    id: 'strongAcid',
    title: const Bi('Strong acid', 'Kuvvetli asit'),
    formula: '[H⁺] = n · C',
    defaultTarget: 'pH',
    variables: [
      _ph(),
      _c('C', 'C', name: const Bi('Acid concentration', 'Asit derişimi')),
      _num('k', 'n', const Bi('H⁺ per formula unit', 'Formül başına H⁺ sayısı'),
          def: 1),
    ],
    solvers: {
      'pH': (v) {
        final a = v['k']! * v['C']!;
        return -_log10((a + math.sqrt(a * a + 4 * kw)) / 2);
      },
      'C': (v) {
        final x = _pow10(-v['pH']!);
        return (x - kw / x) / v['k']!;
      },
      'k': (v) {
        final x = _pow10(-v['pH']!);
        return (x - kw / x) / v['C']!;
      },
    },
    note: const Bi(
      'Complete dissociation assumed; water autoionization is included.',
      'Tam iyonlaşma varsayılır; suyun iyonlaşması hesaba katılır.',
    ),
  ),
  SolverEquation(
    id: 'strongBase',
    title: const Bi('Strong base', 'Kuvvetli baz'),
    formula: '[OH⁻] = n · C',
    defaultTarget: 'pH',
    variables: [
      _ph(),
      _c('C', 'C', name: const Bi('Base concentration', 'Baz derişimi')),
      _num('k', 'n', const Bi('OH⁻ per formula unit', 'Formül başına OH⁻ sayısı'),
          def: 1),
    ],
    solvers: {
      'pH': (v) {
        final b = v['k']! * v['C']!;
        return 14 + _log10((b + math.sqrt(b * b + 4 * kw)) / 2);
      },
      'C': (v) {
        final y = _pow10(v['pH']! - 14);
        return (y - kw / y) / v['k']!;
      },
      'k': (v) {
        final y = _pow10(v['pH']! - 14);
        return (y - kw / y) / v['C']!;
      },
    },
  ),
  SolverEquation(
    id: 'weakAcid',
    title: const Bi('Weak acid', 'Zayıf asit'),
    formula: 'Ka = x² / (C − x),  x = [H⁺]',
    defaultTarget: 'pH',
    variables: [
      _ph(),
      _num('Ka', 'Ka', const Bi('Acid dissociation constant', 'Asitlik sabiti')),
      _c('C', 'C', name: const Bi('Initial concentration', 'Başlangıç derişimi')),
    ],
    solvers: {
      'pH': (v) {
        final ka = v['Ka']!, c = v['C']!;
        return -_log10((-ka + math.sqrt(ka * ka + 4 * ka * c)) / 2);
      },
      'Ka': (v) {
        final x = _pow10(-v['pH']!);
        return x * x / (v['C']! - x);
      },
      'C': (v) {
        final x = _pow10(-v['pH']!);
        return x * x / v['Ka']! + x;
      },
    },
    extras: [
      SolverExtra('α', const Bi('Percent ionization', 'İyonlaşma yüzdesi'),
          Quantity.percent, (v) => _pow10(-v['pH']!) / v['C']! * 100),
      SolverExtra('pKa', const Bi('pKa', 'pKa'), Quantity.dimensionless,
          (v) => -_log10(v['Ka']!)),
    ],
    note: const Bi(
      'Solved exactly with the quadratic formula (no 5% approximation).',
      'İkinci derece denklemle tam çözülür (%5 yaklaşımı kullanılmaz).',
    ),
  ),
  SolverEquation(
    id: 'weakBase',
    title: const Bi('Weak base', 'Zayıf baz'),
    formula: 'Kb = y² / (C − y),  y = [OH⁻]',
    defaultTarget: 'pH',
    variables: [
      _ph(),
      _num('Kb', 'Kb', const Bi('Base dissociation constant', 'Bazlık sabiti')),
      _c('C', 'C', name: const Bi('Initial concentration', 'Başlangıç derişimi')),
    ],
    solvers: {
      'pH': (v) {
        final kb = v['Kb']!, c = v['C']!;
        return 14 + _log10((-kb + math.sqrt(kb * kb + 4 * kb * c)) / 2);
      },
      'Kb': (v) {
        final y = _pow10(v['pH']! - 14);
        return y * y / (v['C']! - y);
      },
      'C': (v) {
        final y = _pow10(v['pH']! - 14);
        return y * y / v['Kb']! + y;
      },
    },
    extras: [
      SolverExtra('α', const Bi('Percent ionization', 'İyonlaşma yüzdesi'),
          Quantity.percent, (v) => _pow10(v['pH']! - 14) / v['C']! * 100),
      SolverExtra('pOH', const Bi('pOH', 'pOH'), Quantity.dimensionless,
          (v) => 14 - v['pH']!),
    ],
  ),
  SolverEquation(
    id: 'buffer',
    title: const Bi('Buffer (Henderson–Hasselbalch)', 'Tampon (Henderson–Hasselbalch)'),
    formula: 'pH = pKa + log([A⁻] / [HA])',
    defaultTarget: 'pH',
    variables: [
      _ph(),
      _num('pKa', 'pKa', const Bi('pKa', 'pKa'), neg: true),
      _c('A', '[A⁻]', name: const Bi('Conjugate base', 'Eşlenik baz')),
      _c('HA', '[HA]', name: const Bi('Weak acid', 'Zayıf asit')),
    ],
    solvers: {
      'pH': (v) => v['pKa']! + _log10(v['A']! / v['HA']!),
      'pKa': (v) => v['pH']! - _log10(v['A']! / v['HA']!),
      'A': (v) => v['HA']! * _pow10(v['pH']! - v['pKa']!),
      'HA': (v) => v['A']! / _pow10(v['pH']! - v['pKa']!),
    },
  ),
  SolverEquation(
    id: 'bufferPrep',
    title: const Bi('Prepare a buffer', 'Tampon hazırlama'),
    formula: 'pH = pKa + log([A⁻]/[HA]),  [HA] + [A⁻] = C',
    defaultTarget: 'mHA',
    variables: [
      _m('mHA', 'm_HA', name: const Bi('Mass of weak acid', 'Zayıf asit kütlesi')),
      _ph(),
      _num('pKa', 'pKa', const Bi('pKa', 'pKa'), neg: true),
      _c('C', 'C', name: const Bi('Total buffer concentration', 'Toplam tampon derişimi')),
      _v('V', 'V', name: const Bi('Buffer volume', 'Tampon hacmi'), unit: 'mL'),
      _mm('Mha', 'M_HA', name: const Bi('Molar mass of the acid', 'Asidin mol kütlesi')),
      _mm('Ma', 'M_A⁻', name: const Bi('Molar mass of the salt', 'Tuzun mol kütlesi')),
    ],
    solvers: {
      'mHA': (v) => v['C']! / (1 + _pow10(v['pH']! - v['pKa']!)) * v['V']! * v['Mha']!,
    },
    extras: [
      SolverExtra('m_A⁻', const Bi('Mass of the salt (conjugate base)', 'Tuzun (eşlenik baz) kütlesi'),
          Quantity.mass, (v) {
        final r = _pow10(v['pH']! - v['pKa']!);
        return v['C']! * r / (1 + r) * v['V']! * v['Ma']!;
      }),
      SolverExtra('[HA]', const Bi('Acid concentration', 'Asit derişimi'), Quantity.concentration,
          (v) => v['C']! / (1 + _pow10(v['pH']! - v['pKa']!))),
      SolverExtra('[A⁻]', const Bi('Conjugate base concentration', 'Eşlenik baz derişimi'),
          Quantity.concentration, (v) {
        final r = _pow10(v['pH']! - v['pKa']!);
        return v['C']! * r / (1 + r);
      }),
    ],
    note: const Bi(
      'Henderson–Hasselbalch; best within pKa ± 1. Check the final pH with a pH meter.',
      'Henderson–Hasselbalch; pKa ± 1 aralığında en iyisidir. Son pH’ı pH metreyle kontrol edin.',
    ),
    presets: const [
      SolverPreset(Bi('Acetate (pKa 4.76)', 'Asetat (pKa 4,76)'), {'pKa': 4.76}),
      SolverPreset(Bi('Phosphate (pKa₂ 7.20)', 'Fosfat (pKa₂ 7,20)'), {'pKa': 7.20}),
      SolverPreset(Bi('Ammonia (pKa 9.25)', 'Amonyak (pKa 9,25)'), {'pKa': 9.25}),
      SolverPreset(Bi('Tris (pKa 8.07)', 'Tris (pKa 8,07)'), {'pKa': 8.07}),
    ],
  ),
  SolverEquation(
    id: 'pKa',
    title: const Bi('Ka ⇄ pKa', 'Ka ⇄ pKa'),
    formula: 'pKa = −log Ka',
    defaultTarget: 'pKa',
    variables: [
      _num('pKa', 'pKa', const Bi('pKa', 'pKa'), neg: true),
      _num('Ka', 'Ka', const Bi('Acid dissociation constant', 'Asitlik sabiti')),
    ],
    solvers: {
      'pKa': (v) => -_log10(v['Ka']!),
      'Ka': (v) => _pow10(-v['pKa']!),
    },
    extras: [
      SolverExtra('pKb', const Bi('pKb of conjugate base', 'Eşlenik bazın pKb’si'),
          Quantity.dimensionless, (v) => 14 - v['pKa']!),
      SolverExtra('Kb', const Bi('Kb of conjugate base', 'Eşlenik bazın Kb’si'),
          Quantity.dimensionless, (v) => kw / v['Ka']!),
    ],
  ),
  SolverEquation(
    id: 'titration',
    title: const Bi('Titration (equivalence point)', 'Titrasyon (eşdeğerlik noktası)'),
    formula: 'nₐ·Cₐ·Vₐ = n_b·C_b·V_b',
    defaultTarget: 'Ca',
    variables: [
      _c('Ca', 'Cₐ', name: const Bi('Acid concentration', 'Asit derişimi')),
      _v('Va', 'Vₐ', name: const Bi('Acid volume', 'Asit hacmi'), unit: 'mL'),
      _num('na', 'nₐ', const Bi('H⁺ per acid', 'Asit başına H⁺'), def: 1),
      _c('Cb', 'C_b', name: const Bi('Base concentration', 'Baz derişimi')),
      _v('Vb', 'V_b', name: const Bi('Base volume', 'Baz hacmi'), unit: 'mL'),
      _num('nb', 'n_b', const Bi('OH⁻ per base', 'Baz başına OH⁻'), def: 1),
    ],
    solvers: {
      'Ca': (v) => v['nb']! * v['Cb']! * v['Vb']! / (v['na']! * v['Va']!),
      'Va': (v) => v['nb']! * v['Cb']! * v['Vb']! / (v['na']! * v['Ca']!),
      'Cb': (v) => v['na']! * v['Ca']! * v['Va']! / (v['nb']! * v['Vb']!),
      'Vb': (v) => v['na']! * v['Ca']! * v['Va']! / (v['nb']! * v['Cb']!),
    },
  ),
];

// ---------------------------------------------------------------------------
// Thermochemistry
// ---------------------------------------------------------------------------

SolverVar _molarE(String id, String sym, Bi name) => SolverVar(
      id,
      sym,
      name,
      Quantity.molarEnergy,
      allowNegative: true,
    );

final thermoEquations = <SolverEquation>[
  SolverEquation(
    id: 'heat',
    title: const Bi('Heat (calorimetry)', 'Isı (kalorimetri)'),
    formula: 'q = m · c · ΔT',
    defaultTarget: 'q',
    variables: [
      const SolverVar('q', 'q', Bi('Heat', 'Isı'), Quantity.energy,
          allowNegative: true),
      _m('m', 'm'),
      const SolverVar('c', 'c', Bi('Specific heat', 'Öz ısı'),
          Quantity.specificHeat,
          defaultValue: 4.184),
      const SolverVar('dT', 'ΔT', Bi('Temperature change', 'Sıcaklık değişimi'),
          Quantity.temperatureDifference,
          unit: 'C', allowNegative: true),
    ],
    solvers: {
      'q': (v) => v['m']! * v['c']! * v['dT']!,
      'm': (v) => v['q']! / (v['c']! * v['dT']!),
      'c': (v) => v['q']! / (v['m']! * v['dT']!),
      'dT': (v) => v['q']! / (v['m']! * v['c']!),
    },
    note: const Bi('Water: c = 4.184 J/(g·K).', 'Su: c = 4,184 J/(g·K).'),
  ),
  SolverEquation(
    id: 'mixTemp',
    title: const Bi('Final temperature of mixing', 'Karışımın son sıcaklığı'),
    formula: 'm₁c₁(T_f − T₁) + m₂c₂(T_f − T₂) = 0',
    formulaTr: 'm₁c₁(T_s − T₁) + m₂c₂(T_s − T₂) = 0',
    defaultTarget: 'Tf',
    variables: [
      _t('Tf', 'T_f', unit: 'C', name: const Bi('Final temperature', 'Son sıcaklık')),
      _m('m1', 'm₁', name: const Bi('Mass 1', '1. kütle')),
      const SolverVar('c1', 'c₁', Bi('Specific heat 1', '1. öz ısı'), Quantity.specificHeat,
          defaultValue: 4.184),
      _t('T1', 'T₁', unit: 'C', name: const Bi('Temperature 1', '1. sıcaklık')),
      _m('m2', 'm₂', name: const Bi('Mass 2', '2. kütle')),
      const SolverVar('c2', 'c₂', Bi('Specific heat 2', '2. öz ısı'), Quantity.specificHeat,
          defaultValue: 4.184),
      _t('T2', 'T₂', unit: 'C', name: const Bi('Temperature 2', '2. sıcaklık')),
    ],
    solvers: {
      'Tf': (v) {
        final a = v['m1']! * v['c1']!, b = v['m2']! * v['c2']!;
        return (a * v['T1']! + b * v['T2']!) / (a + b);
      },
      'T1': (v) => v['Tf']! + v['m2']! * v['c2']! * (v['Tf']! - v['T2']!) / (v['m1']! * v['c1']!),
      'T2': (v) => v['Tf']! + v['m1']! * v['c1']! * (v['Tf']! - v['T1']!) / (v['m2']! * v['c2']!),
      'm1': (v) => v['m2']! * v['c2']! * (v['T2']! - v['Tf']!) / (v['c1']! * (v['Tf']! - v['T1']!)),
      'm2': (v) => v['m1']! * v['c1']! * (v['T1']! - v['Tf']!) / (v['c2']! * (v['Tf']! - v['T2']!)),
      'c1': (v) => v['m2']! * v['c2']! * (v['T2']! - v['Tf']!) / (v['m1']! * (v['Tf']! - v['T1']!)),
      'c2': (v) => v['m1']! * v['c1']! * (v['T1']! - v['Tf']!) / (v['m2']! * (v['Tf']! - v['T2']!)),
    },
    note: const Bi(
      'No heat loss and no phase change. Water: c = 4.184 J/(g·K).',
      'Isı kaybı ve hal değişimi yok sayılır. Su: c = 4,184 J/(g·K).',
    ),
  ),
  SolverEquation(
    id: 'gibbs',
    title: const Bi('Gibbs free energy', 'Gibbs serbest enerjisi'),
    formula: 'ΔG = ΔH − TΔS',
    defaultTarget: 'G',
    variables: [
      _molarE('G', 'ΔG', const Bi('Free energy change', 'Serbest enerji değişimi')),
      _molarE('H', 'ΔH', const Bi('Enthalpy change', 'Entalpi değişimi')),
      _t('T', 'T', def: 298.15),
      const SolverVar('S', 'ΔS', Bi('Entropy change', 'Entropi değişimi'),
          Quantity.molarEntropy,
          allowNegative: true),
    ],
    solvers: {
      'G': (v) => v['H']! - v['T']! * v['S']!,
      'H': (v) => v['G']! + v['T']! * v['S']!,
      'T': (v) => (v['H']! - v['G']!) / v['S']!,
      'S': (v) => (v['H']! - v['G']!) / v['T']!,
    },
    note: const Bi('ΔG < 0: spontaneous process.', 'ΔG < 0: istemli süreç.'),
  ),
  SolverEquation(
    id: 'gibbsK',
    title: const Bi('ΔG° and equilibrium constant', 'ΔG° ve denge sabiti'),
    formula: 'ΔG° = −RT ln K',
    defaultTarget: 'K',
    variables: [
      _molarE('G', 'ΔG°', const Bi('Standard free energy change', 'Standart serbest enerji değişimi')),
      _t('T', 'T', def: 298.15),
      _num('K', 'K', const Bi('Equilibrium constant', 'Denge sabiti')),
    ],
    solvers: {
      'G': (v) => -_r * v['T']! * math.log(v['K']!),
      'K': (v) => math.exp(-v['G']! / (_r * v['T']!)),
      'T': (v) => -v['G']! / (_r * math.log(v['K']!)),
    },
  ),
  SolverEquation(
    id: 'clausius',
    title: const Bi('Clausius–Clapeyron', 'Clausius–Clapeyron'),
    formula: 'ln(P₂/P₁) = −ΔH_vap/R · (1/T₂ − 1/T₁)',
    formulaTr: 'ln(P₂/P₁) = −ΔH_buh/R · (1/T₂ − 1/T₁)',
    defaultTarget: 'P2',
    variables: [
      _p('P1', 'P₁', name: const Bi('Vapor pressure 1', '1. buhar basıncı'), unit: 'mmHg'),
      _t('T1', 'T₁', unit: 'C'),
      _p('P2', 'P₂', name: const Bi('Vapor pressure 2', '2. buhar basıncı'), unit: 'mmHg'),
      _t('T2', 'T₂', unit: 'C'),
      const SolverVar('H', 'ΔH_vap',
          symbolTr: 'ΔH_buh',
          Bi('Enthalpy of vaporization', 'Buharlaşma entalpisi'),
          Quantity.molarEnergy),
    ],
    solvers: _twoPoint('P1', 'P2', 'H'),
  ),
  SolverEquation(
    id: 'vantHoff',
    title: const Bi("van 't Hoff equation", "van 't Hoff denklemi"),
    formula: 'ln(K₂/K₁) = −ΔH°/R · (1/T₂ − 1/T₁)',
    defaultTarget: 'K2',
    variables: [
      _num('K1', 'K₁', const Bi('Equilibrium constant 1', '1. denge sabiti')),
      _t('T1', 'T₁'),
      _num('K2', 'K₂', const Bi('Equilibrium constant 2', '2. denge sabiti')),
      _t('T2', 'T₂'),
      _molarE('H', 'ΔH°', const Bi('Standard enthalpy change', 'Standart entalpi değişimi')),
    ],
    solvers: _twoPoint('K1', 'K2', 'H'),
  ),
];

// ---------------------------------------------------------------------------
// Kinetics
// ---------------------------------------------------------------------------

SolverVar _a0() => _c('A0', '[A]₀', name: const Bi('Initial concentration', 'Başlangıç derişimi'));
SolverVar _at() => _c('At', '[A]ₜ', name: const Bi('Concentration at time t', 't anındaki derişim'));
SolverVar _time(String id, String sym, {Bi? name}) =>
    SolverVar(id, sym, name ?? const Bi('Time', 'Süre'), Quantity.time);
SolverVar _k1(String id, String sym, {Bi? name}) => SolverVar(id, sym,
    name ?? const Bi('Rate constant', 'Hız sabiti'), Quantity.rateConstant);

final kineticsEquations = <SolverEquation>[
  SolverEquation(
    id: 'firstOrder',
    title: const Bi('First-order reaction', 'Birinci dereceden tepkime'),
    formula: '[A]ₜ = [A]₀ · e^(−kt)',
    defaultTarget: 'At',
    variables: [_at(), _a0(), _k1('k', 'k'), _time('t', 't')],
    solvers: {
      'At': (v) => v['A0']! * math.exp(-v['k']! * v['t']!),
      'A0': (v) => v['At']! * math.exp(v['k']! * v['t']!),
      'k': (v) => math.log(v['A0']! / v['At']!) / v['t']!,
      't': (v) => math.log(v['A0']! / v['At']!) / v['k']!,
    },
    extras: [
      SolverExtra('t½', const Bi('Half-life', 'Yarılanma süresi'), Quantity.time,
          (v) => math.ln2 / v['k']!),
    ],
  ),
  SolverEquation(
    id: 'halfLife',
    title: const Bi('Half-life (first order)', 'Yarılanma süresi (1. derece)'),
    formula: 't½ = ln 2 / k',
    defaultTarget: 'th',
    variables: [
      _time('th', 't½', name: const Bi('Half-life', 'Yarılanma süresi')),
      _k1('k', 'k'),
    ],
    solvers: {
      'th': (v) => math.ln2 / v['k']!,
      'k': (v) => math.ln2 / v['th']!,
    },
  ),
  SolverEquation(
    id: 'zeroOrder',
    title: const Bi('Zero-order reaction', 'Sıfırıncı dereceden tepkime'),
    formula: '[A]ₜ = [A]₀ − kt',
    defaultTarget: 'At',
    variables: [
      _at(),
      _a0(),
      const SolverVar('k', 'k', Bi('Rate constant', 'Hız sabiti'),
          Quantity.zeroOrderRate),
      _time('t', 't'),
    ],
    solvers: {
      'At': (v) => v['A0']! - v['k']! * v['t']!,
      'A0': (v) => v['At']! + v['k']! * v['t']!,
      'k': (v) => (v['A0']! - v['At']!) / v['t']!,
      't': (v) => (v['A0']! - v['At']!) / v['k']!,
    },
    extras: [
      SolverExtra('t½', const Bi('Half-life', 'Yarılanma süresi'), Quantity.time,
          (v) => v['A0']! / (2 * v['k']!)),
    ],
  ),
  SolverEquation(
    id: 'secondOrder',
    title: const Bi('Second-order reaction', 'İkinci dereceden tepkime'),
    formula: '1/[A]ₜ = 1/[A]₀ + kt',
    defaultTarget: 'At',
    variables: [
      _at(),
      _a0(),
      const SolverVar('k', 'k', Bi('Rate constant', 'Hız sabiti'),
          Quantity.secondOrderRate),
      _time('t', 't'),
    ],
    solvers: {
      'At': (v) => 1 / (1 / v['A0']! + v['k']! * v['t']!),
      'A0': (v) => 1 / (1 / v['At']! - v['k']! * v['t']!),
      'k': (v) => (1 / v['At']! - 1 / v['A0']!) / v['t']!,
      't': (v) => (1 / v['At']! - 1 / v['A0']!) / v['k']!,
    },
    extras: [
      SolverExtra('t½', const Bi('Half-life', 'Yarılanma süresi'), Quantity.time,
          (v) => 1 / (v['k']! * v['A0']!)),
    ],
  ),
  SolverEquation(
    id: 'arrhenius',
    title: const Bi('Arrhenius equation', 'Arrhenius denklemi'),
    formula: 'k = A · e^(−Ea/RT)',
    defaultTarget: 'k',
    variables: [
      _k1('k', 'k'),
      _k1('A', 'A', name: const Bi('Pre-exponential factor', 'Frekans faktörü')),
      const SolverVar('Ea', 'Ea', Bi('Activation energy', 'Aktivasyon enerjisi'),
          Quantity.molarEnergy),
      _t('T', 'T'),
    ],
    solvers: {
      'k': (v) => v['A']! * math.exp(-v['Ea']! / (_r * v['T']!)),
      'A': (v) => v['k']! / math.exp(-v['Ea']! / (_r * v['T']!)),
      'Ea': (v) => -_r * v['T']! * math.log(v['k']! / v['A']!),
      'T': (v) => -v['Ea']! / (_r * math.log(v['k']! / v['A']!)),
    },
  ),
  SolverEquation(
    id: 'arrhenius2',
    title: const Bi('Arrhenius (two temperatures)', 'Arrhenius (iki sıcaklık)'),
    formula: 'ln(k₂/k₁) = −Ea/R · (1/T₂ − 1/T₁)',
    defaultTarget: 'Ea',
    variables: [
      _k1('k1', 'k₁', name: const Bi('Rate constant 1', '1. hız sabiti')),
      _t('T1', 'T₁'),
      _k1('k2', 'k₂', name: const Bi('Rate constant 2', '2. hız sabiti')),
      _t('T2', 'T₂'),
      const SolverVar('Ea', 'Ea', Bi('Activation energy', 'Aktivasyon enerjisi'),
          Quantity.molarEnergy),
    ],
    solvers: _twoPoint('k1', 'k2', 'Ea'),
  ),
];

// ---------------------------------------------------------------------------
// Electrochemistry
// ---------------------------------------------------------------------------

SolverVar _e(String id, String sym, Bi name) =>
    SolverVar(id, sym, name, Quantity.voltage, allowNegative: true);
SolverVar _ne() => _num('n', 'n', _electrons, def: 1);

final electroEquations = <SolverEquation>[
  SolverEquation(
    id: 'nernst',
    title: const Bi('Nernst equation', 'Nernst denklemi'),
    formula: 'E = E° − (RT / nF) · ln Q',
    defaultTarget: 'E',
    variables: [
      _e('E', 'E', const Bi('Cell potential', 'Hücre potansiyeli')),
      _e('E0', 'E°', const Bi('Standard potential', 'Standart potansiyel')),
      _ne(),
      _num('Q', 'Q', const Bi('Reaction quotient', 'Tepkime oranı')),
      _t('T', 'T', def: 298.15),
    ],
    solvers: {
      'E': (v) => v['E0']! - _r * v['T']! / (v['n']! * _f) * math.log(v['Q']!),
      'E0': (v) => v['E']! + _r * v['T']! / (v['n']! * _f) * math.log(v['Q']!),
      'Q': (v) => math.exp((v['E0']! - v['E']!) * v['n']! * _f / (_r * v['T']!)),
      'n': (v) => _r * v['T']! * math.log(v['Q']!) / (_f * (v['E0']! - v['E']!)),
      'T': (v) => (v['E0']! - v['E']!) * v['n']! * _f / (_r * math.log(v['Q']!)),
    },
  ),
  SolverEquation(
    id: 'electrolysis',
    title: const Bi("Electrolysis (Faraday's law)", 'Elektroliz (Faraday yasası)'),
    formula: 'm = I · t · M / (n · F)',
    defaultTarget: 'm',
    variables: [
      _m('m', 'm', name: const Bi('Mass deposited', 'Biriken kütle')),
      const SolverVar('I', 'I', Bi('Current', 'Akım'), Quantity.current),
      _time('t', 't'),
      _mm('M', 'M'),
      _ne(),
    ],
    solvers: {
      'm': (v) => v['I']! * v['t']! * v['M']! / (v['n']! * _f),
      'I': (v) => v['m']! * v['n']! * _f / (v['t']! * v['M']!),
      't': (v) => v['m']! * v['n']! * _f / (v['I']! * v['M']!),
      'M': (v) => v['m']! * v['n']! * _f / (v['I']! * v['t']!),
      'n': (v) => v['I']! * v['t']! * v['M']! / (v['m']! * _f),
    },
    extras: [
      SolverExtra('Q', const Bi('Charge passed', 'Geçen yük'), Quantity.charge,
          (v) => v['I']! * v['t']!),
    ],
  ),
  SolverEquation(
    id: 'gibbsE',
    title: const Bi('Free energy and cell potential', 'Serbest enerji ve hücre potansiyeli'),
    formula: 'ΔG = −nFE',
    defaultTarget: 'G',
    variables: [
      _molarE('G', 'ΔG', const Bi('Free energy change', 'Serbest enerji değişimi')),
      _ne(),
      _e('E', 'E', const Bi('Cell potential', 'Hücre potansiyeli')),
    ],
    solvers: {
      'G': (v) => -v['n']! * _f * v['E']!,
      'E': (v) => -v['G']! / (v['n']! * _f),
      'n': (v) => -v['G']! / (_f * v['E']!),
    },
  ),
  SolverEquation(
    id: 'cellK',
    title: const Bi('Standard potential and K', 'Standart potansiyel ve K'),
    formula: 'E° = (RT / nF) · ln K',
    defaultTarget: 'K',
    variables: [
      _e('E0', 'E°', const Bi('Standard cell potential', 'Standart hücre potansiyeli')),
      _ne(),
      _num('K', 'K', const Bi('Equilibrium constant', 'Denge sabiti')),
      _t('T', 'T', def: 298.15),
    ],
    solvers: {
      'E0': (v) => _r * v['T']! / (v['n']! * _f) * math.log(v['K']!),
      'K': (v) => math.exp(v['E0']! * v['n']! * _f / (_r * v['T']!)),
      'n': (v) => _r * v['T']! * math.log(v['K']!) / (_f * v['E0']!),
      'T': (v) => v['E0']! * v['n']! * _f / (_r * math.log(v['K']!)),
    },
  ),
];

// ---------------------------------------------------------------------------
// Spectroscopy
// ---------------------------------------------------------------------------

final spectroEquations = <SolverEquation>[
  SolverEquation(
    id: 'beer',
    title: const Bi('Beer–Lambert law', 'Beer–Lambert yasası'),
    formula: 'A = ε · l · c',
    defaultTarget: 'c',
    variables: [
      _num('A', 'A', const Bi('Absorbance', 'Absorbans')),
      const SolverVar('eps', 'ε', Bi('Molar absorptivity', 'Molar absorptivite'),
          Quantity.absorptivity),
      const SolverVar('l', 'l', Bi('Path length', 'Işık yolu'), Quantity.length,
          unit: 'cm', defaultValue: 1),
      _c('c', 'c'),
    ],
    solvers: {
      'A': (v) => v['eps']! * v['l']! * 100 * v['c']!,
      'eps': (v) => v['A']! / (v['l']! * 100 * v['c']!),
      'l': (v) => v['A']! / (v['eps']! * v['c']!) / 100,
      'c': (v) => v['A']! / (v['eps']! * v['l']! * 100),
    },
  ),
  SolverEquation(
    id: 'transmittance',
    title: const Bi('Absorbance ⇄ transmittance', 'Absorbans ⇄ geçirgenlik'),
    formula: 'A = 2 − log(%T)',
    defaultTarget: 'A',
    variables: [
      _num('A', 'A', const Bi('Absorbance', 'Absorbans'), neg: true),
      _pct('T', '%T', const Bi('Transmittance', 'Geçirgenlik')),
    ],
    solvers: {
      'A': (v) => 2 - _log10(v['T']!),
      'T': (v) => _pow10(2 - v['A']!),
    },
  ),
  SolverEquation(
    id: 'photon',
    title: const Bi('Photon energy', 'Foton enerjisi'),
    formula: 'E = hc / λ',
    defaultTarget: 'E',
    variables: [
      const SolverVar('E', 'E', Bi('Photon energy', 'Foton enerjisi'),
          Quantity.energy,
          unit: 'eV'),
      const SolverVar('l', 'λ', Bi('Wavelength', 'Dalga boyu'), Quantity.length,
          unit: 'nm'),
    ],
    solvers: {
      'E': (v) => planck * speedOfLight / v['l']!,
      'l': (v) => planck * speedOfLight / v['E']!,
    },
    extras: [
      SolverExtra('ν', const Bi('Frequency', 'Frekans'), Quantity.frequency,
          (v) => speedOfLight / v['l']!,
          unit: 'THz'),
      SolverExtra('ν̃', const Bi('Wavenumber', 'Dalga sayısı'),
          Quantity.dimensionless, (v) => 1 / (v['l']! * 100),
          unitLabel: 'cm⁻¹'),
      SolverExtra('E·Nₐ', const Bi('Energy per mole', 'Mol başına enerji'),
          Quantity.molarEnergy, (v) => v['E']! * avogadro),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Colligative properties
// ---------------------------------------------------------------------------

SolverVar _molality() =>
    const SolverVar('b', 'm', Bi('Molality', 'Molalite'), Quantity.molality);

final colligativeEquations = <SolverEquation>[
  SolverEquation(
    id: 'boiling',
    title: const Bi('Boiling point elevation', 'Kaynama noktası yükselmesi'),
    formula: 'ΔT_b = i · K_b · m',
    formulaTr: 'ΔT_k = i · K_k · m',
    defaultTarget: 'dT',
    variables: [
      const SolverVar('dT', 'ΔT_b', Bi('Boiling point elevation', 'Kaynama noktası yükselmesi'),
          symbolTr: 'ΔT_k',
          Quantity.temperatureDifference,
          unit: 'C'),
      _num('i', 'i', _vanHoffI, def: 1),
      const SolverVar('K', 'K_b', Bi('Ebullioscopic constant', 'Ebülyoskopi sabiti'),
          symbolTr: 'K_k',
          Quantity.cryoscopic,
          defaultValue: 0.512),
      _molality(),
    ],
    solvers: {
      'dT': (v) => v['i']! * v['K']! * v['b']!,
      'i': (v) => v['dT']! / (v['K']! * v['b']!),
      'K': (v) => v['dT']! / (v['i']! * v['b']!),
      'b': (v) => v['dT']! / (v['i']! * v['K']!),
    },
    note: const Bi('Water: K_b = 0.512 K·kg/mol.', 'Su: K_k = 0,512 K·kg/mol.'),
    presets: const [
      SolverPreset(Bi('Water', 'Su'), {'K': 0.512}),
      SolverPreset(Bi('Benzene', 'Benzen'), {'K': 2.53}),
      SolverPreset(Bi('Ethanol', 'Etanol'), {'K': 1.22}),
      SolverPreset(Bi('Acetic acid', 'Asetik asit'), {'K': 3.07}),
      SolverPreset(Bi('Chloroform', 'Kloroform'), {'K': 3.63}),
      SolverPreset(Bi('Cyclohexane', 'Siklohekzan'), {'K': 2.79}),
    ],
  ),
  SolverEquation(
    id: 'freezing',
    title: const Bi('Freezing point depression', 'Donma noktası alçalması'),
    formula: 'ΔT_f = i · K_f · m',
    formulaTr: 'ΔT_d = i · K_d · m',
    defaultTarget: 'dT',
    variables: [
      const SolverVar('dT', 'ΔT_f', Bi('Freezing point depression', 'Donma noktası alçalması'),
          symbolTr: 'ΔT_d',
          Quantity.temperatureDifference,
          unit: 'C'),
      _num('i', 'i', _vanHoffI, def: 1),
      const SolverVar('K', 'K_f', Bi('Cryoscopic constant', 'Kriyoskopi sabiti'),
          symbolTr: 'K_d',
          Quantity.cryoscopic,
          defaultValue: 1.86),
      _molality(),
    ],
    solvers: {
      'dT': (v) => v['i']! * v['K']! * v['b']!,
      'i': (v) => v['dT']! / (v['K']! * v['b']!),
      'K': (v) => v['dT']! / (v['i']! * v['b']!),
      'b': (v) => v['dT']! / (v['i']! * v['K']!),
    },
    note: const Bi('Water: K_f = 1.86 K·kg/mol.', 'Su: K_d = 1,86 K·kg/mol.'),
    presets: const [
      SolverPreset(Bi('Water', 'Su'), {'K': 1.86}),
      SolverPreset(Bi('Benzene', 'Benzen'), {'K': 5.12}),
      SolverPreset(Bi('Ethanol', 'Etanol'), {'K': 1.99}),
      SolverPreset(Bi('Acetic acid', 'Asetik asit'), {'K': 3.90}),
      SolverPreset(Bi('Chloroform', 'Kloroform'), {'K': 4.68}),
      SolverPreset(Bi('Cyclohexane', 'Siklohekzan'), {'K': 20.0}),
    ],
  ),
  SolverEquation(
    id: 'osmotic',
    title: const Bi('Osmotic pressure', 'Ozmotik basınç'),
    formula: 'π = i · M · R · T',
    defaultTarget: 'pi',
    variables: [
      _p('pi', 'π', name: const Bi('Osmotic pressure', 'Ozmotik basınç')),
      _num('i', 'i', _vanHoffI, def: 1),
      _c('M', 'M', name: const Bi('Molarity', 'Molarite')),
      _t('T', 'T', unit: 'C', def: 25),
    ],
    solvers: {
      'pi': (v) => v['i']! * v['M']! * 1000 * _r * v['T']!,
      'i': (v) => v['pi']! / (v['M']! * 1000 * _r * v['T']!),
      'M': (v) => v['pi']! / (v['i']! * 1000 * _r * v['T']!),
      'T': (v) => v['pi']! / (v['i']! * v['M']! * 1000 * _r),
    },
  ),
  SolverEquation(
    id: 'raoult',
    title: const Bi("Raoult's law", 'Raoult yasası'),
    formula: 'P = x_solvent · P°',
    formulaTr: 'P = x_çözücü · P°',
    defaultTarget: 'P',
    variables: [
      _p('P', 'P', name: const Bi('Vapor pressure of solution', 'Çözeltinin buhar basıncı'), unit: 'mmHg'),
      _num('x', 'x_solvent', _molFrac, symTr: 'x_çözücü'),
      _p('P0', 'P°', name: const Bi('Vapor pressure of pure solvent', 'Saf çözücünün buhar basıncı'), unit: 'mmHg'),
    ],
    solvers: {
      'P': (v) => v['x']! * v['P0']!,
      'x': (v) => v['P']! / v['P0']!,
      'P0': (v) => v['P']! / v['x']!,
    },
  ),
];

// ---------------------------------------------------------------------------
// Numerical helpers
// ---------------------------------------------------------------------------

/// Bisection on [lo, hi] where f(lo) and f(hi) have opposite signs.
double _bisect(double Function(double) f, double lo, double hi) {
  var flo = f(lo);
  for (var i = 0; i < 300; i++) {
    final mid = lo + (hi - lo) / 2;
    final fm = f(mid);
    if (fm == 0 || (hi - lo).abs() <= 1e-15 * mid.abs()) return mid;
    if ((fm < 0) == (flo < 0)) {
      lo = mid;
      flo = fm;
    } else {
      hi = mid;
    }
  }
  return lo + (hi - lo) / 2;
}

/// Largest root of f in (lo, hi], scanning down from hi on a log grid.
/// Used for the van der Waals volume, whose largest root is the gas phase.
double _largestRoot(double Function(double) f, double lo, double hi) {
  var x = hi;
  var fx = f(x);
  const steps = 4000;
  final ratio = math.pow(lo / hi, 1 / steps).toDouble();
  for (var i = 0; i < steps; i++) {
    final y = math.max(x * ratio, lo * (1 + 1e-12));
    final fy = f(y);
    if ((fy < 0) != (fx < 0)) return _bisect(f, y, x);
    x = y;
    fx = fy;
  }
  throw StateError('no root');
}

/// Smallest root of f in [lo, hi), scanning up from lo on a log grid.
double _smallestRoot(double Function(double) f, double lo, double hi) {
  var x = lo;
  var fx = f(x);
  const steps = 4000;
  final ratio = math.pow(hi / lo, 1 / steps).toDouble();
  for (var i = 0; i < steps; i++) {
    final y = math.min(x * ratio, hi * (1 - 1e-12));
    final fy = f(y);
    if ((fy < 0) != (fx < 0)) return _bisect(f, x, y);
    x = y;
    fx = fy;
  }
  throw StateError('no root');
}

// ---------------------------------------------------------------------------
// Real gases & kinetic theory
// ---------------------------------------------------------------------------

/// van der Waals pressure in Pa; a in L²·bar/mol², b in L/mol, V in L.
double _vdwP(double n, double v, double t, double a, double b) =>
    n * _r * t / ((v - n * b) / 1000) - 1e5 * a * n * n / (v * v);

final realGasEquations = <SolverEquation>[
  SolverEquation(
    id: 'vdw',
    title: const Bi('van der Waals equation', 'van der Waals denklemi'),
    formula: '(P + a·n²/V²)(V − n·b) = nRT',
    defaultTarget: 'P',
    variables: [
      _p('P', 'P', unit: 'bar'),
      _v('V', 'V'),
      _n('n', 'n'),
      _t('T', 'T', unit: 'C'),
      const SolverVar('a', 'a', Bi('Attraction constant', 'Çekim sabiti'), Quantity.vdwA),
      const SolverVar('b', 'b', Bi('Excluded volume', 'Molar hacim düzeltmesi'), Quantity.vdwB),
    ],
    solvers: {
      'P': (v) => v['V']! > v['n']! * v['b']!
          ? _vdwP(v['n']!, v['V']!, v['T']!, v['a']!, v['b']!)
          : double.nan,
      'T': (v) => v['V']! > v['n']! * v['b']!
          ? (v['P']! + 1e5 * v['a']! * v['n']! * v['n']! / (v['V']! * v['V']!)) *
              ((v['V']! - v['n']! * v['b']!) / 1000) /
              (v['n']! * _r)
          : double.nan,
      'V': (v) {
        final n = v['n']!, t = v['T']!, a = v['a']!, b = v['b']!, p = v['P']!;
        final ideal = n * _r * t / p * 1000;
        return _largestRoot((x) => _vdwP(n, x, t, a, b) - p, n * b, 1000 * ideal + n * b + 1);
      },
      'n': (v) {
        final vol = v['V']!, t = v['T']!, a = v['a']!, b = v['b']!, p = v['P']!;
        final nmax = b > 0 ? vol / b : 1e12;
        return _smallestRoot((x) => _vdwP(x, vol, t, a, b) - p, 1e-15 * nmax, nmax);
      },
    },
    extras: [
      SolverExtra('Z', const Bi('Compressibility factor PV/nRT', 'Sıkıştırılabilirlik faktörü PV/nRT'),
          Quantity.dimensionless, (v) => v['P']! * v['V']! / 1000 / (v['n']! * _r * v['T']!)),
      SolverExtra('P_ideal', const Bi('Ideal-gas pressure', 'İdeal gaz basıncı'), Quantity.pressure,
          (v) => v['n']! * _r * v['T']! / (v['V']! / 1000),
          unit: 'bar'),
    ],
    note: const Bi(
      'When solving for V or n the gas-phase root is returned. Constants: CRC Handbook.',
      'V veya n çözülürken gaz fazına ait kök verilir. Sabitler: CRC El Kitabı.',
    ),
    presets: const [
      SolverPreset(Bi('He', 'He'), {'a': 0.0346, 'b': 0.0238}),
      SolverPreset(Bi('H₂', 'H₂'), {'a': 0.2476, 'b': 0.02661}),
      SolverPreset(Bi('N₂', 'N₂'), {'a': 1.370, 'b': 0.0387}),
      SolverPreset(Bi('O₂', 'O₂'), {'a': 1.382, 'b': 0.03186}),
      SolverPreset(Bi('Ar', 'Ar'), {'a': 1.355, 'b': 0.03201}),
      SolverPreset(Bi('CO₂', 'CO₂'), {'a': 3.640, 'b': 0.04267}),
      SolverPreset(Bi('CH₄', 'CH₄'), {'a': 2.283, 'b': 0.04278}),
      SolverPreset(Bi('NH₃', 'NH₃'), {'a': 4.225, 'b': 0.0371}),
      SolverPreset(Bi('H₂O', 'H₂O'), {'a': 5.536, 'b': 0.03049}),
      SolverPreset(Bi('Cl₂', 'Cl₂'), {'a': 6.579, 'b': 0.05622}),
    ],
  ),
  SolverEquation(
    id: 'gasSpeed',
    title: const Bi('Molecular speeds', 'Molekül hızları'),
    formula: 'u_rms = √(3RT / M)',
    defaultTarget: 'u',
    variables: [
      const SolverVar('u', 'u_rms', Bi('Root-mean-square speed', 'Kök ortalama kare hız'),
          Quantity.speed),
      _t('T', 'T', unit: 'C', def: 25),
      _mm('M', 'M'),
    ],
    solvers: {
      'u': (v) => math.sqrt(3 * _r * v['T']! / (v['M']! / 1000)),
      'T': (v) => v['u']! * v['u']! * (v['M']! / 1000) / (3 * _r),
      'M': (v) => 3 * _r * v['T']! / (v['u']! * v['u']!) * 1000,
    },
    extras: [
      SolverExtra('ū', const Bi('Mean speed √(8RT/πM)', 'Ortalama hız √(8RT/πM)'), Quantity.speed,
          (v) => math.sqrt(8 * _r * v['T']! / (math.pi * v['M']! / 1000))),
      SolverExtra('u_mp', const Bi('Most probable speed √(2RT/M)', 'En olası hız √(2RT/M)'),
          Quantity.speed, (v) => math.sqrt(2 * _r * v['T']! / (v['M']! / 1000))),
      SolverExtra('E_k', const Bi('Mean kinetic energy (3/2)RT', 'Ortalama kinetik enerji (3/2)RT'),
          Quantity.molarEnergy, (v) => 1.5 * _r * v['T']!),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Equilibrium & solubility
// ---------------------------------------------------------------------------

/// R in L·atm/(mol·K) for Kp (atm) ⇄ Kc (mol/L).
const double _rLatm = gasConstant / 101.325;

final equilibriumEquations = <SolverEquation>[
  SolverEquation(
    id: 'kpkc',
    title: const Bi('Kp ⇄ Kc', 'Kp ⇄ Kc'),
    formula: 'Kp = Kc·(RT)^Δn',
    defaultTarget: 'Kp',
    variables: [
      _num('Kp', 'Kp', const Bi('Equilibrium constant (pressures in atm)', 'Denge sabiti (basınçlar atm)')),
      _num('Kc', 'Kc', const Bi('Equilibrium constant (mol/L)', 'Denge sabiti (mol/L)')),
      _t('T', 'T', unit: 'C', def: 25),
      _num('dn', 'Δn', const Bi('Δn of gases (products − reactants)', 'Gazların Δn’i (ürünler − girenler)'),
          neg: true),
    ],
    solvers: {
      'Kp': (v) => v['Kc']! * math.pow(_rLatm * v['T']!, v['dn']!),
      'Kc': (v) => v['Kp']! / math.pow(_rLatm * v['T']!, v['dn']!),
      'T': (v) => math.pow(v['Kp']! / v['Kc']!, 1 / v['dn']!) / _rLatm,
      'dn': (v) => math.log(v['Kp']! / v['Kc']!) / math.log(_rLatm * v['T']!),
    },
    note: const Bi(
      'R = 0.082057 L·atm/(mol·K); e.g. N₂ + 3H₂ ⇌ 2NH₃ has Δn = −2.',
      'R = 0,082057 L·atm/(mol·K); ör. N₂ + 3H₂ ⇌ 2NH₃ için Δn = −2.',
    ),
  ),
  SolverEquation(
    id: 'ksp',
    title: const Bi('Solubility product', 'Çözünürlük çarpımı'),
    formula: 'MₓAᵧ ⇌ xM + yA,  Ksp = xˣ·yʸ·s^(x+y)',
    defaultTarget: 's',
    variables: [
      _num('Ksp', 'Ksp', const Bi('Solubility product', 'Çözünürlük çarpımı')),
      _c('s', 's', name: const Bi('Molar solubility', 'Molar çözünürlük')),
      _num('x', 'x', const Bi('Cations per formula', 'Formüldeki katyon sayısı'), def: 1),
      _num('y', 'y', const Bi('Anions per formula', 'Formüldeki anyon sayısı'), def: 1),
    ],
    solvers: {
      'Ksp': (v) {
        final x = v['x']!, y = v['y']!;
        return math.pow(x, x) * math.pow(y, y) * math.pow(v['s']!, x + y).toDouble();
      },
      's': (v) {
        final x = v['x']!, y = v['y']!;
        return math.pow(v['Ksp']! / (math.pow(x, x) * math.pow(y, y)), 1 / (x + y)).toDouble();
      },
    },
    extras: [
      SolverExtra('[M]', const Bi('Cation concentration', 'Katyon derişimi'), Quantity.concentration,
          (v) => v['x']! * v['s']!),
      SolverExtra('[A]', const Bi('Anion concentration', 'Anyon derişimi'), Quantity.concentration,
          (v) => v['y']! * v['s']!),
    ],
    note: const Bi(
      'In pure water, neglecting activity coefficients and hydrolysis. CaF₂: x = 1, y = 2.',
      'Saf suda; aktiflik katsayıları ve hidroliz ihmal edilir. CaF₂: x = 1, y = 2.',
    ),
    presets: const [
      SolverPreset(Bi('AgCl (25 °C)', 'AgCl (25 °C)'), {'Ksp': 1.77e-10, 'x': 1, 'y': 1}),
      SolverPreset(Bi('BaSO₄', 'BaSO₄'), {'Ksp': 1.08e-10, 'x': 1, 'y': 1}),
      SolverPreset(Bi('CaF₂', 'CaF₂'), {'Ksp': 3.45e-11, 'x': 1, 'y': 2}),
      SolverPreset(Bi('Ag₂CrO₄', 'Ag₂CrO₄'), {'Ksp': 1.12e-12, 'x': 2, 'y': 1}),
      SolverPreset(Bi('PbI₂', 'PbI₂'), {'Ksp': 9.8e-9, 'x': 1, 'y': 2}),
      SolverPreset(Bi('Ca₃(PO₄)₂', 'Ca₃(PO₄)₂'), {'Ksp': 2.07e-33, 'x': 3, 'y': 2}),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Nuclear chemistry
// ---------------------------------------------------------------------------

SolverVar _halfLife() => const SolverVar(
    'th', 't½', Bi('Half-life', 'Yarılanma süresi'), Quantity.time,
    unit: 'y');

final nuclearEquations = <SolverEquation>[
  SolverEquation(
    id: 'decay',
    title: const Bi('Radioactive decay', 'Radyoaktif bozunma'),
    formula: 'm = m₀·(½)^(t / t½)',
    defaultTarget: 'm',
    variables: [
      _m('m', 'm', name: const Bi('Amount remaining', 'Kalan miktar')),
      _m('m0', 'm₀', name: const Bi('Initial amount', 'Başlangıç miktarı')),
      const SolverVar('t', 't', Bi('Elapsed time', 'Geçen süre'), Quantity.time, unit: 'y'),
      _halfLife(),
    ],
    solvers: {
      'm': (v) => v['m0']! * math.pow(0.5, v['t']! / v['th']!),
      'm0': (v) => v['m']! / math.pow(0.5, v['t']! / v['th']!),
      't': (v) => v['th']! * math.log(v['m0']! / v['m']!) / math.ln2,
      'th': (v) => v['t']! * math.ln2 / math.log(v['m0']! / v['m']!),
    },
    extras: [
      SolverExtra('m/m₀', const Bi('Fraction remaining', 'Kalan oran'), Quantity.percent,
          (v) => v['m']! / v['m0']! * 100),
      SolverExtra('λ', const Bi('Decay constant ln2/t½', 'Bozunma sabiti ln2/t½'),
          Quantity.rateConstant, (v) => math.ln2 / v['th']!,
          unit: 'h-1'),
    ],
    note: const Bi(
      'Works with any amount unit (mass, moles, atoms, activity) as long as both are the same. Half-lives: NUBASE2020.',
      'Her iki miktar aynı birimde olduğu sürece kütle, mol, atom sayısı veya aktiviteyle çalışır. Yarılanma süreleri: NUBASE2020.',
    ),
    presets: const [
      SolverPreset(Bi('¹⁴C', '¹⁴C'), {'th': 5700}),
      SolverPreset(Bi('³H', '³H'), {'th': 12.32}),
      SolverPreset(Bi('⁶⁰Co', '⁶⁰Co'), {'th': 5.2714}),
      SolverPreset(Bi('¹³⁷Cs', '¹³⁷Cs'), {'th': 30.04}),
      SolverPreset(Bi('⁹⁰Sr', '⁹⁰Sr'), {'th': 28.91}),
      SolverPreset(Bi('²²⁶Ra', '²²⁶Ra'), {'th': 1600}),
      SolverPreset(Bi('²³⁸U', '²³⁸U'), {'th': 4.463e9}),
      SolverPreset(Bi('⁴⁰K', '⁴⁰K'), {'th': 1.248e9}),
    ],
  ),
  SolverEquation(
    id: 'activity',
    title: const Bi('Activity of a sample', 'Numunenin aktivitesi'),
    formula: 'A = (ln 2 / t½)·(m / M)·Nₐ',
    defaultTarget: 'A',
    variables: [
      const SolverVar('A', 'A', Bi('Activity', 'Aktivite'), Quantity.activity),
      _halfLife(),
      _m('m', 'm', name: const Bi('Mass of the nuclide', 'Çekirdeğin kütlesi')),
      _mm('M', 'M', name: const Bi('Molar mass of the nuclide', 'Çekirdeğin mol kütlesi')),
    ],
    solvers: {
      'A': (v) => math.ln2 / v['th']! * v['m']! / v['M']! * avogadro,
      'th': (v) => math.ln2 * v['m']! / v['M']! * avogadro / v['A']!,
      'm': (v) => v['A']! * v['th']! / math.ln2 * v['M']! / avogadro,
      'M': (v) => math.ln2 / v['th']! * v['m']! * avogadro / v['A']!,
    },
    extras: [
      SolverExtra('N', const Bi('Number of nuclei', 'Çekirdek sayısı'), Quantity.dimensionless,
          (v) => v['m']! / v['M']! * avogadro),
    ],
    presets: const [
      SolverPreset(Bi('¹⁴C', '¹⁴C'), {'th': 5700, 'M': 14.003241988}),
      SolverPreset(Bi('⁶⁰Co', '⁶⁰Co'), {'th': 5.2714, 'M': 59.933815577}),
      SolverPreset(Bi('¹³⁷Cs', '¹³⁷Cs'), {'th': 30.04, 'M': 136.907089267}),
      SolverPreset(Bi('²²⁶Ra', '²²⁶Ra'), {'th': 1600, 'M': 226.025408212}),
      SolverPreset(Bi('²³⁸U', '²³⁸U'), {'th': 4.463e9, 'M': 238.050786902}),
    ],
    note: const Bi(
      '1 g of ²²⁶Ra ≈ 1 Ci (the historical definition of the curie).',
      '1 g ²²⁶Ra ≈ 1 Ci (curie biriminin tarihsel tanımı).',
    ),
  ),
];

// ---------------------------------------------------------------------------
// Atomic structure & crystals
// ---------------------------------------------------------------------------

/// Rydberg constant for hydrogen (reduced-mass corrected), m⁻¹.
const double rydbergH = 10973731.568157 / (1 + 9.1093837139e-31 / 1.67262192595e-27);

final atomicEquations = <SolverEquation>[
  SolverEquation(
    id: 'rydberg',
    title: const Bi('Hydrogen spectrum (Rydberg)', 'Hidrojen spektrumu (Rydberg)'),
    formula: '1/λ = R_H·(1/n₁² − 1/n₂²)',
    defaultTarget: 'l',
    variables: [
      const SolverVar('l', 'λ', Bi('Wavelength (vacuum)', 'Dalga boyu (vakum)'), Quantity.length,
          unit: 'nm'),
      _num('n1', 'n₁', const Bi('Lower level', 'Alt seviye'), def: 2),
      _num('n2', 'n₂', const Bi('Upper level', 'Üst seviye'), def: 3),
    ],
    solvers: {
      'l': (v) => 1 / (rydbergH * (1 / (v['n1']! * v['n1']!) - 1 / (v['n2']! * v['n2']!))),
      'n2': (v) => 1 / math.sqrt(1 / (v['n1']! * v['n1']!) - 1 / (v['l']! * rydbergH)),
    },
    extras: [
      SolverExtra('E', const Bi('Photon energy', 'Foton enerjisi'), Quantity.energy,
          (v) => planck * speedOfLight / v['l']!,
          unit: 'eV'),
      SolverExtra('ν', const Bi('Frequency', 'Frekans'), Quantity.frequency,
          (v) => speedOfLight / v['l']!,
          unit: 'THz'),
    ],
    note: const Bi(
      'n₁ = 1 Lyman, 2 Balmer (visible), 3 Paschen. R_H = 1.0967758 × 10⁷ m⁻¹.',
      'n₁ = 1 Lyman, 2 Balmer (görünür), 3 Paschen. R_H = 1,0967758 × 10⁷ m⁻¹.',
    ),
  ),
  SolverEquation(
    id: 'bohr',
    title: const Bi('Hydrogen-like energy levels', 'Hidrojen benzeri enerji seviyeleri'),
    formula: 'Eₙ = −R_H·h·c·Z² / n²',
    defaultTarget: 'E',
    variables: [
      const SolverVar('E', 'Eₙ', Bi('Energy of level n', 'n seviyesinin enerjisi'), Quantity.energy,
          unit: 'eV', allowNegative: true),
      _num('n', 'n', const Bi('Principal quantum number', 'Baş kuantum sayısı'), def: 1),
      _num('Z', 'Z', const Bi('Nuclear charge', 'Çekirdek yükü'), def: 1),
    ],
    solvers: {
      'E': (v) => -rydbergH * planck * speedOfLight * v['Z']! * v['Z']! / (v['n']! * v['n']!),
      'n': (v) => math.sqrt(-rydbergH * planck * speedOfLight * v['Z']! * v['Z']! / v['E']!),
    },
    extras: [
      SolverExtra('IE', const Bi('Ionization energy from this level', 'Bu seviyeden iyonlaşma enerjisi'),
          Quantity.molarEnergy,
          (v) => rydbergH * planck * speedOfLight * v['Z']! * v['Z']! / (v['n']! * v['n']!) * avogadro),
    ],
    note: const Bi('Hydrogen: E₁ = −13.598 eV.', 'Hidrojen: E₁ = −13,598 eV.'),
  ),
  SolverEquation(
    id: 'deBroglie',
    title: const Bi('de Broglie wavelength', 'de Broglie dalga boyu'),
    formula: 'λ = h / (m·v)',
    defaultTarget: 'l',
    variables: [
      const SolverVar('l', 'λ', Bi('Wavelength', 'Dalga boyu'), Quantity.length, unit: 'nm'),
      _m('m', 'm', name: const Bi('Particle mass', 'Parçacık kütlesi'), unit: 'u'),
      const SolverVar('v', 'v', Bi('Speed', 'Hız'), Quantity.speed),
    ],
    solvers: {
      'l': (v) => planck / (v['m']! / 1000 * v['v']!),
      'm': (v) => planck / (v['l']! * v['v']!) * 1000,
      'v': (v) => planck / (v['l']! * v['m']! / 1000),
    },
    extras: [
      SolverExtra('E_k', const Bi('Kinetic energy ½mv²', 'Kinetik enerji ½mv²'), Quantity.energy,
          (v) => 0.5 * v['m']! / 1000 * v['v']! * v['v']!,
          unit: 'eV'),
    ],
    presets: const [
      SolverPreset(Bi('electron', 'elektron'), {'m': 9.1093837139e-31 / 1.66053906892e-27}),
      SolverPreset(Bi('proton', 'proton'), {'m': 1.67262192595e-27 / 1.66053906892e-27}),
      SolverPreset(Bi('neutron', 'nötron'), {'m': 1.67492750056e-27 / 1.66053906892e-27}),
    ],
  ),
  SolverEquation(
    id: 'crystal',
    title: const Bi('Density of a cubic crystal', 'Kübik kristalin yoğunluğu'),
    formula: 'ρ = Z·M / (Nₐ·a³)',
    defaultTarget: 'rho',
    variables: [
      const SolverVar('rho', 'ρ', Bi('Density', 'Yoğunluk'), Quantity.density, unit: 'gcm3'),
      _num('Z', 'Z', const Bi('Formula units per unit cell', 'Birim hücredeki formül birimi'), def: 4),
      _mm('M', 'M'),
      const SolverVar('a', 'a', Bi('Cell edge', 'Hücre kenarı'), Quantity.length, unit: 'pm'),
    ],
    solvers: {
      'rho': (v) => v['Z']! * v['M']! / (avogadro * math.pow(v['a']! * 100, 3)),
      'Z': (v) => v['rho']! * avogadro * math.pow(v['a']! * 100, 3) / v['M']!,
      'M': (v) => v['rho']! * avogadro * math.pow(v['a']! * 100, 3) / v['Z']!,
      'a': (v) => math.pow(v['Z']! * v['M']! / (avogadro * v['rho']!), 1 / 3) / 100,
    },
    presets: const [
      SolverPreset(Bi('simple cubic (Z = 1)', 'basit kübik (Z = 1)'), {'Z': 1}),
      SolverPreset(Bi('bcc (Z = 2)', 'hacim merkezli (Z = 2)'), {'Z': 2}),
      SolverPreset(Bi('fcc / NaCl (Z = 4)', 'yüzey merkezli / NaCl (Z = 4)'), {'Z': 4}),
      SolverPreset(Bi('diamond (Z = 8)', 'elmas (Z = 8)'), {'Z': 8}),
    ],
  ),
  SolverEquation(
    id: 'bragg',
    title: const Bi("Bragg's law (X-ray diffraction)", 'Bragg yasası (X-ışını kırınımı)'),
    formula: 'n·λ = 2·d·sin θ',
    defaultTarget: 'd',
    variables: [
      _num('n', 'n', const Bi('Diffraction order', 'Kırınım mertebesi'), def: 1),
      const SolverVar(
        'l',
        'λ',
        Bi('X-ray wavelength', 'X-ışını dalga boyu'),
        Quantity.length,
        unit: 'pm',
        defaultValue: 154.0593,
      ),
      const SolverVar('d', 'd', Bi('Interplanar spacing', 'Düzlemler arası uzaklık'), Quantity.length, unit: 'pm'),
      const SolverVar(
        'theta',
        'θ',
        Bi('Bragg angle (half of 2θ)', 'Bragg açısı (2θ’nın yarısı)'),
        Quantity.dimensionless,
        unitLabel: '°',
      ),
    ],
    solvers: {
      'd': (v) => v['n']! * v['l']! / (2 * math.sin(_braggRad(v['theta']!))),
      'theta': (v) => math.asin(v['n']! * v['l']! / (2 * v['d']!)) * 180 / math.pi,
      'l': (v) => 2 * v['d']! * math.sin(_braggRad(v['theta']!)) / v['n']!,
      'n': (v) => 2 * v['d']! * math.sin(_braggRad(v['theta']!)) / v['l']!,
    },
    extras: [
      SolverExtra(
        '2θ',
        const Bi('Diffractometer angle', 'Difraktometre açısı'),
        Quantity.dimensionless,
        (v) => 2 * v['theta']!,
        unitLabel: '°',
      ),
      SolverExtra(
        'd/n',
        const Bi('Spacing of the first-order reflection', 'Birinci mertebe yansıma aralığı'),
        Quantity.length,
        (v) => v['d']! / v['n']!,
        unit: 'A',
      ),
    ],
    presets: const [
      SolverPreset(Bi('Cu Kα₁', 'Cu Kα₁'), {'l': 154.0593}),
      SolverPreset(Bi('Mo Kα₁', 'Mo Kα₁'), {'l': 70.9317}),
      SolverPreset(Bi('Co Kα₁', 'Co Kα₁'), {'l': 178.8965}),
      SolverPreset(Bi('Cr Kα₁', 'Cr Kα₁'), {'l': 228.9760}),
    ],
    note: const Bi(
      'θ is the angle between the beam and the lattice planes; diffractometers report 2θ. '
          'Kα₁ wavelengths: Hölzer et al., Phys. Rev. A 56, 4554 (1997).',
      'θ, ışın ile örgü düzlemleri arasındaki açıdır; difraktometreler 2θ verir. '
          'Kα₁ dalga boyları: Hölzer vd., Phys. Rev. A 56, 4554 (1997).',
    ),
  ),
  SolverEquation(
    id: 'vibration',
    title: const Bi('Diatomic vibration (harmonic)', 'İki atomlu titreşim (harmonik)'),
    formula: 'ν̃ = (1/2πc)·√(k/μ),  μ = m₁m₂/(m₁+m₂)',
    defaultTarget: 'wn',
    variables: [
      const SolverVar('wn', 'ν̃', Bi('Wavenumber', 'Dalga sayısı'), Quantity.dimensionless, unitLabel: 'cm⁻¹'),
      const SolverVar('kf', 'k', Bi('Force constant', 'Kuvvet sabiti'), Quantity.dimensionless, unitLabel: 'N/m'),
      _m('m1', 'm₁', name: const Bi('Mass of atom 1', '1. atomun kütlesi'), unit: 'u'),
      _m('m2', 'm₂', name: const Bi('Mass of atom 2', '2. atomun kütlesi'), unit: 'u'),
    ],
    solvers: {
      'wn': (v) => math.sqrt(v['kf']! / _reducedKg(v['m1']!, v['m2']!)) / (2 * math.pi * speedOfLight * 100),
      'kf': (v) => _reducedKg(v['m1']!, v['m2']!) * math.pow(2 * math.pi * speedOfLight * 100 * v['wn']!, 2),
      'm2': (v) => _otherMass(v['kf']!, v['wn']!, v['m1']!),
      'm1': (v) => _otherMass(v['kf']!, v['wn']!, v['m2']!),
    },
    extras: [
      SolverExtra(
        'μ',
        const Bi('Reduced mass', 'İndirgenmiş kütle'),
        Quantity.mass,
        (v) => v['m1']! * v['m2']! / (v['m1']! + v['m2']!),
        unit: 'u',
      ),
      SolverExtra(
        'ν',
        const Bi('Frequency', 'Frekans'),
        Quantity.frequency,
        (v) => speedOfLight * 100 * v['wn']!,
        unit: 'THz',
      ),
      SolverExtra('λ', const Bi('Wavelength', 'Dalga boyu'), Quantity.length, (v) => 1 / (100 * v['wn']!), unit: 'um'),
    ],
    presets: const [
      SolverPreset(Bi('¹H³⁵Cl', '¹H³⁵Cl'), {'kf': 516, 'm1': 1.00782503, 'm2': 34.96885268}),
      SolverPreset(Bi('¹H¹⁹F', '¹H¹⁹F'), {'kf': 966, 'm1': 1.00782503, 'm2': 18.99840316}),
      SolverPreset(Bi('¹²C¹⁶O', '¹²C¹⁶O'), {'kf': 1902, 'm1': 12, 'm2': 15.99491462}),
      SolverPreset(Bi('¹⁴N₂', '¹⁴N₂'), {'kf': 2295, 'm1': 14.00307401, 'm2': 14.00307401}),
      SolverPreset(Bi('¹H₂', '¹H₂'), {'kf': 575, 'm1': 1.00782503, 'm2': 1.00782503}),
    ],
    note: const Bi(
      'Harmonic wavenumber ωₑ; the observed fundamental is lower because of anharmonicity '
          '(¹H³⁵Cl: ωₑ = 2991, fundamental 2886 cm⁻¹). Replacing H by D lowers ν̃ by about √2.',
      'Harmonik dalga sayısı ωₑ; gözlenen temel bant anharmoniklik nedeniyle daha düşüktür '
          '(¹H³⁵Cl: ωₑ = 2991, temel bant 2886 cm⁻¹). H yerine D konunca ν̃ yaklaşık √2 kat düşer.',
    ),
  ),
];

/// Bragg angle in radians; θ must lie in (0°, 90°].
double _braggRad(double deg) {
  if (deg <= 0 || deg > 90) throw ArgumentError('θ outside (0, 90]');
  return deg * math.pi / 180;
}

/// Reduced mass in kg from atomic masses in grams (the solver's base unit).
double _reducedKg(double m1, double m2) => m1 * m2 / (m1 + m2) / 1000;

/// The second mass (g) from k, ν̃ and the first mass; none when the first
/// mass alone is lighter than the required reduced mass.
double _otherMass(double k, double wn, double m) {
  final mu = k / math.pow(2 * math.pi * speedOfLight * 100 * wn, 2) * 1000;
  final inv = 1 / mu - 1 / m;
  if (inv <= 0) throw ArgumentError('no second mass');
  return 1 / inv;
}
