"""Checks the store texts in docs/STORE_LISTING.md against the store limits.

Each field is written as
    <!-- field: <lang>.<name> max=<n> -->
    text
    <!-- end -->
App Store keywords are also checked against the 100-byte limit, for
duplicates and for words that the name or subtitle already index.

Usage: python3 tool/check_store_listing.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    text = open(os.path.join(ROOT, 'docs/STORE_LISTING.md'), encoding='utf-8').read()
    fields = {}
    errors = []
    for key, limit, body in re.findall(r'<!-- field: (\S+) max=(\d+) -->\n(.*?)\n<!-- end -->', text, re.S):
        fields[key] = body
        n = len(body)
        print(f'{key:16} {n:5} / {limit}')
        if n > int(limit):
            errors.append(f'{key}: {n} characters, limit {limit}')
        if not body.strip():
            errors.append(f'{key}: empty')
    for lang in ('tr', 'en'):
        kw = fields.get(f'{lang}.keywords')
        if kw is None:
            continue
        # App Store Connect counts keyword bytes (UTF-8), not characters
        if len(kw.encode('utf-8')) > 100:
            errors.append(f'{lang}.keywords: {len(kw.encode("utf-8"))} bytes, limit 100')
        words = kw.split(',')
        if len(words) != len(set(words)):
            errors.append(f'{lang}.keywords: duplicates')
        if any(w != w.strip() or not w for w in words):
            errors.append(f'{lang}.keywords: spaces around commas or empty entries')
        indexed = set(re.findall(r'\w+', (fields[f'{lang}.title'] + ' ' + fields[f'{lang}.subtitle']).lower()))
        for w in words:
            if w.lower() in indexed:
                errors.append(f'{lang}.keywords: "{w}" is already in the name or subtitle')
    if errors:
        print('\n'.join(['ERRORS:'] + errors))
        sys.exit(1)
    print('OK')


if __name__ == '__main__':
    main()
