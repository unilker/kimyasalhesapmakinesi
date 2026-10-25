"""Checks lib/core/titration.dart: the charge balance is solved independently
with scipy.optimize.brentq for 400 random titrations.

  flutter test tool/crosscheck/dump_titration_test.dart
  python3 tool/crosscheck/check_titration.py tool/crosscheck/out_titration.json
"""
import json
import math
import sys

from scipy.optimize import brentq

KW = 1e-14


def ph(r):
    V = r['v'] + r['vt']
    CA = r['c'] * r['v'] / V
    T = r['ct'] * r['vt'] / V
    Na = r['cat'] * CA + (T if r['acid'] else 0)
    Cl = r['an'] * CA + (0 if r['acid'] else T)
    kas = [10 ** -p for p in r['pkas']]

    def F(logh):
        h = 10 ** logh
        s = 0.0
        if kas:
            # log-space species fractions
            lb = [0.0]
            for k in kas:
                lb.append(lb[-1] + math.log10(k) - logh)
            m = max(lb)
            w = [10 ** (x - m) for x in lb]
            s = CA * sum(wj * (r['z0'] - j) for j, wj in enumerate(w)) / sum(w)
        return h + Na - KW / h - Cl + s

    return -brentq(F, -18, 2, xtol=1e-13, rtol=1e-15, maxiter=1000)


def main(path):
    data = json.load(open(path))
    bad = 0
    for r in data:
        want = ph(r)
        if abs(r['pH'] - want) > 1e-7:
            bad += 1
            print('MISMATCH', r, want)
    print('checked %d titration points; mismatches %d' % (len(data), bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
