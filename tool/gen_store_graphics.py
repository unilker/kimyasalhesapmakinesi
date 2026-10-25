"""Generates the store graphics in docs/store from code:

- play_icon_512.png        Google Play icon (512 × 512, 32-bit PNG; Play
                           applies its own rounded mask)
- feature_graphic_tr.png   Google Play feature graphic (1024 × 500, 24-bit)
- feature_graphic_en.png

Usage: python3 tool/gen_store_graphics.py
"""
import os

from PIL import Image, ImageDraw, ImageFont

from gen_icons import composite, flask_layer, gradient

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = os.path.join(ROOT, 'assets/fonts')

TEXT = {
    'tr': ('Kimya Hesap', 'Makinesi', 'Ücretsiz · Çevrimdışı · Reklamsız',
           ['mol', 'pH', 'ΔG°', 'NMR', 'Ksp', 'E°']),
    'en': ('Chemistry', 'Calculator', 'Free · Offline · No ads',
           ['mol', 'pH', 'ΔG°', 'NMR', 'Ksp', 'E°']),
}


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size)


def feature_graphic(lang):
    w, h = 1024, 500
    k = 2  # supersampling
    img = gradient(256).resize((w * k, h * k), Image.BICUBIC).convert('RGBA')
    # soft white disc behind the flask
    disc = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(disc).ellipse([70 * k, 70 * k, 430 * k, 430 * k], fill=(255, 255, 255, 38))
    img.alpha_composite(disc)
    flask = flask_layer(360 * k, 0.9)
    img.alpha_composite(flask, (70 * k, 70 * k))

    d = ImageDraw.Draw(img)
    title1, title2, tagline, chips = TEXT[lang]
    x = 470 * k
    d.text((x, 92 * k), title1, font=font('Nunito-ExtraBold.ttf', 74 * k), fill='white')
    d.text((x, 172 * k), title2, font=font('Nunito-ExtraBold.ttf', 74 * k), fill='white')
    d.text((x, 270 * k), tagline, font=font('Nunito-Bold.ttf', 30 * k), fill=(255, 255, 255, 230))
    f = font('Nunito-ExtraBold.ttf', 26 * k)
    cx, cy = x, 336 * k
    for label in chips:
        tw = d.textlength(label, font=f)
        box = [cx, cy, cx + tw + 32 * k, cy + 48 * k]
        d.rounded_rectangle(box, radius=24 * k, fill=(255, 255, 255, 235))
        d.text((cx + 16 * k, cy + 7 * k), label, font=f, fill=(106, 76, 255))
        cx = box[2] + 10 * k
    return img.resize((w, h), Image.LANCZOS).convert('RGB')


def main():
    out = os.path.join(ROOT, 'docs/store')
    os.makedirs(out, exist_ok=True)
    composite(512, 0.86).save(os.path.join(out, 'play_icon_512.png'))
    for lang in TEXT:
        feature_graphic(lang).save(os.path.join(out, f'feature_graphic_{lang}.png'))


if __name__ == '__main__':
    main()
