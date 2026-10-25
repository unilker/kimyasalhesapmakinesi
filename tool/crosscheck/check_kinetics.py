"""Checks lib/core/kinetics_fit.dart: 200 noisy concentration–time data sets
against scipy.stats.linregress on [A], ln[A] and 1/[A], and 200 random
initial-rate designs against numpy.linalg.lstsq on the log-linear model.

  flutter test tool/crosscheck/dump_kinetics_test.dart
  python3 tool/crosscheck/check_kinetics.py tool/crosscheck/out_kinetics.json
"""
import json
import math
import sys

import numpy as np
from scipy import stats


def close(a, b, rel=1e-9, abs_=1e-14):
    return abs(a - b) <= max(abs_, rel * abs(b))


def main(path):
    data = json.load(open(path))
    bad = 0
    for r in data['integrated']:
        t = np.array(r['t'])
        c = np.array(r['c'])
        want = []
        for order, y in enumerate([c, np.log(c), 1 / c]):
            f = stats.linregress(t, y)
            k = f.slope if order == 2 else -f.slope
            if order == 0:
                c0, hl = f.intercept, f.intercept / (2 * k)
            elif order == 1:
                c0, hl = math.exp(f.intercept), math.log(2) / k
            else:
                c0 = 1 / f.intercept
                hl = 1 / (k * c0)
            want.append([k, f.stderr, f.rvalue ** 2, c0, hl])
        best = max(range(3), key=lambda i: want[i][2])
        ok = r['best'] == best and all(
            close(g, w, 1e-8) for gf, wf in zip(r['fits'], want) for g, w in zip(gf, wf))
        if not ok:
            bad += 1
            print('MISMATCH integrated', r['fits'], want)
    for r in data['initial']:
        X = np.column_stack([np.ones(len(r['rates']))] + [np.log([row[i] for row in r['conc']])
                                                          for i in range(len(r['conc'][0]))])
        beta, *_ = np.linalg.lstsq(X, np.log(r['rates']), rcond=None)
        got = [r['logK']] + r['orders']
        if not all(close(g, w, 1e-7, 1e-9) for g, w in zip(got, beta)):
            bad += 1
            print('MISMATCH initial', got, list(beta))
    print('checked %d integrated and %d initial-rate data sets; mismatches %d'
          % (len(data['integrated']), len(data['initial']), bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
