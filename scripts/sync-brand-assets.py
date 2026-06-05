#!/usr/bin/env python3
"""Extract LivingBKK brand assets from the official v4 guide and sync platform icons."""

from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "mobile" / "assets" / "brand"
GUIDE = BRAND / "livingbkk-brand-guide.png"

# Verified crop boxes on livingbkk-brand-guide.png (1024×682, v4 layout).
NAVY = (18, 18, 43)
WHITE = (255, 255, 255)
COOL_GRAY = (241, 243, 247)

# Icon + wordmark row only (no taglines) — section 2 navy band, top row.
COMPACT_LOCKUP = (248, 205, 430, 228)

CROPS: dict[str, tuple[int, int, int, int]] = {
    "logo-mark.png": (70, 82, 155, 162),
    # Section 2 dark lockups on the navy band (wordmark + taglines beside mark).
    "logo-lockup-dark.png": (248, 205, 430, 250),
    "logo-stacked.png": (48, 362, 442, 387),
    "logo-stacked-vertical.png": (538, 358, 705, 416),
    # Section "APP ICONS" row in the guide.
    "app-icon-gradient.png": (45, 455, 104, 520),
    "favicon-256.png": (143, 463, 201, 520),
}

# Tagline accent when deriving light lockups from dark raster previews.
LIGHT_TAGLINE: dict[str, tuple[int, int, int]] = {
    "logo-lockup-light.png": (108, 93, 211),
    "logo-lockup-en-light.png": (77, 79, 224),
}

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

MACOS_ICONS: dict[str, int] = {
    "app_icon_16.png": 16,
    "app_icon_32.png": 32,
    "app_icon_64.png": 64,
    "app_icon_128.png": 128,
    "app_icon_256.png": 256,
    "app_icon_512.png": 512,
    "app_icon_1024.png": 1024,
}


def trim_transparent(image: Image.Image) -> Image.Image:
    alpha = image.split()[-1]
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def knock_out_background(
    image: Image.Image,
    rgb: tuple[int, int, int],
    *,
    tolerance: int = 32,
) -> Image.Image:
    """Make solid guide background transparent (white, cool gray, or navy panels)."""
    img = image.convert("RGBA")
    tr, tg, tb = rgb
    pixels = list(img.getdata())
    cleared = []
    for r, g, b, a in pixels:
        if (
            abs(r - tr) <= tolerance
            and abs(g - tg) <= tolerance
            and abs(b - tb) <= tolerance
        ):
            cleared.append((r, g, b, 0))
        else:
            cleared.append((r, g, b, a))
    img.putdata(cleared)
    return trim_transparent(img)


def knock_out_light_panel(image: Image.Image) -> Image.Image:
    img = knock_out_background(image, WHITE, tolerance=24)
    img = knock_out_background(img, COOL_GRAY, tolerance=18)
    # Remove card fringe without eating navy wordmark anti-aliasing.
    cleaned = Image.new("RGBA", img.size, (0, 0, 0, 0))
    cleaned.putdata(
        [
            (r, g, b, 0)
            if a > 0 and r > 246 and g > 246 and b > 246
            else (r, g, b, a)
            for r, g, b, a in img.getdata()
        ]
    )
    return trim_transparent(cleaned)


def remap_pixel(
    r: int,
    g: int,
    b: int,
    a: int,
    *,
    white_to: tuple[int, int, int],
    lavender_to: tuple[int, int, int],
) -> tuple[int, int, int, int]:
    if a < 128:
        return (r, g, b, 0)
    # Keep pink/purple brand colors from the dark lockup raster.
    if b > 130 and r > 120 and g < 170:
        return (r, g, b, a)
    if r > 165 and g > 165 and b > 165:
        return (*white_to, a)
    if r > 130 and g > 120 and b > 170:
        return (*lavender_to, a)
    return (r, g, b, a)


def dark_lockup_to_light(
    image: Image.Image,
    *,
    lavender_to: tuple[int, int, int],
) -> Image.Image:
    """Derive light lockup from dark lockup raster (guide shows dark on navy band)."""
    src = knock_out_background(image, NAVY)
    pixels = list(src.getdata())
    mapped = [
        remap_pixel(r, g, b, a, white_to=(18, 18, 43), lavender_to=lavender_to)
        for r, g, b, a in pixels
    ]
    out = Image.new("RGBA", src.size)
    out.putdata(mapped)
    return trim_transparent(out)


def compose_en_dark_lockup(guide: Image.Image) -> Image.Image:
    """Horizontal EN dark lockup: shared mark/wordmark row + English taglines from the guide."""
    top = knock_out_background(
        guide.crop((248, 205, 430, 228)).convert("RGBA"),
        NAVY,
    )
    tags = knock_out_background(
        guide.crop((455, 200, 575, 250)).convert("RGBA"),
        NAVY,
    )
    gap = 3
    tag_x = 34
    width = max(top.width, tag_x + tags.width)
    height = top.height + gap + tags.height
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    canvas.paste(top, (0, 0), top)
    canvas.paste(tags, (tag_x, top.height + gap), tags)
    return trim_transparent(canvas)


def apply_squircle_alpha(image: Image.Image) -> Image.Image:
    """Preserve rounded-square icon shape with transparent corners."""
    img = image.convert("RGBA")
    w, h = img.size
    radius = int(min(w, h) * 0.22)
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=255)
    img.putalpha(mask)
    return img


def upscale_canvas(
    image: Image.Image,
    size: int,
    *,
    inset_ratio: float = 0.0,
) -> Image.Image:
    if inset_ratio <= 0:
        return image.resize((size, size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inset = int(size * inset_ratio)
    inner = size - inset * 2
    scaled = image.resize((inner, inner), Image.Resampling.LANCZOS)
    canvas.paste(scaled, (inset, inset), scaled)
    return canvas


def resize_icon(source: Image.Image, size: int) -> Image.Image:
    return source.resize((size, size), Image.Resampling.LANCZOS)


def maskable_icon(source: Image.Image, size: int, *, inset_ratio: float = 0.12) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inset = int(size * inset_ratio)
    inner = size - inset * 2
    icon = resize_icon(source, inner)
    canvas.paste(icon, (inset, inset), icon)
    return canvas


def write_png(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    image.save(path, format="PNG", optimize=True)


def sync_brand_assets(guide: Image.Image) -> None:
    mark = knock_out_light_panel(guide.crop(CROPS["logo-mark.png"]).convert("RGBA"))
    write_png(BRAND / "logo-mark.png", mark)

    dark_th = guide.crop(CROPS["logo-lockup-dark.png"]).convert("RGBA")
    write_png(BRAND / "logo-lockup-dark.png", knock_out_background(dark_th, NAVY))
    write_png(
        BRAND / "logo-lockup-light.png",
        dark_lockup_to_light(dark_th, lavender_to=LIGHT_TAGLINE["logo-lockup-light.png"]),
    )

    compact_dark = knock_out_background(
        guide.crop(COMPACT_LOCKUP).convert("RGBA"),
        NAVY,
    )
    write_png(BRAND / "logo-lockup-compact-dark.png", compact_dark)
    write_png(
        BRAND / "logo-lockup-compact-light.png",
        dark_lockup_to_light(
            guide.crop(COMPACT_LOCKUP).convert("RGBA"),
            lavender_to=LIGHT_TAGLINE["logo-lockup-light.png"],
        ),
    )

    en_dark = compose_en_dark_lockup(guide)
    write_png(BRAND / "logo-lockup-en-dark.png", en_dark)
    write_png(
        BRAND / "logo-lockup-en-light.png",
        dark_lockup_to_light(
            en_dark,
            lavender_to=LIGHT_TAGLINE["logo-lockup-en-light.png"],
        ),
    )

    write_png(
        BRAND / "logo-stacked.png",
        knock_out_light_panel(guide.crop(CROPS["logo-stacked.png"]).convert("RGBA")),
    )
    write_png(
        BRAND / "logo-stacked-vertical.png",
        knock_out_light_panel(
            guide.crop(CROPS["logo-stacked-vertical.png"]).convert("RGBA")
        ),
    )

    app_icon = apply_squircle_alpha(guide.crop(CROPS["app-icon-gradient.png"]).convert("RGBA"))
    write_png(BRAND / "app-icon-gradient.png", upscale_canvas(app_icon, 1024))

    favicon_src = knock_out_light_panel(
        guide.crop(CROPS["favicon-256.png"]).convert("RGBA")
    )
    favicon = apply_squircle_alpha(favicon_src)
    write_png(BRAND / "favicon-256.png", upscale_canvas(favicon, 256, inset_ratio=0.04))
    write_png(BRAND / "favicon-128.png", upscale_canvas(favicon, 128, inset_ratio=0.04))

    shutil.copy2(BRAND / "logo-lockup-light.png", BRAND / "logo-lockup.png")

    # Optional companion icons from the same APP ICONS row in the guide.
    optional = {
        "app-icon-white.png": (143, 463, 201, 520),
        "app-icon-lavender.png": (242, 455, 290, 520),
        "app-icon-navy.png": (285, 455, 355, 520),
    }
    for filename, box in optional.items():
        crop = apply_squircle_alpha(guide.crop(box).convert("RGBA"))
        write_png(BRAND / filename, upscale_canvas(crop, 1024))


def sync_platform_icons(source: Image.Image) -> None:
    android_res = ROOT / "mobile" / "android" / "app" / "src" / "main" / "res"
    for folder, size in ANDROID_SIZES.items():
        write_png(android_res / folder / "ic_launcher.png", resize_icon(source, size))

    ios_dir = ROOT / "mobile" / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for filename, size in IOS_ICONS.items():
        write_png(ios_dir / filename, resize_icon(source, size))

    mac_dir = ROOT / "mobile" / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for filename, size in MACOS_ICONS.items():
        write_png(mac_dir / filename, resize_icon(source, size))

    web_dir = ROOT / "mobile" / "web"
    write_png(web_dir / "favicon.png", resize_icon(source, 32))
    write_png(web_dir / "icons" / "Icon-192.png", resize_icon(source, 192))
    write_png(web_dir / "icons" / "Icon-512.png", resize_icon(source, 512))
    write_png(web_dir / "icons" / "Icon-maskable-192.png", maskable_icon(source, 192))
    write_png(web_dir / "icons" / "Icon-maskable-512.png", maskable_icon(source, 512))

    ico_sizes = [16, 32, 48, 64, 128, 256]
    ico_images = [resize_icon(source, s) for s in ico_sizes]
    ico_path = ROOT / "mobile" / "windows" / "runner" / "resources" / "app_icon.ico"
    ico_images[0].save(
        ico_path,
        format="ICO",
        sizes=[(s, s) for s in ico_sizes],
        append_images=ico_images[1:],
    )


def cleanup_debug_assets() -> None:
    keep = {
        "livingbkk-brand-guide.png",
        "logo-mark.png",
        "logo-lockup.png",
        "logo-lockup-light.png",
        "logo-lockup-en-light.png",
        "logo-lockup-dark.png",
        "logo-lockup-en-dark.png",
        "logo-lockup-compact-light.png",
        "logo-lockup-compact-dark.png",
        "logo-stacked.png",
        "logo-stacked-vertical.png",
        "app-icon-gradient.png",
        "app-icon-white.png",
        "app-icon-lavender.png",
        "app-icon-navy.png",
        "app-icon-outline.png",
        "favicon-256.png",
        "favicon-128.png",
    }
    for path in BRAND.iterdir():
        if not path.is_file() or path.suffix.lower() != ".png":
            continue
        if path.name in keep:
            continue
        if path.name.startswith(
            (
                "_",
                "auto_",
                "probe",
                "manual_",
                "tight_",
                "find_",
                "final_",
                "pick_",
                "sec5_",
                "sec",
                "bottom_",
                "midbottom_",
                "appicon_",
                "light_",
                "lockup_",
                "exact_",
                "wider_",
                "both_",
                "favicon_",
                "dark_",
                "sum_",
                "try_",
                "mark_",
                "th_",
                "en_",
                "lock_",
                "end_",
                "enonly",
                "enr_",
                "env_",
                "tags_",
                "right_white",
                "test.png",
            )
        ) or path.name in ("test.png", "right_white_area.png"):
            path.unlink()


def main() -> None:
    if not GUIDE.exists():
        raise SystemExit(f"Missing brand guide: {GUIDE}")

    guide = Image.open(GUIDE).convert("RGBA")
    sync_brand_assets(guide)

    app_icon = Image.open(BRAND / "app-icon-gradient.png").convert("RGBA")
    sync_platform_icons(app_icon)
    cleanup_debug_assets()

    print(f"Synced brand assets from {GUIDE.name}")
    print(f"  Brand PNGs written to {BRAND}")
    print("  Platform icons: Android, iOS, macOS, Web, Windows")


if __name__ == "__main__":
    main()
