#!/usr/bin/env python3
"""Generate cool/dynamic app icon variants for SwiftBible."""

from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageEnhance, ImageChops
import os
import math
import random

from icon_utils import save_complete_icon

ICON_ASSETS = os.path.join(os.path.dirname(__file__), "..", "icon_assets")
LIGHT_SRC = os.path.join(ICON_ASSETS, "Icon-Light-1024×1024.png")


def create_gradient(size, colors, direction="diagonal"):
    """Create a gradient image."""
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)

    for y in range(size):
        for x in range(size):
            if direction == "diagonal":
                t = (x + y) / (2 * size)
            elif direction == "vertical":
                t = y / size
            elif direction == "horizontal":
                t = x / size
            elif direction == "radial":
                cx, cy = size / 2, size / 2
                dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
                t = min(dist / (size * 0.7), 1.0)
            elif direction == "angular":
                cx, cy = size / 2, size / 2
                angle = math.atan2(y - cy, x - cx)
                t = (angle + math.pi) / (2 * math.pi)
            else:
                t = (x + y) / (2 * size)

            n = len(colors) - 1
            idx = min(int(t * n), n - 1)
            local_t = (t * n) - idx
            c1, c2 = colors[idx], colors[idx + 1]

            r = int(c1[0] + (c2[0] - c1[0]) * local_t)
            g = int(c1[1] + (c2[1] - c1[1]) * local_t)
            b = int(c1[2] + (c2[2] - c1[2]) * local_t)
            draw.point((x, y), fill=(r, g, b))

    return img


def create_noise_overlay(size, intensity=30, seed=42):
    """Create a subtle noise texture."""
    random.seed(seed)
    img = Image.new("RGB", (size, size))
    pixels = img.load()
    for y in range(size):
        for x in range(size):
            v = random.randint(-intensity, intensity)
            pixels[x, y] = (128 + v, 128 + v, 128 + v)
    return img


def extract_bible_mask(light_icon):
    """Extract the bible silhouette as a mask from the light icon."""
    gray = light_icon.convert("L")
    threshold = 80
    mask = gray.point(lambda p: 255 if p < threshold else 0)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=1))
    return mask


def composite_icon(background, bible_mask, bible_color, size=1024):
    """Composite the bible silhouette onto a background."""
    result = background.resize((size, size), Image.LANCZOS).convert("RGBA")
    bible_layer = Image.new("RGBA", (size, size), bible_color + (0,))
    bible_alpha = bible_mask.resize((size, size), Image.LANCZOS)
    bible_layer.putalpha(bible_alpha)
    result = Image.alpha_composite(result, bible_layer)
    return result


THEMES = {
    "Sunset": {
        "desc": "Warm horizon — orange through pink to purple",
        "bg_colors": [(255, 140, 0), (255, 69, 100), (180, 50, 160), (80, 20, 120)],
        "bg_direction": "vertical",
        "bible_color": (40, 10, 30),
    },
    "Aurora": {
        "desc": "Northern lights — green, teal, purple shimmer",
        "bg_colors": [(10, 20, 40), (20, 180, 120), (80, 200, 180), (120, 80, 200), (20, 10, 50)],
        "bg_direction": "vertical",
        "bible_color": (5, 10, 25),
    },
    "Ember": {
        "desc": "Smoldering coals — dark with warm glow",
        "bg_colors": [(20, 8, 5), (60, 15, 5), (180, 60, 10), (60, 15, 5), (20, 8, 5)],
        "bg_direction": "radial",
        "bible_color": (255, 245, 235),
        "invert_mask": True,
        "noise": True,
    },
    "Frost": {
        "desc": "Icy arctic — pale blue to deep blue",
        "bg_colors": [(180, 210, 240), (120, 170, 220), (70, 130, 200), (120, 170, 220), (180, 210, 240)],
        "bg_direction": "radial",
        "bible_color": (245, 250, 255),
    },
    "Neon": {
        "desc": "Electric — hot pink to cyan on black",
        "bg_colors": [(10, 5, 20), (255, 0, 150), (0, 255, 200), (10, 5, 20)],
        "bg_direction": "diagonal",
        "bible_color": (255, 255, 255),
    },
    "Copper": {
        "desc": "Burnished metal — warm metallic sheen",
        "bg_colors": [(140, 80, 45), (200, 130, 70), (230, 170, 100), (200, 130, 70), (140, 80, 45)],
        "bg_direction": "radial",
        "bible_color": (255, 240, 220),
        "noise": True,
    },
    "Storm": {
        "desc": "Thundercloud — dark grays with electric blue",
        "bg_colors": [(30, 30, 40), (50, 55, 70), (40, 80, 140), (50, 55, 70), (30, 30, 40)],
        "bg_direction": "radial",
        "bible_color": (220, 225, 240),
        "noise": True,
    },
    "Blossom": {
        "desc": "Spring cherry blossom — soft pinks and whites",
        "bg_colors": [(255, 230, 235), (255, 180, 200), (255, 150, 180), (255, 180, 200), (255, 230, 235)],
        "bg_direction": "radial",
        "bible_color": (100, 30, 50),
    },
}


def main():
    print("Loading source icon...")
    light = Image.open(LIGHT_SRC).convert("RGB")
    bible_mask = extract_bible_mask(light)

    for name, theme in THEMES.items():
        print(f"\n{name} — {theme['desc']}")
        bg = create_gradient(1024, theme["bg_colors"], theme["bg_direction"])

        if theme.get("noise"):
            noise = create_noise_overlay(1024, intensity=8, seed=hash(name) % 10000)
            bg = ImageChops.multiply(bg, noise)
            bg = ImageEnhance.Brightness(bg).enhance(1.8)

        mask = bible_mask
        if theme.get("invert_mask"):
            mask = ImageOps.invert(mask)

        icon = composite_icon(bg, mask, theme["bible_color"])
        save_complete_icon(icon, f"AppIcon-{name}", bible_mask=bible_mask)

    print("\nDone!")


if __name__ == "__main__":
    main()
