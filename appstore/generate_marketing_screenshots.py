#!/usr/bin/env python3
"""
Generate App Store marketing screenshots from raw simulator captures.

Features:
- Per-screenshot unique color themes with gradient backgrounds
- Ambient gradient orbs (dark glassmorphism)
- Gradient text headlines
- Tilted device presentations
- Light/dark split-screen layout
- Badge overlays
- Drop shadows and rounded corners

Usage:
    python3 generate_marketing_screenshots.py

Output goes to marketing/ subfolders.
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# --- Brand Palette (source of truth: scripts/generate_palette.py) ---
# Icon gradient (peridot)
PERIDOT = (191, 217, 0)       # brandPeridot
GREEN = (51, 204, 102)        # brandGreen
CYAN = (0, 191, 217)          # brandCyan
# Accent (teal)
ACCENT = (0, 180, 160)        # brandAccent
# Warm (gold)
GOLD = (217, 173, 82)         # brandGold
GOLD_LIGHT = (255, 237, 184)  # brandGoldLight
# Red
RED = (204, 51, 51)           # brandRed
RED_DARK = (140, 31, 31)      # brandRedDark
# Surface
DEEP_NAVY = (13, 18, 38)      # brandDeepNavy
COVER_DARK = (46, 31, 20)     # brandCoverDark

# Headline gradient tints (white → brand-tinted)
TINT_TEAL = (180, 240, 230)       # derived from ACCENT
TINT_TEAL_HERO = (180, 240, 220)  # warmer teal for hero headlines
TINT_BLUE = (180, 230, 255)       # derived from CYAN
TINT_RED = (255, 200, 200)        # derived from RED
TINT_GOLD = (255, 230, 160)       # derived from GOLD
TINT_WARM = (255, 220, 170)       # derived from GOLD (warm variant)
TINT_NEUTRAL = (220, 220, 240)    # neutral light
SUBTITLE_COLOR = (180, 180, 200, 230)
SUBTITLE_COLOR_STRIP = (180, 180, 200, 200)

# --- Device Specs ---

DEVICES = {
    "iphone-6.9": {
        "canvas": (1320, 2868),
        "screenshot_scale": 0.75,
        "corner_radius": 55,
    },
    "ipad-13": {
        "canvas": (2048, 2732),
        "screenshot_scale": 0.70,
        "corner_radius": 30,
    },
}

# --- Screenshot Definitions ---
# (filename, headline, subtitle, style, gradient_top, gradient_bottom, orb_color, headline_gradient)

# Slot order follows Sebastian's playbook: lead with most visually impressive +
# differentiating feature. Headlines double as OCR-indexed keyword surface
# (Apple change, Jun 2025) — each one contains a target keyword for that theme.
#
# Appearance mix: dark dominates for visual cohesion / premium feel; slot 2
# (translations) breaks pattern in light mode for contrast and readability of
# the dropdown menu listing "King James / American Standard / World English /
# Original (Hebrew OT / Greek NT)".
SCREENSHOTS = [
    # --- Slot 1: Hook — daily devotional (kw: "daily devotional") ---
    {
        "filename": "06_devotional",
        "appearance": "dark",
        "headline": "Daily Devotional, Every Morning",
        "subtitle": "Verse, context & prayer to start your day",
        "style": "tilt_right",
        "grad_top": (42, 26, 10),       # warm brown (cover dark family)
        "grad_bot": (65, 40, 14),
        "orbs": [(0.6, 0.3, 0.45, GOLD, 45), (0.2, 0.65, 0.35, GOLD, 30)],
        "headline_grad": ((255, 255, 255), TINT_WARM),
    },
    # --- Slot 2: Unique moat (kw: "Hebrew Greek Bible"). LIGHT — pattern
    #     break for contrast, and the dropdown reads more clearly on white. ---
    {
        "filename": "05_translations",
        "appearance": "light",
        "headline": "Hebrew & Greek Bible",
        "subtitle": "KJV, ASV, WEB — switch as you read",
        "style": "split",
        "grad_top": (38, 30, 10),       # warm amber/gold (brand warm family)
        "grad_bot": (60, 48, 16),
        "orbs": [(0.5, 0.3, 0.55, GOLD, 45), (0.15, 0.7, 0.3, GOLD, 25)],
        "headline_grad": ((255, 255, 255), TINT_GOLD),
    },
    # --- Slot 3: Visual standout (kw: "red letter Bible") ---
    {
        "filename": "03_verses",
        "appearance": "dark",
        "headline": "Red Letter Bible",
        "subtitle": "Jesus's words in red, beautifully preserved",
        "style": "tilt_left",
        "grad_top": (45, 12, 18),       # deep warm red (ribbon red family)
        "grad_bot": (72, 20, 30),
        "orbs": [(0.3, 0.35, 0.5, RED_DARK, 45), (0.85, 0.65, 0.3, RED, 30)],
        "headline_grad": ((255, 255, 255), TINT_RED),
    },
    # --- Slot 4: Premium AI signal (kw: "Bible AI explanations") ---
    {
        "filename": "04b_explain",
        "appearance": "dark",
        "headline": "Bible AI Verse Explanations",
        "subtitle": "Apple Intelligence, on device & private",
        "style": "straight",
        "grad_top": (8, 32, 35),        # deep teal (accent family)
        "grad_bot": (14, 55, 58),
        "orbs": [(0.5, 0.3, 0.5, ACCENT, 45), (0.1, 0.7, 0.35, GREEN, 30)],
        "headline_grad": ((255, 255, 255), TINT_TEAL),
    },
    # --- Slot 5: Library depth (kw: "Apocrypha Bible") ---
    {
        "filename": "01_bible_books",
        "appearance": "dark",
        "headline": "Apocrypha & Enoch Included",
        "subtitle": "Jubilees, Clement, Didache — all public domain",
        "style": "straight",
        "grad_top": (13, 18, 45),       # deep navy tint
        "grad_bot": (20, 30, 65),
        "orbs": [(0.2, 0.3, 0.5, ACCENT, 50), (0.8, 0.7, 0.4, CYAN, 35)],
        "headline_grad": ((255, 255, 255), TINT_TEAL),
    },
    # --- Slot 6: Study-tool signal (kw: "chapter summary") ---
    {
        "filename": "02_chapters",
        "appearance": "dark",
        "headline": "Summary on Every Chapter",
        "subtitle": "Know the gist before you read",
        "style": "tilt_right",
        "grad_top": (8, 22, 48),        # deep blue (navy family)
        "grad_bot": (14, 38, 72),
        "orbs": [(0.7, 0.25, 0.45, CYAN, 45), (0.15, 0.6, 0.35, GREEN, 30)],
        "headline_grad": ((255, 255, 255), TINT_BLUE),
    },
    # --- Slot 7: Close — bookmarks/highlights/notes (kw: "Bible notes") ---
    {
        "filename": "07_more",
        "headline": "Bible Notes & Bookmarks",
        "subtitle": "Highlights, stats & history in one place",
        "style": "straight",
        "grad_top": (16, 18, 30),       # dark navy (deep navy family)
        "grad_bot": (28, 32, 48),
        "orbs": [(0.3, 0.35, 0.4, ACCENT, 35), (0.75, 0.6, 0.3, CYAN, 25)],
        "headline_grad": ((255, 255, 255), TINT_TEAL),
    },
]

# --- Panoramic Pairs (continuous background split across two frames) ---

PANORAMIC_PAIRS = [
    {
        "left_filename": "02_chapters",
        "right_filename": "03_verses",
        "left_headline": "Every Chapter, Summarized",      # Competence Signalling (#95)
        "left_subtitle": "Know what you're reading before you start",
        "right_headline": "Jesus's Words in Red",           # Von Restorff (#1)
        "right_subtitle": "The tradition, beautifully preserved",
        "left_angle": 5,
        "right_angle": -5,
        "grad_tl": (8, 22, 48),
        "grad_tr": (45, 12, 18),
        "grad_bl": (14, 38, 72),
        "grad_br": (72, 20, 30),
        "orbs": [
            (0.15, 0.3, 0.22, CYAN, 50),
            (0.5, 0.45, 0.28, ACCENT, 55),
            (0.85, 0.35, 0.22, RED_DARK, 50),
            (0.35, 0.7, 0.18, GREEN, 30),
            (0.65, 0.65, 0.18, RED, 30),
        ],
        "left_headline_grad": ((255, 255, 255), TINT_BLUE),
        "right_headline_grad": ((255, 255, 255), TINT_RED),
    },
    {
        "left_filename": "06_devotional",
        "right_filename": "07_more",
        "left_headline": "A New Word, Every Morning",
        "left_subtitle": "Daily devotional with verse, context & prayer",
        "right_headline": "Your Library, At a Glance",
        "right_subtitle": "Bookmarks, stats & history in one place",
        "left_angle": 5,
        "right_angle": -5,
        "grad_tl": (42, 26, 10),
        "grad_tr": (16, 18, 30),
        "grad_bl": (65, 40, 14),
        "grad_br": (28, 32, 48),
        "orbs": [
            (0.2, 0.3, 0.22, GOLD, 50),
            (0.5, 0.4, 0.25, GOLD, 45),
            (0.8, 0.35, 0.22, ACCENT, 40),
            (0.35, 0.65, 0.16, GOLD, 28),
            (0.7, 0.7, 0.16, CYAN, 25),
        ],
        "left_headline_grad": ((255, 255, 255), TINT_WARM),
        "right_headline_grad": ((255, 255, 255), TINT_TEAL),
    },
]

# --- Panoramic Strip (one continuous canvas sliced into frames) ---
# Devices are centered on the cut lines between frames, so each device
# is split 50/50 across two adjacent screenshots. Headlines straddle too.

PANORAMIC_STRIP = {
    "screenshots": [
        {"filename": "06_devotional", "headline": "A New Word, Every Morning",
         "subtitle": "Daily devotional with verse, context & prayer"},
        {"filename": "05_translations", "headline": "Hebrew, Greek & English",
         "subtitle": "Four translations, switch as you read"},
        {"filename": "03_verses", "headline": "Jesus's Words in Red",
         "subtitle": "The tradition, beautifully preserved"},
        {"filename": "04b_explain", "headline": "Understand Any Verse",
         "subtitle": "AI-powered explanations on device"},
        {"filename": "01_bible_books", "headline": "Apocrypha, Enoch & Beyond",
         "subtitle": "Eight extra collections, all public domain"},
        # Dark mode device — no headline; visual contrast speaks for itself
        {"filename": "05_translations_dark", "headline": "", "subtitle": ""},
        {"filename": "02_chapters", "headline": "Know Before You Read",
         "subtitle": "Plain-English summary at every chapter"},
        {"filename": "07_more", "headline": "Your Library, At a Glance",
         "subtitle": "Bookmarks, stats & history in one place"},
        {"filename": "01_bible_books_dark", "headline": "Read Anytime",
         "subtitle": "Beautiful in every light"},
    ],
    "intro_headline": "SwiftBible",
    "intro_subtitle": "Open Source Bible App",
    "outro_headline": "Get Started",
    "outro_subtitle": "Available on the App Store",
    # Horizontal color flow: deep navy (left) → warm amber (right)
    "grad_tl": (13, 18, 45),
    "grad_tr": (42, 26, 10),
    "grad_bl": (20, 30, 65),
    "grad_br": (60, 38, 12),
    "orbs": [
        (0.05, 0.30, 0.06, CYAN, 55),
        (0.15, 0.55, 0.05, GREEN, 40),
        (0.25, 0.35, 0.06, RED_DARK, 45),
        (0.35, 0.50, 0.07, ACCENT, 50),
        (0.45, 0.40, 0.06, ACCENT, 45),
        (0.55, 0.55, 0.06, GREEN, 42),
        (0.65, 0.35, 0.06, GOLD, 40),
        (0.75, 0.50, 0.07, GOLD, 45),
        (0.85, 0.40, 0.06, GOLD, 38),
        (0.95, 0.35, 0.06, ACCENT, 35),
    ],
}


# --- Drawing Helpers ---


def create_gradient(width, height, top_color, bottom_color):
    """Create a vertical gradient image."""
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        ratio = y / height
        r = int(top_color[0] + (bottom_color[0] - top_color[0]) * ratio)
        g = int(top_color[1] + (bottom_color[1] - top_color[1]) * ratio)
        b = int(top_color[2] + (bottom_color[2] - top_color[2]) * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    return img


def create_bilinear_gradient(width, height, tl, tr, bl, br):
    """Create a 2D gradient from four corner colors (fast upscale method)."""
    small = Image.new("RGB", (2, 2))
    small.putpixel((0, 0), tl)
    small.putpixel((1, 0), tr)
    small.putpixel((0, 1), bl)
    small.putpixel((1, 1), br)
    return small.resize((width, height), Image.BILINEAR)


def add_ambient_orbs(canvas, orbs_config, canvas_w, canvas_h):
    """Add soft glowing orbs for glassmorphism depth effect."""
    overlay = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    for (cx_pct, cy_pct, r_pct, color, alpha) in orbs_config:
        cx = int(canvas_w * cx_pct)
        cy = int(canvas_h * cy_pct)
        radius = int(min(canvas_w, canvas_h) * r_pct)
        draw.ellipse(
            [cx - radius, cy - radius, cx + radius, cy + radius],
            fill=(*color, alpha),
        )

    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=130))
    return Image.alpha_composite(canvas, overlay)


def round_corners(img, radius):
    """Apply rounded corners to an image."""
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), img.size], radius=radius, fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def create_shadow(size, radius, blur_radius=30, offset=(0, 15), opacity=100):
    """Create a drop shadow."""
    pad = blur_radius * 3
    shadow_size = (size[0] + pad * 2, size[1] + pad * 2)
    shadow = Image.new("RGBA", shadow_size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.rounded_rectangle(
        [pad, pad, pad + size[0], pad + size[1]],
        radius=radius,
        fill=(0, 0, 0, opacity),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur_radius))
    return shadow, (pad - offset[0], pad - offset[1])


def load_font(size, bold=False):
    """Load SF Pro Display font."""
    if bold:
        paths = [
            "/Library/Fonts/SF-Pro-Display-Bold.otf",
            "/Library/Fonts/SF-Pro-Display-Semibold.otf",
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        ]
    else:
        paths = [
            "/Library/Fonts/SF-Pro-Display-Medium.otf",
            "/Library/Fonts/SF-Pro-Display-Regular.otf",
            "/System/Library/Fonts/Supplemental/Arial.ttf",
        ]
    for p in paths:
        try:
            return ImageFont.truetype(p, size)
        except (OSError, IOError):
            continue
    return ImageFont.load_default()


def draw_gradient_text(canvas, text, y, font, color_top, color_bottom, canvas_w, glow_color=None):
    """Draw headline text with a vertical gradient fill and optional glow."""
    # Get text dimensions
    tmp_draw = ImageDraw.Draw(canvas)
    bbox = tmp_draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (canvas_w - text_w) // 2

    # Optional glow: soft colored bloom behind the text
    if glow_color:
        glow_pad = 60
        glow_layer = Image.new("RGBA", (canvas_w, text_h + glow_pad * 2), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow_layer)
        glow_draw.text((x, glow_pad - bbox[1]), text, font=font,
                        fill=(*glow_color, 120))
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=35))
        canvas.paste(glow_layer, (0, y - glow_pad), glow_layer)

    # Create gradient strip for the text area
    grad = Image.new("RGBA", (canvas_w, text_h + 40), (0, 0, 0, 0))
    for row in range(text_h + 40):
        ratio = row / (text_h + 40)
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * ratio)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * ratio)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * ratio)
        ImageDraw.Draw(grad).line([(0, row), (canvas_w, row)], fill=(r, g, b, 255))

    # Create text mask
    text_mask = Image.new("L", (canvas_w, text_h + 40), 0)
    mask_draw = ImageDraw.Draw(text_mask)
    mask_draw.text((x, -bbox[1]), text, font=font, fill=255)

    # Apply mask to gradient
    grad.putalpha(text_mask)

    # Composite onto canvas at y position
    canvas.paste(grad, (0, y), grad)
    return text_h


def add_device_edge_glow(canvas, x, y, width, height, corner_r, glow_color, intensity=80):
    """Add a colored glow radiating from device edges."""
    glow_pad = 40
    glow = Image.new("RGBA", (width + glow_pad * 2, height + glow_pad * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    draw.rounded_rectangle(
        [glow_pad, glow_pad, glow_pad + width, glow_pad + height],
        radius=corner_r,
        outline=(*glow_color, intensity),
        width=8,
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=25))
    canvas.paste(glow, (x - glow_pad, y - glow_pad), glow)


# --- Togglable Visual Effects ---
# All effects are keyed by name in frame configs.
# Example: {"bokeh": CYAN, "grain": True, "vignette": True, "god_rays": GOLD, ...}


def add_bokeh(canvas, canvas_w, canvas_h, count=12, color=None, seed=42):
    """Soft out-of-focus light circles for depth."""
    import random
    rng = random.Random(seed)
    overlay = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for _ in range(count):
        cx = rng.randint(0, canvas_w)
        cy = rng.randint(0, canvas_h)
        radius = rng.randint(8, 45)
        alpha = rng.randint(12, 35)
        c = color if color else (255, 255, 255)
        draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=(*c, alpha))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=8))
    return Image.alpha_composite(canvas, overlay)


def add_film_grain(canvas, canvas_w, canvas_h, intensity=8):
    """Subtle noise texture for a premium analog feel."""
    import random
    grain = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    pixels = grain.load()
    rng = random.Random(99)
    for y in range(0, canvas_h, 3):
        for x in range(0, canvas_w, 3):
            v = rng.randint(-intensity, intensity)
            if v > 0:
                pixels[x, y] = (255, 255, 255, v)
            else:
                pixels[x, y] = (0, 0, 0, -v)
    grain = grain.filter(ImageFilter.GaussianBlur(radius=1))
    return Image.alpha_composite(canvas, grain)


def add_vignette(canvas, canvas_w, canvas_h, strength=0.4):
    """Darken corners to draw focus toward the center."""
    vignette = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(vignette)
    cx, cy = canvas_w // 2, canvas_h // 2
    max_dist = math.sqrt(cx ** 2 + cy ** 2)
    for ring in range(0, int(max_dist), 4):
        ratio = ring / max_dist
        if ratio < (1.0 - strength):
            continue
        alpha = int(((ratio - (1.0 - strength)) / strength) * 80)
        draw.ellipse([cx - ring, cy - ring, cx + ring, cy + ring], outline=(0, 0, 0, alpha), width=5)
    vignette = vignette.filter(ImageFilter.GaussianBlur(radius=60))
    return Image.alpha_composite(canvas, vignette)


def add_god_rays(canvas, canvas_w, canvas_h, color, corner="top_right", intensity=40):
    """Diagonal light beams radiating from a corner."""
    import random
    rng = random.Random(77)
    overlay = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    corners = {
        "top_left": (0, 0),
        "top_right": (canvas_w, 0),
        "bottom_left": (0, canvas_h),
        "bottom_right": (canvas_w, canvas_h),
    }
    ox, oy = corners.get(corner, (canvas_w, 0))

    for _ in range(12):
        angle = rng.uniform(-0.6, 0.6)
        length = int(max(canvas_w, canvas_h) * rng.uniform(0.8, 1.4))
        width = rng.randint(20, 80)
        alpha = rng.randint(intensity // 3, intensity)

        ex = ox + int(math.cos(math.atan2(canvas_h / 2 - oy, canvas_w / 2 - ox) + angle) * length)
        ey = oy + int(math.sin(math.atan2(canvas_h / 2 - oy, canvas_w / 2 - ox) + angle) * length)

        draw.line([(ox, oy), (ex, ey)], fill=(*color, alpha), width=width)

    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=50))
    return Image.alpha_composite(canvas, overlay)


def add_light_leak(canvas, canvas_w, canvas_h, color, corner="top_right", size=0.4):
    """Warm gradient bleeding from a corner — like sun hitting a lens."""
    overlay = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    corners = {
        "top_left": (0, 0),
        "top_right": (canvas_w, 0),
        "bottom_left": (0, canvas_h),
        "bottom_right": (canvas_w, canvas_h),
    }
    ox, oy = corners.get(corner, (canvas_w, 0))
    radius = int(min(canvas_w, canvas_h) * size)

    for r in range(radius, 0, -3):
        ratio = r / radius
        alpha = int((1.0 - ratio) * 50)
        draw.ellipse([ox - r, oy - r, ox + r, oy + r], fill=(*color, alpha))

    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=80))
    return Image.alpha_composite(canvas, overlay)


def add_shimmer(canvas, text, y, font, canvas_w, angle=-30):
    """Diagonal metallic shine streak across headline text."""
    tmp_draw = ImageDraw.Draw(canvas)
    bbox = tmp_draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (canvas_w - text_w) // 2

    # Create text-shaped mask
    text_mask = Image.new("L", (canvas_w, text_h + 40), 0)
    ImageDraw.Draw(text_mask).text((x, -bbox[1]), text, font=font, fill=255)

    # Create diagonal white streak
    streak = Image.new("RGBA", (canvas_w, text_h + 40), (0, 0, 0, 0))
    streak_draw = ImageDraw.Draw(streak)
    # Draw a wide diagonal band
    cx = canvas_w // 2
    for offset in range(-40, 40):
        alpha = max(0, 25 - abs(offset))
        streak_draw.line(
            [(cx + offset - 200, 0), (cx + offset + 200, text_h + 40)],
            fill=(255, 255, 255, alpha), width=1,
        )

    streak = streak.rotate(angle, expand=False, center=(canvas_w // 2, (text_h + 40) // 2))
    streak.putalpha(text_mask)
    canvas.paste(streak, (0, y), streak)


def add_accent_line(canvas, y, canvas_w, color, width_pct=0.3):
    """Thin horizontal gradient accent line — a separator flourish."""
    line_w = int(canvas_w * width_pct)
    line_x = (canvas_w - line_w) // 2
    overlay = Image.new("RGBA", (canvas_w, 6), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for px in range(line_w):
        ratio = px / line_w
        # Fade in from left, fade out to right
        fade = min(ratio * 4, (1.0 - ratio) * 4, 1.0)
        alpha = int(fade * 120)
        draw.line([(line_x + px, 1), (line_x + px, 4)], fill=(*color, alpha))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=2))
    canvas.paste(overlay, (0, y), overlay)


def add_app_icon_badge(canvas, canvas_w, icon_path, y=None, size=80):
    """Float the app icon as a small badge, centered above headline."""
    if not os.path.exists(icon_path):
        return
    icon = Image.open(icon_path).convert("RGBA")
    icon = icon.resize((size, size), Image.LANCZOS)
    icon = round_corners(icon, size // 4)
    ix = (canvas_w - size) // 2
    iy = y if y is not None else 20
    # Subtle shadow
    shadow = Image.new("RGBA", (size + 20, size + 20), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [10, 10, size + 10, size + 10], radius=size // 4, fill=(0, 0, 0, 60)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=8))
    canvas.paste(shadow, (ix - 10, iy - 6), shadow)
    canvas.paste(icon, (ix, iy), icon)
    return iy + size + 10  # return bottom y for text positioning


def add_color_grade(canvas, canvas_w, canvas_h, warmth=0.1):
    """Shift the entire frame warm (positive) or cool (negative)."""
    overlay = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    if warmth > 0:
        # Warm: add orange tint
        color = (255, 180, 80, int(warmth * 40))
    else:
        # Cool: add blue tint
        color = (80, 160, 255, int(abs(warmth) * 40))
    ImageDraw.Draw(overlay).rectangle([(0, 0), (canvas_w, canvas_h)], fill=color)
    return Image.alpha_composite(canvas, overlay)


def add_bloom(canvas, canvas_w, canvas_h, intensity=0.15):
    """Soft glow on bright areas — dreamy highlight bloom."""
    # Extract bright areas, blur them, blend back
    bright = canvas.convert("RGB")
    bright = Image.eval(bright, lambda x: x if x > 180 else 0)
    bright = bright.filter(ImageFilter.GaussianBlur(radius=40))
    bright = bright.convert("RGBA")
    # Reduce opacity
    bright_data = bright.split()
    alpha = Image.eval(bright_data[0], lambda x: int(x * intensity))
    bright.putalpha(alpha)
    return Image.alpha_composite(canvas, bright)


def draw_text_centered(canvas, text, y, font, fill, canvas_w):
    """Draw centered text with optional glow."""
    draw = ImageDraw.Draw(canvas)
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    x = (canvas_w - text_w) // 2
    draw.text((x, y), text, font=font, fill=fill)
    return bbox[3] - bbox[1]


def draw_gradient_text_at(canvas, text, center_x, y, font, color_top, color_bottom):
    """Draw gradient text centered at a specific x position on a wide canvas."""
    tmp_draw = ImageDraw.Draw(canvas)
    bbox = tmp_draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = center_x - text_w // 2

    full_w = canvas.size[0]

    grad = Image.new("RGBA", (full_w, text_h + 40), (0, 0, 0, 0))
    for row in range(text_h + 40):
        ratio = row / (text_h + 40)
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * ratio)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * ratio)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * ratio)
        ImageDraw.Draw(grad).line([(0, row), (full_w, row)], fill=(r, g, b, 255))

    text_mask = Image.new("L", (full_w, text_h + 40), 0)
    mask_draw = ImageDraw.Draw(text_mask)
    mask_draw.text((x, -bbox[1]), text, font=font, fill=255)

    grad.putalpha(text_mask)
    canvas.paste(grad, (0, y), grad)
    return text_h


def draw_text_at(canvas, text, center_x, y, font, fill):
    """Draw text centered at a specific x position."""
    draw = ImageDraw.Draw(canvas)
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    x = center_x - text_w // 2
    draw.text((x, y), text, font=font, fill=fill)
    return bbox[3] - bbox[1]


def place_device_at(canvas, raw, center_x, y, scale, corner_r, ref_width, angle=0):
    """Place a device screenshot centered at a specific x position with optional tilt."""
    scaled = scale_screenshot(raw, ref_width, scale)
    rounded = round_corners(scaled, corner_r)

    if angle != 0:
        rotated = rounded.rotate(
            angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0)
        )
        shadow_base = Image.new("RGBA", scaled.size, (0, 0, 0, 110))
        shadow_base = round_corners(shadow_base, corner_r)
        shadow_rot = shadow_base.rotate(
            angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0)
        )
        shadow_rot = shadow_rot.filter(ImageFilter.GaussianBlur(30))

        sx = center_x - rotated.size[0] // 2
        canvas.paste(shadow_rot, (sx + 8, y + 16), shadow_rot)
        canvas.paste(rotated, (sx, y), rotated)
    else:
        sx = center_x - rounded.size[0] // 2
        shadow, s_offset = create_shadow(
            scaled.size, corner_r, blur_radius=28, offset=(0, 14), opacity=110
        )
        canvas.paste(shadow, (sx - s_offset[0], y - s_offset[1]), shadow)
        canvas.paste(rounded, (sx, y), rounded)


def draw_badge_row(canvas, badges, y, canvas_w):
    """Draw a row of pill badges."""
    badge_font = load_font(32, bold=True)
    draw = ImageDraw.Draw(canvas)

    # Measure total width
    pad_h, pad_v, gap = 24, 12, 16
    total_w = 0
    badge_sizes = []
    for text in badges:
        bbox = draw.textbbox((0, 0), text, font=badge_font)
        w = bbox[2] - bbox[0] + pad_h * 2
        h = bbox[3] - bbox[1] + pad_v * 2
        badge_sizes.append((w, h, text))
        total_w += w + gap
    total_w -= gap  # remove trailing gap

    x = (canvas_w - total_w) // 2
    for w, h, text in badge_sizes:
        draw.rounded_rectangle(
            [x, y, x + w, y + h],
            radius=h // 2,
            fill=(255, 255, 255, 30),
        )
        bbox = draw.textbbox((0, 0), text, font=badge_font)
        tx = x + (w - (bbox[2] - bbox[0])) // 2
        ty = y + (h - (bbox[3] - bbox[1])) // 2
        draw.text((tx, ty), text, font=badge_font, fill=(255, 255, 255, 200))
        x += w + gap


def scale_screenshot(raw, canvas_w, scale):
    """Scale a raw screenshot proportionally."""
    scaled_w = int(canvas_w * scale)
    scaled_h = int(raw.size[1] * (scaled_w / raw.size[0]))
    return raw.resize((scaled_w, scaled_h), Image.LANCZOS)


def paste_with_shadow(canvas, img, x, y, corner_r, shadow_blur=28, shadow_opacity=110):
    """Paste a rounded screenshot with drop shadow onto canvas."""
    rounded = round_corners(img, corner_r)
    shadow, s_offset = create_shadow(
        img.size, corner_r, blur_radius=shadow_blur, offset=(0, 14), opacity=shadow_opacity
    )
    canvas.paste(shadow, (x - s_offset[0], y - s_offset[1]), shadow)
    canvas.paste(rounded, (x, y), rounded)


# --- Layout Styles ---


def layout_straight(canvas, raw, config, canvas_w, canvas_h, corner_r, text_bottom):
    """Standard centered screenshot below text."""
    scale = config["screenshot_scale"]
    scaled = scale_screenshot(raw, canvas_w, scale)
    screenshot_y = text_bottom + int(canvas_h * 0.025)
    screenshot_x = (canvas_w - scaled.size[0]) // 2
    paste_with_shadow(canvas, scaled, screenshot_x, screenshot_y, corner_r)


def layout_tilted(canvas, raw, config, canvas_w, canvas_h, corner_r, text_bottom, angle):
    """Tilted/angled screenshot presentation."""
    scale = config["screenshot_scale"] * 0.92  # slightly smaller to fit rotation
    scaled = scale_screenshot(raw, canvas_w, scale)
    rounded = round_corners(scaled, corner_r)

    # Rotate with transparent background
    rotated = rounded.rotate(angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))

    # Create shadow for rotated version
    shadow_base = Image.new("RGBA", scaled.size, (0, 0, 0, 110))
    shadow_base = round_corners(shadow_base, corner_r)
    shadow_rotated = shadow_base.rotate(angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))
    shadow_rotated = shadow_rotated.filter(ImageFilter.GaussianBlur(30))

    screenshot_y = text_bottom + int(canvas_h * 0.02)
    screenshot_x = (canvas_w - rotated.size[0]) // 2

    canvas.paste(shadow_rotated, (screenshot_x + 8, screenshot_y + 16), shadow_rotated)
    canvas.paste(rotated, (screenshot_x, screenshot_y), rotated)


def layout_split(canvas, raw_light, raw_dark, config, canvas_w, canvas_h, corner_r, text_bottom):
    """Side-by-side light mode / dark mode split."""
    gap = int(canvas_w * 0.03)
    single_scale = 0.46
    tilt_angle = 4

    # Scale both screenshots
    light_scaled = scale_screenshot(raw_light, canvas_w, single_scale)
    dark_scaled = scale_screenshot(raw_dark if raw_dark else raw_light, canvas_w, single_scale)

    # Round corners
    light_rounded = round_corners(light_scaled, corner_r)
    dark_rounded = round_corners(dark_scaled, corner_r)

    # Tilt in opposite directions
    light_tilted = light_rounded.rotate(tilt_angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))
    dark_tilted = dark_rounded.rotate(-tilt_angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))

    screenshot_y = text_bottom + int(canvas_h * 0.02)

    # Position: left and right of center
    total_w = light_tilted.size[0] + gap + dark_tilted.size[0]
    left_x = (canvas_w - total_w) // 2
    right_x = left_x + light_tilted.size[0] + gap

    # Shadows
    for img, x, angle in [(light_scaled, left_x, tilt_angle), (dark_scaled, right_x, -tilt_angle)]:
        shadow_base = Image.new("RGBA", img.size, (0, 0, 0, 90))
        shadow_base = round_corners(shadow_base, corner_r)
        shadow_rot = shadow_base.rotate(angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))
        shadow_rot = shadow_rot.filter(ImageFilter.GaussianBlur(25))
        canvas.paste(shadow_rot, (x + 6, screenshot_y + 14), shadow_rot)

    canvas.paste(light_tilted, (left_x, screenshot_y), light_tilted)
    canvas.paste(dark_tilted, (right_x, screenshot_y), dark_tilted)


# --- Main Generator ---


def generate_screenshot(device_name, device_config, raw_dir, shot_config, output_path):
    """Generate a single marketing screenshot with full styling."""
    canvas_w, canvas_h = device_config["canvas"]
    corner_r = device_config["corner_radius"]
    is_ipad = "ipad" in device_name

    # 1. Gradient background
    canvas = create_gradient(canvas_w, canvas_h, shot_config["grad_top"], shot_config["grad_bot"])
    canvas = canvas.convert("RGBA")

    # 2. Ambient orbs
    canvas = add_ambient_orbs(canvas, shot_config["orbs"], canvas_w, canvas_h)

    # 3. Text
    headline_size = 105 if is_ipad else 96
    subtitle_size = 55 if is_ipad else 48
    headline_font = load_font(headline_size, bold=True)
    subtitle_font = load_font(subtitle_size, bold=False)

    text_top = int(canvas_h * 0.065)
    text_gap = int(canvas_h * 0.016)

    # Gradient headline
    h_top, h_bot = shot_config["headline_grad"]
    headline_h = draw_gradient_text(
        canvas, shot_config["headline"], text_top, headline_font, h_top, h_bot, canvas_w
    )

    # Subtitle
    subtitle_y = text_top + headline_h + text_gap
    subtitle_h = draw_text_centered(
        canvas, shot_config["subtitle"], subtitle_y, subtitle_font, SUBTITLE_COLOR, canvas_w
    )

    text_bottom = subtitle_y + subtitle_h

    # 4. Optional badges
    if "badges" in shot_config:
        badge_y = text_bottom + int(canvas_h * 0.015)
        draw_badge_row(canvas, shot_config["badges"], badge_y, canvas_w)
        text_bottom = badge_y + 60

    # 5. Screenshot layout
    style = shot_config["style"]
    filename = shot_config["filename"]
    raw_path = os.path.join(raw_dir, f"{filename}.png")

    if not os.path.exists(raw_path):
        # For split mode on iPad, the light screenshot might be translations
        if style != "split":
            print(f"  SKIP {filename} (not found)")
            return

    if style == "straight":
        raw = Image.open(raw_path).convert("RGBA")
        layout_straight(canvas, raw, device_config, canvas_w, canvas_h, corner_r, text_bottom)

    elif style == "tilt_right":
        raw = Image.open(raw_path).convert("RGBA")
        layout_tilted(canvas, raw, device_config, canvas_w, canvas_h, corner_r, text_bottom, angle=5)

    elif style == "tilt_left":
        raw = Image.open(raw_path).convert("RGBA")
        layout_tilted(canvas, raw, device_config, canvas_w, canvas_h, corner_r, text_bottom, angle=-5)

    elif style == "split":
        # Light mode = the translations screenshot, dark mode = dark version if available
        light_path = raw_path
        dark_path = os.path.join(raw_dir, f"{filename}_dark.png")

        if not os.path.exists(light_path):
            print(f"  SKIP {filename} (not found)")
            return

        raw_light = Image.open(light_path).convert("RGBA")
        raw_dark = Image.open(dark_path).convert("RGBA") if os.path.exists(dark_path) else None

        if raw_dark is None:
            # Create a faux dark mode by inverting and adjusting
            raw_dark = create_faux_dark(raw_light)

        layout_split(canvas, raw_light, raw_dark, device_config, canvas_w, canvas_h, corner_r, text_bottom)

    # 6. Save
    final = canvas.convert("RGB")
    final.save(output_path, "PNG", optimize=True)
    print(f"  -> {output_path}")


def generate_panoramic_pair(device_name, device_config, raw_dir, pair_config, out_dir):
    """Generate a panoramic pair: one continuous scene split across two frames."""
    canvas_w, canvas_h = device_config["canvas"]
    corner_r = device_config["corner_radius"]
    is_ipad = "ipad" in device_name
    double_w = canvas_w * 2

    # Load raw screenshots
    left_path = os.path.join(raw_dir, f"{pair_config['left_filename']}.png")
    right_path = os.path.join(raw_dir, f"{pair_config['right_filename']}.png")

    if not os.path.exists(left_path) or not os.path.exists(right_path):
        print(f"  SKIP panoramic {pair_config['left_filename']}+{pair_config['right_filename']} (missing)")
        return

    left_raw = Image.open(left_path).convert("RGBA")
    right_raw = Image.open(right_path).convert("RGBA")

    # 1. Double-wide bilinear gradient background
    canvas = create_bilinear_gradient(
        double_w, canvas_h,
        pair_config["grad_tl"], pair_config["grad_tr"],
        pair_config["grad_bl"], pair_config["grad_br"],
    )
    canvas = canvas.convert("RGBA")

    # 2. Ambient orbs across full double width
    canvas = add_ambient_orbs(canvas, pair_config["orbs"], double_w, canvas_h)

    # 3. Text for each half
    headline_size = 105 if is_ipad else 96
    subtitle_size = 55 if is_ipad else 48
    headline_font = load_font(headline_size, bold=True)
    subtitle_font = load_font(subtitle_size, bold=False)

    text_top = int(canvas_h * 0.065)
    text_gap = int(canvas_h * 0.016)

    # Left half text (centered in left frame)
    left_center = canvas_w // 2
    h_top_l, h_bot_l = pair_config["left_headline_grad"]
    left_hl_h = draw_gradient_text_at(
        canvas, pair_config["left_headline"],
        left_center, text_top, headline_font, h_top_l, h_bot_l,
    )
    left_sub_y = text_top + left_hl_h + text_gap
    left_sub_h = draw_text_at(
        canvas, pair_config["left_subtitle"],
        left_center, left_sub_y, subtitle_font, SUBTITLE_COLOR,
    )
    left_text_bottom = left_sub_y + left_sub_h

    # Right half text (centered in right frame)
    right_center = canvas_w + canvas_w // 2
    h_top_r, h_bot_r = pair_config["right_headline_grad"]
    right_hl_h = draw_gradient_text_at(
        canvas, pair_config["right_headline"],
        right_center, text_top, headline_font, h_top_r, h_bot_r,
    )
    right_sub_y = text_top + right_hl_h + text_gap
    right_sub_h = draw_text_at(
        canvas, pair_config["right_subtitle"],
        right_center, right_sub_y, subtitle_font, SUBTITLE_COLOR,
    )
    right_text_bottom = right_sub_y + right_sub_h

    text_bottom = max(left_text_bottom, right_text_bottom)

    # 4. Place device screenshots
    scale = device_config["screenshot_scale"] * 0.88
    screenshot_y = text_bottom + int(canvas_h * 0.02)

    place_device_at(
        canvas, left_raw, left_center, screenshot_y,
        scale, corner_r, canvas_w, pair_config["left_angle"],
    )
    place_device_at(
        canvas, right_raw, right_center, screenshot_y,
        scale, corner_r, canvas_w, pair_config["right_angle"],
    )

    # 5. Split canvas in half and save
    left_img = canvas.crop((0, 0, canvas_w, canvas_h)).convert("RGB")
    right_img = canvas.crop((canvas_w, 0, double_w, canvas_h)).convert("RGB")

    left_out = os.path.join(out_dir, f"{pair_config['left_filename']}.png")
    right_out = os.path.join(out_dir, f"{pair_config['right_filename']}.png")

    left_img.save(left_out, "PNG", optimize=True)
    right_img.save(right_out, "PNG", optimize=True)

    print(f"  -> {left_out} (panoramic left)")
    print(f"  -> {right_out} (panoramic right)")


def generate_panoramic_strip(device_name, device_config, raw_dir, out_dir):
    """Generate a full panoramic strip: one continuous canvas sliced into frames.

    Devices are centered on cut lines so each is split 50/50 across two frames.
    Frame 0 is an intro, last frame is a closer. Headlines straddle cuts too.
    """
    canvas_w, canvas_h = device_config["canvas"]
    corner_r = device_config["corner_radius"]
    is_ipad = "ipad" in device_name
    cfg = PANORAMIC_STRIP

    # Filter to screenshots that exist for this device
    shots = []
    for s in cfg["screenshots"]:
        if os.path.exists(os.path.join(raw_dir, f"{s['filename']}.png")):
            shots.append(s)

    if len(shots) < 2:
        print(f"  SKIP panoramic strip (need at least 2 screenshots)")
        return

    num_devices = len(shots)
    num_frames = num_devices + 1  # intro frame + one cut per device
    total_w = num_frames * canvas_w

    # 1. Background — bilinear gradient across full strip
    canvas = create_bilinear_gradient(
        total_w, canvas_h,
        cfg["grad_tl"], cfg["grad_tr"],
        cfg["grad_bl"], cfg["grad_br"],
    )
    canvas = canvas.convert("RGBA")

    # 2. Ambient orbs distributed across the strip
    canvas = add_ambient_orbs(canvas, cfg["orbs"], total_w, canvas_h)

    # 3. Fonts
    headline_size = 100 if is_ipad else 88
    subtitle_size = 50 if is_ipad else 42
    intro_size = 130 if is_ipad else 110
    headline_font = load_font(headline_size, bold=True)
    subtitle_font = load_font(subtitle_size, bold=False)
    intro_font = load_font(intro_size, bold=True)

    text_y = int(canvas_h * 0.07)
    text_gap = int(canvas_h * 0.014)

    # 4. Intro text — shifted LEFT within frame 0 to avoid first device bleed
    intro_cx = int(canvas_w * 0.35)
    intro_hl_h = draw_gradient_text_at(
        canvas, cfg["intro_headline"], intro_cx, text_y,
        intro_font, (255, 255, 255), TINT_TEAL,
    )
    draw_text_at(
        canvas, cfg["intro_subtitle"], intro_cx,
        text_y + intro_hl_h + text_gap,
        subtitle_font, SUBTITLE_COLOR,
    )

    # 5. Place devices on cut lines with headlines above
    device_scale = 0.68
    device_y = int(canvas_h * 0.24)

    for i, shot in enumerate(shots):
        cut_x = (i + 1) * canvas_w  # the cut between frame i and frame i+1

        # Load screenshot
        raw = Image.open(os.path.join(raw_dir, f"{shot['filename']}.png")).convert("RGBA")

        # Alternate tilt: even=right tilt, odd=left tilt
        angle = 3 if i % 2 == 0 else -3

        place_device_at(
            canvas, raw, cut_x, device_y,
            device_scale, corner_r, canvas_w, angle,
        )

        # Headline + subtitle straddling the same cut (skip if empty)
        if shot["headline"]:
            hl_h = draw_gradient_text_at(
                canvas, shot["headline"], cut_x, text_y,
                headline_font, (255, 255, 255), TINT_NEUTRAL,
            )
            if shot["subtitle"]:
                draw_text_at(
                    canvas, shot["subtitle"], cut_x,
                    text_y + hl_h + text_gap,
                    subtitle_font, SUBTITLE_COLOR_STRIP,
                )

    # 6. Outro text — shifted RIGHT within last frame to avoid last device bleed
    outro_cx = int((num_frames - 0.35) * canvas_w)
    outro_hl_h = draw_gradient_text_at(
        canvas, cfg["outro_headline"], outro_cx, text_y,
        intro_font, (255, 255, 255), TINT_WARM,
    )
    draw_text_at(
        canvas, cfg["outro_subtitle"], outro_cx,
        text_y + outro_hl_h + text_gap,
        subtitle_font, SUBTITLE_COLOR,
    )

    # 7. Slice into individual frames
    os.makedirs(out_dir, exist_ok=True)
    for i in range(num_frames):
        frame = canvas.crop((i * canvas_w, 0, (i + 1) * canvas_w, canvas_h))
        frame = frame.convert("RGB")
        out_path = os.path.join(out_dir, f"strip_{i + 1:02d}.png")
        frame.save(out_path, "PNG", optimize=True)
        print(f"  -> {out_path}")


# --- Ultimate Strip ---
# Per-device angle/scale for dynamic visual rhythm.
# Heroes (scale 0.75, angle 0) anchor the eye; tilts vary to break monotony.
# Headlines rewritten with Gatena Cookbook principles:
#   - Gain Framing (#53): benefits over features
#   - Curiosity Gap (#103): invite exploration
#   - Tiny Habits (#114): anchor routine
#   - Autonomy Bias (#108): ownership language
#   - Primacy (#58) & Peak-End (#117): heroes at start and climax

ULTIMATE_STRIP = {
    "screenshots": [
        # 1. HERO — straight, large. Hook: name the pain, promise the shift.
        #    Primacy Effect (#58): strongest message first. Stop the scroll.
        {"filename": "01_bible_books",
         "headline": "Scripture Without the Clutter",
         "subtitle": "No ads. No sign-up. Just the Word.",
         "angle": 0, "scale": 0.92},
        # 2. Tilt right. Competence Signalling (#95): user outcome, not feature.
        {"filename": "02_chapters",
         "headline": "Understand Before You Read",
         "subtitle": "Every chapter summarized at a glance",
         "angle": 4, "scale": 0.85},
        # 3. Tilt left. Von Restorff (#1): distinctive feature as experience.
        {"filename": "03_verses",
         "headline": "See What Jesus Actually Said",
         "subtitle": "Red-letter words, beautifully preserved",
         "angle": -3, "scale": 0.85},
        # 4. Straight — anchors "tools" message. Outcome over interaction.
        {"filename": "04_verse_options",
         "headline": "Make Every Verse Yours",
         "subtitle": "Bookmark, highlight, take notes, share",
         "angle": 0, "scale": 0.85},
        # 5. Right tilt — light mode. Specific benefit, not generic.
        {"filename": "05_translations",
         "headline": "Three Translations. Your Choice.",
         "subtitle": "KJV, ASV, and WEB \u2014 all free",
         "angle": 3, "scale": 0.82},
        # 6. Left tilt — dark mode mirror. Aesthetic-Usability (#122).
        {"filename": "05_translations_dark",
         "headline": "Easy on Your Eyes",
         "subtitle": "Dark mode that reads as good as it looks",
         "angle": -3, "scale": 0.82},
        # 7. HERO — straight, large. Peak moment (#117): daily habit hook.
        {"filename": "06_devotional",
         "headline": "Start Each Morning Different",
         "subtitle": "A fresh devotional, every single day",
         "angle": 0, "scale": 0.92},
        # 8. Left tilt — library breadth via the More hub.
        {"filename": "07_more",
         "headline": "Your Library, At a Glance",
         "subtitle": "Bookmarks, stats & history in one place",
         "angle": -4, "scale": 0.85},
        # 9. Visual bookend with closing text.
        {"filename": "01_bible_books_dark",
         "headline": "", "subtitle": "",
         "angle": 3, "scale": 0.85},
    ],
    "intro_headline": "Scripture Without the Clutter",
    "intro_subtitle": "No ads. No sign-up. Just the Word.",
    "bridge_headline": "Free Forever. Open Source.",
    "bridge_subtitle": "No ads. No tracking. No subscriptions.",
    "outro_headline": "Read. Study. Grow.",
    "outro_subtitle": "SwiftBible",
    # Background: deep navy → warm amber (brand palette flow)
    "grad_tl": (13, 18, 45),
    "grad_tr": (42, 26, 10),
    "grad_bl": (20, 30, 65),
    "grad_br": (60, 38, 12),
    "orbs": [
        (0.05, 0.30, 0.06, CYAN, 55),
        (0.15, 0.55, 0.05, GREEN, 40),
        (0.25, 0.35, 0.06, RED_DARK, 45),
        (0.35, 0.50, 0.07, ACCENT, 50),
        (0.45, 0.40, 0.06, ACCENT, 45),
        (0.55, 0.55, 0.06, GREEN, 42),
        (0.65, 0.35, 0.06, GOLD, 40),
        (0.75, 0.50, 0.07, GOLD, 45),
        (0.85, 0.40, 0.06, GOLD, 38),
        (0.95, 0.35, 0.06, ACCENT, 35),
    ],
}


# --- Ultimate Mixed ---
# Mixed layout styles for visual variety.  Each frame is a complete composition.
# Layout types:
#   "hero"      — big headline, centered device overflows bottom edge
#   "panoramic" — two frames share a continuous background, devices on cut line
#   "split"     — light/dark side by side in one frame

# ULTIMATE_MIXED — the marketing set actually uploaded to App Store Connect.
#
# Slot order follows Sebastian's playbook (devotional hook → unique moat →
# visual standout → premium feature → depth → study tool → close).
#
# Appearance: mostly DARK for visual cohesion and a premium feel; slot 2
# breaks pattern as a halved light/dark split — both reads as "we have light
# AND dark" AND showcases the translation dropdown clearly.
#
# Headlines are OCR-indexed (Apple change Jun 2025) and contain the target
# keyword for each theme.
# Reordered to front-load the three most distinctive features
# (Devotional → Explain → More), then the unique-moat translations break,
# then secondary features. Mostly DARK with one LIGHT/DARK halved break.
ULTIMATE_MIXED = [
    # Slot 1: HERO (DARK) — daily devotional hook (kw: "daily devotional")
    {"layout": "hero",
     "filename": "06_devotional_dark",
     "headline": "Daily Devotional, Every Morning",
     "subtitle": "Verse, context & prayer to start your day",
     "scale": 0.88, "angle": 0,
     "grad_top": (42, 26, 10), "grad_bot": (65, 40, 14),
     "orbs": [(0.6, 0.3, 0.45, GOLD, 45), (0.2, 0.65, 0.35, GOLD, 30)],
     "headline_grad": ((255, 255, 255), TINT_WARM),
     "headline_font": "intro",
     "glow": GOLD, "bokeh": GOLD, "vignette": True,
     "god_rays": GOLD, "god_rays_corner": "top_left",
     "shimmer": False, "color_grade": 0.12, "bloom": True},

    # Slot 2: HERO (DARK) — Apple Intelligence verse explanations
    {"layout": "hero",
     "filename": "04b_explain_dark",
     "headline": "Bible AI Verse Explanations",
     "subtitle": "Apple Intelligence, on device & private",
     "scale": 0.85, "angle": 4,
     "grad_top": (8, 32, 35), "grad_bot": (14, 55, 58),
     "orbs": [(0.5, 0.3, 0.5, ACCENT, 45), (0.1, 0.7, 0.35, GREEN, 30)],
     "headline_grad": ((255, 255, 255), TINT_TEAL),
     "headline_font": "headline",
     "light_leak": ACCENT, "light_leak_corner": "top_right", "light_leak_size": 0.3,
     "accent_line": ACCENT, "bloom": True},

    # Slot 3: HERO (DARK) — More hub (bookmarks, notes, library at a glance)
    {"layout": "hero",
     "filename": "07_more_dark",
     "headline": "Bible Notes & Bookmarks",
     "subtitle": "Highlights, stats & history in one place",
     "scale": 0.85, "angle": -4,
     "grad_top": (16, 18, 30), "grad_bot": (28, 32, 48),
     "orbs": [(0.3, 0.35, 0.4, ACCENT, 35), (0.75, 0.6, 0.3, CYAN, 25)],
     "headline_grad": ((255, 255, 255), TINT_TEAL),
     "headline_font": "headline",
     "glow": ACCENT, "bokeh": CYAN, "vignette": True,
     "accent_line": ACCENT, "bloom": True},

    # Slot 4: HALVED (LIGHT/DARK split) — translations + appearance combo.
    # The split itself signals "we support light AND dark" while the open
    # dropdown lands the Hebrew/Greek moat keyword.
    {"layout": "halved",
     "light_filename": "05_translations",
     "dark_filename": "05_translations_dark",
     "headline": "Hebrew & Greek Bible",
     "subtitle": "KJV, ASV, WEB — switch as you read",
     "grad_top": (38, 30, 10), "grad_bot": (60, 48, 16),
     "orbs": [(0.5, 0.3, 0.55, GOLD, 45), (0.15, 0.7, 0.3, GOLD, 25)],
     "headline_grad": ((255, 255, 255), TINT_GOLD)},

    # Slot 5: HERO (DARK) — Jesus's words in red (kw: "red letter Bible")
    {"layout": "hero",
     "filename": "03_red_letter_dark",
     "headline": "Red Letter Bible",
     "subtitle": "Jesus's words in red, beautifully preserved",
     "scale": 0.85, "angle": 4,
     "grad_top": (45, 12, 18), "grad_bot": (72, 20, 30),
     "orbs": [(0.3, 0.35, 0.5, RED_DARK, 45), (0.85, 0.65, 0.3, RED, 30)],
     "headline_grad": ((255, 255, 255), TINT_RED),
     "headline_font": "headline",
     "vignette": True, "accent_line": RED, "bloom": True},

    # Slots 6+7: PANORAMIC (DARK) — library depth + study tool combo.
    # Left uses the apocrypha-scrolled book list so the headline matches.
    {"layout": "panoramic",
     "left_filename": "01b_apocrypha_books_dark",
     "right_filename": "02_chapters_dark",
     "left_headline": "Apocrypha & Enoch Included",
     "left_subtitle": "Jubilees, Clement, Didache — public domain",
     "right_headline": "Summary on Every Chapter",
     "right_subtitle": "Know the gist before you read",
     "left_angle": 4, "right_angle": -4,
     "scale": 0.88,
     "grad_tl": (13, 18, 45), "grad_tr": (8, 22, 48),
     "grad_bl": (20, 30, 65), "grad_br": (14, 38, 72),
     "orbs": [
         (0.15, 0.3, 0.22, ACCENT, 50),
         (0.5, 0.45, 0.28, CYAN, 55),
         (0.85, 0.35, 0.22, CYAN, 50),
         (0.35, 0.7, 0.18, GREEN, 30),
         (0.65, 0.65, 0.18, ACCENT, 30),
     ],
     "left_headline_grad": ((255, 255, 255), TINT_TEAL),
     "right_headline_grad": ((255, 255, 255), TINT_BLUE)},

    # Slot 8: WATCH+WIDGET composite — companion experiences.
    # Custom layout reads from the asset catalog (OnboardingWatch/Widget) since
    # those are shipped product art, not simulator captures.
    {"layout": "watch_widget",
     "headline": "On Apple Watch & Widget Too",
     "subtitle": "Verse-of-the-day at a wrist or home-screen glance",
     "grad_top": (20, 14, 8), "grad_bot": (42, 28, 12),
     "orbs": [(0.4, 0.4, 0.5, GOLD, 35), (0.7, 0.6, 0.3, ACCENT, 25)],
     "headline_grad": ((255, 255, 255), TINT_WARM),
     "headline_font": "intro",
     "vignette": True,
     "god_rays": GOLD, "god_rays_corner": "top_right",
     "color_grade": 0.15},
]


def generate_hero_frame(device_config, raw_dir, frame_cfg, output_path):
    """Generate a single hero frame: big headline, device overflows bottom."""
    canvas_w, canvas_h = device_config["canvas"]
    corner_r = device_config["corner_radius"]
    is_ipad = "ipad" in device_config.get("name", "")

    raw_path = os.path.join(raw_dir, f"{frame_cfg['filename']}.png")
    if not os.path.exists(raw_path):
        print(f"  SKIP hero {frame_cfg['filename']} (not found)")
        return

    # 1. Gradient background
    canvas = create_gradient(canvas_w, canvas_h, frame_cfg["grad_top"], frame_cfg["grad_bot"])
    canvas = canvas.convert("RGBA")

    # 2. Ambient orbs
    canvas = add_ambient_orbs(canvas, frame_cfg["orbs"], canvas_w, canvas_h)

    # 2b. Optional background effects (applied before text/device)
    if frame_cfg.get("god_rays"):
        gr = frame_cfg["god_rays"]
        gr_color = gr if isinstance(gr, tuple) else GOLD
        canvas = add_god_rays(canvas, canvas_w, canvas_h, gr_color,
                              corner=frame_cfg.get("god_rays_corner", "top_right"))
    if frame_cfg.get("light_leak"):
        ll = frame_cfg["light_leak"]
        ll_color = ll if isinstance(ll, tuple) else GOLD
        canvas = add_light_leak(canvas, canvas_w, canvas_h, ll_color,
                                corner=frame_cfg.get("light_leak_corner", "top_right"),
                                size=frame_cfg.get("light_leak_size", 0.4))
    if frame_cfg.get("bokeh"):
        bokeh_color = frame_cfg["bokeh"] if isinstance(frame_cfg["bokeh"], tuple) else None
        canvas = add_bokeh(canvas, canvas_w, canvas_h, count=15, color=bokeh_color)
    if frame_cfg.get("grain", False):
        canvas = add_film_grain(canvas, canvas_w, canvas_h, intensity=6)
    if frame_cfg.get("vignette", False):
        canvas = add_vignette(canvas, canvas_w, canvas_h, strength=0.35)
    if frame_cfg.get("color_grade") is not None:
        canvas = add_color_grade(canvas, canvas_w, canvas_h, warmth=frame_cfg["color_grade"])
    if frame_cfg.get("bloom", False):
        canvas = add_bloom(canvas, canvas_w, canvas_h)

    # 3. Headline — auto-size down if text is too wide for canvas
    font_style = frame_cfg.get("headline_font", "headline")
    if font_style == "intro":
        hl_size = 120 if is_ipad else 100
    else:
        hl_size = 100 if is_ipad else 88
    sub_size = 55 if is_ipad else 46

    max_text_w = int(canvas_w * 0.92)  # leave 4% margin each side
    headline_font = load_font(hl_size, bold=True)
    # Shrink until headline fits within margins
    tmp_draw = ImageDraw.Draw(canvas)
    while hl_size > 60:
        bbox = tmp_draw.textbbox((0, 0), frame_cfg["headline"], font=headline_font)
        if (bbox[2] - bbox[0]) <= max_text_w:
            break
        hl_size -= 4
        headline_font = load_font(hl_size, bold=True)
    subtitle_font = load_font(sub_size, bold=False)

    text_y = int(canvas_h * 0.055)
    text_gap = int(canvas_h * 0.012)

    h_top, h_bot = frame_cfg["headline_grad"]
    # Optional: app icon badge above headline
    if frame_cfg.get("icon"):
        icon_path = os.path.join(SCRIPT_DIR, frame_cfg["icon"])
        icon_bottom = add_app_icon_badge(canvas, canvas_w, icon_path, y=int(canvas_h * 0.02))
        if icon_bottom:
            text_y = icon_bottom

    glow_color = frame_cfg.get("glow")  # optional glow color tuple
    hl_h = draw_gradient_text(canvas, frame_cfg["headline"], text_y, headline_font, h_top, h_bot, canvas_w, glow_color=glow_color)

    # Optional: metallic shimmer across headline
    if frame_cfg.get("shimmer", False):
        add_shimmer(canvas, frame_cfg["headline"], text_y, headline_font, canvas_w)

    sub_y = text_y + hl_h + text_gap
    draw_text_centered(canvas, frame_cfg["subtitle"], sub_y, subtitle_font, SUBTITLE_COLOR, canvas_w)

    # Optional: accent line between text and device
    if frame_cfg.get("accent_line"):
        al_color = frame_cfg["accent_line"] if isinstance(frame_cfg["accent_line"], tuple) else ACCENT
        add_accent_line(canvas, sub_y + int(canvas_h * 0.02), canvas_w, al_color)

    # 4. Device — starts right below subtitle, overflows bottom
    raw = Image.open(raw_path).convert("RGBA")
    scale = frame_cfg.get("scale", 0.88)
    angle = frame_cfg.get("angle", 0)
    device_y = sub_y + int(canvas_h * 0.045)

    scaled = scale_screenshot(raw, canvas_w, scale)

    # Optional device edge glow
    if glow_color:
        glow_x = (canvas_w - scaled.size[0]) // 2
        add_device_edge_glow(canvas, glow_x, device_y, scaled.size[0], scaled.size[1], corner_r, glow_color)

    if angle != 0:
        rounded = round_corners(scaled, corner_r)
        rotated = rounded.rotate(angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))
        shadow_base = Image.new("RGBA", scaled.size, (0, 0, 0, 110))
        shadow_base = round_corners(shadow_base, corner_r)
        shadow_rot = shadow_base.rotate(angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))
        shadow_rot = shadow_rot.filter(ImageFilter.GaussianBlur(30))
        sx = (canvas_w - rotated.size[0]) // 2
        canvas.paste(shadow_rot, (sx + 8, device_y + 16), shadow_rot)
        canvas.paste(rotated, (sx, device_y), rotated)
    else:
        rounded = round_corners(scaled, corner_r)
        shadow, s_offset = create_shadow(scaled.size, corner_r, blur_radius=28, offset=(0, 14), opacity=110)
        sx = (canvas_w - scaled.size[0]) // 2
        canvas.paste(shadow, (sx - s_offset[0], device_y - s_offset[1]), shadow)
        canvas.paste(rounded, (sx, device_y), rounded)

    # 5. Save (crop to canvas bounds — device overflow is natural)
    final = canvas.crop((0, 0, canvas_w, canvas_h)).convert("RGB")
    final.save(output_path, "PNG", optimize=True)
    print(f"  -> {output_path}")


def generate_mixed_panoramic(device_config, raw_dir, pair_cfg, out_path_left, out_path_right):
    """Generate a panoramic pair: continuous scene split across two frames."""
    canvas_w, canvas_h = device_config["canvas"]
    corner_r = device_config["corner_radius"]
    is_ipad = "ipad" in device_config.get("name", "")
    double_w = canvas_w * 2

    left_path = os.path.join(raw_dir, f"{pair_cfg['left_filename']}.png")
    right_path = os.path.join(raw_dir, f"{pair_cfg['right_filename']}.png")
    if not os.path.exists(left_path) or not os.path.exists(right_path):
        print(f"  SKIP panoramic (missing)")
        return

    left_raw = Image.open(left_path).convert("RGBA")
    right_raw = Image.open(right_path).convert("RGBA")

    # 1. Double-wide gradient
    canvas = create_bilinear_gradient(
        double_w, canvas_h,
        pair_cfg["grad_tl"], pair_cfg["grad_tr"],
        pair_cfg["grad_bl"], pair_cfg["grad_br"],
    ).convert("RGBA")

    # 2. Orbs
    canvas = add_ambient_orbs(canvas, pair_cfg["orbs"], double_w, canvas_h)

    # 3. Text — each headline must fit within its own frame's width.
    base_hl_size = 100 if is_ipad else 88
    sub_size = 55 if is_ipad else 46
    subtitle_font = load_font(sub_size, bold=False)
    max_text_w = int(canvas_w * 0.92)  # 4% margin each side per frame
    tmp_draw = ImageDraw.Draw(canvas)

    def fit_headline_font(text):
        size = base_hl_size
        font = load_font(size, bold=True)
        while size > 50:
            bbox = tmp_draw.textbbox((0, 0), text, font=font)
            if (bbox[2] - bbox[0]) <= max_text_w:
                break
            size -= 4
            font = load_font(size, bold=True)
        return font

    text_y = int(canvas_h * 0.055)
    text_gap = int(canvas_h * 0.012)

    # Left headline (auto-fit)
    left_font = fit_headline_font(pair_cfg["left_headline"])
    left_cx = canvas_w // 2
    h_top_l, h_bot_l = pair_cfg["left_headline_grad"]
    left_hl_h = draw_gradient_text_at(canvas, pair_cfg["left_headline"], left_cx, text_y, left_font, h_top_l, h_bot_l)
    draw_text_at(canvas, pair_cfg["left_subtitle"], left_cx, text_y + left_hl_h + text_gap, subtitle_font, SUBTITLE_COLOR)

    # Right headline (auto-fit)
    right_font = fit_headline_font(pair_cfg["right_headline"])
    right_cx = canvas_w + canvas_w // 2
    h_top_r, h_bot_r = pair_cfg["right_headline_grad"]
    right_hl_h = draw_gradient_text_at(canvas, pair_cfg["right_headline"], right_cx, text_y, right_font, h_top_r, h_bot_r)
    draw_text_at(canvas, pair_cfg["right_subtitle"], right_cx, text_y + right_hl_h + text_gap, subtitle_font, SUBTITLE_COLOR)

    text_bottom = max(text_y + left_hl_h, text_y + right_hl_h) + int(canvas_h * 0.06)

    # 4. Place devices — offset from cut line toward their home frames
    #    Each device still bleeds ~25% into the adjacent frame for the
    #    panoramic effect, but fills ~75% of its own frame.
    scale = pair_cfg.get("scale", 0.88)
    offset = int(canvas_w * 0.34)
    place_device_at(canvas, left_raw, canvas_w - offset, text_bottom, scale, corner_r, canvas_w, pair_cfg["left_angle"])
    place_device_at(canvas, right_raw, canvas_w + offset, text_bottom, scale, corner_r, canvas_w, pair_cfg["right_angle"])

    # 5. Split and save
    left_img = canvas.crop((0, 0, canvas_w, canvas_h)).convert("RGB")
    right_img = canvas.crop((canvas_w, 0, double_w, canvas_h)).convert("RGB")
    left_img.save(out_path_left, "PNG", optimize=True)
    right_img.save(out_path_right, "PNG", optimize=True)
    print(f"  -> {out_path_left} (panoramic left)")
    print(f"  -> {out_path_right} (panoramic right)")


def generate_mixed_split(device_config, raw_dir, frame_cfg, output_path):
    """Generate a split frame: light + dark side by side."""
    canvas_w, canvas_h = device_config["canvas"]
    corner_r = device_config["corner_radius"]
    is_ipad = "ipad" in device_config.get("name", "")

    light_path = os.path.join(raw_dir, f"{frame_cfg['light_filename']}.png")
    dark_path = os.path.join(raw_dir, f"{frame_cfg['dark_filename']}.png")
    if not os.path.exists(light_path) or not os.path.exists(dark_path):
        print(f"  SKIP split (missing)")
        return

    # 1. Background
    canvas = create_gradient(canvas_w, canvas_h, frame_cfg["grad_top"], frame_cfg["grad_bot"])
    canvas = canvas.convert("RGBA")
    canvas = add_ambient_orbs(canvas, frame_cfg["orbs"], canvas_w, canvas_h)

    # 2. Headline
    hl_size = 100 if is_ipad else 88
    sub_size = 55 if is_ipad else 46
    headline_font = load_font(hl_size, bold=True)
    subtitle_font = load_font(sub_size, bold=False)

    text_y = int(canvas_h * 0.055)
    text_gap = int(canvas_h * 0.012)

    h_top, h_bot = frame_cfg["headline_grad"]
    hl_h = draw_gradient_text(canvas, frame_cfg["headline"], text_y, headline_font, h_top, h_bot, canvas_w)
    sub_y = text_y + hl_h + text_gap
    draw_text_centered(canvas, frame_cfg["subtitle"], sub_y, subtitle_font, SUBTITLE_COLOR, canvas_w)

    # 3. Two devices side by side, tilted, overflow bottom
    raw_light = Image.open(light_path).convert("RGBA")
    raw_dark = Image.open(dark_path).convert("RGBA")

    gap = int(canvas_w * 0.03)
    single_scale = 0.46
    tilt = 4
    device_top = sub_y + int(canvas_h * 0.04)

    light_scaled = scale_screenshot(raw_light, canvas_w, single_scale)
    dark_scaled = scale_screenshot(raw_dark, canvas_w, single_scale)

    light_rounded = round_corners(light_scaled, corner_r)
    dark_rounded = round_corners(dark_scaled, corner_r)

    light_tilted = light_rounded.rotate(tilt, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))
    dark_tilted = dark_rounded.rotate(-tilt, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))

    total_w = light_tilted.size[0] + gap + dark_tilted.size[0]
    left_x = (canvas_w - total_w) // 2
    right_x = left_x + light_tilted.size[0] + gap

    # Shadows
    for img, x, a in [(light_scaled, left_x, tilt), (dark_scaled, right_x, -tilt)]:
        sb = Image.new("RGBA", img.size, (0, 0, 0, 90))
        sb = round_corners(sb, corner_r)
        sr = sb.rotate(a, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))
        sr = sr.filter(ImageFilter.GaussianBlur(25))
        canvas.paste(sr, (x + 6, device_top + 14), sr)

    canvas.paste(light_tilted, (left_x, device_top), light_tilted)
    canvas.paste(dark_tilted, (right_x, device_top), dark_tilted)

    final = canvas.crop((0, 0, canvas_w, canvas_h)).convert("RGB")
    final.save(output_path, "PNG", optimize=True)
    print(f"  -> {output_path}")


def generate_halved_frame(device_config, raw_dir, frame_cfg, output_path):
    """Generate a halved frame: left half of light screenshot + right half of dark.

    Creates a clean vertical split — one device, half light half dark.
    No tilt, no gap, fills the entire frame below the headline.
    """
    canvas_w, canvas_h = device_config["canvas"]
    corner_r = device_config["corner_radius"]
    is_ipad = "ipad" in device_config.get("name", "")

    light_path = os.path.join(raw_dir, f"{frame_cfg['light_filename']}.png")
    dark_path = os.path.join(raw_dir, f"{frame_cfg['dark_filename']}.png")
    if not os.path.exists(light_path) or not os.path.exists(dark_path):
        print(f"  SKIP halved (missing)")
        return

    # 1. Background
    canvas = create_gradient(canvas_w, canvas_h, frame_cfg["grad_top"], frame_cfg["grad_bot"])
    canvas = canvas.convert("RGBA")
    canvas = add_ambient_orbs(canvas, frame_cfg["orbs"], canvas_w, canvas_h)

    # 2. Headline
    hl_size = 100 if is_ipad else 88
    sub_size = 55 if is_ipad else 46
    headline_font = load_font(hl_size, bold=True)
    subtitle_font = load_font(sub_size, bold=False)

    text_y = int(canvas_h * 0.055)
    text_gap = int(canvas_h * 0.012)

    # Auto-size headline
    max_text_w = int(canvas_w * 0.92)
    tmp_draw = ImageDraw.Draw(canvas)
    while hl_size > 60:
        bbox = tmp_draw.textbbox((0, 0), frame_cfg["headline"], font=headline_font)
        if (bbox[2] - bbox[0]) <= max_text_w:
            break
        hl_size -= 4
        headline_font = load_font(hl_size, bold=True)

    h_top, h_bot = frame_cfg["headline_grad"]
    hl_h = draw_gradient_text(canvas, frame_cfg["headline"], text_y, headline_font, h_top, h_bot, canvas_w)
    sub_y = text_y + hl_h + text_gap
    draw_text_centered(canvas, frame_cfg["subtitle"], sub_y, subtitle_font, SUBTITLE_COLOR, canvas_w)

    # 3. Load both screenshots and scale to fill width
    raw_light = Image.open(light_path).convert("RGBA")
    raw_dark = Image.open(dark_path).convert("RGBA")

    device_top = sub_y + int(canvas_h * 0.035)
    device_h = canvas_h - device_top + int(canvas_h * 0.1)  # overflow bottom

    # Scale to full canvas width, maintaining aspect ratio
    scale_w = canvas_w
    scale_h = int(raw_light.size[1] * (scale_w / raw_light.size[0]))
    if scale_h < device_h:
        # Scale by height instead to ensure we fill vertically
        scale_h = device_h
        scale_w = int(raw_light.size[0] * (scale_h / raw_light.size[1]))

    light_scaled = raw_light.resize((scale_w, scale_h), Image.LANCZOS)
    dark_scaled = raw_dark.resize((scale_w, scale_h), Image.LANCZOS)

    # 4. Crop: left half of light, right half of dark
    half_w = canvas_w // 2
    # Center-crop each screenshot horizontally before halving
    x_offset = max(0, (scale_w - canvas_w) // 2)
    light_crop = light_scaled.crop((x_offset, 0, x_offset + half_w, scale_h))
    dark_crop = dark_scaled.crop((x_offset + half_w, 0, x_offset + canvas_w, scale_h))

    # 5. Round only the outer top corners
    # Create a combined device image first
    combined = Image.new("RGBA", (canvas_w, scale_h), (0, 0, 0, 0))
    combined.paste(light_crop, (0, 0))
    combined.paste(dark_crop, (half_w, 0))

    # Round top corners only
    rounded = round_corners(combined, corner_r)

    # 6. Add shadow and paste
    shadow, s_offset = create_shadow(
        (canvas_w, scale_h), corner_r, blur_radius=28, offset=(0, 14), opacity=110
    )
    canvas.paste(shadow, (0 - s_offset[0], device_top - s_offset[1]), shadow)
    canvas.paste(rounded, (0, device_top), rounded)

    # Add a thin vertical divider line at the center
    draw = ImageDraw.Draw(canvas)
    draw.line([(half_w, device_top), (half_w, canvas_h)], fill=(255, 255, 255, 60), width=2)

    final = canvas.crop((0, 0, canvas_w, canvas_h)).convert("RGB")
    final.save(output_path, "PNG", optimize=True)
    print(f"  -> {output_path}")


def generate_triple_panoramic(device_config, raw_dir, triple_cfg, out_paths):
    """Generate a triple panoramic: 3 frames from one canvas.

    Left frame: a standalone device.
    Center frame: split light/dark devices on the cut lines (bleed into L and R).
    Right frame: a standalone device.
    """
    canvas_w, canvas_h = device_config["canvas"]
    corner_r = device_config["corner_radius"]
    is_ipad = "ipad" in device_config.get("name", "")
    triple_w = canvas_w * 3

    # 1. Background
    canvas = create_bilinear_gradient(
        triple_w, canvas_h,
        triple_cfg["grad_tl"], triple_cfg["grad_tr"],
        triple_cfg["grad_bl"], triple_cfg["grad_br"],
    ).convert("RGBA")

    # 2. Orbs
    canvas = add_ambient_orbs(canvas, triple_cfg["orbs"], triple_w, canvas_h)

    # 3. Fonts
    hl_size = 100 if is_ipad else 88
    sub_size = 55 if is_ipad else 46
    headline_font = load_font(hl_size, bold=True)
    subtitle_font = load_font(sub_size, bold=False)

    text_y = int(canvas_h * 0.055)
    text_gap = int(canvas_h * 0.012)
    device_y = int(canvas_h * 0.20)

    # 4. Left frame device (centered-left in frame 0)
    left = triple_cfg["left"]
    left_path = os.path.join(raw_dir, f"{left['filename']}.png")
    if os.path.exists(left_path):
        left_raw = Image.open(left_path).convert("RGBA")
        left_cx = int(canvas_w * 0.42)
        place_device_at(
            canvas, left_raw, left_cx, device_y,
            left["scale"], corner_r, canvas_w, left["angle"],
        )

    # Left headline
    h_top, h_bot = left["headline_grad"]
    hl_h = draw_gradient_text_at(
        canvas, left["headline"], canvas_w // 2, text_y,
        headline_font, h_top, h_bot,
    )
    draw_text_at(
        canvas, left["subtitle"], canvas_w // 2,
        text_y + hl_h + text_gap, subtitle_font, SUBTITLE_COLOR,
    )

    # 5. Center split devices — offset inward from cut lines to fill center frame
    #    and bleed into adjacent frames
    center = triple_cfg["center"]
    split_scale = center.get("scale", 0.52)
    tilt = center.get("tilt", 5)
    # Shift each device inward toward center so the gap between them is small
    inward_offset = int(canvas_w * 0.18)

    light_path = os.path.join(raw_dir, f"{center['light_filename']}.png")
    dark_path = os.path.join(raw_dir, f"{center['dark_filename']}.png")

    if os.path.exists(light_path):
        light_raw = Image.open(light_path).convert("RGBA")
        place_device_at(
            canvas, light_raw, canvas_w + inward_offset, device_y,
            split_scale, corner_r, canvas_w, tilt,
        )

    if os.path.exists(dark_path):
        dark_raw = Image.open(dark_path).convert("RGBA")
        place_device_at(
            canvas, dark_raw, canvas_w * 2 - inward_offset, device_y,
            split_scale, corner_r, canvas_w, -tilt,
        )

    # Center headline
    center_cx = int(canvas_w * 1.5)
    h_top, h_bot = center["headline_grad"]
    hl_h = draw_gradient_text_at(
        canvas, center["headline"], center_cx, text_y,
        headline_font, h_top, h_bot,
    )
    draw_text_at(
        canvas, center["subtitle"], center_cx,
        text_y + hl_h + text_gap, subtitle_font, SUBTITLE_COLOR,
    )

    # 6. Right frame device (centered-right in frame 2)
    right = triple_cfg["right"]
    right_path = os.path.join(raw_dir, f"{right['filename']}.png")
    if os.path.exists(right_path):
        right_raw = Image.open(right_path).convert("RGBA")
        right_cx = int(canvas_w * 2.58)
        place_device_at(
            canvas, right_raw, right_cx, device_y,
            right["scale"], corner_r, canvas_w, right["angle"],
        )

    # Right headline
    h_top, h_bot = right["headline_grad"]
    hl_h = draw_gradient_text_at(
        canvas, right["headline"], int(canvas_w * 2.5), text_y,
        headline_font, h_top, h_bot,
    )
    draw_text_at(
        canvas, right["subtitle"], int(canvas_w * 2.5),
        text_y + hl_h + text_gap, subtitle_font, SUBTITLE_COLOR,
    )

    # 7. Slice into 3 frames
    for i, out_path in enumerate(out_paths):
        frame = canvas.crop((i * canvas_w, 0, (i + 1) * canvas_w, canvas_h))
        frame = frame.convert("RGB")
        frame.save(out_path, "PNG", optimize=True)
        print(f"  -> {out_path}")


def generate_ultimate_mixed(device_name, device_config, raw_dir, out_dir):
    """Generate the ultimate screenshot set with mixed layout styles.

    Each frame uses the best layout for its content:
    - Hero: centered device, overflows bottom, text fills top
    - Panoramic: two frames with continuous background, split devices
    - Split: light/dark side by side
    """
    os.makedirs(out_dir, exist_ok=True)
    # Stash name for iPad detection in sub-functions
    device_config = {**device_config, "name": device_name}

    frame_num = 1
    for entry in ULTIMATE_MIXED:
        layout = entry["layout"]

        if layout == "hero":
            out_path = os.path.join(out_dir, f"ultimate_{frame_num:02d}.png")
            generate_hero_frame(device_config, raw_dir, entry, out_path)
            frame_num += 1

        elif layout == "panoramic":
            left_out = os.path.join(out_dir, f"ultimate_{frame_num:02d}.png")
            right_out = os.path.join(out_dir, f"ultimate_{frame_num + 1:02d}.png")
            generate_mixed_panoramic(device_config, raw_dir, entry, left_out, right_out)
            frame_num += 2

        elif layout == "triple":
            out_paths = [
                os.path.join(out_dir, f"ultimate_{frame_num + i:02d}.png")
                for i in range(3)
            ]
            generate_triple_panoramic(device_config, raw_dir, entry, out_paths)
            frame_num += 3

        elif layout == "halved":
            out_path = os.path.join(out_dir, f"ultimate_{frame_num:02d}.png")
            generate_halved_frame(device_config, raw_dir, entry, out_path)
            frame_num += 1

        elif layout == "split":
            out_path = os.path.join(out_dir, f"ultimate_{frame_num:02d}.png")
            generate_mixed_split(device_config, raw_dir, entry, out_path)
            frame_num += 1

        elif layout == "watch_widget":
            out_path = os.path.join(out_dir, f"ultimate_{frame_num:02d}.png")
            generate_watch_widget_frame(device_config, entry, out_path)
            frame_num += 1


def generate_watch_widget_frame(device_config, frame_cfg, output_path):
    """Composite Apple Watch + Home Screen Widget on a single frame.

    Reads source images from absolute paths (the asset catalog) instead of the
    raw_dir, since these aren't simulator captures — they're shipped product
    art that already has a transparent / dark background.
    """
    canvas_w, canvas_h = device_config["canvas"]
    is_ipad = "ipad" in device_config.get("name", "")

    # 1. Background gradient + ambient effects (same as hero)
    canvas = create_gradient(canvas_w, canvas_h, frame_cfg["grad_top"], frame_cfg["grad_bot"])
    canvas = canvas.convert("RGBA")
    canvas = add_ambient_orbs(canvas, frame_cfg["orbs"], canvas_w, canvas_h)

    if frame_cfg.get("god_rays"):
        gr = frame_cfg["god_rays"]
        gr_color = gr if isinstance(gr, tuple) else GOLD
        canvas = add_god_rays(canvas, canvas_w, canvas_h, gr_color,
                              corner=frame_cfg.get("god_rays_corner", "top_right"))
    if frame_cfg.get("vignette", False):
        canvas = add_vignette(canvas, canvas_w, canvas_h, strength=0.35)
    if frame_cfg.get("color_grade") is not None:
        canvas = add_color_grade(canvas, canvas_w, canvas_h, warmth=frame_cfg["color_grade"])

    # 2. Headline + subtitle
    font_style = frame_cfg.get("headline_font", "headline")
    if font_style == "intro":
        hl_size = 120 if is_ipad else 100
    else:
        hl_size = 100 if is_ipad else 88
    sub_size = 55 if is_ipad else 46

    max_text_w = int(canvas_w * 0.92)
    headline_font = load_font(hl_size, bold=True)
    tmp_draw = ImageDraw.Draw(canvas)
    while hl_size > 60:
        bbox = tmp_draw.textbbox((0, 0), frame_cfg["headline"], font=headline_font)
        if (bbox[2] - bbox[0]) <= max_text_w:
            break
        hl_size -= 4
        headline_font = load_font(hl_size, bold=True)
    subtitle_font = load_font(sub_size, bold=False)

    text_y = int(canvas_h * 0.055)
    text_gap = int(canvas_h * 0.012)
    h_top, h_bot = frame_cfg["headline_grad"]
    hl_h = draw_gradient_text(canvas, frame_cfg["headline"], text_y, headline_font,
                              h_top, h_bot, canvas_w)
    sub_y = text_y + hl_h + text_gap
    draw_text_centered(canvas, frame_cfg["subtitle"], sub_y, subtitle_font, SUBTITLE_COLOR, canvas_w)

    # 3. Watch image — top of the device area, centered, ~40% canvas width
    watch_path = os.path.join(SCRIPT_DIR, "..", "swiftbible", "Assets.xcassets",
                              "OnboardingWatch.imageset", "watch.png")
    widget_medium_path = os.path.join(SCRIPT_DIR, "widget_assets", "widget_medium.png")
    widget_small_path = os.path.join(SCRIPT_DIR, "widget_assets", "widget_small.png")

    if not os.path.exists(watch_path) or not os.path.exists(widget_medium_path):
        print(f"  SKIP watch_widget (missing source)")
        return

    device_top = sub_y + int(canvas_h * 0.05)
    bottom_margin = int(canvas_h * 0.04)
    available_h = canvas_h - device_top - bottom_margin
    gap = int(canvas_h * 0.025)

    watch = Image.open(watch_path).convert("RGBA")
    widget_medium = Image.open(widget_medium_path).convert("RGBA")

    def scale_to_width(img, target_w):
        s = target_w / img.size[0]
        return img.resize((target_w, int(img.size[1] * s)), Image.LANCZOS)

    # Each tuple: (kind, image, angle_degrees, x_offset_px, overlap_with_previous)
    # x_offset shifts the item off-center; overlap pulls it up into the previous item.
    if is_ipad:
        widget_small = Image.open(widget_small_path).convert("RGBA") \
            if os.path.exists(widget_small_path) else None
        watch = scale_to_width(watch, int(canvas_w * 0.36))
        widget_medium = scale_to_width(widget_medium, int(canvas_w * 0.55))
        items = [("watch", watch, -7, -int(canvas_w * 0.10), 0)]
        if widget_small is not None:
            widget_small = scale_to_width(widget_small, int(canvas_w * 0.28))
            items.append(("widget_small", widget_small, 8, int(canvas_w * 0.16), int(canvas_h * 0.05)))
        items.append(("widget_medium", widget_medium, -4, -int(canvas_w * 0.04), int(canvas_h * 0.04)))
    else:
        widget_small = Image.open(widget_small_path).convert("RGBA") \
            if os.path.exists(widget_small_path) else None
        watch = scale_to_width(watch, int(canvas_w * 0.55))
        widget_medium = scale_to_width(widget_medium, int(canvas_w * 0.85))
        items = [("watch", watch, -7, -int(canvas_w * 0.10), 0)]
        if widget_small is not None:
            widget_small = scale_to_width(widget_small, int(canvas_w * 0.42))
            items.append(("widget_small", widget_small, 8, int(canvas_w * 0.18), int(canvas_h * 0.05)))
        items.append(("widget_medium", widget_medium, -4, -int(canvas_w * 0.02), int(canvas_h * 0.04)))

    # Rotation expands the bounding box — compute the actual rendered height
    # for each item (cos|θ| · h + sin|θ| · w, approximately) so the stack math
    # accounts for it and the bottom item doesn't overflow the canvas.
    import math
    def rotated_h(img, angle):
        a = math.radians(abs(angle))
        return int(abs(math.cos(a)) * img.size[1] + abs(math.sin(a)) * img.size[0])

    def stack_height(items_list):
        h = 0
        for i, (_, img, ang, _, overlap) in enumerate(items_list):
            h += rotated_h(img, ang)
            if i > 0:
                h -= overlap
                h += gap
        return h

    total_h = stack_height(items)
    if total_h > available_h:
        shrink = available_h / total_h
        scaled = []
        for kind, img, ang, xoff, overlap in items:
            new_w = int(img.size[0] * shrink)
            scaled.append((kind, scale_to_width(img, new_w), ang, int(xoff * shrink), int(overlap * shrink)))
        items = scaled
        gap = int(gap * shrink)
        total_h = stack_height(items)

    # Distribute leftover vertical space as extra spacing.
    extra_space = available_h - total_h
    if extra_space > 0 and len(items) > 1:
        gap += extra_space // (len(items) - 1)

    cursor_y = device_top
    widget_corner = int(canvas_w * 0.045)
    for i, (kind, img, angle, x_offset, overlap) in enumerate(items):
        if kind == "watch":
            corner = int(min(img.size) * 0.18)
        else:
            corner = widget_corner

        if i > 0:
            cursor_y -= overlap

        x_centered = (canvas_w - img.size[0]) // 2 + x_offset
        rounded = round_corners(img, corner)

        if angle != 0:
            rotated = rounded.rotate(angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))
            # Build a matching shadow (rotated)
            shadow_base = Image.new("RGBA", img.size, (0, 0, 0, 130))
            shadow_base = round_corners(shadow_base, corner)
            shadow_rot = shadow_base.rotate(angle, expand=True, resample=Image.BICUBIC, fillcolor=(0, 0, 0, 0))
            shadow_rot = shadow_rot.filter(ImageFilter.GaussianBlur(28))
            sx = (canvas_w - rotated.size[0]) // 2 + x_offset
            canvas.paste(shadow_rot, (sx + 10, cursor_y + 18), shadow_rot)
            canvas.paste(rotated, (sx, cursor_y), rotated)
            cursor_y += rotated.size[1] + gap
        else:
            shadow, off = create_shadow(img.size, corner, blur_radius=24, offset=(0, 12), opacity=130)
            canvas.paste(shadow, (x_centered - off[0], cursor_y - off[1]), shadow)
            canvas.paste(rounded, (x_centered, cursor_y), rounded)
            cursor_y += img.size[1] + gap

    # 4. Save
    final = canvas.crop((0, 0, canvas_w, canvas_h)).convert("RGB")
    final.save(output_path, "PNG", optimize=True)
    print(f"  -> {output_path}")


def generate_ultimate_strip(device_name, device_config, raw_dir, out_dir):
    """Generate the ultimate panoramic strip — devices fill frames edge-to-edge.

    Layout: text fills the top ~20%, device fills the remaining 80% and bleeds
    off the bottom edge. Devices sit on cut lines for panoramic continuity.
    No dead space — every pixel is text, device, or flowing gradient.
    """
    canvas_w, canvas_h = device_config["canvas"]
    corner_r = device_config["corner_radius"]
    is_ipad = "ipad" in device_name
    cfg = ULTIMATE_STRIP

    # Filter to screenshots that exist for this device
    shots = []
    for s in cfg["screenshots"]:
        if os.path.exists(os.path.join(raw_dir, f"{s['filename']}.png")):
            shots.append(s)

    if len(shots) < 2:
        print(f"  SKIP ultimate strip (need at least 2 screenshots)")
        return

    num_devices = len(shots)
    num_frames = num_devices + 1
    total_w = num_frames * canvas_w

    # 1. Panoramic gradient background
    canvas = create_bilinear_gradient(
        total_w, canvas_h,
        cfg["grad_tl"], cfg["grad_tr"],
        cfg["grad_bl"], cfg["grad_br"],
    )
    canvas = canvas.convert("RGBA")

    # 2. Ambient orbs
    canvas = add_ambient_orbs(canvas, cfg["orbs"], total_w, canvas_h)

    # 3. Fonts
    headline_size = 100 if is_ipad else 88
    subtitle_size = 50 if is_ipad else 42
    intro_size = 120 if is_ipad else 100
    headline_font = load_font(headline_size, bold=True)
    subtitle_font = load_font(subtitle_size, bold=False)
    intro_font = load_font(intro_size, bold=True)

    text_y = int(canvas_h * 0.055)
    text_gap = int(canvas_h * 0.012)

    # Device starts right below text — fills to bottom and beyond
    device_y_hero = int(canvas_h * 0.19)
    device_y_std = int(canvas_h * 0.22)

    # 4. Frame 0 — standalone hero: text + large centered device
    hero_cx = canvas_w // 2
    intro_hl_h = draw_gradient_text_at(
        canvas, cfg["intro_headline"], hero_cx, text_y,
        intro_font, (255, 255, 255), TINT_TEAL,
    )
    draw_text_at(
        canvas, cfg["intro_subtitle"], hero_cx,
        text_y + intro_hl_h + text_gap,
        subtitle_font, SUBTITLE_COLOR,
    )

    hero_shot = shots[0]
    hero_raw = Image.open(os.path.join(raw_dir, f"{hero_shot['filename']}.png")).convert("RGBA")
    place_device_at(
        canvas, hero_raw, hero_cx, device_y_hero,
        hero_shot.get("scale", 0.92), corner_r, canvas_w,
        hero_shot.get("angle", 0),
    )

    # 5. Bridge text in frame 1
    bridge_cx = int(canvas_w * 1.5)
    bridge_hl_h = draw_gradient_text_at(
        canvas, cfg.get("bridge_headline", ""), bridge_cx, text_y,
        headline_font, (255, 255, 255), TINT_TEAL,
    )
    if cfg.get("bridge_subtitle"):
        draw_text_at(
            canvas, cfg["bridge_subtitle"], bridge_cx,
            text_y + bridge_hl_h + text_gap,
            subtitle_font, SUBTITLE_COLOR,
        )

    # 6. Remaining devices on cut lines (panoramic split)
    for j, shot in enumerate(shots[1:]):
        cut_x = (j + 2) * canvas_w

        # First panoramic device shifts left to fill bridge frame
        if j == 0:
            cut_x -= int(canvas_w * 0.15)

        raw = Image.open(os.path.join(raw_dir, f"{shot['filename']}.png")).convert("RGBA")
        angle = shot.get("angle", 0)
        scale = shot.get("scale", 0.85)
        is_hero = scale >= 0.90
        dy = device_y_hero if is_hero else device_y_std

        place_device_at(canvas, raw, cut_x, dy, scale, corner_r, canvas_w, angle)

        # Headline centered in the frame to the RIGHT of the cut
        if shot["headline"]:
            hl_grad_bot = TINT_TEAL_HERO if is_hero else TINT_NEUTRAL
            headline_cx = (j + 2) * canvas_w + canvas_w // 2

            hl_h = draw_gradient_text_at(
                canvas, shot["headline"], headline_cx, text_y,
                headline_font, (255, 255, 255), hl_grad_bot,
            )
            if shot["subtitle"]:
                draw_text_at(
                    canvas, shot["subtitle"], headline_cx,
                    text_y + hl_h + text_gap,
                    subtitle_font, SUBTITLE_COLOR_STRIP,
                )

    # 7. Outro text centered in last frame
    outro_cx = int((num_frames - 0.5) * canvas_w)
    outro_hl_h = draw_gradient_text_at(
        canvas, cfg["outro_headline"], outro_cx, text_y,
        intro_font, (255, 255, 255), TINT_WARM,
    )
    draw_text_at(
        canvas, cfg["outro_subtitle"], outro_cx,
        text_y + outro_hl_h + text_gap,
        subtitle_font, SUBTITLE_COLOR,
    )

    # 8. Slice into individual frames
    os.makedirs(out_dir, exist_ok=True)
    for i in range(num_frames):
        frame = canvas.crop((i * canvas_w, 0, (i + 1) * canvas_w, canvas_h))
        frame = frame.convert("RGB")
        out_path = os.path.join(out_dir, f"ultimate_{i + 1:02d}.png")
        frame.save(out_path, "PNG", optimize=True)
        print(f"  -> {out_path}")


def create_faux_dark(img):
    """Create a rough dark-mode approximation by inverting bright areas."""
    # Simple approach: invert the image and reduce brightness
    inverted = ImageChops.invert(img.convert("RGB"))
    # Darken it
    darkened = Image.eval(inverted, lambda x: int(x * 0.7))
    return darkened.convert("RGBA")


def main():
    """Generate ONLY the ultimate (mixed-layout) marketing set.

    Other variants (basic per-slot, panoramic pair, panoramic strip, legacy
    ultimate strip) were dropped — only the mixed-layout set goes to App
    Store Connect, so we don't waste cycles regenerating the rest.
    """
    for device_name, device_config in DEVICES.items():
        raw_dir = os.path.join(SCRIPT_DIR, "screenshots", device_name)
        out_dir = os.path.join(SCRIPT_DIR, "marketing", "ultimate", device_name)

        print(f"\n=== {device_name} (ultimate) ===")
        generate_ultimate_mixed(device_name, device_config, raw_dir, out_dir)

    print("\nDone! Marketing screenshots saved to marketing/ultimate/")


if __name__ == "__main__":
    main()
