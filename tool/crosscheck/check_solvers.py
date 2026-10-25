"""Independent verification of the solver catalogue.

Each equation is written here in its textbook form, as a pair of sides that
must be equal, directly from physical chemistry (not from the Dart code).
Every result dumped by dump_solvers_test.dart is substituted back.

Usage: python3 tool/crosscheck/check_solvers.py tool/crosscheck/out_solvers.json
"""
import json
import math
import sys
from collections import Counter, defaultdict

NA = 6.02214076e23
R = NA * 1.380649e-23    # J/(mol K), exact (SI 2019)
F = NA * 1.602176634e-19  # C/mol, exact
H = 6.62607015e-34
C = 299792458.0
KW = 1e-14
VM = R * 273.15 / 101325 * 1000  # L/mol at 0 °C, 1 atm
ln, log10, exp, sqrt = math.log, math.log10, math.exp, math.sqrt

# (lhs, rhs) of each equation; v holds base-unit values (Pa, L, mol, K, g,
# mol/L, g/mL, g/mol, J/mol, J/(mol K), J/(g K), s, 1/s, V, A, m, …).
EQ = {
    'idealGas': lambda v: (v['P'] * v['V'] / 1000, v['n'] * R * v['T']),
    'combinedGas': lambda v: (v['P1'] * v['V1'] / v['T1'], v['P2'] * v['V2'] / v['T2']),
    'gasDensity': lambda v: (v['d'] * 1e6, v['P'] * v['M'] / (R * v['T'])),
    'dalton': lambda v: (v['Pi'], v['x'] * v['Pt']),
    'graham': lambda v: (v['r1'] / v['r2'], sqrt(v['M2'] / v['M1'])),
    'massMoles': lambda v: (v['n'] * v['M'], v['m']),
    'particles': lambda v: (v['N'], v['n'] * NA),
    'gasStp': lambda v: (v['V'], v['n'] * VM),
    'percentYield': lambda v: (v['y'], v['a'] / v['t'] * 100),
    'prep': lambda v: (v['m'], v['C'] * v['V'] * v['M']),
    'molality': lambda v: (v['b'] * v['ms'] / 1000, v['m'] / v['M']),
    'stock': lambda v: (v['C'] * v['M'], v['w'] / 100 * v['rho'] * 1000),
    'massPercent': lambda v: (v['w'], v['ms'] / v['mt'] * 100),
    'ppm': lambda v: (v['ppm'], v['ms'] / v['mt'] * 1e6),
    'dilution': lambda v: (v['C1'] * v['V1'], v['C2'] * v['V2']),
    'mixing': lambda v: (v['Cf'] * (v['V1'] + v['V2']), v['C1'] * v['V1'] + v['C2'] * v['V2']),
    'phH': lambda v: (v['H'], 10 ** -v['pH']),
    'pohOH': lambda v: (v['OH'], 10 ** -v['pOH']),
    # charge balance [H+] = [A-] + [OH-]
    'strongAcid': lambda v: (10 ** -v['pH'], v['k'] * v['C'] + KW / 10 ** -v['pH']),
    'strongBase': lambda v: (10 ** (v['pH'] - 14), v['k'] * v['C'] + KW / 10 ** (v['pH'] - 14)),
    'weakAcid': lambda v: (v['Ka'] * (v['C'] - 10 ** -v['pH']), (10 ** -v['pH']) ** 2),
    'weakBase': lambda v: (v['Kb'] * (v['C'] - 10 ** (v['pH'] - 14)), (10 ** (v['pH'] - 14)) ** 2),
    'buffer': lambda v: (v['pH'], v['pKa'] + log10(v['A'] / v['HA'])),
    'pKa': lambda v: (v['Ka'], 10 ** -v['pKa']),
    'titration': lambda v: (v['na'] * v['Ca'] * v['Va'], v['nb'] * v['Cb'] * v['Vb']),
    'heat': lambda v: (v['q'], v['m'] * v['c'] * v['dT']),
    'gibbs': lambda v: (v['G'], v['H'] - v['T'] * v['S']),
    'gibbsK': lambda v: (v['G'], -R * v['T'] * ln(v['K'])),
    'clausius': lambda v: (ln(v['P2'] / v['P1']), -v['H'] / R * (1 / v['T2'] - 1 / v['T1'])),
    'vantHoff': lambda v: (ln(v['K2'] / v['K1']), -v['H'] / R * (1 / v['T2'] - 1 / v['T1'])),
    'firstOrder': lambda v: (ln(v['A0'] / v['At']), v['k'] * v['t']),
    'halfLife': lambda v: (v['th'] * v['k'], ln(2)),
    'zeroOrder': lambda v: (v['A0'] - v['At'], v['k'] * v['t']),
    'secondOrder': lambda v: (1 / v['At'] - 1 / v['A0'], v['k'] * v['t']),
    'arrhenius': lambda v: (v['k'], v['A'] * exp(-v['Ea'] / (R * v['T']))),
    'arrhenius2': lambda v: (ln(v['k2'] / v['k1']), -v['Ea'] / R * (1 / v['T2'] - 1 / v['T1'])),
    'nernst': lambda v: (v['E'], v['E0'] - R * v['T'] / (v['n'] * F) * ln(v['Q'])),
    'electrolysis': lambda v: (v['m'] * v['n'] * F, v['I'] * v['t'] * v['M']),
    'gibbsE': lambda v: (v['G'], -v['n'] * F * v['E']),
    'cellK': lambda v: (v['E0'], R * v['T'] / (v['n'] * F) * ln(v['K'])),
    'beer': lambda v: (v['A'], v['eps'] * v['l'] * 100 * v['c']),
    'transmittance': lambda v: (v['A'], -log10(v['T'] / 100)),
    'photon': lambda v: (v['E'] * v['l'], H * C),
    'boiling': lambda v: (v['dT'], v['i'] * v['K'] * v['b']),
    'freezing': lambda v: (v['dT'], v['i'] * v['K'] * v['b']),
    'osmotic': lambda v: (v['pi'], v['i'] * v['M'] * 1000 * R * v['T']),
    'raoult': lambda v: (v['P'], v['x'] * v['P0']),
}

# Derived extras, in the order the app lists them.
EXTRAS = {
    'massMoles': [lambda v: v['n'] * NA],
    'prep': [lambda v: v['C'] * v['V']],
    'stock': [lambda v: (v['w'] / v['M']) / ((100 - v['w']) / 1000)],
    'dilution': [lambda v: v['V2'] - v['V1'], lambda v: v['V2'] / v['V1']],
    'phH': [lambda v: 14 - v['pH'], lambda v: KW / v['H']],
    'pohOH': [lambda v: 14 - v['pOH'], lambda v: KW / v['OH']],
    'weakAcid': [lambda v: 10 ** -v['pH'] / v['C'] * 100, lambda v: -log10(v['Ka'])],
    'weakBase': [lambda v: 10 ** (v['pH'] - 14) / v['C'] * 100, lambda v: 14 - v['pH']],
    'pKa': [lambda v: 14 - v['pKa'], lambda v: KW / v['Ka']],
    'firstOrder': [lambda v: ln(2) / v['k']],
    'zeroOrder': [lambda v: v['A0'] / (2 * v['k'])],
    'secondOrder': [lambda v: 1 / (v['k'] * v['A0'])],
    'electrolysis': [lambda v: v['I'] * v['t']],
    'photon': [lambda v: C / v['l'], lambda v: 1 / (v['l'] * 100), lambda v: v['E'] * NA],
}


def find_root(rec):
    """Scans the target over many decades for a sign change of lhs-rhs that
    is a genuine root (not a pole). Returns the root or None."""
    eq = EQ[rec['eq']]
    def f(x):
        v = dict(rec['inputs']); v[rec['target']] = x
        try:
            a, b = eq(v)
        except (ValueError, ZeroDivisionError, OverflowError):
            return None
        d = a - b
        return d if math.isfinite(d) else None
    grid = [10 ** (e / 4) for e in range(-160, 161)]
    candidates = [x for x in grid] + ([-x for x in grid] if rec.get('targetNeg') else [])
    candidates.sort()
    prev = None
    for x in candidates:
        fx = f(x)
        if fx is None:
            prev = None
            continue
        if fx == 0:
            return x
        if prev is not None and (prev[1] < 0) != (fx < 0):
            lo, hi, flo = prev[0], x, prev[1]
            for _ in range(200):
                mid = (lo + hi) / 2
                fm = f(mid)
                if fm is None:
                    break
                if (fm < 0) == (flo < 0):
                    lo, flo = mid, fm
                else:
                    hi = mid
            v = dict(rec['inputs']); v[rec['target']] = (lo + hi) / 2
            try:
                a, b = eq(v)
            except (ValueError, ZeroDivisionError, OverflowError):
                a, b = 1, 0
            if close(a, b, rel=1e-6):
                return (lo + hi) / 2
        prev = (x, fx)
    return None


def close(a, b, rel=1e-8, absol=1e-12):
    return abs(a - b) <= max(rel * max(abs(a), abs(b)), absol)


def main(path):
    data = json.load(open(path))
    checked = Counter()
    failures = []
    not_ok = Counter()
    total = Counter()
    for rec in data:
        key = (rec['eq'], rec['target'])
        total[key] += 1
        if not rec['ok']:
            not_ok[key] += 1
            root = find_root(rec)
            if root is not None:
                failures.append((key, 'app found no solution but %r satisfies the equation' % root, rec['inputs']))
            continue
        v = dict(rec['inputs'])
        v[rec['target']] = rec['value']
        if rec['value'] == 0:
            # e.g. exp underflow: [A]t = [A]0·e^(−kt) below 1e−308
            checked[key] += 1
            continue
        try:
            lhs, rhs = EQ[rec['eq']](v)
        except (ValueError, ZeroDivisionError, OverflowError) as e:
            failures.append((key, 'python could not evaluate: %s' % e, v))
            continue
        # Log-type equations can lose relative precision; compare on the
        # scale of the larger term.
        scale = max(abs(lhs), abs(rhs), 1e-300)
        if not close(lhs, rhs, rel=1e-7):
            failures.append((key, 'lhs %r != rhs %r (rel %.2e)' % (lhs, rhs, abs(lhs - rhs) / scale), v))
        for i, f in enumerate(EXTRAS.get(rec['eq'], [])):
            got = rec['extras'][i]
            try:
                want = f(v)
            except (ValueError, ZeroDivisionError):
                want = None
            if got is None or want is None:
                if (got is None) != (want is None or not math.isfinite(want)):
                    failures.append((key, 'extra %d: app %r, reference %r' % (i, got, want), v))
                continue
            if not close(got, want, rel=1e-9):
                failures.append((key, 'extra %d: app %r, reference %r' % (i, got, want), v))
        checked[key] += 1

    missing = set(EQ) - {k[0] for k in total}
    print('equations in dump:', len({k[0] for k in total}), 'reference equations:', len(EQ))
    if missing:
        print('reference equations without data:', sorted(missing))
    unknown = {k[0] for k in total} - set(EQ)
    if unknown:
        print('NO REFERENCE for:', sorted(unknown))
    print('checked results:', sum(checked.values()), 'of', sum(total.values()))
    print('targets that never produced a result:', [k for k in total if checked[k] == 0])
    rates = sorted(((not_ok[k] / total[k], k) for k in total if not_ok[k]), reverse=True)[:12]
    print('highest "no solution" rates (random inputs may be outside the domain):')
    for r, k in rates:
        print('   %.0f%%  %s' % (r * 100, k))
    print('FAILURES:', len(failures))
    by = defaultdict(list)
    for k, msg, v in failures:
        by[k].append((msg, v))
    for k, lst in by.items():
        print(k, len(lst), lst[0][0], lst[0][1])
    return 1 if failures or unknown else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
