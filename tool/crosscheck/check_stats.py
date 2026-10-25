"""Checks lib/core/stats.dart against scipy/numpy.

  pip install scipy numpy
  flutter test tool/crosscheck/dump_stats_test.dart
  python3 tool/crosscheck/check_stats.py tool/crosscheck/out_stats.json
"""
import json
import statistics
import sys

import numpy as np
from scipy import stats


def main(path):
    d = json.load(open(path))
    bad = 0
    for q in d['quantiles']:
        want = stats.t.ppf(q['p'], q['df'])
        if abs(q['t'] - want) > 1e-9 * abs(want):
            bad += 1
            print('t quantile', q, want)
    for g in d['grubbs']:
        n, a = g['n'], 1 - g['level']
        t = stats.t.ppf(1 - a / (2 * n), n - 2)
        want = (n - 1) / np.sqrt(n) * np.sqrt(t * t / (n - 2 + t * t))
        if abs(g['g'] - want) > 1e-9 * want:
            bad += 1
            print('grubbs', g, want)
    for r in d['regressions']:
        x, y = np.array(r['xs']), np.array(r['ys'])
        lr = stats.linregress(x, y)
        checks = {
            'slope': lr.slope, 'intercept': lr.intercept, 'r': lr.rvalue,
            'sSlope': lr.stderr, 'sIntercept': lr.intercept_stderr,
            'syx': np.sqrt(((y - lr.slope * x - lr.intercept) ** 2).sum() / (len(x) - 2)),
            'mean': statistics.fmean(r['ys']), 'sd': statistics.stdev(r['ys']),
            'median': statistics.median(r['ys']),
            'ci95': stats.t.ppf(0.975, len(y) - 1) * statistics.stdev(r['ys']) / np.sqrt(len(y)),
            'x0': (r['y0'] - lr.intercept) / lr.slope,
        }
        for k, want in checks.items():
            if abs(r[k] - want) > 1e-8 * max(1, abs(want)):
                bad += 1
                print('regression', k, r[k], want)
    print('checked %d t quantiles, %d Grubbs values, %d regressions; mismatches %d'
          % (len(d['quantiles']), len(d['grubbs']), len(d['regressions']), bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
