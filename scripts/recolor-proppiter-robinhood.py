#!/usr/bin/env python3
"""Recolor PROPPITER master lockup → Robinhood-inspired palette (geometry preserved).

Reads:  mobile/assets/brand/proppiter-logo-master.png
Writes: mobile/assets/brand/proppiter-logo-master-robinhood.png (preview)
Then runs sync-proppiter-brand.py on the recolored master.

Icon: cyan/teal → purple → yellow → orange gradient (same polygon shapes).
Wordmark: PROP = deep purple, PITER = vibrant orange.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "mobile" / "assets" / "brand"
MASTER = BRAND / "proppiter-logo-master.png"
ROBINHOOD_MASTER = BRAND / "proppiter-logo-master-robinhood.png"
BACKUP = BRAND / "proppiter-logo-master-original.png"

# Robinhood-inspired (Thailand delivery UI)
PROP_PURPLE = (78, 42, 132)       # #4E2A84
PITER_ORANGE = (255, 107, 0)      # #FF6B00
GRAD_TOP = (78, 42, 132)          # #4E2A84
GRAD_MID = (155, 109, 255)        # #9B6DFF
GRAD_YELLOW = (255, 203, 5)       # #FFCB05
GRAD_ORANGE = (255, 138, 0)       # #FF8A00

NAVY_BG = (7, 12, 47)
CYAN_REF = (83, 144, 169)  # #5390A9 from master


def _lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def gradient_at(t: float) -> tuple[int, int, int]:
    """t ∈ [0,1] top→bottom gradient for the P mark."""
    if t < 0.45:
        u = t / 0.45
        return (
            _lerp(GRAD_TOP[0], GRAD_MID[0], u),
            _lerp(GRAD_TOP[1], GRAD_MID[1], u),
            _lerp(GRAD_TOP[2], GRAD_MID[2], u),
        )
    if t < 0.72:
        u = (t - 0.45) / 0.27
        return (
            _lerp(GRAD_MID[0], GRAD_YELLOW[0], u),
            _lerp(GRAD_MID[1], GRAD_YELLOW[1], u),
            _lerp(GRAD_MID[2], GRAD_YELLOW[2], u),
        )
    u = (t - 0.72) / 0.28
    return (
        _lerp(GRAD_YELLOW[0], GRAD_ORANGE[0], u),
        _lerp(GRAD_YELLOW[1], GRAD_ORANGE[1], u),
        _lerp(GRAD_YELLOW[2], GRAD_ORANGE[2], u),
    )


def is_cyanish(r: int, g: int, b: int) -> bool:
    cr, cg, cb = CYAN_REF
    return abs(r - cr) <= 40 and abs(g - cg) <= 40 and abs(b - cb) <= 40


def is_near_bg(r: int, g: int, b: int) -> bool:
    br, bg, bb = NAVY_BG
    return abs(r - br) <= 18 and abs(g - bg) <= 18 and abs(b - bb) <= 18


def is_near_white(r: int, g: int, b: int) -> bool:
    return r >= 200 and g >= 200 and b >= 200


def text_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    """Bounding box of near-white wordmark pixels."""
    w, h = img.size
    xs: list[int] = []
    for y in range(h):
        for x in range(int(w * 0.28), w):
            r, g, b, a = img.getpixel((x, y))
            if a > 16 and is_near_white(r, g, b):
                xs.append(x)
    if not xs:
        return int(w * 0.30), 0, int(w * 0.98), h
    return min(xs), 0, max(xs), h


def text_split_x(img: Image.Image) -> int:
    """x where PROP ends / PITER begins (4 chars of 9, tuned for Prompt caps)."""
    left, _, right, _ = text_bbox(img)
    text_w = right - left
    # Slightly under 4/9 — wide P + O reads shorter than monospace 4/9.
    return left + int(text_w * 0.395)


def recolor_master(img: Image.Image) -> Image.Image:
    src = img.convert("RGBA")
    w, h = src.size
    split_x = text_split_x(src)
    mark_right = int(w * 0.30)

    # Icon vertical bounds for gradient
    icon_pixels = [
        (x, y)
        for y in range(h)
        for x in range(mark_right)
        if not is_near_bg(*src.getpixel((x, y))[:3])
    ]
    if icon_pixels:
        ys = [y for _, y in icon_pixels]
        y_min, y_max = min(ys), max(ys)
    else:
        y_min, y_max = 0, h - 1

    out = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = src.getpixel((x, y))
            if a < 16 or is_near_bg(r, g, b):
                out.append((r, g, b, a))
            elif x < mark_right and is_cyanish(r, g, b):
                t = (y - y_min) / max(1, y_max - y_min)
                nr, ng, nb = gradient_at(t)
                out.append((nr, ng, nb, a))
            elif is_near_white(r, g, b) or (x >= mark_right and not is_cyanish(r, g, b)):
                color = PROP_PURPLE if x < split_x else PITER_ORANGE
                out.append((*color, a))
            elif is_cyanish(r, g, b):
                t = (y - y_min) / max(1, y_max - y_min)
                nr, ng, nb = gradient_at(t)
                out.append((nr, ng, nb, a))
            else:
                out.append((r, g, b, a))

    result = Image.new("RGBA", (w, h))
    result.putdata(out)
    return result


def main() -> None:
    if not MASTER.exists():
        raise SystemExit(f"Missing master: {MASTER}")

    if not BACKUP.exists():
        shutil.copy2(MASTER, BACKUP)
        print(f"Backed up original → {BACKUP.name}")

    master = Image.open(MASTER).convert("RGBA")
    recolored = recolor_master(master)
    recolored.save(ROBINHOOD_MASTER, format="PNG", optimize=True)
    print(f"Robinhood preview → {ROBINHOOD_MASTER.name}")

    # Promote recolored master and sync all derived assets
    recolored.save(MASTER, format="PNG", optimize=True)
    sync = ROOT / "scripts" / "sync-proppiter-brand.py"
    subprocess.run([sys.executable, str(sync)], check=True)
    print("Done — all brand variants synced from Robinhood master.")


if __name__ == "__main__":
    main()
