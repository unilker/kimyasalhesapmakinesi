import 'dart:math' as math;

import 'chem/equation.dart';

enum IceErrorKind { unbalanced, noSpecies, noReaction, invalidInput }

class IceException implements Exception {
  const IceException(this.kind);

  final IceErrorKind kind;

  @override
  String toString() => 'IceException($kind)';
}

/// One species of an equilibrium reaction.
class IceSpecies {
  const IceSpecies(this.label, this.nu, {this.inQ = true});

  /// Pretty formula with state symbol.
  final String label;

  /// Signed stoichiometric coefficient: negative for reactants.
  final double nu;

  /// Pure solids and liquids have activity 1 and are left out of Q and K.
  final bool inQ;
}

/// A reaction prepared for an ICE table, with the equation it was read as.
class IceReaction {
  const IceReaction(this.species, this.equation, {required this.autoBalanced});

  final List<IceSpecies> species;

  /// Equation with the coefficients K refers to.
  final String equation;

  /// The input had no coefficients and was balanced automatically.
  final bool autoBalanced;
}

/// Reads [input] like `N2 + 3H2 = 2NH3` or `AgCl(s) = Ag+ + Cl-`. Written
/// coefficients are kept (K depends on them); an equation written without
/// any coefficients is balanced automatically.
IceReaction parseIceReaction(String input) {
  final written = parseWrittenEquation(input);
  List<Species> reactants = written.reactants, products = written.products;
  List<double> coefficients = written.coefficients;
  var auto = false;
  if (!written.isBalanced) {
    if (written.hasCoefficients) throw const IceException(IceErrorKind.unbalanced);
    final balanced = balanceEquation(input);
    reactants = balanced.reactants;
    products = balanced.products;
    coefficients = [for (final c in balanced.coefficients) c.toDouble()];
    auto = true;
  }
  final all = [...reactants, ...products];
  final species = [
    for (var j = 0; j < all.length; j++)
      IceSpecies(
        all[j].pretty,
        j < reactants.length ? -coefficients[j] : coefficients[j],
        inQ: all[j].stateSymbol != 's' && all[j].stateSymbol != 'l',
      ),
  ];
  if (species.every((s) => !s.inQ)) throw const IceException(IceErrorKind.noSpecies);
  String coef(double c) => c == 1 ? '' : (c == c.roundToDouble() ? '${c.toInt()}' : '$c');
  String side(int from, int to) => [
        for (var j = from; j < to; j++) '${coef(coefficients[j])}${all[j].pretty}',
      ].join(' + ');
  final eq = '${side(0, reactants.length)} ⇌ ${side(reactants.length, all.length)}';
  return IceReaction(species, eq, autoBalanced: auto);
}

class IceResult {
  const IceResult({
    required this.extent,
    required this.initial,
    required this.equilibrium,
    required this.q0,
  });

  /// Reaction extent x (concentration units); negative = shifts left.
  final double extent;
  final List<double> initial;
  final List<double> equilibrium;

  /// Reaction quotient of the initial mixture (0 or ∞ when a species is
  /// missing).
  final double q0;
}

/// Solves Q(x) = K for the extent x, with cᵢ = cᵢ⁰ + νᵢ·x for every species
/// in Q. ln Q(x) increases strictly with x between the limits where a
/// product (lower) or a reactant (upper) runs out, so the root is unique.
///
/// The bisection runs on the log of the distance to the nearer limit, and
/// the species that defines that limit is computed from the distance
/// directly: a reactant left at 1e-30 M is resolved to full precision.
IceResult solveIce(List<IceSpecies> species, List<double> initial, double k) {
  if (!(k > 0) || !k.isFinite) throw const IceException(IceErrorKind.invalidInput);
  if (initial.length != species.length ||
      initial.any((c) => !(c >= 0) || !c.isFinite)) {
    throw const IceException(IceErrorKind.invalidInput);
  }
  final idx = [for (var i = 0; i < species.length; i++) if (species[i].inQ && species[i].nu != 0) i];
  if (idx.isEmpty) throw const IceException(IceErrorKind.noSpecies);
  // Limits of x and the species defining them.
  var xLo = double.negativeInfinity, xHi = double.infinity;
  for (final i in idx) {
    final nu = species[i].nu, c = initial[i];
    if (nu > 0 && -c / nu > xLo) {
      xLo = -c / nu;
    } else if (nu < 0 && c / -nu < xHi) {
      xHi = c / -nu;
    }
  }
  if (xLo >= xHi) throw const IceException(IceErrorKind.noReaction);

  final lnK = math.log(k);
  final half = xLo.isFinite && xHi.isFinite ? (xHi - xLo) / 2 : 1.0;
  // Midpoint reference when the range is bounded on one side only.
  final xMid = xLo.isFinite && xHi.isFinite
      ? xLo + half
      : (xLo.isFinite ? xLo + half : xHi - half);

  // Concentrations at the limits; the species that run out there (ties
  // included) are exactly zero.
  List<double> base(double xb) => [
        for (var i = 0; i < species.length; i++)
          () {
            final v = initial[i] + species[i].nu * xb;
            return v.abs() <= 1e-14 * initial[i] ? 0.0 : v;
          }(),
      ];
  final baseLo = xLo.isFinite ? base(xLo) : null;
  final baseHi = xHi.isFinite ? base(xHi) : null;

  // Concentrations for parameter p: p ≤ 0 measures d = x − xLo = half·eᵖ,
  // p > 0 measures d = xHi − x = half·e⁻ᵖ. On an unbounded side x moves
  // away from xMid by half·(e^|p| − 1) instead.
  List<double> concAt(double p) {
    final out = List<double>.of(initial);
    for (final i in idx) {
      final nu = species[i].nu;
      if (p <= 0) {
        out[i] = baseLo != null
            ? baseLo[i] + nu * half * math.exp(p)
            : initial[i] + nu * (xMid - half * (math.exp(-p) - 1));
      } else {
        out[i] = baseHi != null
            ? baseHi[i] - nu * half * math.exp(-p)
            : initial[i] + nu * (xMid + half * (math.exp(p) - 1));
      }
    }
    return out;
  }

  double lnQ(List<double> c) {
    var s = 0.0;
    for (final i in idx) {
      if (c[i] <= 0) return species[i].nu > 0 ? double.negativeInfinity : double.infinity;
      s += species[i].nu * math.log(c[i]);
    }
    return s;
  }

  var lo = -800.0, hi = 800.0;
  for (var it = 0; it < 300; it++) {
    final mid = (lo + hi) / 2;
    if (lnQ(concAt(mid)) > lnK) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  final p = (lo + hi) / 2;
  final eq = concAt(p);
  for (final i in idx) {
    if (eq[i] < 0) eq[i] = 0;
  }
  double extent;
  if (p <= 0 && xLo.isFinite) {
    extent = xLo + half * math.exp(p);
  } else if (p > 0 && xHi.isFinite) {
    extent = xHi - half * math.exp(-p);
  } else {
    extent = p <= 0 ? xMid - half * (math.exp(-p) - 1) : xMid + half * (math.exp(p) - 1);
  }
  return IceResult(
    extent: extent,
    initial: List.unmodifiable(initial),
    equilibrium: List.unmodifiable(eq),
    q0: math.exp(lnQ(initial)),
  );
}
