"""Generates the launcher icons (Android, iOS, web) from code.

Usage: python3 tool/gen_icons.py
"""
import json
import os

from PIL import Image, ImageDraw, ImageFilter

S = 1024  # master size


def gradient(size):
    """Diagonal violet → magenta gradient."""
    a, b = (106, 76, 255), (214, 64, 230)
    img = Image.new('RGB', (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
    return img


def flask_layer(size, scale=1.0, color=(255, 255, 255, 255), liquid=True):
    """White Erlenmeyer flask with liquid and bubbles, centred."""
    k = size / S * scale
    off = size * (1 - scale) / 2
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    def p(x, y):
        return (off + x * k, off + y * k)

    # neck + body outline (polygon), rounded by drawing thick lines
    body = [p(430, 230), p(594, 230), p(594, 430), p(800, 760), p(224, 760), p(430, 430)]
    d.polygon(body, fill=color)
    d.rounded_rectangle([p(395, 190), p(629, 250)], radius=28 * k, fill=color)
    # rounded bottom corners
    d.rounded_rectangle([p(210, 700), p(814, 810)], radius=55 * k, fill=color)
    if liquid:
        teal = (0, 191, 165, 255)
        liq = [p(332, 590), p(692, 590), p(782, 735), p(242, 735)]
        d.polygon(liq, fill=teal)
        d.rounded_rectangle([p(236, 690), p(788, 772)], radius=40 * k, fill=teal)
        # bubbles
        for (cx, cy, r) in [(450, 655, 26), (560, 690, 18), (520, 520, 22), (545, 410, 16), (470, 300, 12)]:
            fill = (255, 255, 255, 230) if cy > 590 else (255, 255, 255, 0)
            if cy <= 590:
                d.ellipse([p(cx - r, cy - r), p(cx + r, cy + r)], outline=(106, 76, 255, 255), width=int(8 * k) or 1)
            else:
                d.ellipse([p(cx - r, cy - r), p(cx + r, cy + r)], fill=fill)
    return layer


def composite(size, scale, rounded=False, transparent_bg=False):
    big = size * 4
    if transparent_bg:
        base = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    else:
        base = gradient(256).resize((big, big), Image.BICUBIC).convert('RGBA')
    shadow = flask_layer(big, scale, color=(40, 0, 90, 90), liquid=False)
    shadow = shadow.transform(shadow.size, Image.AFFINE, (1, 0, 0, 0, 1, -big * 0.012))
    shadow = shadow.filter(ImageFilter.GaussianBlur(big * 0.01))
    if not transparent_bg:
        base.alpha_composite(shadow)
    base.alpha_composite(flask_layer(big, scale))
    if rounded:
        mask = Image.new('L', (big, big), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, big - 1, big - 1], radius=big * 0.22, fill=255)
        base.putalpha(mask)
    return base.resize((size, size), Image.LANCZOS)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    res = os.path.join(root, 'android/app/src/main/res')
    dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, f in dens.items():
        d = os.path.join(res, f'mipmap-{name}')
        os.makedirs(d, exist_ok=True)
        composite(int(48 * f), 0.86, rounded=True).save(os.path.join(d, 'ic_launcher.png'))
        n = int(108 * f)
        composite(n, 0.56, transparent_bg=True).save(os.path.join(d, 'ic_launcher_foreground.png'))
        gradient(256).resize((n, n), Image.BICUBIC).save(os.path.join(d, 'ic_launcher_background.png'))
        mono = flask_layer(n * 4, 0.56, liquid=False).resize((n, n), Image.LANCZOS)
        mono.save(os.path.join(d, 'ic_launcher_monochrome.png'))
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

    ios = os.path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    for img in json.load(open(os.path.join(ios, 'Contents.json')))['images']:
        px = int(round(float(img['size'].split('x')[0]) * int(img['scale'][0])))
        composite(px, 0.86).convert('RGB').save(os.path.join(ios, img['filename']))

    web = os.path.join(root, 'web')
    for n in (192, 512):
        composite(n, 0.86, rounded=True).save(os.path.join(web, f'icons/Icon-{n}.png'))
        composite(n, 0.62).save(os.path.join(web, f'icons/Icon-maskable-{n}.png'))
    composite(32, 0.86, rounded=True).save(os.path.join(web, 'favicon.png'))
    composite(1024, 0.86, rounded=True).save(os.path.join(root, 'assets/icon.png'))


if __name__ == '__main__':
    main()
