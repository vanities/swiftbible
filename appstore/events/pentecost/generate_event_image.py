#!/usr/bin/env python3
"""Generate the 1080×1080 In-App Event image for Pentecost.

Apple's IAE image spec: 1080×1080 PNG, original art (no app screenshots,
no Apple trademarks). The image is shown on the product page, in search
results, and in editorial / browse placements.

Visual: a stylized flame on a deep navy background, with subtle gold
"god rays" radiating from above. Pentecost iconography is fire (Acts 2:3
"divided tongues, as it were of fire") — restrained and reverent.

Run:
    uv run --with Pillow python3 generate_event_image.py
Output: pentecost_event.png in this directory.
"""

import math
import os
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZE = 1080
SCRIPT_DIR = Path(__file__).resolve().parent
OUT = SCRIPT_DIR / "pentecost_event.png"

# Brand palette (matches scripts/generate_palette.py)
DEEP_NAVY = (13, 18, 38)
DEEP_NAVY_BR = (32, 22, 14)
GOLD = (217, 173, 82)
GOLD_LIGHT = (255, 237, 186)
RED = (204, 51, 51)
RED_DARK = (140, 31, 31)
ORANGE = (240, 130, 60)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def radial_gradient(size, center, inner, outer, max_radius):
    """Centered radial gradient — inner color at center fading to outer at max_radius."""
    canvas = Image.new("RGB", (size, size), outer)
    px = canvas.load()
    cx, cy = center
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy)
            t = min(1.0, d / max_radius)
            px[x, y] = lerp(inner, outer, t)
    return canvas


def gradient_background():
    """Two-tone background: deep navy with a warm bottom-right hint."""
    img = Image.new("RGB", (SIZE, SIZE), DEEP_NAVY)
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            t = ((x + y) / (2 * SIZE)) * 0.45
            px[x, y] = lerp(DEEP_NAVY, DEEP_NAVY_BR, t)
    return img


def add_god_rays(canvas, color=GOLD, intensity=70):
    """Soft rays from top-center."""
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    cx, cy = SIZE // 2, -SIZE // 4
    for angle_deg in range(-60, 61, 8):
        a = math.radians(angle_deg + 90)
        x2 = cx + int(math.cos(a) * SIZE * 1.4)
        y2 = cy + int(math.sin(a) * SIZE * 1.4)
        alpha = intensity
        d.line([(cx, cy), (x2, y2)], fill=(color[0], color[1], color[2], alpha), width=80)
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=60))
    canvas = canvas.convert("RGBA")
    canvas.alpha_composite(overlay)
    return canvas


def draw_flame(canvas):
    """A stylized flame composed of layered radial gradients."""
    cx, cy = SIZE // 2, int(SIZE * 0.58)

    # Outer halo — wide soft gold
    halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    halo_draw = ImageDraw.Draw(halo)
    for r in range(420, 320, -2):
        alpha = max(0, int(50 * (420 - r) / 100))
        halo_draw.ellipse(
            (cx - r, cy - int(r * 1.1), cx + r, cy + int(r * 0.7)),
            fill=(GOLD[0], GOLD[1], GOLD[2], alpha),
        )
    halo = halo.filter(ImageFilter.GaussianBlur(radius=60))
    canvas.alpha_composite(halo)

    # Middle flame — orange/red, teardrop shape
    flame = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    flame_draw = ImageDraw.Draw(flame)
    for r in range(280, 60, -3):
        t = (280 - r) / 220
        color = lerp(RED_DARK, ORANGE, t)
        alpha = int(160 + 95 * t)
        # Teardrop — narrower top, wider middle, narrower bottom
        rx = int(r * (0.55 + 0.30 * math.sin(math.pi * t)))
        ry = int(r * (1.2 + 0.10 * t))
        flame_draw.ellipse(
            (cx - rx, cy - ry, cx + rx, cy + int(ry * 0.55)),
            fill=(color[0], color[1], color[2], alpha),
        )
    flame = flame.filter(ImageFilter.GaussianBlur(radius=8))
    canvas.alpha_composite(flame)

    # Inner core — bright gold/white
    core = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    core_draw = ImageDraw.Draw(core)
    for r in range(120, 20, -2):
        t = (120 - r) / 100
        color = lerp(GOLD, GOLD_LIGHT, t)
        alpha = int(180 + 70 * t)
        rx = int(r * 0.55)
        ry = int(r * 1.05)
        core_draw.ellipse(
            (cx - rx, cy - ry, cx + rx, cy + int(ry * 0.4)),
            fill=(color[0], color[1], color[2], alpha),
        )
    core = core.filter(ImageFilter.GaussianBlur(radius=4))
    canvas.alpha_composite(core)

    # A few sparks rising from the flame
    sparks = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sparks)
    rng = random.Random(42)
    for _ in range(35):
        x = cx + int(rng.gauss(0, 110))
        y = cy - int(rng.uniform(150, 480))
        r = rng.randint(2, 6)
        a = int(rng.uniform(80, 220))
        sd.ellipse((x - r, y - r, x + r, y + r), fill=(*GOLD_LIGHT, a))
    sparks = sparks.filter(ImageFilter.GaussianBlur(radius=2))
    canvas.alpha_composite(sparks)

    return canvas


def load_font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf" if bold else
        "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf",
    ]
    for c in candidates:
        if os.path.exists(c):
            try:
                return ImageFont.truetype(c, size)
            except Exception:
                continue
    return ImageFont.load_default()


def draw_text(canvas):
    """'Pentecost' wordmark + 'Acts 2' subtitle near the top."""
    title_font = load_font(120, bold=True)
    sub_font = load_font(56, bold=False)

    d = ImageDraw.Draw(canvas)

    title = "Pentecost"
    sub = "Acts 2"

    # Title with subtle drop shadow for legibility on the gradient
    tw = d.textlength(title, font=title_font)
    tx = (SIZE - tw) / 2
    ty = 130

    # Shadow
    for ox, oy, alpha in [(0, 4, 90), (3, 0, 60)]:
        d.text((tx + ox, ty + oy), title, font=title_font, fill=(0, 0, 0, alpha))
    # Gold gradient text — fake it with two passes (gold base, lighter highlight)
    d.text((tx, ty), title, font=title_font, fill=(*GOLD_LIGHT, 255))

    sw = d.textlength(sub, font=sub_font)
    sx = (SIZE - sw) / 2
    sy = ty + 145
    d.text((sx + 2, sy + 2), sub, font=sub_font, fill=(0, 0, 0, 100))
    d.text((sx, sy), sub, font=sub_font, fill=(*GOLD, 230))

    return canvas


def main():
    canvas = gradient_background()
    canvas = add_god_rays(canvas, color=GOLD, intensity=70)
    canvas = draw_flame(canvas)
    canvas = draw_text(canvas)

    canvas = canvas.convert("RGB")
    canvas.save(OUT, "PNG", optimize=True)
    print(f"Saved {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
