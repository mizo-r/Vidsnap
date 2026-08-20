#!/usr/bin/env python3
"""
VidSnap app icon generator.

Generates:
  - app/assets/icons/app_icon.png           (1024×1024 master)
  - app/assets/icons/app_icon_foreground.png (adaptive icon foreground, 1024×1024)
  - app/android/app/src/main/res/mipmap-*/ic_launcher.png (legacy launcher icons)
  - app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  - app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml
  - app/android/app/src/main/res/drawable/ic_launcher_foreground.xml (vector)
  - app/android/app/src/main/res/values/ic_launcher_background.xml

No external deps — uses Pillow only.
"""

import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ---- Config -----------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent
APP_DIR = PROJECT_ROOT / "app"
ASSETS_ICONS = APP_DIR / "assets" / "icons"
ANDROID_RES = APP_DIR / "android" / "app" / "src" / "main" / "res"

BG_DARK = (14, 15, 19, 255)       # #0E0F13
BG_SURFACE = (26, 28, 34, 255)    # #1A1C22
ACCENT = (77, 124, 254, 255)      # #4D7CFE
ACCENT_2 = (110, 91, 255, 255)    # #6E5BFF
SUCCESS = (46, 204, 113, 255)     # #2ECC71
WHITE = (245, 246, 250, 255)

ICON_SIZE = 1024
ANDROID_MIPMAP_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def find_font() -> ImageFont.FreeTypeFont:
    """Find a suitable font for the V letter."""
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
    ]
    for p in candidates:
        if os.path.exists(p):
            return ImageFont.truetype(p, size=620)
    return ImageFont.load_default()


def make_master_icon() -> Image.Image:
    """Create the master 1024×1024 app icon.

    Design: dark gradient background with rounded square, large white V with
    accent gradient stroke, and a small download arrow accent.
    """
    img = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background: rounded square with vertical gradient (top-left accent → bottom-right darker)
    radius = 220
    mask = Image.new("L", (ICON_SIZE, ICON_SIZE), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((0, 0, ICON_SIZE, ICON_SIZE), radius=radius, fill=255)

    # Vertical gradient BG_DARK → BG_SURFACE
    bg = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), BG_DARK)
    bg_draw = ImageDraw.Draw(bg)
    for y in range(ICON_SIZE):
        t = y / ICON_SIZE
        r = int(BG_DARK[0] + (BG_SURFACE[0] - BG_DARK[0]) * t)
        g = int(BG_DARK[1] + (BG_SURFACE[1] - BG_DARK[1]) * t)
        b = int(BG_DARK[2] + (BG_SURFACE[2] - BG_DARK[2]) * t)
        bg_draw.line([(0, y), (ICON_SIZE, y)], fill=(r, g, b, 255))

    img.paste(bg, (0, 0), mask)

    # Accent gradient circle (subtle glow on top-left)
    glow = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    for r in range(360, 0, -8):
        alpha = int(60 * (1 - r / 360))
        glow_draw.ellipse(
            (180 - r // 2, 180 - r // 2, 180 + r // 2, 180 + r // 2),
            fill=(ACCENT[0], ACCENT[1], ACCENT[2], alpha),
        )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=40))
    img = Image.alpha_composite(img, glow)

    # Large "V" letter in accent gradient
    draw = ImageDraw.Draw(img)
    font = find_font()
    text = "V"
    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    pos = ((ICON_SIZE - text_w) // 2 - bbox[0], (ICON_SIZE - text_h) // 2 - bbox[1])

    # Shadow first
    shadow = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.text(pos, text, font=font, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=20))
    img = Image.alpha_composite(img, shadow)

    # Accent gradient text via two-step: draw text mask, fill with gradient
    text_mask = Image.new("L", (ICON_SIZE, ICON_SIZE), 0)
    text_mask_draw = ImageDraw.Draw(text_mask)
    text_mask_draw.text(pos, text, font=font, fill=255)

    gradient = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    grad_draw = ImageDraw.Draw(gradient)
    for y in range(ICON_SIZE):
        t = y / ICON_SIZE
        r = int(ACCENT[0] + (ACCENT_2[0] - ACCENT[0]) * t)
        g = int(ACCENT[1] + (ACCENT_2[1] - ACCENT[1]) * t)
        b = int(ACCENT[2] + (ACCENT_2[2] - ACCENT[2]) * t)
        grad_draw.line([(0, y), (ICON_SIZE, y)], fill=(r, g, b, 255))

    img.paste(gradient, (0, 0), text_mask)

    # Download arrow accent at bottom-right
    arrow_size = 180
    arrow_x = ICON_SIZE - arrow_size - 120
    arrow_y = ICON_SIZE - arrow_size - 120
    arrow_mask = Image.new("L", (ICON_SIZE, ICON_SIZE), 0)
    arrow_draw = ImageDraw.Draw(arrow_mask)
    # Down-pointing arrow shape
    cx = arrow_x + arrow_size // 2
    # Shaft
    shaft_w = arrow_size // 3
    shaft_top = arrow_y
    shaft_bot = arrow_y + int(arrow_size * 0.55)
    arrow_draw.rounded_rectangle(
        (cx - shaft_w // 2, shaft_top, cx + shaft_w // 2, shaft_bot),
        radius=20,
        fill=255,
    )
    # Head (triangle)
    head_top = shaft_bot - 30
    head_bot = arrow_y + arrow_size
    arrow_draw.polygon(
        [
            (cx - arrow_size // 2, head_top),
            (cx + arrow_size // 2, head_top),
            (cx, head_bot),
        ],
        fill=255,
    )

    # Fill arrow with SUCCESS color
    arrow_layer = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    arrow_layer_draw = ImageDraw.Draw(arrow_layer)
    # Re-draw on the actual layer
    arrow_layer_draw.rounded_rectangle(
        (cx - shaft_w // 2, shaft_top, cx + shaft_w // 2, shaft_bot),
        radius=20,
        fill=SUCCESS,
    )
    arrow_layer_draw.polygon(
        [
            (cx - arrow_size // 2, head_top),
            (cx + arrow_size // 2, head_top),
            (cx, head_bot),
        ],
        fill=SUCCESS,
    )
    img = Image.alpha_composite(img, arrow_layer)

    return img


def make_foreground_icon() -> Image.Image:
    """Adaptive icon foreground — just the V + arrow, transparent background."""
    master = make_master_icon()
    # Make background transparent while keeping the V and arrow
    fg = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    # Copy non-background pixels (the V and arrow are bright colors)
    for y in range(ICON_SIZE):
        for x in range(ICON_SIZE):
            px = master.getpixel((x, y))
            # Keep if it's an accent-ish color or success color
            if (px[0] > 100 and px[2] > 150) or (px[1] > 150 and px[2] < 150):
                fg.putpixel((x, y), px)
    return fg


def write_legacy_mipmaps(master: Image.Image) -> None:
    for density, size in ANDROID_MIPMAP_SIZES.items():
        out_dir = ANDROID_RES / f"mipmap-{density}"
        out_dir.mkdir(parents=True, exist_ok=True)
        resized = master.resize((size, size), Image.LANCZOS)
        resized.save(out_dir / "ic_launcher.png")
        resized.save(out_dir / "ic_launcher_round.png")


def write_adaptive_xml() -> None:
    anydpi = ANDROID_RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""
    )
    (anydpi / "ic_launcher_round.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
"""
    )


def write_foreground_vector() -> None:
    """Write a vector drawable for the adaptive icon foreground.
    This is a simple geometric V shape — high-quality vector alternative to the raster PNG."""
    drawable = ANDROID_RES / "drawable"
    drawable.mkdir(parents=True, exist_ok=True)
    (drawable / "ic_launcher_foreground.xml").write_text(
        """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
  <path
      android:fillColor="#4D7CFE"
      android:pathData="M30,30 L54,78 L78,30 L66,30 L54,54 L42,30 Z"/>
  <path
      android:fillColor="#2ECC71"
      android:pathData="M64,68 L72,68 L72,82 L78,82 L68,92 L58,82 L64,82 Z"/>
</vector>
"""
    )


def write_background_color() -> None:
    values = ANDROID_RES / "values"
    values.mkdir(parents=True, exist_ok=True)
    existing = ""
    colors_xml = values / "ic_launcher_background.xml"
    colors_xml.write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0E0F13</color>
</resources>
"""
    )


def main() -> None:
    print("[VidSnap] Generating app icons…")
    ASSETS_ICONS.mkdir(parents=True, exist_ok=True)
    ANDROID_RES.mkdir(parents=True, exist_ok=True)

    master = make_master_icon()
    master.save(ASSETS_ICONS / "app_icon.png")
    print(f"  ✓ {ASSETS_ICONS / 'app_icon.png'}")

    foreground = make_foreground_icon()
    foreground.save(ASSETS_ICONS / "app_icon_foreground.png")
    print(f"  ✓ {ASSETS_ICONS / 'app_icon_foreground.png'}")

    write_legacy_mipmaps(master)
    print("  ✓ Legacy mipmap densities (mdpi..xxxhdpi)")

    write_adaptive_xml()
    print("  ✓ Adaptive icon XML (mipmap-anydpi-v26)")

    write_foreground_vector()
    print("  ✓ Foreground vector drawable")

    write_background_color()
    print("  ✓ Background color resource")

    print("[VidSnap] Done.")


if __name__ == "__main__":
    main()
