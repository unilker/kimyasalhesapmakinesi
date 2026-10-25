"""Checks lib/core/ice.dart: Q(x) = K is solved again with 300-digit mpmath
bisection on the extent x for 1000 random reactions (K from 1e-30 to 1e30,
some species absent at the start, some pure solids/liquids). Every
equilibrium concentration must agree to 1e-9 relative.

  flutter test tool/crosscheck/dump_ice_test.dart
  python3 tool/crosscheck/check_ice.py tool/crosscheck/out_ice.json
"""
import json
import sys

import mpmath as mp

mp.mp.dps = 300


def solve(r):
    nu = [mp.mpf(v) for v in r['nu']]
    c0 = [mp.mpf(v) for v in r['c0']]
    idx = [i for i, q in enumerate(r['inQ']) if q and nu[i] != 0]
    lo = max([-c0[i] / nu[i] for i in idx if nu[i] > 0], default=None)
    hi = min([c0[i] / -nu[i] for i in idx if nu[i] < 0], default=None)
    if not idx or (lo is not None and hi is not None and lo >= hi):
        return None
    if lo is None:
        lo = hi - 1
        while lnq(nu, c0, idx, lo) > mp.log(r['K']):
            lo = hi - 2 * (hi - lo)
    if hi is None:
        hi = lo + 1
        while lnq(nu, c0, idx, hi) < mp.log(r['K']):
            hi = lo + 2 * (hi - lo)
    lnk = mp.log(mp.mpf(r['K']))
    for _ in range(1100):
        mid = (lo + hi) / 2
        if lnq(nu, c0, idx, mid) > lnk:
            hi = mid
        else:
            lo = mid
    x = (lo + hi) / 2
    return [c0[i] + nu[i] * x if i in idx else c0[i] for i in range(len(nu))]


def lnq(nu, c0, idx, x):
    s = mp.mpf(0)
    for i in idx:
        c = c0[i] + nu[i] * x
        if c <= 0:
            return mp.mpf('-inf') if nu[i] > 0 else mp.mpf('inf')
        s += nu[i] * mp.log(c)
    return s


def main(path):
    data = json.load(open(path))
    bad = solved = 0
    for r in data:
        want = solve(r)
        if want is None or 'error' in r:
            if (want is None) != ('error' in r):
                bad += 1
                print('MISMATCH (solvability)', r)
            continue
        solved += 1
        for got, w in zip(r['eq'], want):
            # Relative accuracy for every species, including remainders of
            # 1e-77 M left by extreme constants.
            scale = abs(w)
            if abs(mp.mpf(got) - w) > 1e-9 * scale:
                bad += 1
                print('MISMATCH', r, [mp.nstr(v, 12) for v in want])
                break
    print('checked %d equilibria (%d solvable); mismatches %d' % (len(data), solved, bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
