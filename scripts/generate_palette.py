"""
SwiftBible — Brand Palette Generator
Generates a visual palette swatch PNG based on the app icon's peridot gradient.

This is the SOURCE OF TRUTH for the brand palette.
Color.swift and marketing scripts should match these values.

Grounded in Gatena Cookbook behavioural principles:
  - Biophilia Effect → natural peridot green, cyan
  - Halo Effect → icon gradient creates premium first impression
  - Von Restorff Effect → teal accent pops against warm/neutral tones
  - Processing Fluency → 4 core groups, clean naming
  - Nostalgia Effect → warm gold evokes timeless craftsmanship
"""

from PIL import Image, ImageDraw, ImageFont

# ── Brand Palette ────────────────────────────────────────────────────
# Naming convention: brand{Color} / brand{Color}{Variant}
# All colors derive from the icon's peridot gradient or complement it.

palette = {
    "Icon Gradient (Peridot)": [
        ("#BFD900", "brandPeridot", "Top-left of icon gradient"),
        ("#33CC66", "brandGreen", "Midpoint of icon gradient"),
        ("#00BFD9", "brandCyan", "Bottom-right of icon gradient"),
    ],
    "Accent (Teal)": [
        ("#00B4A0", "brandAccent", "Primary — toggles, links, active tab"),
        ("#00C8B4", "brandAccentLight", "Dark mode variant (brighter)"),
        ("#007A6D", "brandAccentDark", "Pressed states"),
    ],
    "Warm (Gold)": [
        ("#D9AD52", "brandGold", "Cover embossing, splash glow, warmth"),
        ("#FFEDBA", "brandGoldLight", "Page glow, verse text accent"),
    ],
    "Red": [
        ("#CC3333", "brandRed", "Jesus's words, emphasis, alerts"),
        ("#8C1F1F", "brandRedDark", "Ribbon bookmark, pressed states"),
    ],
    "Surface": [
        ("#0D1226", "brandDeepNavy", "Launch screen, splash background"),
        ("#2E1F14", "brandCoverDark", "Dark leather cover"),
        ("#473321", "brandCoverLight", "Light leather cover"),
    ],
}

# ── Image Generation ─────────────────────────────────────────────────
SWATCH_W = 180
SWATCH_H = 120
PADDING = 28
ROW_GAP = 44
COL_GAP = 18
LABEL_H = 56

cols = max(len(v) for v in palette.values())
rows = len(palette)

img_w = PADDING * 2 + cols * SWATCH_W + (cols - 1) * COL_GAP
img_h = PADDING * 2 + rows * (SWATCH_H + LABEL_H + ROW_GAP) + 120

img = Image.new("RGB", (img_w, img_h), "#FFFFFF")
draw = ImageDraw.Draw(img)

try:
    font_title = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
    font_group = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 18)
    font_name = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 13)
    font_hex = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 11)
    font_desc = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 10)
except OSError:
    font_title = ImageFont.load_default()
    font_group = font_title
    font_name = font_title
    font_hex = font_title
    font_desc = font_title

# Title
draw.text(
    (PADDING, PADDING),
    "SwiftBible — Brand Palette (Peridot)",
    fill="#0D1226",
    font=font_title,
)

y = PADDING + 56

for group_name, colors in palette.items():
    draw.text((PADDING, y), group_name, fill="#473321", font=font_group)
    y += 28

    for i, (hex_color, name, desc) in enumerate(colors):
        x = PADDING + i * (SWATCH_W + COL_GAP)

        draw.rounded_rectangle(
            [x, y, x + SWATCH_W, y + SWATCH_H],
            radius=12,
            fill=hex_color,
        )

        r = int(hex_color[1:3], 16)
        g = int(hex_color[3:5], 16)
        b = int(hex_color[5:7], 16)
        luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        text_on_swatch = "#FFFFFF" if luminance < 0.5 else "#0D1226"

        # Hex on swatch
        draw.text(
            (x + 8, y + SWATCH_H - 22),
            hex_color,
            fill=text_on_swatch,
            font=font_hex,
        )

        # Name + description below
        draw.text((x, y + SWATCH_H + 4), name, fill="#0D1226", font=font_name)
        draw.text((x, y + SWATCH_H + 20), desc, fill="#473321", font=font_desc)

    y += SWATCH_H + LABEL_H + ROW_GAP

output_path = "brand-palette.png"
img.save(output_path, "PNG")
print(f"Palette saved to {output_path}")
print(f"Image size: {img_w}x{img_h}")
