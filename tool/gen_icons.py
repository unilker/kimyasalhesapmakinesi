"""Generates the launcher icons (Android, iOS, web) and the in-app logo from
code: a 2 × 2 calculator keypad (+, ×, −) whose fourth key holds an
Erlenmeyer flask, on a deep violet gradient.

Usage: python3 tool/gen_icons.py
"""
import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 1024  # design grid
K = 2  # supersampling for the masters
N = S * K

BG = ((49, 27, 146), (106, 27, 154))  # gradient, 45°
KEYS = [  # centre on the design grid, colour, symbol
    ((282, 282), (124, 77, 255), '+'),
    ((742, 282), (255, 179, 0), '×'),
    ((282, 742), (236, 64, 122), '−'),
    ((742, 742), (0, 191, 165), 'flask'),
]
HALF, RADIUS = 200, 80  # key half-size and corner radius
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)


def gradient(size, c1=BG[0], c2=BG[1]):
    """Diagonal gradient (top-left → bottom-right)."""
    y, x = np.mgrid[0:size, 0:size] / max(size - 1, 1)
    t = (x + y) / 2
    a, b = np.array(c1, float), np.array(c2, float)
    arr = a[None, None, :] * (1 - t[..., None]) + b[None, None, :] * t[..., None]
    return Image.fromarray(arr.astype(np.uint8), 'RGB').convert('RGBA')


class Grid:
    """Maps the 1024 design grid onto a master canvas, scaled about the centre."""

    def __init__(self, scale):
        self.s = scale

    def x(self, v):
        return (S / 2 + (v - S / 2) * self.s) * K

    def l(self, v):
        return v * self.s * K

    def box(self, x1, y1, x2, y2):
        return (self.x(x1), self.x(y1), self.x(x2), self.x(y2))


def draw_op(d, g, kind, cx, cy, s, fill):
    """+, −, × drawn as geometry; s is the half-length on the design grid."""
    w = s * 0.32
    r = w / 2
    if kind in '+−':
        d.rounded_rectangle(g.box(cx - s, cy - r, cx + s, cy + r), radius=g.l(r), fill=fill)
    if kind == '+':
        d.rounded_rectangle(g.box(cx - r, cy - s, cx + r, cy + s), radius=g.l(r), fill=fill)
    if kind == '×':
        e = s * 0.78
        for (x1, y1, x2, y2) in [(cx - e, cy - e, cx + e, cy + e), (cx - e, cy + e, cx + e, cy - e)]:
            d.line([g.x(x1), g.x(y1), g.x(x2), g.x(y2)], fill=fill, width=round(g.l(w)))
            for (px, py) in [(x1, y1), (x2, y2)]:
                d.ellipse(g.box(px - r, py - r, px + r, py + r), fill=fill)


def draw_flask(d, g, cx, cy, fill):
    """Erlenmeyer flask centred in a key."""
    top, h, neck, body = cy - 120, 250, 64, 220
    neck_h = h * 0.38
    pts = [(cx - neck / 2, top), (cx + neck / 2, top), (cx + neck / 2, top + neck_h),
           (cx + body / 2, top + h), (cx - body / 2, top + h), (cx - neck / 2, top + neck_h)]
    d.polygon([(g.x(px), g.x(py)) for px, py in pts], fill=fill)
    ext, rh = neck * 0.14, h * 0.07
    d.rounded_rectangle(g.box(cx - neck / 2 - ext, top - rh * 0.6, cx + neck / 2 + ext, top + rh * 0.9),
                        radius=g.l(rh * 0.6), fill=fill)
    bh = h * 0.12
    d.rounded_rectangle(g.box(cx - body / 2 - bh * 0.15, top + h - bh, cx + body / 2 + bh * 0.15, top + h + bh * 0.35),
                        radius=g.l(bh * 0.6), fill=fill)


def keypad(scale, background=True, shadow=True, mono=False):
    """Master image (N × N). mono: white keys with the symbols cut out."""
    g = Grid(scale)
    img = gradient(N) if background else Image.new('RGBA', (N, N), CLEAR)
    for (cx, cy), colour, sym in KEYS:
        key = Image.new('RGBA', (N, N), CLEAR)
        d = ImageDraw.Draw(key)
        d.rounded_rectangle(g.box(cx - HALF, cy - HALF, cx + HALF, cy + HALF), radius=g.l(RADIUS),
                            fill=WHITE if mono else colour + (255,))
        if shadow and not mono:
            a = key.split()[3].point(lambda v: v * 120 // 255)
            sh = Image.new('RGBA', (N, N), (20, 0, 60, 0))
            sh.putalpha(a)
            sh = sh.transform(sh.size, Image.AFFINE, (1, 0, 0, 0, 1, -g.l(10))).filter(ImageFilter.GaussianBlur(g.l(16)))
            img.alpha_composite(sh)
        # ImageDraw writes pixels directly, so CLEAR punches holes in mono keys
        glyph = CLEAR if mono else WHITE
        if sym == 'flask':
            draw_flask(d, g, cx, cy, glyph)
        else:
            draw_op(d, g, sym, cx, cy, 92, glyph)
        img.alpha_composite(key)
    return img


def rounded(img, radius=0.22):
    """Applies the launcher-style rounded-square mask."""
    n = img.size[0]
    mask = Image.new('L', (n, n), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, n - 1, n - 1], radius=n * radius, fill=255)
    out = img.copy()
    out.putalpha(mask)
    return out


def sized(master, px):
    return master.resize((px, px), Image.LANCZOS)


# Android adaptive icons: 108 dp layers, the launcher shows the inner 72 dp
# and may mask it to a circle (66 dp safe zone), so the keypad (842/1024 of
# the full-bleed icon) is drawn at 0.54 → 44 % of the layer.
ADAPTIVE_SCALE = 0.54
# Web maskable icons: 80 % safe circle.
MASKABLE_SCALE = 0.72


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    full = keypad(1.0)
    fore = keypad(ADAPTIVE_SCALE, background=False)
    mono = keypad(ADAPTIVE_SCALE, background=False, mono=True)
    back = gradient(N)
    maskable = keypad(MASKABLE_SCALE)

    res = os.path.join(root, 'android/app/src/main/res')
    dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, f in dens.items():
        d = os.path.join(res, f'mipmap-{name}')
        os.makedirs(d, exist_ok=True)
        rounded(sized(full, int(48 * f))).save(os.path.join(d, 'ic_launcher.png'))
        n = int(108 * f)
        sized(fore, n).save(os.path.join(d, 'ic_launcher_foreground.png'))
        sized(back, n).convert('RGB').save(os.path.join(d, 'ic_launcher_background.png'))
        sized(mono, n).save(os.path.join(d, 'ic_launcher_monochrome.png'))
    anydpi = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w') as fh:
        fh.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
''')

    # iOS: full-bleed and opaque; the system applies its own mask
    ios = os.path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    for img in json.load(open(os.path.join(ios, 'Contents.json')))['images']:
        px = int(round(float(img['size'].split('x')[0]) * int(img['scale'][0])))
        sized(full, px).convert('RGB').save(os.path.join(ios, img['filename']))

    web = os.path.join(root, 'web')
    for n in (192, 512):
        rounded(sized(full, n)).save(os.path.join(web, f'icons/Icon-{n}.png'))
        sized(maskable, n).save(os.path.join(web, f'icons/Icon-maskable-{n}.png'))
    rounded(sized(full, 32)).save(os.path.join(web, 'favicon.png'))

    rounded(sized(full, 1024)).save(os.path.join(root, 'assets/icon.png'))
    # in-app logo (navigation rail), 48 dp at up to 4x
    rounded(sized(full, 192), radius=0.3).save(os.path.join(root, 'assets/logo.png'))


if __name__ == '__main__':
    main()
