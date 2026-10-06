"""Generates the app icon (variant A): ThinkPad-black tile, white battery, Lenovo-red charge
level stopped by a white threshold marker.

Each size is drawn separately with 4x supersampling; small sizes get a larger battery so it
stays readable in the taskbar and the Start menu.

    uv run --with pillow python assets/make_icon.py
writes src/LenovoBatteryToggle/app.ico and assets/icon-256.png
"""
from pathlib import Path
from PIL import Image, ImageDraw

RED = (226, 35, 26)
DARK = (30, 30, 32)
WHITE = (245, 245, 245)
SIZES = [256, 128, 64, 48, 40, 32, 24, 20, 16]


def draw(n: int) -> Image.Image:
    s = n * 4
    small = n <= 32
    im = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 0, s - 1, s - 1), radius=s * 0.2, fill=DARK)

    # Battery body; wider and taller on small icons
    x0, y0, x1, y1 = (s * 0.10, s * 0.27, s * 0.80, s * 0.73) if small else (s * 0.17, s * 0.33, s * 0.76, s * 0.67)
    line = s * (0.08 if small else 0.055)
    d.rounded_rectangle((x0, y0, x1, y1), radius=s * 0.07, fill=WHITE)
    d.rounded_rectangle((x0 + line, y0 + line, x1 - line, y1 - line), radius=s * 0.035, fill=DARK)
    # Terminal
    t = s * (0.09 if small else 0.07)
    d.rounded_rectangle((x1 + s * 0.015, s * 0.5 - t, x1 + s * (0.085 if small else 0.07), s * 0.5 + t), radius=s * 0.02, fill=WHITE)

    # Charge level at 80% with the threshold marker
    pad = line + s * (0.035 if small else 0.03)
    inner = (x1 - pad) - (x0 + pad)
    level = x0 + pad + inner * 0.8
    d.rounded_rectangle((x0 + pad, y0 + pad, level, y1 - pad), radius=s * 0.02, fill=RED)
    if not small or n >= 24:
        marker = s * (0.035 if small else 0.025)
        gap = s * 0.012
        d.rectangle((level + gap, y0 + pad * 0.6, level + gap + marker, y1 - pad * 0.6), fill=WHITE)

    return im.resize((n, n), Image.LANCZOS)


if __name__ == '__main__':
    root = Path(__file__).resolve().parent.parent
    images = [draw(n) for n in SIZES]
    images[0].save(root / 'src/LenovoBatteryToggle/app.ico', format='ICO',
                   sizes=[(n, n) for n in SIZES], append_images=images[1:])
    images[0].save(root / 'assets/icon-256.png')
    print('written: app.ico (' + ', '.join(map(str, SIZES)) + '), icon-256.png')
