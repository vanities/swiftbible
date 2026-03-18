#!/usr/bin/env python3
"""Generate themed app icon variants for SwiftBible donor perks.

Creates icons with solid/themed backgrounds instead of just hue-shifted gradients.
Uses the dark icon (outline bible) as a mask and composites onto new backgrounds.
"""

from PIL import Image, ImageDraw, ImageFilter
import os
import math

from icon_utils import save_complete_icon

ICON_ASSETS = os.path.join(os.path.dirname(__file__), "..", "icon_assets")

# Source: the light icon (gradient bg + dark bible silhouette)
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
            else:
                t = (x + y) / (2 * size)

            if len(colors) == 2:
                r = int(colors[0][0] + (colors[1][0] - colors[0][0]) * t)
                g = int(colors[0][1] + (colors[1][1] - colors[0][1]) * t)
                b = int(colors[0][2] + (colors[1][2] - colors[0][2]) * t)
            elif len(colors) == 3:
                if t < 0.5:
                    t2 = t * 2
                    r = int(colors[0][0] + (colors[1][0] - colors[0][0]) * t2)
                    g = int(colors[0][1] + (colors[1][1] - colors[0][1]) * t2)
                    b = int(colors[0][2] + (colors[1][2] - colors[0][2]) * t2)
                else:
                    t2 = (t - 0.5) * 2
                    r = int(colors[1][0] + (colors[2][0] - colors[1][0]) * t2)
                    g = int(colors[1][1] + (colors[2][1] - colors[1][1]) * t2)
                    b = int(colors[1][2] + (colors[2][2] - colors[1][2]) * t2)
            else:
                r, g, b = colors[0]

            draw.point((x, y), fill=(r, g, b))

    return img


def extract_bible_mask(light_icon):
    """Extract the bible silhouette as a mask from the light icon.
    The bible is dark on a light gradient background.
    """
    gray = light_icon.convert("L")
    threshold = 80
    mask = gray.point(lambda p: 255 if p < threshold else 0)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=1))
    return mask


def composite_icon(background, bible_mask, bible_color, cross_color, size=1024):
    """Composite the bible silhouette onto a background."""
    result = background.resize((size, size), Image.LANCZOS).convert("RGBA")

    bible_layer = Image.new("RGBA", (size, size), bible_color + (0,))
    bible_alpha = bible_mask.resize((size, size), Image.LANCZOS)
    bible_layer.putalpha(bible_alpha)

    result = Image.alpha_composite(result, bible_layer)
    return result


# ── Theme definitions ──

THEMES = {
    "Classic": {
        "desc": "Rich brown leather with gold cross",
        "bg_colors": [(101, 67, 33), (139, 90, 43), (101, 67, 33)],
        "bg_direction": "radial",
        "bible_color": (240, 225, 200),
        "cross_color": (212, 175, 55),
    },
    "Rose": {
        "desc": "Soft pink to mauve",
        "bg_colors": [(255, 182, 193), (219, 112, 147), (199, 21, 133)],
        "bg_direction": "diagonal",
        "bible_color": (80, 20, 50),
        "cross_color": (255, 220, 230),
    },
    "Midnight": {
        "desc": "Deep navy with silver accents",
        "bg_colors": [(15, 20, 50), (25, 35, 80), (10, 15, 40)],
        "bg_direction": "radial",
        "bible_color": (220, 225, 240),
        "cross_color": (192, 192, 210),
    },
    "Ivory": {
        "desc": "Clean cream with dark accents",
        "bg_colors": [(255, 253, 245), (245, 240, 225), (235, 228, 210)],
        "bg_direction": "vertical",
        "bible_color": (60, 50, 40),
        "cross_color": (60, 50, 40),
    },
    "Ruby": {
        "desc": "Deep crimson — Jesus's words",
        "bg_colors": [(139, 0, 0), (178, 34, 34), (120, 10, 10)],
        "bg_direction": "radial",
        "bible_color": (255, 220, 200),
        "cross_color": (255, 215, 0),
    },
    "Ocean": {
        "desc": "Calm sea blues",
        "bg_colors": [(0, 105, 148), (0, 150, 199), (0, 80, 120)],
        "bg_direction": "diagonal",
        "bible_color": (200, 230, 255),
        "cross_color": (200, 230, 255),
    },
    "Sage": {
        "desc": "Earthy muted green",
        "bg_colors": [(120, 140, 110), (150, 170, 135), (100, 120, 90)],
        "bg_direction": "vertical",
        "bible_color": (40, 50, 35),
        "cross_color": (220, 230, 210),
    },
    "Lavender": {
        "desc": "Soft purple calm",
        "bg_colors": [(180, 160, 210), (200, 180, 230), (150, 130, 190)],
        "bg_direction": "diagonal",
        "bible_color": (60, 40, 80),
        "cross_color": (240, 230, 255),
    },
}


def main():
    print("Loading source icon...")
    light = Image.open(LIGHT_SRC).convert("RGB")
    bible_mask = extract_bible_mask(light)

    for name, theme in THEMES.items():
        print(f"\nGenerating '{name}' — {theme['desc']}")

        bg = create_gradient(1024, theme["bg_colors"], theme["bg_direction"])
        icon = composite_icon(bg, bible_mask, theme["bible_color"], theme["cross_color"])

        save_complete_icon(icon, f"AppIcon-{name}", bible_mask=bible_mask)

    print("\nDone! Generated all themed icon variants.")


if __name__ == "__main__":
    main()
