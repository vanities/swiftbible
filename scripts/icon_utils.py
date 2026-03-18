"""Shared utilities for generating SwiftBible app icon variants.

Uses All Sizes mode: generates every required size from a 1024px source.
Only the "Any" appearance — no dark/tinted in alternates (causes blank icons).
"""

import json
import os
from PIL import Image

XCASSETS = os.path.join(os.path.dirname(__file__), "..", "swiftbible", "Assets.xcassets")
ALT_ICONS = os.path.join(os.path.dirname(__file__), "..", "swiftbible", "AltIcons")
ICON_ASSETS = os.path.join(os.path.dirname(__file__), "..", "icon_assets")

# Every size needed, matching the primary AppIcon structure (Any appearance only)
# (size_points, scale, pixel_size)
ICON_SIZES = [
    ("20x20", "2x", 40),
    ("20x20", "3x", 60),
    ("29x29", "2x", 58),
    ("29x29", "3x", 87),
    ("38x38", "2x", 76),
    ("38x38", "3x", 114),
    ("40x40", "2x", 80),
    ("40x40", "3x", 120),
    ("60x60", "2x", 120),
    ("60x60", "3x", 180),
    ("64x64", "2x", 128),
    ("64x64", "3x", 192),
    ("68x68", "2x", 136),
    ("76x76", "2x", 152),
    ("83.5x83.5", "2x", 167),
    ("1024x1024", None, 1024),
]


def generate_contents_json():
    """Generate Contents.json with all sizes and all appearances (any/dark/tinted).

    Uses the same image file for all appearances since our themed icons
    are designed to work in any mode.
    """
    images = []
    for size, scale, px in ICON_SIZES:
        suffix = f"@{scale}" if scale else ""
        filename = f"{px}{suffix}.png"

        # Any appearance
        entry = {
            "filename": filename,
            "idiom": "universal",
            "platform": "ios",
            "size": size,
        }
        if scale:
            entry["scale"] = scale
        images.append(entry)

        # Dark appearance (same file)
        dark_entry = {
            "appearances": [{"appearance": "luminosity", "value": "dark"}],
            "filename": filename,
            "idiom": "universal",
            "platform": "ios",
            "size": size,
        }
        if scale:
            dark_entry["scale"] = scale
        images.append(dark_entry)

        # Tinted appearance (same file)
        tinted_entry = {
            "appearances": [{"appearance": "luminosity", "value": "tinted"}],
            "filename": filename,
            "idiom": "universal",
            "platform": "ios",
            "size": size,
        }
        if scale:
            tinted_entry["scale"] = scale
        images.append(tinted_entry)

    return {"images": images, "info": {"author": "xcode", "version": 1}}


def make_dark_variant(light_img, bible_mask):
    """Create dark mode variant: colored bible shape on transparent background."""
    size = light_img.size[0]
    mask_img = bible_mask.resize((size, size), Image.LANCZOS)
    light_rgb = light_img.convert("RGB")
    samples = []
    for sx, sy in [(100, 100), (900, 100), (100, 900), (900, 900)]:
        if sx < size and sy < size:
            samples.append(light_rgb.getpixel((sx, sy)))
    if samples:
        fill_color = tuple(sum(c) // len(samples) for c in zip(*samples))
    else:
        fill_color = (180, 180, 180)
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bible_layer = Image.new("RGBA", (size, size), fill_color + (0,))
    bible_layer.putalpha(mask_img)
    return Image.alpha_composite(result, bible_layer)


def make_tinted_variant(bible_mask):
    """Create tinted variant: gray bible shape on black background."""
    size = 1024
    mask_img = bible_mask.resize((size, size), Image.LANCZOS)
    result = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    bible_layer = Image.new("RGBA", (size, size), (190, 190, 190, 0))
    bible_layer.putalpha(mask_img)
    return Image.alpha_composite(result, bible_layer)


def save_complete_icon(img, icon_name, bible_mask=None, save_previews=True):
    """Save icon with all required sizes for xcassets.

    Args:
        img: PIL Image (1024x1024 light variant)
        icon_name: e.g. "AppIcon-Rose"
        bible_mask: PIL Image mask for generating dark/tinted previews
        save_previews: Whether to save preview images
    """
    rgb = img.convert("RGB")

    # === xcassets appiconset (All Sizes, Any appearance only) ===
    appiconset_dir = os.path.join(XCASSETS, f"{icon_name}.appiconset")
    if os.path.exists(appiconset_dir):
        for f in os.listdir(appiconset_dir):
            os.remove(os.path.join(appiconset_dir, f))
    os.makedirs(appiconset_dir, exist_ok=True)

    for size, scale, px in ICON_SIZES:
        suffix = f"@{scale}" if scale else ""
        filename = f"{px}{suffix}.png"
        resized = rgb.resize((px, px), Image.LANCZOS)
        resized.save(os.path.join(appiconset_dir, filename))

    contents = generate_contents_json()
    with open(os.path.join(appiconset_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
        f.write("\n")

    print(f"  xcassets: {icon_name}.appiconset ({len(ICON_SIZES)} sizes)")

    # Generate dark/tinted for preview images only (not in xcassets)
    if bible_mask is not None:
        dark = make_dark_variant(rgb, bible_mask)
        tinted = make_tinted_variant(bible_mask)
    else:
        dark = rgb
        tinted = rgb

    # === AltIcons (preview images only) ===
    os.makedirs(ALT_ICONS, exist_ok=True)

    if save_previews:
        preview_name = icon_name.replace("AppIcon-", "Icon-")
        # Light preview
        preview_path = os.path.join(ALT_ICONS, f"{preview_name}1024x1024.png")
        rgb.save(preview_path)
        # Dark preview
        dark.save(os.path.join(ALT_ICONS, f"{preview_name}-Dark1024x1024.png"), "PNG")
        # Tinted preview
        tinted.save(os.path.join(ALT_ICONS, f"{preview_name}-Tinted1024x1024.png"), "PNG")
        print(f"  Previews: {preview_name} (light + dark + tinted)")
        # icon_assets reference
        ref_path = os.path.join(ICON_ASSETS, f"{preview_name}1024\u00d71024.png")
        rgb.save(ref_path)
