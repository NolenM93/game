"""Cut painted backgrounds so characters/props can sit in the game."""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(r"c:\game\assets\art")
SRC_CURSOR = Path(r"C:\Users\nolen\.cursor\projects\c-game\assets")

CUT = {
    "hero_sling_idle", "hero_sling_run", "hero_titan_idle", "hero_titan_run",
    "hero_forge_idle", "hero_forge_run",
    "enemy_drainling", "enemy_drone", "enemy_scraper", "enemy_shieldbot",
    "enemy_leaper", "enemy_seeker",
    "boss_riptide", "boss_drain",
    "civilian", "dummy", "prop_building", "prop_swing", "prop_crate",
    "pickup_token",
}

KEEP = {
    "title_keyart", "bg_midtown", "bg_docks", "bg_grid", "bg_hub",
    "tex_rooftop", "tex_docks", "tex_grid", "ui_panel",
}


def chroma_mask(arr: np.ndarray) -> np.ndarray | None:
    rgb = arr[:, :, :3].astype(np.float32)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    # True lime screen only — not teal hoodies or cyan jets.
    lime = (g > 150) & (r < 95) & (b < 120) & (g > r + 55) & (g > b + 40)
    if lime.mean() < 0.12:
        return None
    return lime


def rembg_cut(im: Image.Image) -> Image.Image:
    from rembg import remove
    return remove(im.convert("RGBA"))


def crop_alpha(im: Image.Image, pad: int = 12) -> Image.Image:
    a = np.array(im)
    alpha = a[:, :, 3]
    ys, xs = np.where(alpha > 12)
    if len(xs) == 0:
        return im
    x0, x1 = int(xs.min()), int(xs.max())
    y0, y1 = int(ys.min()), int(ys.max())
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(a.shape[1] - 1, x1 + pad)
    y1 = min(a.shape[0] - 1, y1 + pad)
    return im.crop((x0, y0, x1 + 1, y1 + 1))


def feather(im: Image.Image) -> Image.Image:
    a = np.array(im)
    alpha = a[:, :, 3].astype(np.float32)
    # kill leftover green fringe
    rgb = a[:, :, :3].astype(np.float32)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    fringe = (g > r + 18) & (g > b + 18) & (alpha > 0)
    alpha[fringe] *= 0.15
    a[:, :, 3] = np.clip(alpha, 0, 255).astype(np.uint8)
    return Image.fromarray(a)


def process(name: str, src: Path) -> None:
    im = Image.open(src).convert("RGBA")
    arr = np.array(im)
    mask = chroma_mask(arr)
    if mask is not None:
        arr[:, :, 3] = np.where(mask, 0, arr[:, :, 3])
        out = Image.fromarray(arr)
        print(f"chroma {name}")
    else:
        print(f"rembg {name} ...")
        out = rembg_cut(im)
    out = feather(out)
    out = crop_alpha(out)
    dest = ROOT / f"{name}.png"
    out.save(dest, "PNG")
    print(f"  -> {dest} {out.size}")


def main() -> int:
    ROOT.mkdir(parents=True, exist_ok=True)
    if SRC_CURSOR.exists():
        for p in SRC_CURSOR.glob("*.png"):
            if p.name.startswith("c__"):
                continue
            target = ROOT / p.name
            if not target.exists() or p.stat().st_mtime > target.stat().st_mtime:
                Image.open(p).save(target)
    for name in sorted(CUT):
        src = ROOT / f"{name}.png"
        if not src.exists():
            print("missing", name)
            continue
        process(name, src)
    return 0


if __name__ == "__main__":
    sys.exit(main())
