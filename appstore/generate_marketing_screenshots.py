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
    "iphone-6.5": {
        "canvas": (1284, 2778),
        "screenshot_scale": 0.75,
        "corner_radius": 52,
    },
    "ipad-13": {
        "canvas": (2048, 2732),
        "screenshot_scale": 0.70,
        "corner_radius": 30,
    },
}

# --- Screenshot Definitions ---
# (filename, headline, subtitle, style, gradient_top, gradient_bottom, orb_color, headline_gradient)

SCREENSHOTS = [
    {
        "filename": "01_bible_books",
        "headline": "The Word at Your Fingertips",        # Gain Framing (#53)
        "subtitle": "Three translations, one beautiful app",
        "style": "straight",
        "grad_top": (13, 18, 45),       # deep navy tint
        "grad_bot": (20, 30, 65),
        "orbs": [(0.2, 0.3, 0.5, ACCENT, 50), (0.8, 0.7, 0.4, CYAN, 35)],
        "headline_grad": ((255, 255, 255), TINT_TEAL),
    },
    {
        "filename": "02_chapters",
        "headline": "Every Chapter, Summarized",           # Competence Signalling (#95)
        "subtitle": "Know what you're reading before you start",
        "style": "tilt_right",
        "grad_top": (8, 22, 48),        # deep blue (navy family)
        "grad_bot": (14, 38, 72),
        "orbs": [(0.7, 0.25, 0.45, CYAN, 45), (0.15, 0.6, 0.35, GREEN, 30)],
        "headline_grad": ((255, 255, 255), TINT_BLUE),
    },
    {
        "filename": "03_verses",
        "headline": "Jesus's Words in Red",                # Von Restorff (#1)
        "subtitle": "The tradition, beautifully preserved",
        "style": "tilt_left",
        "grad_top": (45, 12, 18),       # deep warm red (ribbon red family)
        "grad_bot": (72, 20, 30),
        "orbs": [(0.3, 0.35, 0.5, RED_DARK, 45), (0.85, 0.65, 0.3, RED, 30)],
        "headline_grad": ((255, 255, 255), TINT_RED),
    },
    {
        "filename": "04_verse_options",
        "headline": "Long Press. Discover More.",          # Curiosity Gap (#103)
        "subtitle": "Bookmark, highlight, take notes, share",
        "style": "straight",
        "grad_top": (8, 32, 35),        # deep teal (accent family)
        "grad_bot": (14, 55, 58),
        "orbs": [(0.5, 0.3, 0.5, ACCENT, 45), (0.1, 0.7, 0.35, GREEN, 30)],
        "headline_grad": ((255, 255, 255), TINT_TEAL),
        "badges": ["Copy", "Bookmark", "Highlight", "Explain", "Share"],
    },
    {
        "filename": "05_translations",
        "headline": "Beautiful in Any Light",              # Aesthetic-Usability (#122)
        "subtitle": "Four translations with your preferred style",
        "style": "split",
        "grad_top": (38, 30, 10),       # warm amber/gold (brand warm family)
        "grad_bot": (60, 48, 16),
        "orbs": [(0.5, 0.3, 0.55, GOLD, 45), (0.15, 0.7, 0.3, GOLD, 25)],
        "headline_grad": ((255, 255, 255), TINT_GOLD),
    },
    {
        "filename": "06_devotional",
        "headline": "Start Each Day in Scripture",         # Tiny Habits (#114)
        "subtitle": "A new devotional, every morning",
        "style": "tilt_right",
        "grad_top": (42, 26, 10),       # warm brown (cover dark family)
        "grad_bot": (65, 40, 14),
        "orbs": [(0.6, 0.3, 0.45, GOLD, 45), (0.2, 0.65, 0.35, GOLD, 30)],
        "headline_grad": ((255, 255, 255), TINT_WARM),
    },
    {
        "filename": "07_settings",
        "headline": "Make It Yours",                       # Autonomy Bias (#108)
        "subtitle": "Fonts, colors, and hidden texts to unlock",
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
        "right_filename": "07_settings",
        "left_headline": "Start Each Day in Scripture",    # Tiny Habits (#114)
        "left_subtitle": "A new devotional, every morning",
        "right_headline": "Make It Yours",                  # Autonomy Bias (#108)
        "right_subtitle": "Fonts, colors, and hidden texts to unlock",
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
        {"filename": "01_bible_books", "headline": "The Word at Your Fingertips",
         "subtitle": "Three translations, one beautiful app"},
        {"filename": "02_chapters", "headline": "Every Chapter, Summarized",
         "subtitle": "Know what you're reading before you start"},
        {"filename": "03_verses", "headline": "Jesus's Words in Red",
         "subtitle": "The tradition, beautifully preserved"},
        {"filename": "04_verse_options", "headline": "Long Press. Discover More.",
         "subtitle": "Bookmark, highlight, take notes, share"},
        {"filename": "05_translations", "headline": "Beautiful in Any Light",
         "subtitle": "Read comfortably, any time"},
        # Dark mode device — no headline; visual contrast speaks for itself
        {"filename": "05_translations_dark", "headline": "", "subtitle": ""},
        {"filename": "06_devotional", "headline": "Start Each Day in Scripture",
         "subtitle": "A new devotional, every morning"},
        {"filename": "07_settings", "headline": "Make It Yours",
         "subtitle": "Fonts, colors, and hidden texts to unlock"},
        {"filename": "01_bible_books_dark", "headline": "Read Anytime",
         "subtitle": "Beautiful in every light"},
    ],
    "intro_headline": "SwiftBible",
    "intro_subtitle": "Open Source Bible App",
    "outro_headline": "Download Free",
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


def draw_gradient_text(canvas, text, y, font, color_top, color_bottom, canvas_w):
    """Draw headline text with a vertical gradient fill."""
    # Get text dimensions
    tmp_draw = ImageDraw.Draw(canvas)
    bbox = tmp_draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (canvas_w - text_w) // 2

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
        # 1. HERO — straight, large. Primacy Effect (#58): strongest first.
        {"filename": "01_bible_books",
         "headline": "The Word at Your Fingertips",
         "subtitle": "Three translations, one beautiful app",
         "angle": 0, "scale": 0.75},
        # 2. Tilt right, standard. Competence Signalling (#95): specific benefit.
        {"filename": "02_chapters",
         "headline": "Every Chapter, Summarized",
         "subtitle": "Know what you're reading before you start",
         "angle": 5, "scale": 0.65},
        # 3. Tilt left. Von Restorff (#1): the distinctive red-letter feature.
        {"filename": "03_verses",
         "headline": "Jesus's Words in Red",
         "subtitle": "The tradition, beautifully preserved",
         "angle": -3, "scale": 0.68},
        # 4. Straight — anchors "tools" message. Curiosity Gap (#103).
        {"filename": "04_verse_options",
         "headline": "Long Press. Discover More.",
         "subtitle": "Bookmark, highlight, take notes, share",
         "angle": 0, "scale": 0.65},
        # 5. Right tilt — light mode, headline on next frame with dark pair.
        {"filename": "05_translations",
         "headline": "Read Anytime",
         "subtitle": "Beautiful in every light",
         "angle": 4, "scale": 0.62},
        # 6. Left tilt — dark mode mirror. Aesthetic-Usability (#122).
        {"filename": "05_translations_dark",
         "headline": "Beautiful in Any Light",
         "subtitle": "Read comfortably, day or night",
         "angle": -4, "scale": 0.62},
        # 7. HERO — straight, large. Peak moment (#117): the devotional climax.
        {"filename": "06_devotional",
         "headline": "Start Each Day in Scripture",
         "subtitle": "A new devotional, every morning",
         "angle": 0, "scale": 0.75},
        # 8. Left tilt — pattern break. Autonomy Bias (#108).
        {"filename": "07_settings",
         "headline": "Make It Yours",
         "subtitle": "Fonts, colors, and hidden texts to unlock",
         "angle": -5, "scale": 0.65},
        # 9. Right tilt — visual bookend (no headline, outro CTA follows).
        {"filename": "01_bible_books_dark",
         "headline": "", "subtitle": "",
         "angle": 3, "scale": 0.68},
    ],
    "intro_headline": "SwiftBible",
    "intro_subtitle": "Open Source Bible App",
    "bridge_headline": "Open Source & Free Forever",
    "bridge_subtitle": "No ads. No tracking. Just scripture.",
    "outro_headline": "Download Free",
    "outro_subtitle": "Available on the App Store",
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


def generate_ultimate_strip(device_name, device_config, raw_dir, out_dir):
    """Generate the ultimate panoramic strip with per-device angles, scales, and hero moments.

    Unlike the standard strip (alternating 3/-3), this uses intentionally varied
    angles and two hero devices at larger scale for visual rhythm.
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

    # 1. Background
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
    intro_size = 130 if is_ipad else 110
    headline_font = load_font(headline_size, bold=True)
    subtitle_font = load_font(subtitle_size, bold=False)
    intro_font = load_font(intro_size, bold=True)

    text_y = int(canvas_h * 0.07)
    text_gap = int(canvas_h * 0.014)

    # 4. Frame 0 — standalone hero (not panoramic)
    #    Intro text + first device centered in frame, no cut-line bleed
    hero_cx = canvas_w // 2
    intro_hl_h = draw_gradient_text_at(
        canvas, cfg["intro_headline"], hero_cx, text_y,
        intro_font, (255, 255, 255), TINT_TEAL,
    )
    intro_sub_y = text_y + intro_hl_h + text_gap
    draw_text_at(
        canvas, cfg["intro_subtitle"], hero_cx,
        intro_sub_y, subtitle_font, SUBTITLE_COLOR,
    )

    # Place hero device centered in frame 0
    hero_shot = shots[0]
    hero_raw = Image.open(os.path.join(raw_dir, f"{hero_shot['filename']}.png")).convert("RGBA")
    hero_scale = hero_shot.get("scale", 0.75)
    hero_device_y = int(canvas_h * 0.20)
    place_device_at(
        canvas, hero_raw, hero_cx, hero_device_y,
        hero_scale, corner_r, canvas_w, hero_shot.get("angle", 0),
    )

    # 4b. Trust bridge text — frame 1 (between hero and first panoramic device)
    #     Power of Free (#113) + Transparency Effect (#85)
    bridge_cx = int(canvas_w * 1.5)  # center of frame 1
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

    # 5. Remaining devices — on cut lines (panoramic)
    for j, shot in enumerate(shots[1:]):
        cut_x = (j + 2) * canvas_w  # skip frame 0, start cuts at frame 1/2 boundary

        raw = Image.open(os.path.join(raw_dir, f"{shot['filename']}.png")).convert("RGBA")

        angle = shot.get("angle", 0)
        scale = shot.get("scale", 0.68)

        # Heroes sit slightly higher for prominence
        if scale >= 0.75:
            device_y = int(canvas_h * 0.22)
        else:
            device_y = int(canvas_h * 0.25)

        place_device_at(
            canvas, raw, cut_x, device_y,
            scale, corner_r, canvas_w, angle,
        )

        # Headline + subtitle — offset into an adjacent frame so text isn't
        # split across two frames at the cut line.
        # Last device: shift LEFT (right frame is the outro).
        # All others: shift RIGHT (into the next frame).
        if shot["headline"]:
            if scale >= 0.75:
                hl_grad_bot = TINT_TEAL_HERO
            else:
                hl_grad_bot = TINT_NEUTRAL

            # Center headline in the RIGHT frame (the frame after the cut)
            headline_cx = cut_x + canvas_w // 2

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

    # 6. Outro text — centered in the last frame
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

    # 7. Slice into individual frames
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
    for device_name, device_config in DEVICES.items():
        raw_dir = os.path.join(SCRIPT_DIR, "screenshots", device_name)
        out_dir = os.path.join(SCRIPT_DIR, "marketing", device_name)
        os.makedirs(out_dir, exist_ok=True)

        print(f"\n=== {device_name} ===")

        for shot_config in SCREENSHOTS:
            output_path = os.path.join(out_dir, f"{shot_config['filename']}.png")
            generate_screenshot(device_name, device_config, raw_dir, shot_config, output_path)

    # --- Panoramic Pairs ---
    for device_name, device_config in DEVICES.items():
        raw_dir = os.path.join(SCRIPT_DIR, "screenshots", device_name)
        pano_dir = os.path.join(SCRIPT_DIR, "marketing", "panoramic", device_name)
        os.makedirs(pano_dir, exist_ok=True)

        print(f"\n=== {device_name} (panoramic) ===")

        for pair_config in PANORAMIC_PAIRS:
            generate_panoramic_pair(device_name, device_config, raw_dir, pair_config, pano_dir)

    # --- Panoramic Strip (full continuous canvas) ---
    for device_name, device_config in DEVICES.items():
        raw_dir = os.path.join(SCRIPT_DIR, "screenshots", device_name)
        strip_dir = os.path.join(SCRIPT_DIR, "marketing", "strip", device_name)

        print(f"\n=== {device_name} (strip) ===")

        generate_panoramic_strip(device_name, device_config, raw_dir, strip_dir)

    # --- Ultimate Strip (mixed angles, heroes, Gatena-optimized copy) ---
    for device_name, device_config in DEVICES.items():
        raw_dir = os.path.join(SCRIPT_DIR, "screenshots", device_name)
        ultimate_dir = os.path.join(SCRIPT_DIR, "marketing", "ultimate", device_name)

        print(f"\n=== {device_name} (ultimate) ===")

        generate_ultimate_strip(device_name, device_config, raw_dir, ultimate_dir)

    print("\nDone! Marketing screenshots saved to marketing/")
    print("Panoramic pairs saved to marketing/panoramic/")
    print("Panoramic strip saved to marketing/strip/")
    print("Ultimate strip saved to marketing/ultimate/")


if __name__ == "__main__":
    main()
