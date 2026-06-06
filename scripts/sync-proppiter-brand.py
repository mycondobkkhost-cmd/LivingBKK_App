#!/usr/bin/env python3
"""Sync PROPPITER brand assets from the official master lockup (pixel-faithful).

Master source: mobile/assets/brand/proppiter-logo-master.png
Do NOT AI-regenerate the lockup — upscale and derive variants only.
"""

from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "mobile" / "assets" / "brand"
MASTER = BRAND / "proppiter-logo-master.png"

# Sampled from official master raster (370×144).
NAVY_BG = (7, 12, 47)
PROP_NAVY = (26, 27, 65)  # #1A1B41 — wordmark on light surfaces
WHITE = (255, 255, 255)

ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

IOS_ICONS: dict[str, int] = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def trim_transparent(image: Image.Image) -> Image.Image:
    alpha = image.split()[-1]
    bbox = alpha.getbbox()
    return image.crop(bbox) if bbox else image


def knock_out_near(
    image: Image.Image,
    rgb: tuple[int, int, int],
    *,
    tolerance: int = 28,
) -> Image.Image:
    img = image.convert("RGBA")
    tr, tg, tb = rgb
    out = []
    for r, g, b, a in img.getdata():
        if (
            abs(r - tr) <= tolerance
            and abs(g - tg) <= tolerance
            and abs(b - tb) <= tolerance
        ):
            out.append((r, g, b, 0))
        else:
            out.append((r, g, b, a))
    img.putdata(out)
    return trim_transparent(img)


def is_near_white(r: int, g: int, b: int, *, min_channel: int = 200) -> bool:
    return r >= min_channel and g >= min_channel and b >= min_channel


def to_light_lockup(image: Image.Image) -> Image.Image:
    """Cyan P + navy wordmark on transparent (light UI surfaces)."""
    src = knock_out_near(image, NAVY_BG)
    mapped = []
    for r, g, b, a in src.getdata():
        if a < 16:
            mapped.append((0, 0, 0, 0))
        elif is_near_white(r, g, b):
            mapped.append((*PROP_NAVY, a))
        else:
            mapped.append((r, g, b, a))
    out = Image.new("RGBA", src.size)
    out.putdata(mapped)
    return trim_transparent(out)


def to_dark_lockup_transparent(image: Image.Image) -> Image.Image:
    """Cyan P + white wordmark on transparent (gradient / dark UI)."""
    return knock_out_near(image, NAVY_BG)


def extract_mark(image: Image.Image) -> Image.Image:
    """P mark only — left glyph, transparent background."""
    rgba = image.convert("RGBA")
    w, h = rgba.size
    # Mark lives in the left ~28% of the master lockup.
    slice_w = max(1, int(w * 0.30))
    left = rgba.crop((0, 0, slice_w, h))
    left = knock_out_near(left, NAVY_BG, tolerance=32)
    return trim_transparent(left)


def upscale_height(image: Image.Image, height: int) -> Image.Image:
    w, h = image.size
    scale = height / h
    return image.resize((max(1, int(w * scale)), height), Image.Resampling.LANCZOS)


def paste_on_solid(
    foreground: Image.Image,
    *,
    size: int,
    bg: tuple[int, int, int],
    inset_ratio: float = 0.14,
) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (*bg, 255))
    fg = foreground.convert("RGBA")
    inset = int(size * inset_ratio)
    inner = size - inset * 2
    scale = min(inner / fg.width, inner / fg.height)
    nw, nh = max(1, int(fg.width * scale)), max(1, int(fg.height * scale))
    fg = fg.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (size - nw) // 2
    y = (size - nh) // 2
    canvas.paste(fg, (x, y), fg)
    return canvas


def apply_squircle_alpha(image: Image.Image) -> Image.Image:
    img = image.convert("RGBA")
    w, h = img.size
    radius = int(min(w, h) * 0.22)
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=255)
    img.putalpha(mask)
    return img


def resize_square(source: Image.Image, size: int) -> Image.Image:
    return source.resize((size, size), Image.Resampling.LANCZOS)


def maskable_icon(source: Image.Image, size: int, *, inset_ratio: float = 0.12) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inset = int(size * inset_ratio)
    inner = size - inset * 2
    icon = resize_square(source, inner)
    canvas.paste(icon, (inset, inset), icon)
    return canvas


def write_png(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def sync_brand_assets(master: Image.Image) -> None:
    # ── Master archive @4× height ──
    write_png(BRAND / "proppiter-logo-master.png", master.convert("RGBA"))

    lockup_hires = upscale_height(master, 576)  # 4× of 144px master height
    write_png(BRAND / "logo-lockup-dark.png", lockup_hires.convert("RGBA"))

    compact_dark = to_dark_lockup_transparent(master)
    compact_light = to_light_lockup(master)
    mark = extract_mark(master)

    write_png(BRAND / "logo-lockup-compact-dark.png", upscale_height(compact_dark, 128))
    write_png(BRAND / "logo-lockup-compact-light.png", upscale_height(compact_light, 128))
    write_png(BRAND / "logo-lockup-light.png", upscale_height(compact_light, 128))
    write_png(BRAND / "logo-lockup.png", upscale_height(compact_light, 128))
    write_png(BRAND / "logo-lockup-en-light.png", upscale_height(compact_light, 128))
    write_png(BRAND / "logo-lockup-en-dark.png", upscale_height(compact_dark, 128))
    write_png(BRAND / "logo-mark.png", upscale_height(mark, 256))

    # Stacked variants reuse horizontal lockup centered on transparent canvas.
    stacked = upscale_height(compact_light, 96)
    sw, sh = stacked.size
    pad = Image.new("RGBA", (sw, sh + 40), (0, 0, 0, 0))
    pad.paste(stacked, (0, 20), stacked)
    write_png(BRAND / "logo-stacked.png", pad)
    write_png(BRAND / "logo-stacked-vertical.png", pad)

    # App icons — P mark on official navy, squircle mask.
    mark_hires = upscale_height(mark, 640)
    icon_navy = paste_on_solid(mark_hires, size=1024, bg=NAVY_BG)
    icon_prop = paste_on_solid(mark_hires, size=1024, bg=PROP_NAVY)
    icon_white = paste_on_solid(mark_hires, size=1024, bg=WHITE)
    icon_grad = paste_on_solid(mark_hires, size=1024, bg=(61, 40, 88))

    write_png(BRAND / "app-icon-navy.png", apply_squircle_alpha(icon_navy))
    write_png(BRAND / "app-icon-gradient.png", apply_squircle_alpha(icon_prop))
    write_png(BRAND / "app-icon-lavender.png", apply_squircle_alpha(icon_prop))
    write_png(BRAND / "app-icon-white.png", apply_squircle_alpha(icon_white))
    write_png(BRAND / "app-icon-outline.png", apply_squircle_alpha(icon_navy))

    favicon_src = apply_squircle_alpha(paste_on_solid(mark_hires, size=512, bg=NAVY_BG))
    write_png(BRAND / "favicon-256.png", favicon_src.resize((256, 256), Image.Resampling.LANCZOS))
    write_png(BRAND / "favicon-128.png", favicon_src.resize((128, 128), Image.Resampling.LANCZOS))

    # Brand guide sheet for designers / future sync.
    guide = Image.new("RGBA", (1480, 900), (*NAVY_BG, 255))
    hero = upscale_height(master, 200)
    guide.paste(hero, (40, 40))
    guide.paste(upscale_height(compact_light, 120), (40, 280))
    guide.paste(upscale_height(compact_dark, 120), (40, 440))
    guide.paste(upscale_height(mark, 160), (40, 600))
    write_png(BRAND / "livingbkk-brand-guide.png", guide)


def sync_platform_icons(source: Image.Image) -> None:
    android_res = ROOT / "mobile" / "android" / "app" / "src" / "main" / "res"
    for folder, size in ANDROID_SIZES.items():
        write_png(android_res / folder / "ic_launcher.png", resize_square(source, size))

    ios_dir = ROOT / "mobile" / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for filename, size in IOS_ICONS.items():
        write_png(ios_dir / filename, resize_square(source, size))

    web_dir = ROOT / "mobile" / "web"
    write_png(web_dir / "favicon.png", resize_square(source, 32))
    icons = web_dir / "icons"
    write_png(icons / "Icon-192.png", resize_square(source, 192))
    write_png(icons / "Icon-512.png", resize_square(source, 512))
    write_png(icons / "Icon-maskable-192.png", maskable_icon(source, 192))
    write_png(icons / "Icon-maskable-512.png", maskable_icon(source, 512))


def main() -> None:
    if not MASTER.exists():
        raise SystemExit(f"Missing master logo: {MASTER}")

    master = Image.open(MASTER).convert("RGBA")
    sync_brand_assets(master)

    app_icon = Image.open(BRAND / "app-icon-navy.png").convert("RGBA")
    sync_platform_icons(app_icon)

    print("PROPPITER brand assets synced from proppiter-logo-master.png")
    print(f"  → {BRAND}")
    print("  → Android / iOS / Web launcher icons")


if __name__ == "__main__":
    main()
