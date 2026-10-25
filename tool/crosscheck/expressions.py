"""Random calculator expressions checked against Python's math library.

  python3 tool/crosscheck/expressions.py gen tool/crosscheck/out_expr_in.json
  flutter test tool/crosscheck/eval_expressions_test.dart
  python3 tool/crosscheck/expressions.py check tool/crosscheck/out_expr_out.json
"""
import json
import math
import random
import sys

FUNCS = {
    # app name: python implementation (degree mode for trig)
    # exact reduction modulo 360° before converting (true value of the
    # trig function of the given double)
    'sin': lambda x: math.sin(math.radians(math.fmod(x, 360))),
    'cos': lambda x: math.cos(math.radians(math.fmod(x, 360))),
    'tan': lambda x: math.tan(math.radians(math.fmod(x, 360))),
    'asin': lambda x: math.degrees(math.asin(x)),
    'acos': lambda x: math.degrees(math.acos(x)),
    'atan': lambda x: math.degrees(math.atan(x)),
    'ln': math.log,
    'log': math.log10,
    'sqrt': math.sqrt,
    'exp': math.exp,
    'abs': abs,
    'sinh': math.sinh,
    'cosh': math.cosh,
    'tanh': math.tanh,
}


def gen(depth, rnd):
    """Returns (app_text, python_value)."""
    if depth == 0 or rnd.random() < 0.25:
        kind = rnd.random()
        if kind < 0.1:
            return 'π', math.pi
        if kind < 0.15:
            return 'e', math.e
        x = round(rnd.uniform(0, 50), rnd.choice([0, 1, 2, 3]))
        text = ('%r' % x).rstrip('0').rstrip('.') if '.' in '%r' % x else '%r' % x
        if rnd.random() < 0.1:
            m = rnd.randint(-5, 5)
            text = '%sE%d' % (text, m)
            x = float(text.replace('E', 'e'))
        return text, float(x)
    r = rnd.random()
    if r < 0.55:
        op = rnd.choice(['+', '−', '×', '÷', '^'])
        a, va = gen(depth - 1, rnd)
        b, vb = gen(depth - 1, rnd)
        if math.isnan(va) or math.isnan(vb):
            return '(%s)%s(%s)' % (a, op, b), float('nan')
        if op == '+':
            v = va + vb
        elif op == '−':
            v = va - vb
        elif op == '×':
            v = va * vb
        elif op == '÷':
            v = va / vb if vb != 0 else float('nan')
        else:
            try:
                v = math.pow(va, vb)
            except (OverflowError, ValueError):
                v = float('nan')
        return '(%s)%s(%s)' % (a, op, b), v
    if r < 0.65:
        a, va = gen(depth - 1, rnd)
        return '−(%s)' % a, -va
    name = rnd.choice(list(FUNCS))
    a, va = gen(depth - 1, rnd)
    if math.isnan(va):
        return '%s(%s)' % (name, a), va
    try:
        v = FUNCS[name](va)
    except (ValueError, OverflowError):
        v = float('nan')
    return '%s(%s)' % (name, a), v


def main():
    mode, path = sys.argv[1], sys.argv[2]
    if mode == 'gen':
        rnd = random.Random(7)
        cases = []
        while len(cases) < 3000:
            t, v = gen(rnd.randint(1, 4), rnd)
            if isinstance(v, complex) or not math.isfinite(v) or abs(v) > 1e250:
                continue
            cases.append({'expr': t, 'want': v})
        json.dump(cases, open(path, 'w'), ensure_ascii=False)
        print('generated', len(cases))
        return 0
    cases = json.load(open(path))
    bad = 0
    for c in cases:
        got, want = c['got'], c['want']
        if got is None:
            bad += 1
            print('ERROR', c['expr'], 'want', want, c.get('error'))
            continue
        # tan near 90°, cancellation in sums etc.: compare relative to the
        # magnitude of the result, with an absolute floor.
        if abs(got - want) > 1e-9 * max(1, abs(want)):
            bad += 1
            print('MISMATCH', c['expr'], 'app', got, 'python', want)
    print('checked', len(cases), 'mismatches', bad)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
