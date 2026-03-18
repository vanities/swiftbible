#!/usr/bin/env python3
"""
Generate color-variant app icons by hue-shifting the source Light and Dark icons.

Variants:
  Rose   — pink/rose gradient   (hue shift +240°)
  Gold   — warm gold/amber      (hue shift -40°)
  Purple — royal purple          (hue shift +180°)
  Ocean  — deep blue             (hue shift +120°)

Outputs:
  swiftbible/AltIcons/AppIcon-{Variant}Light@2x.png   (120x120)
  swiftbible/AltIcons/AppIcon-{Variant}Light@3x.png   (180x180)
  swiftbible/AltIcons/AppIcon-{Variant}Dark@2x.png    (120x120)
  swiftbible/AltIcons/AppIcon-{Variant}Dark@3x.png    (180x180)
  icon_assets/Icon-{Variant}-Light-1024×1024.png      (1024x1024 preview)
  icon_assets/Icon-{Variant}-Dark-1024×1024.png       (1024x1024 preview)

Usage:
  uv run python scripts/generate_icon_variants.py
"""

import os
from pathlib import Path

import numpy as np
from PIL import Image

# ── Project root (one level up from scripts/) ────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent

ICON_ASSETS = ROOT / "icon_assets"
ALT_ICONS = ROOT / "swiftbible" / "AltIcons"

# Source icons (note: filename uses × not x)
LIGHT_SRC = ICON_ASSETS / "Icon-Light-1024×1024.png"
DARK_SRC = ICON_ASSETS / "Icon-Dark-1024×1024.png"

# ── Variant definitions ──────────────────────────────────────────────────────
VARIANTS = [
    {"name": "Rose",   "hue_shift": 240},
    {"name": "Gold",   "hue_shift": -40},
    {"name": "Purple", "hue_shift": 180},
    {"name": "Ocean",  "hue_shift": 120},
]

# iOS alternate icon sizes
ALT_ICON_SIZES = {
    "@2x": 120,
    "@3x": 180,
}


def hue_shift_image(img: Image.Image, shift_degrees: float) -> Image.Image:
    """Shift the hue of an image by `shift_degrees`, preserving alpha."""
    # Separate alpha if present
    has_alpha = img.mode == "RGBA"
    if has_alpha:
        r, g, b, a = img.split()
        rgb_img = Image.merge("RGB", (r, g, b))
    else:
        rgb_img = img.convert("RGB")
        a = None

    # Convert to HSV via numpy for speed
    hsv_img = rgb_img.convert("HSV")
    hsv_arr = np.array(hsv_img, dtype=np.int16)

    # Pillow HSV: H is 0-255 (maps to 0-360°)
    # shift_degrees → shift in 0-255 space
    shift_units = int(round(shift_degrees / 360.0 * 256))
    hsv_arr[:, :, 0] = (hsv_arr[:, :, 0] + shift_units) % 256

    hsv_shifted = Image.fromarray(hsv_arr.astype(np.uint8), mode="HSV")
    rgb_result = hsv_shifted.convert("RGB")

    # Reattach alpha
    if has_alpha and a is not None:
        rgb_result.putalpha(a)

    return rgb_result


def save_resized(img: Image.Image, path: Path, size: int) -> None:
    """Resize image to size×size with high-quality downsampling and save."""
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(str(path), "PNG")
    print(f"  Saved {path.relative_to(ROOT)}  ({size}x{size})")


def main() -> None:
    # Ensure output directories exist
    ALT_ICONS.mkdir(parents=True, exist_ok=True)
    ICON_ASSETS.mkdir(parents=True, exist_ok=True)

    # Load source icons once
    print(f"Loading {LIGHT_SRC.name} ...")
    light_src = Image.open(str(LIGHT_SRC))
    print(f"  Mode: {light_src.mode}, Size: {light_src.size}")

    print(f"Loading {DARK_SRC.name} ...")
    dark_src = Image.open(str(DARK_SRC))
    print(f"  Mode: {dark_src.mode}, Size: {dark_src.size}")

    for variant in VARIANTS:
        name = variant["name"]
        shift = variant["hue_shift"]
        print(f"\n--- {name} (hue shift {shift:+d}°) ---")

        # Hue-shift both light and dark
        light_shifted = hue_shift_image(light_src, shift)
        dark_shifted = hue_shift_image(dark_src, shift)

        # 1024×1024 previews in icon_assets/
        preview_light = ICON_ASSETS / f"Icon-{name}-Light-1024×1024.png"
        preview_dark = ICON_ASSETS / f"Icon-{name}-Dark-1024×1024.png"
        light_shifted.save(str(preview_light), "PNG")
        print(f"  Saved {preview_light.relative_to(ROOT)}  (1024x1024)")
        dark_shifted.save(str(preview_dark), "PNG")
        print(f"  Saved {preview_dark.relative_to(ROOT)}  (1024x1024)")

        # Alt icon sizes for iOS
        for suffix, size in ALT_ICON_SIZES.items():
            light_path = ALT_ICONS / f"AppIcon-{name}Light{suffix}.png"
            dark_path = ALT_ICONS / f"AppIcon-{name}Dark{suffix}.png"
            save_resized(light_shifted, light_path, size)
            save_resized(dark_shifted, dark_path, size)

    print("\nDone! All variants generated.")


if __name__ == "__main__":
    main()
