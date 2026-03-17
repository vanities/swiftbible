"""
SwiftBible — Brand Palette Generator
Generates a visual palette swatch PNG based on the app icon's peridot gradient.

Grounded in Gatena Cookbook behavioural principles:
  - Biophilia Effect → natural peridot green, cyan
  - Halo Effect → icon gradient creates premium first impression
  - Von Restorff Effect → teal accent pops against warm/neutral tones
  - Processing Fluency → 5 core groups, expanded with tints/shades
  - Nostalgia Effect → warm gold/amber evoke timeless craftsmanship
"""

from PIL import Image, ImageDraw, ImageFont

# ── Brand Palette (matches swiftbible/Extensions/Color.swift) ────────

palette = {
    "Icon Gradient (Peridot)": [
        ("#BFD900", "Peridot", "Top-left of icon gradient"),
        ("#33CC66", "Green", "Midpoint of icon gradient"),
        ("#00BFD9", "Cyan", "Bottom-right of icon gradient"),
        ("#00B4A0", "Accent Teal", "Primary accent — interactive elements"),
    ],
    "Warm Tones": [
        ("#D9AD52", "Gold", "Book cover embossing, splash glow"),
        ("#FFEDBA", "Light Gold", "Page glow, verse text accent"),
        ("#D4A050", "Amber", "Devotional warmth, callout accents"),
        ("#CC3333", "Jesus Red", "Jesus's words in red"),
    ],
    "Book Cover": [
        ("#2E1F14", "Cover Dark", "Dark leather cover"),
        ("#473321", "Cover Light", "Light leather cover"),
        ("#8C1F1F", "Ribbon Red", "Bookmark ribbon"),
        ("#0D1226", "Deep Navy", "Launch screen background"),
    ],
    "Accent (Light Mode)": [
        ("#00B4A0", "Accent", "Toggles, links, active tab"),
        ("#33C3B3", "Accent Light", "Hover / highlight states"),
        ("#E6F7F5", "Accent Tint", "Badge backgrounds, subtle fills"),
        ("#007A6D", "Accent Dark", "Pressed states"),
    ],
    "Accent (Dark Mode)": [
        ("#00C8B4", "Accent Dark Mode", "Brighter for contrast on dark"),
        ("#4DD9CC", "Accent Light DM", "Hover / highlight on dark"),
        ("#1A3330", "Accent Surface DM", "Dark mode surface tint"),
        ("#009E8F", "Accent Muted DM", "Secondary accent on dark"),
    ],
    "Marketing Backgrounds": [
        ("#0D1230", "Navy Deep", "Bible / chapters screens"),
        ("#2D140C", "Warm Brown", "Devotional screen"),
        ("#08202E", "Teal Dark", "Study tools screen"),
        ("#1C1020", "Charcoal", "Settings screen"),
    ],
}

# ── Image Generation ─────────────────────────────────────────────────
SWATCH_W = 160
SWATCH_H = 120
PADDING = 24
ROW_GAP = 48
COL_GAP = 16
LABEL_H = 56

cols = max(len(v) for v in palette.values())
rows = len(palette)

img_w = PADDING * 2 + cols * SWATCH_W + (cols - 1) * COL_GAP
img_h = PADDING * 2 + rows * (SWATCH_H + LABEL_H + ROW_GAP) + 140

img = Image.new("RGB", (img_w, img_h), "#FFFFFF")
draw = ImageDraw.Draw(img)

# Try to load a nice font, fall back to default
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

y = PADDING + 60

for group_name, colors in palette.items():
    # Group label
    draw.text((PADDING, y), group_name, fill="#473321", font=font_group)
    y += 28

    for i, (hex_color, name, desc) in enumerate(colors):
        x = PADDING + i * (SWATCH_W + COL_GAP)

        # Swatch with rounded corners
        draw.rounded_rectangle(
            [x, y, x + SWATCH_W, y + SWATCH_H],
            radius=12,
            fill=hex_color,
        )

        # Determine text color for contrast
        r = int(hex_color[1:3], 16)
        g = int(hex_color[3:5], 16)
        b = int(hex_color[5:7], 16)
        luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        text_on_swatch = "#FFFFFF" if luminance < 0.5 else "#0D1226"

        # Hex on swatch
        draw.text(
            (x + 10, y + SWATCH_H - 22),
            hex_color,
            fill=text_on_swatch,
            font=font_hex,
        )

        # Name below swatch
        draw.text((x, y + SWATCH_H + 4), name, fill="#0D1226", font=font_name)
        # Description below name
        draw.text((x, y + SWATCH_H + 20), desc, fill="#473321", font=font_desc)

    y += SWATCH_H + LABEL_H + ROW_GAP

# Save
output_path = "brand-palette.png"
img.save(output_path, "PNG")
print(f"Palette saved to {output_path}")
print(f"Image size: {img_w}x{img_h}")
