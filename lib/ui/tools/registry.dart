import 'package:flutter/material.dart';

import '../../core/bi.dart';
import '../../core/solver_catalog.dart';
import '../theme.dart';
import 'balancer_screen.dart';
import 'constants_screen.dart';
import 'empirical_screen.dart';
import 'molar_mass_screen.dart';
import 'ph_scale.dart';
import 'solver_screen.dart';
import 'unit_converter_screen.dart';

enum ToolCategory { basics, solutions, reactions, physical, reference }

Bi categoryTitle(ToolCategory c) => switch (c) {
      ToolCategory.basics => const Bi('Basics', 'Temel'),
      ToolCategory.solutions => const Bi('Solutions & acids', 'Çözeltiler ve asitler'),
      ToolCategory.reactions => const Bi('Reactions', 'Tepkimeler'),
      ToolCategory.physical => const Bi('Physical chemistry', 'Fizikokimya'),
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
    id: 'gas',
    title: const Bi('Gas Laws', 'Gaz Yasaları'),
    subtitle: const Bi('PV = nRT and more', 'PV = nRT ve fazlası'),
    icon: Icons.air_rounded,
    color: Palette.indigo,
    category: ToolCategory.physical,
    keywords: 'ideal gas ideal gaz boyle charles dalton graham',
    builder: (t) => SolverScreen(tool: t, equations: gasEquations),
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
