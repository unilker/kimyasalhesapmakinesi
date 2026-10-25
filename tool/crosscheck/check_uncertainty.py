"""Checks lib/core/uncertainty.dart: 500 random expressions in four
uncertain variables are re-evaluated with the `uncertainties` package, which
propagates uncertainties linearly using exact derivatives (automatic
differentiation). Values must agree to 1e-12, every sensitivity coefficient
and the combined standard uncertainty to 1e-7 (relative).

  pip install uncertainties
  flutter test tool/crosscheck/dump_uncertainty_test.dart
  python3 tool/crosscheck/check_uncertainty.py tool/crosscheck/out_uncertainty.json
"""
import json
import sys

from uncertainties import ufloat, umath  # noqa: F401  (umath is used by eval)


def close(got, want, rel, abs_=1e-15):
    return abs(got - want) <= max(abs_, rel * abs(want))


def main(path):
    data = json.load(open(path))
    bad = 0
    for r in data:
        env = {n: ufloat(v, u, n) for n, (v, u) in r['vars'].items()}
        env['umath'] = umath
        y = eval(r['py'], {'__builtins__': {}}, env)
        if not hasattr(y, 'nominal_value'):  # expression without variables
            continue
        derivs = {n: y.derivatives.get(env[n], 0.0) for n in r['vars']}
        if any(d != d for d in derivs.values()):
            continue  # singular point (e.g. sqrt(0)); automatic differentiation gives nan
        ok = close(r['value'], y.nominal_value, 1e-12, 1e-12) and close(r['u'], y.std_dev, 1e-7, 1e-12)
        scale = max(abs(d) for d in derivs.values()) or 1
        ok = ok and all(close(r['c'][n], d, 1e-7, 1e-9 * scale) for n, d in derivs.items())
        if not ok:
            bad += 1
            print('MISMATCH', r['expr'], r['value'], r['u'], r['c'], '|', y, derivs)
    print('checked %d propagations; mismatches %d' % (len(data), bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
