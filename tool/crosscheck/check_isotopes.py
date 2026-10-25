"""Checks lib/core/isotope_pattern.dart for 300 random formulas with an
independent algorithm: the isotopic fine structure (every distinct exact mass)
is built element by element as multinomial distributions, then grouped by
nominal mass. Abundances must agree to 1e-9 relative (peaks above 1e-12) and
mean masses to 1e-7 u; monoisotopic and average masses are checked too.

  flutter test tool/crosscheck/dump_isotopes_test.dart
  python3 tool/crosscheck/check_isotopes.py tool/crosscheck/out_isotopes.json
"""
import json
import math
import sys
from collections import defaultdict

ME = 5.485799090441e-4
ISO = defaultdict(list)
for line in open('tool/data/nist_isotopes.tsv'):
    if line.startswith('#') or not line.strip():
        continue
    _, sym, a, m, c = line.split('\t')
    ISO[sym].append((int(a), float(m), float(c)))


def multinomial(isotopes, n):
    """All compositions of n atoms over the isotopes: {(nominal, mass): p}."""
    out = {}

    def rec(i, left, nominal, mass, logp):
        if i == len(isotopes) - 1:
            a, m, c = isotopes[i]
            if c == 0 and left:
                return
            lp = logp + (left * math.log(c) if left else 0) - math.lgamma(left + 1)
            key = (nominal + left * a, round(mass + left * m, 9))
            out[key] = out.get(key, 0) + math.exp(lp + math.lgamma(n + 1))
            return
        a, m, c = isotopes[i]
        for k in range(left + 1):
            if c == 0 and k:
                break
            rec(i + 1, left - k, nominal + k * a, mass + k * m,
                logp + (k * math.log(c) if k else 0) - math.lgamma(k + 1))

    rec(0, n, 0, 0.0, 0.0)
    return {k: v for k, v in out.items() if v > 1e-40}


def convolve(d1, d2):
    out = {}
    for (n1, m1), p1 in d1.items():
        for (n2, m2), p2 in d2.items():
            p = p1 * p2
            if p < 1e-40:
                continue
            key = (n1 + n2, round(m1 + m2, 9))
            out[key] = out.get(key, 0) + p
    return out


def pattern(atoms, z):
    d = {(0, 0.0): 1.0}
    mono = 0.0
    for el, n in atoms.items():
        iso = ISO[el]
        d = convolve(d, multinomial(iso, n))
        mono += n * max(iso, key=lambda t: t[2])[1]
    peaks = defaultdict(lambda: [0.0, 0.0])
    for (nom, m), p in d.items():
        peaks[nom][0] += p
        peaks[nom][1] += p * m
    tot = sum(v[0] for v in peaks.values())
    mz = (lambda m: m) if z == 0 else (lambda m: (m - z * ME) / abs(z))
    avg = mz(sum(v[1] for v in peaks.values()) / tot)
    return mz(mono), avg, {k: (v[0] / tot, mz(v[1] / v[0])) for k, v in peaks.items()}


def main(path):
    data = json.load(open(path))
    bad = 0
    npeaks = 0
    for r in data:
        mono, avg, want = pattern(r['atoms'], r['z'])
        msgs = []
        if abs(mono - r['mono']) > 1e-7:
            msgs.append('mono %r vs %r' % (r['mono'], mono))
        if abs(avg - r['avg']) > 1e-7:
            msgs.append('avg %r vs %r' % (r['avg'], avg))
        got = {n: (f, m) for n, m, f in r['peaks']}
        for nom, (f, m) in want.items():
            if f < 1e-12:
                continue
            npeaks += 1
            if nom not in got:
                msgs.append('missing peak %d (%g)' % (nom, f))
                continue
            gf, gm = got[nom]
            if abs(gf - f) > 1e-9 * f or abs(gm - m) > 1e-7:
                msgs.append('peak %d: %r %r vs %r %r' % (nom, gf, gm, f, m))
        if msgs:
            bad += 1
            print('MISMATCH', r['atoms'], r['z'], msgs[:3])
    print('checked %d formulas, %d peaks; mismatches %d' % (len(data), npeaks, bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
