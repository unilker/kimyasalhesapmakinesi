import 'package:flutter/material.dart';

import '../../core/bi.dart';
import '../../core/solver_catalog.dart';
import '../theme.dart';
import 'activity_screen.dart';
import 'balancer_screen.dart';
import 'cell_screen.dart';
import 'constants_screen.dart';
import 'empirical_screen.dart';
import 'hess_screen.dart';
import 'ice_screen.dart';
import 'mass_spec_screen.dart';
import 'molar_mass_screen.dart';
import 'nmr_screen.dart';
import 'nuclide_screen.dart';
import 'ph_scale.dart';
import 'rate_data_screen.dart';
import 'solver_screen.dart';
import 'speciation_screen.dart';
import 'stats_screen.dart';
import 'titration_screen.dart';
import 'uncertainty_screen.dart';
import 'unit_converter_screen.dart';

enum ToolCategory { basics, solutions, reactions, physical, analysis, reference }

Bi categoryTitle(ToolCategory c) => switch (c) {
      ToolCategory.basics => const Bi('Basics', 'Temel'),
      ToolCategory.solutions => const Bi('Solutions & acids', 'Çözeltiler ve asitler'),
      ToolCategory.reactions => const Bi('Reactions', 'Tepkimeler'),
      ToolCategory.physical => const Bi('Physical chemistry', 'Fizikokimya'),
      ToolCategory.analysis => const Bi('Analytical chemistry', 'Analitik kimya'),
      ToolCategory.reference => const Bi('Reference', 'Başvuru'),
    };

class ToolInfo {
  const ToolInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    required this.builder,
    this.keywords = '',
  });

  final String id;
  final Bi title;
  final Bi subtitle;
  final IconData icon;
  final Color color;
  final ToolCategory category;
  final Widget Function(ToolInfo tool) builder;

  /// Extra search terms (both languages).
  final String keywords;

  bool matches(String query, String lang) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = [title.en, title.tr, subtitle.en, subtitle.tr, keywords]
        .join(' ')
        .toLowerCase();
    return q.split(RegExp(r'\s+')).every(hay.contains);
  }
}

final List<ToolInfo> tools = [
  ToolInfo(
    id: 'molarMass',
    title: const Bi('Molar Mass', 'Mol Kütlesi'),
    subtitle: const Bi('Formula → g/mol & composition', 'Formül → g/mol ve bileşim'),
    icon: Icons.scale_rounded,
    color: Palette.violet,
    category: ToolCategory.basics,
    keywords: 'molecular weight molekül ağırlığı formula yüzde bileşim',
    builder: (t) => MolarMassScreen(tool: t),
  ),
  ToolInfo(
    id: 'moles',
    title: const Bi('Moles & Yield', 'Mol ve Verim'),
    subtitle: const Bi('Mass, particles, gas at STP, % yield', 'Kütle, tanecik, NŞA gaz, % verim'),
    icon: Icons.bubble_chart_rounded,
    color: Palette.blue,
    category: ToolCategory.basics,
    keywords: 'avogadro mol sayısı yield verim',
    builder: (t) => SolverScreen(tool: t, equations: moleEquations),
  ),
  ToolInfo(
    id: 'empirical',
    title: const Bi('Empirical Formula', 'Basit Formül'),
    subtitle: const Bi('From % composition', 'Yüzde bileşimden'),
    icon: Icons.pie_chart_rounded,
    color: Palette.pink,
    category: ToolCategory.basics,
    keywords: 'empirical molecular ampirik molekül formülü',
    builder: (t) => EmpiricalScreen(tool: t),
  ),
  ToolInfo(
    id: 'solutions',
    title: const Bi('Solutions', 'Çözeltiler'),
    subtitle: const Bi('Molarity, molality, %, ppm', 'Molarite, molalite, %, ppm'),
    icon: Icons.science_rounded,
    color: Palette.teal,
    category: ToolCategory.solutions,
    keywords: 'concentration derişim molarity molarite prepare hazırlama stock stok',
    builder: (t) => SolverScreen(tool: t, equations: solutionEquations),
  ),
  ToolInfo(
    id: 'dilution',
    title: const Bi('Dilution & Mixing', 'Seyreltme ve Karıştırma'),
    subtitle: const Bi('C₁V₁ = C₂V₂', 'C₁V₁ = C₂V₂'),
    icon: Icons.water_drop_rounded,
    color: Palette.cyan,
    category: ToolCategory.solutions,
    keywords: 'dilute seyrelt mix karıştır',
    builder: (t) => SolverScreen(tool: t, equations: dilutionEquations),
  ),
  ToolInfo(
    id: 'acidBase',
    title: const Bi('Acids, Bases & pH', 'Asit, Baz ve pH'),
    subtitle: const Bi('pH, Ka, buffers, titration', 'pH, Ka, tampon, titrasyon'),
    icon: Icons.opacity_rounded,
    color: Palette.green,
    category: ToolCategory.solutions,
    keywords: 'ph poh ka kb pka buffer tampon titration titrasyon asit baz',
    builder: (t) => SolverScreen(
      tool: t,
      equations: acidBaseEquations,
      resultExtra: phScaleForValues,
    ),
  ),
  ToolInfo(
    id: 'titration',
    title: const Bi('Titration Curve', 'Titrasyon Eğrisi'),
    subtitle: const Bi('pH curve, equivalence points, indicators', 'pH eğrisi, eşdeğerlik, gösterge'),
    icon: Icons.show_chart_rounded,
    color: Palette.pink,
    category: ToolCategory.solutions,
    keywords: 'titration titrasyon curve eğri equivalence eşdeğerlik indicator gösterge indikatör phenolphthalein fenolftalein polyprotic',
    builder: (t) => TitrationScreen(tool: t),
  ),
  ToolInfo(
    id: 'speciation',
    title: const Bi('Species Distribution', 'Tür Dağılımı'),
    subtitle: const Bi('α fractions vs pH for polyprotic acids', 'Poliprotik asitlerde α – pH'),
    icon: Icons.stacked_line_chart_rounded,
    color: Palette.teal,
    category: ToolCategory.solutions,
    keywords: 'speciation tür dağılımı alpha alfa fraction kesir polyprotic poliprotik distribution diagram diyagram pka',
    builder: (t) => SpeciationScreen(tool: t),
  ),
  ToolInfo(
    id: 'balancer',
    title: const Bi('Equations & Stoichiometry', 'Denklem ve Stokiyometri'),
    subtitle: const Bi('Balance, limiting reactant', 'Denkleştir, sınırlayıcı bileşen'),
    icon: Icons.balance_rounded,
    color: Palette.orange,
    category: ToolCategory.reactions,
    keywords: 'balance denkleştir reaction tepkime limiting sınırlayıcı redox',
    builder: (t) => BalancerScreen(tool: t),
  ),
  ToolInfo(
    id: 'equilibrium',
    title: const Bi('Equilibrium & Solubility', 'Denge ve Çözünürlük'),
    subtitle: const Bi('Kp ⇄ Kc, Ksp, solubility', 'Kp ⇄ Kc, Ksp, çözünürlük'),
    icon: Icons.sync_alt_rounded,
    color: Palette.teal,
    category: ToolCategory.reactions,
    keywords: 'equilibrium denge kp kc ksp solubility çözünürlük çökelme precipitate',
    builder: (t) => SolverScreen(tool: t, equations: equilibriumEquations),
  ),
  ToolInfo(
    id: 'ice',
    title: const Bi('ICE Table', 'Denge Tablosu (ICE)'),
    subtitle: const Bi('Equilibrium composition from K', 'K’den denge derişimleri'),
    icon: Icons.table_chart_rounded,
    color: Palette.indigo,
    category: ToolCategory.reactions,
    keywords: 'ice table equilibrium denge kc kp concentration derişim başlangıç değişim extent le chatelier common ion ortak iyon',
    builder: (t) => IceScreen(tool: t),
  ),
  ToolInfo(
    id: 'gas',
    title: const Bi('Gas Laws', 'Gaz Yasaları'),
    subtitle: const Bi('Ideal, real gases, molecular speeds', 'İdeal, gerçek gazlar, molekül hızları'),
    icon: Icons.air_rounded,
    color: Palette.indigo,
    category: ToolCategory.physical,
    keywords: 'ideal gas ideal gaz boyle charles dalton graham van der waals real gerçek rms speed hız',
    builder: (t) => SolverScreen(tool: t, equations: [...gasEquations, ...realGasEquations]),
  ),
  ToolInfo(
    id: 'thermo',
    title: const Bi('Thermochemistry', 'Termokimya'),
    subtitle: const Bi('q = mcΔT, ΔG, K', 'q = mcΔT, ΔG, K'),
    icon: Icons.local_fire_department_rounded,
    color: Palette.red,
    category: ToolCategory.physical,
    keywords: 'heat ısı enthalpy entalpi entropy entropi gibbs clausius',
    builder: (t) => SolverScreen(tool: t, equations: thermoEquations),
  ),
  ToolInfo(
    id: 'hess',
    title: const Bi('Reaction Thermodynamics', 'Tepkime Termodinamiği'),
    subtitle: const Bi('ΔH°, ΔS°, ΔG°, K from formation data', 'Oluşum verilerinden ΔH°, ΔS°, ΔG°, K'),
    icon: Icons.whatshot_rounded,
    color: Palette.orange,
    category: ToolCategory.physical,
    keywords: 'hess enthalpy entalpi entropy entropi gibbs formation oluşum combustion yanma spontaneous istemli codata thermodynamic termodinamik',
    builder: (t) => HessScreen(tool: t),
  ),
  ToolInfo(
    id: 'kinetics',
    title: const Bi('Kinetics', 'Kinetik'),
    subtitle: const Bi('Rate laws, half-life, Arrhenius', 'Hız yasaları, yarılanma, Arrhenius'),
    icon: Icons.timer_rounded,
    color: Palette.amber,
    category: ToolCategory.physical,
    keywords: 'rate hız half life yarılanma arrhenius activation aktivasyon',
    builder: (t) => SolverScreen(tool: t, equations: kineticsEquations),
  ),
  ToolInfo(
    id: 'rateData',
    title: const Bi('Rate Law from Data', 'Veriden Hız Kanunu'),
    subtitle: const Bi('Order, k and t½ from [A]–t data', '[A]–t verisinden derece, k ve t½'),
    icon: Icons.timeline_rounded,
    color: Palette.brown,
    category: ToolCategory.physical,
    keywords: 'kinetics kinetik order derece rate constant hız sabiti integrated integral half-life yarılanma data veri graph grafik linear',
    builder: (t) => RateDataScreen(tool: t),
  ),
  ToolInfo(
    id: 'electro',
    title: const Bi('Electrochemistry', 'Elektrokimya'),
    subtitle: const Bi('Nernst, Faraday, ΔG = −nFE', 'Nernst, Faraday, ΔG = −nFE'),
    icon: Icons.bolt_rounded,
    color: Palette.lime,
    category: ToolCategory.physical,
    keywords: 'nernst faraday electrolysis elektroliz cell hücre potential potansiyel',
    builder: (t) => SolverScreen(tool: t, equations: electroEquations),
  ),
  ToolInfo(
    id: 'cell',
    title: const Bi('Galvanic Cells & E° Table', 'Piller ve E° Tablosu'),
    subtitle: const Bi('E°cell, overall reaction, ΔG°, K', 'E°pil, toplam tepkime, ΔG°, K'),
    icon: Icons.battery_charging_full_rounded,
    color: Palette.blue,
    category: ToolCategory.physical,
    keywords: 'galvanic galvanik voltaic pil cell battery batarya electrode elektrot standard reduction potential indirgenme potansiyeli redox daniell anode anot cathode katot',
    builder: (t) => CellScreen(tool: t),
  ),
  ToolInfo(
    id: 'spectro',
    title: const Bi('Spectroscopy', 'Spektroskopi'),
    subtitle: const Bi('Beer–Lambert, photon energy', 'Beer–Lambert, foton enerjisi'),
    icon: Icons.wb_iridescent_rounded,
    color: Palette.pink,
    category: ToolCategory.physical,
    keywords: 'absorbance absorbans beer lambert wavelength dalga boyu photon foton',
    builder: (t) => SolverScreen(tool: t, equations: spectroEquations),
  ),
  ToolInfo(
    id: 'colligative',
    title: const Bi('Colligative Properties', 'Koligatif Özellikler'),
    subtitle: const Bi('ΔTb, ΔTf, osmotic pressure', 'Kaynama, donma, ozmotik basınç'),
    icon: Icons.ac_unit_rounded,
    color: Palette.cyan,
    category: ToolCategory.physical,
    keywords: 'boiling kaynama freezing donma osmotic ozmotik raoult',
    builder: (t) => SolverScreen(tool: t, equations: colligativeEquations),
  ),
  ToolInfo(
    id: 'nuclear',
    title: const Bi('Nuclear Chemistry', 'Nükleer Kimya'),
    subtitle: const Bi('Radioactive decay, activity', 'Radyoaktif bozunma, aktivite'),
    icon: Icons.radar_rounded,
    color: Palette.lime,
    category: ToolCategory.physical,
    keywords: 'radioactive radyoaktif decay bozunma half-life yarılanma activity aktivite becquerel curie carbon dating karbon',
    builder: (t) => SolverScreen(tool: t, equations: nuclearEquations),
  ),
  ToolInfo(
    id: 'nuclides',
    title: const Bi('Radionuclides', 'Radyonüklitler'),
    subtitle: const Bi('Half-lives, decay modes, activity', 'Yarılanma, bozunma türü, aktivite'),
    icon: Icons.hourglass_bottom_rounded,
    color: Palette.green,
    category: ToolCategory.physical,
    keywords: 'radionuclide radyonüklit isotope izotop half-life yarılanma decay bozunma nubase activity aktivite becquerel curie carbon dating karbon tarihleme',
    builder: (t) => NuclideScreen(tool: t),
  ),
  ToolInfo(
    id: 'atomic',
    title: const Bi('Atoms & Crystals', 'Atom ve Kristal'),
    subtitle: const Bi(
      'Rydberg, Bohr, de Broglie, unit cell, Bragg, IR vibration',
      'Rydberg, Bohr, de Broglie, birim hücre, Bragg, IR titreşimi',
    ),
    icon: Icons.blur_circular_rounded,
    color: Palette.violet,
    category: ToolCategory.physical,
    keywords: 'hydrogen hidrojen spectrum spektrum rydberg balmer bohr de broglie crystal kristal lattice örgü unit cell birim hücre bragg xrd x-ray x-ışını kırınım diffraction ir infrared kızılötesi vibration titreşim force constant kuvvet sabiti reduced mass indirgenmiş kütle wavenumber dalga sayısı',
    builder: (t) => SolverScreen(tool: t, equations: atomicEquations),
  ),
  ToolInfo(
    id: 'stats',
    title: const Bi('Statistics & Calibration', 'İstatistik ve Kalibrasyon'),
    subtitle: const Bi('Mean ± CI, Q/Grubbs, LOD/LOQ', 'Ortalama ± GA, Q/Grubbs, LOD/LOQ'),
    icon: Icons.query_stats_rounded,
    color: Palette.indigo,
    category: ToolCategory.analysis,
    keywords: 'statistics istatistik mean ortalama standard deviation standart sapma confidence güven outlier aykırı q test grubbs calibration kalibrasyon regression regresyon lod loq',
    builder: (t) => StatsScreen(tool: t),
  ),
  ToolInfo(
    id: 'activity',
    title: const Bi('Ionic Strength & Activity', 'İyonik Şiddet ve Aktiflik'),
    subtitle: const Bi('Debye–Hückel, Davies, Kielland ion sizes', 'Debye–Hückel, Davies, Kielland iyon boyutları'),
    icon: Icons.bubble_chart_rounded,
    color: Palette.orange,
    category: ToolCategory.analysis,
    keywords: 'ionic strength iyonik şiddet activity aktiflik aktivite coefficient katsayı debye hückel huckel davies kielland ion size iyon boyutu salt tuz electrolyte elektrolit',
    builder: (t) => ActivityScreen(tool: t),
  ),
  ToolInfo(
    id: 'uncertainty',
    title: const Bi('Uncertainty Propagation', 'Belirsizlik Yayılımı'),
    subtitle: const Bi('y ± u from any formula (GUM)', 'Her formülden y ± u (GUM)'),
    icon: Icons.track_changes_rounded,
    color: Palette.pink,
    category: ToolCategory.analysis,
    keywords: 'uncertainty belirsizlik error hata propagation yayılım gum budget bütçe monte carlo standard deviation standart sapma relative bağıl',
    builder: (t) => UncertaintyScreen(tool: t),
  ),
  ToolInfo(
    id: 'massSpec',
    title: const Bi('Mass Spectrometry', 'Kütle Spektrometrisi'),
    subtitle: const Bi('Exact mass, isotope pattern, m/z', 'Tam kütle, izotop deseni, m/z'),
    icon: Icons.bar_chart_rounded,
    color: Palette.violet,
    category: ToolCategory.analysis,
    keywords: 'mass spectrometry kütle spektrometrisi ms hrms exact mass tam kütle monoisotopic monoizotopik isotope izotop pattern desen m/z adduct esi',
    builder: (t) => MassSpecScreen(tool: t),
  ),
  ToolInfo(
    id: 'nmr',
    title: const Bi('NMR Frequencies', 'NMR Frekansları'),
    subtitle: const Bi('Nuclei at any field, ppm ⇄ Hz', 'Her alanda çekirdekler, ppm ⇄ Hz'),
    icon: Icons.graphic_eq_rounded,
    color: Palette.cyan,
    category: ToolCategory.analysis,
    keywords: 'nmr nuclear magnetic resonance nükleer manyetik rezonans larmor frequency frekans ppm hz chemical shift kimyasal kayma spectrometer spektrometre receptivity alıcılık 13c 31p 19f',
    builder: (t) => NmrScreen(tool: t),
  ),
  ToolInfo(
    id: 'units',
    title: const Bi('Unit Converter', 'Birim Çevirici'),
    subtitle: const Bi('Pressure, energy, temperature…', 'Basınç, enerji, sıcaklık…'),
    icon: Icons.swap_horiz_rounded,
    color: Palette.blue,
    category: ToolCategory.reference,
    keywords: 'convert dönüştür çevir unit birim',
    builder: (t) => UnitConverterScreen(tool: t),
  ),
  ToolInfo(
    id: 'constants',
    title: const Bi('Constants', 'Sabitler'),
    subtitle: const Bi('CODATA physical constants', 'CODATA fiziksel sabitleri'),
    icon: Icons.push_pin_rounded,
    color: Palette.brown,
    category: ToolCategory.reference,
    keywords: 'avogadro planck gas constant gaz sabiti faraday boltzmann',
    builder: (t) => ConstantsScreen(tool: t),
  ),
];

/// Pseudo tools used to label history entries from the main tabs.
const calculatorToolId = 'calculator';

ToolInfo? toolById(String id) {
  for (final t in tools) {
    if (t.id == id) return t;
  }
  return null;
}
