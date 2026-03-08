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
        "headline": "Read the Word of God",
        "subtitle": "Multiple translations at your fingertips",
        "style": "straight",
        "grad_top": (25, 12, 55),
        "grad_bot": (55, 20, 85),
        "orbs": [(0.2, 0.3, 0.5, (120, 50, 200), 50), (0.8, 0.7, 0.4, (80, 30, 160), 35)],
        "headline_grad": ((255, 255, 255), (220, 200, 255)),
    },
    {
        "filename": "02_chapters",
        "headline": "Navigate with Ease",
        "subtitle": "Chapter summaries guide your study",
        "style": "tilt_right",
        "grad_top": (10, 20, 50),
        "grad_bot": (20, 40, 80),
        "orbs": [(0.7, 0.25, 0.45, (40, 80, 200), 45), (0.15, 0.6, 0.35, (30, 60, 170), 30)],
        "headline_grad": ((255, 255, 255), (180, 210, 255)),
    },
    {
        "filename": "03_verses",
        "headline": "Every Verse, Beautifully",
        "subtitle": "With Jesus's words in red",
        "style": "tilt_left",
        "grad_top": (50, 10, 18),
        "grad_bot": (80, 22, 35),
        "orbs": [(0.3, 0.35, 0.5, (180, 40, 60), 45), (0.85, 0.65, 0.3, (140, 25, 45), 30)],
        "headline_grad": ((255, 255, 255), (255, 200, 200)),
    },
    {
        "filename": "04_verse_options",
        "headline": "Study Tools Built In",
        "subtitle": "Long press any verse",
        "style": "straight",
        "grad_top": (10, 35, 38),
        "grad_bot": (18, 60, 62),
        "orbs": [(0.5, 0.3, 0.5, (30, 160, 150), 45), (0.1, 0.7, 0.35, (20, 120, 115), 30)],
        "headline_grad": ((255, 255, 255), (180, 255, 245)),
        "badges": ["Copy", "Bookmark", "Highlight", "Explain", "Share"],
    },
    {
        "filename": "05_translations",
        "headline": "Light & Dark Mode",
        "subtitle": "4 translations with your preferred style",
        "style": "split",  # light/dark split
        "grad_top": (40, 32, 10),
        "grad_bot": (65, 50, 18),
        "orbs": [(0.5, 0.3, 0.55, (180, 140, 40), 45), (0.15, 0.7, 0.3, (140, 110, 20), 25)],
        "headline_grad": ((255, 255, 255), (255, 230, 160)),
    },
    {
        "filename": "06_devotional",
        "headline": "Daily Devotionals",
        "subtitle": "Start each day with scripture",
        "style": "tilt_right",
        "grad_top": (48, 28, 10),
        "grad_bot": (72, 42, 14),
        "orbs": [(0.6, 0.3, 0.45, (200, 130, 40), 45), (0.2, 0.65, 0.35, (160, 100, 30), 30)],
        "headline_grad": ((255, 255, 255), (255, 220, 170)),
    },
    {
        "filename": "07_settings",
        "headline": "Customize Everything",
        "subtitle": "Fonts, colors, and hidden texts to explore",
        "style": "straight",
        "grad_top": (22, 22, 28),
        "grad_bot": (42, 42, 52),
        "orbs": [(0.3, 0.35, 0.4, (80, 80, 120), 35), (0.75, 0.6, 0.3, (60, 60, 100), 25)],
        "headline_grad": ((255, 255, 255), (200, 200, 220)),
    },
]

# --- Panoramic Pairs (continuous background split across two frames) ---

PANORAMIC_PAIRS = [
    {
        "left_filename": "02_chapters",
        "right_filename": "03_verses",
        "left_headline": "Navigate with Ease",
        "left_subtitle": "Chapter summaries guide your study",
        "right_headline": "Every Verse, Beautifully",
        "right_subtitle": "With Jesus's words in red",
        "left_angle": 5,
        "right_angle": -5,
        "grad_tl": (10, 20, 55),
        "grad_tr": (55, 10, 22),
        "grad_bl": (20, 35, 80),
        "grad_br": (80, 22, 38),
        "orbs": [
            (0.15, 0.3, 0.22, (40, 80, 200), 50),
            (0.5, 0.45, 0.28, (120, 40, 160), 55),
            (0.85, 0.35, 0.22, (180, 40, 60), 50),
            (0.35, 0.7, 0.18, (60, 60, 180), 30),
            (0.65, 0.65, 0.18, (160, 30, 80), 30),
        ],
        "left_headline_grad": ((255, 255, 255), (180, 210, 255)),
        "right_headline_grad": ((255, 255, 255), (255, 200, 200)),
    },
    {
        "left_filename": "06_devotional",
        "right_filename": "07_settings",
        "left_headline": "Daily Devotionals",
        "left_subtitle": "Start each day with scripture",
        "right_headline": "Customize Everything",
        "right_subtitle": "Fonts, colors, and hidden texts",
        "left_angle": 5,
        "right_angle": -5,
        "grad_tl": (48, 28, 10),
        "grad_tr": (22, 22, 32),
        "grad_bl": (72, 42, 14),
        "grad_br": (42, 42, 55),
        "orbs": [
            (0.2, 0.3, 0.22, (200, 130, 40), 50),
            (0.5, 0.4, 0.25, (130, 90, 50), 45),
            (0.8, 0.35, 0.22, (80, 80, 120), 40),
            (0.35, 0.65, 0.16, (160, 100, 30), 28),
            (0.7, 0.7, 0.16, (60, 60, 100), 25),
        ],
        "left_headline_grad": ((255, 255, 255), (255, 220, 170)),
        "right_headline_grad": ((255, 255, 255), (200, 200, 220)),
    },
]

# --- Panoramic Strip (one continuous canvas sliced into frames) ---
# Devices are centered on the cut lines between frames, so each device
# is split 50/50 across two adjacent screenshots. Headlines straddle too.

PANORAMIC_STRIP = {
    "screenshots": [
        {"filename": "01_bible_books", "headline": "The Word of God",
         "subtitle": "Multiple translations at your fingertips"},
        {"filename": "02_chapters", "headline": "Navigate with Ease",
         "subtitle": "Chapter summaries guide your study"},
        {"filename": "03_verses", "headline": "Every Verse, Beautifully",
         "subtitle": "With Jesus's words in red"},
        {"filename": "04_verse_options", "headline": "Study Tools Built In",
         "subtitle": "Long press any verse"},
        {"filename": "05_translations", "headline": "Light & Dark Mode",
         "subtitle": "Read comfortably, any time"},
        # Dark mode device — no headline; visual contrast speaks for itself
        {"filename": "05_translations_dark", "headline": "", "subtitle": ""},
        {"filename": "06_devotional", "headline": "Daily Devotionals",
         "subtitle": "Start each day with scripture"},
        {"filename": "07_settings", "headline": "Customize Everything",
         "subtitle": "Fonts, colors, and hidden texts"},
        {"filename": "01_bible_books_dark", "headline": "Read Anytime",
         "subtitle": "Beautiful in every light"},
    ],
    "intro_headline": "SwiftBible",
    "intro_subtitle": "Open Source Bible App",
    "outro_headline": "Download Free",
    "outro_subtitle": "Available on the App Store",
    # Horizontal color flow: purple (left) → amber (right)
    "grad_tl": (25, 12, 55),
    "grad_tr": (48, 28, 10),
    "grad_bl": (45, 18, 75),
    "grad_br": (65, 38, 12),
    "orbs": [
        (0.05, 0.30, 0.06, (120, 50, 200), 55),
        (0.15, 0.55, 0.05, (40, 80, 200), 40),
        (0.25, 0.35, 0.06, (180, 40, 60), 45),
        (0.35, 0.50, 0.07, (120, 40, 160), 50),
        (0.45, 0.40, 0.06, (30, 160, 150), 45),
        (0.55, 0.55, 0.06, (80, 60, 180), 42),
        (0.65, 0.35, 0.06, (200, 130, 40), 40),
        (0.75, 0.50, 0.07, (160, 40, 100), 45),
        (0.85, 0.40, 0.06, (200, 160, 50), 38),
        (0.95, 0.35, 0.06, (80, 80, 120), 35),
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
        canvas, shot_config["subtitle"], subtitle_y, subtitle_font, (180, 180, 200, 230), canvas_w
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
        left_center, left_sub_y, subtitle_font, (180, 180, 200, 230),
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
        right_center, right_sub_y, subtitle_font, (180, 180, 200, 230),
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
        intro_font, (255, 255, 255), (220, 200, 255),
    )
    draw_text_at(
        canvas, cfg["intro_subtitle"], intro_cx,
        text_y + intro_hl_h + text_gap,
        subtitle_font, (180, 180, 200, 230),
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
                headline_font, (255, 255, 255), (220, 220, 240),
            )
            if shot["subtitle"]:
                draw_text_at(
                    canvas, shot["subtitle"], cut_x,
                    text_y + hl_h + text_gap,
                    subtitle_font, (180, 180, 200, 200),
                )

    # 6. Outro text — shifted RIGHT within last frame to avoid last device bleed
    outro_cx = int((num_frames - 0.35) * canvas_w)
    outro_hl_h = draw_gradient_text_at(
        canvas, cfg["outro_headline"], outro_cx, text_y,
        intro_font, (255, 255, 255), (255, 230, 180),
    )
    draw_text_at(
        canvas, cfg["outro_subtitle"], outro_cx,
        text_y + outro_hl_h + text_gap,
        subtitle_font, (180, 180, 200, 230),
    )

    # 7. Slice into individual frames
    os.makedirs(out_dir, exist_ok=True)
    for i in range(num_frames):
        frame = canvas.crop((i * canvas_w, 0, (i + 1) * canvas_w, canvas_h))
        frame = frame.convert("RGB")
        out_path = os.path.join(out_dir, f"strip_{i + 1:02d}.png")
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

    print("\nDone! Marketing screenshots saved to marketing/")
    print("Panoramic pairs saved to marketing/panoramic/")
    print("Panoramic strip saved to marketing/strip/")


if __name__ == "__main__":
    main()
