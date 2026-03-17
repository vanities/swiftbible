"""
Generate In-App Purchase review screenshots for App Store Connect.
Creates one screenshot per donation tier showing the donation prompt UI.
"""

from PIL import Image, ImageDraw, ImageFont

TIERS = [
    ("com.swiftbible.donation.3", "$2.99", "Donation - $3", "Support SwiftBible with a small donation"),
    ("com.swiftbible.donation.5", "$4.99", "Donation - $5", "Support SwiftBible with a donation"),
    ("com.swiftbible.donation.10", "$9.99", "Donation - $10", "Support SwiftBible with a generous donation"),
    ("com.swiftbible.donation.25", "$24.99", "Donation - $25", "Support SwiftBible with a champion donation"),
    ("com.swiftbible.donation.50", "$49.99", "Donation - $50", "Support SwiftBible with an extraordinary donation"),
]

# Brand colors
DEEP_NAVY = (13, 18, 38)
ACCENT = (0, 180, 160)
ACCENT_DARK = (0, 122, 109)
GOLD = (217, 173, 82)
WHITE = (255, 255, 255)
LIGHT_GRAY = (240, 240, 245)
MID_GRAY = (160, 160, 170)
DARK_TEXT = (30, 30, 40)

W, H = 1290, 2796  # iPhone 6.7" size for App Store Connect

try:
    font_title = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 72)
    font_price = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 120)
    font_subtitle = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 48)
    font_body = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 40)
    font_label = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
    font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 32)
except OSError:
    font_title = ImageFont.load_default()
    font_price = font_title
    font_subtitle = font_title
    font_body = font_title
    font_label = font_title
    font_small = font_title


def draw_centered(draw, text, y, font, fill, width):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((width - tw) // 2, y), text, font=font, fill=fill)
    return bbox[3] - bbox[1]


def draw_pill(draw, text, x, y, w, h, bg, fg, font, selected=False):
    draw.rounded_rectangle([x, y, x + w, y + h], radius=20, fill=bg)
    if selected:
        draw.rounded_rectangle([x, y, x + w, y + h], radius=20, outline=ACCENT, width=4)
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((x + (w - tw) // 2, y + (h - th) // 2 - 4), text, font=font, fill=fg)


for product_id, price, display_name, description in TIERS:
    img = Image.new("RGB", (W, H), WHITE)
    draw = ImageDraw.Draw(img)

    # Status bar area (dark)
    draw.rectangle([0, 0, W, 120], fill=DEEP_NAVY)

    # App header
    y = 200
    draw_centered(draw, "Support SwiftBible", y, font_title, DARK_TEXT, W)
    y += 100

    # Description
    draw_centered(draw, "Your generosity keeps it free for everyone.", y, font_body, MID_GRAY, W)
    y += 80
    draw_centered(draw, "Every gift directly supports the servers and tools", y, font_body, MID_GRAY, W)
    y += 55
    draw_centered(draw, "that bring Scripture to readers worldwide.", y, font_body, MID_GRAY, W)
    y += 120

    # "Choose an amount" label
    draw.text((100, y), "Choose an amount", font=font_subtitle, fill=DARK_TEXT)
    y += 80

    # Amount grid (2x2 for the 4-tier variants, highlight current)
    all_prices = ["$2.99", "$4.99", "$9.99", "$24.99"]
    if price == "$49.99":
        all_prices = ["$4.99", "$9.99", "$24.99", "$49.99"]

    pill_w = 520
    pill_h = 110
    gap = 30
    grid_x = (W - pill_w * 2 - gap) // 2

    for i, p in enumerate(all_prices):
        col = i % 2
        row = i // 2
        px = grid_x + col * (pill_w + gap)
        py = y + row * (pill_h + gap)
        is_selected = (p == price)
        bg = ACCENT if is_selected else LIGHT_GRAY
        fg = WHITE if is_selected else DARK_TEXT
        draw_pill(draw, p, px, py, pill_w, pill_h, bg, fg, font_subtitle, selected=is_selected)

        # "Most chosen" label for $4.99
        if p == "$4.99" and price != "$49.99":
            label = "Most chosen"
            lbbox = draw.textbbox((0, 0), label, font=font_small)
            lw = lbbox[2] - lbbox[0]
            draw.text((px + (pill_w - lw) // 2, py + pill_h + 5), label, font=font_small, fill=MID_GRAY)

    y += 2 * (pill_h + gap) + 60

    # Highlighted price display
    draw_centered(draw, "Selected:", y, font_subtitle, MID_GRAY, W)
    y += 80
    draw_centered(draw, price, y, font_price, ACCENT, W)
    y += 160

    # Donate button
    btn_w = 900
    btn_h = 120
    btn_x = (W - btn_w) // 2
    draw.rounded_rectangle([btn_x, y, btn_x + btn_w, y + btn_h], radius=24, fill=ACCENT)
    draw_centered(draw, f"Give {price}", y + 15, font_subtitle, WHITE, W)
    y += btn_h + 40

    # "Not now" button
    draw_centered(draw, "Not now", y, font_label, MID_GRAY, W)
    y += 100

    # Product info footer
    draw.line([(100, y), (W - 100, y)], fill=LIGHT_GRAY, width=2)
    y += 30
    draw_centered(draw, display_name, y, font_label, DARK_TEXT, W)
    y += 50
    draw_centered(draw, description, y, font_small, MID_GRAY, W)
    y += 50
    draw_centered(draw, f"Product ID: {product_id}", y, font_small, MID_GRAY, W)
    y += 50
    draw_centered(draw, "Type: Consumable In-App Purchase", y, font_small, MID_GRAY, W)

    # Save
    tier = product_id.split(".")[-1]
    out = f"../appstore/iap/iap_screenshot_donation_{tier}.png"
    img.save(out, "PNG")
    print(f"  -> {out}")

print("\nDone! Upload these to App Store Connect for each IAP product.")
