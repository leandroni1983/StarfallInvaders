#!/usr/bin/env python3
"""Genera el arte tipográfico original de "ALONSO INVADER" (pixel art).

Todo se dibuja por código con una fuente de mapa de bits 5x7 propia + degradado
"cromado", bisel, contorno, resplandor y destellos. No se usa ninguna fuente ni
imagen de terceros (requisito del proyecto). Salidas:

  * assets/sprites/ui/title_logo.png  -> título de la pantalla de inicio
  * assets/sprites/ui/app_icon.png    -> icono de la app (letra A en cromo)

Uso:
    python tools/gen_title_logo.py
"""

from __future__ import annotations

import os
import random

from PIL import Image, ImageDraw, ImageFilter

# --- Fuente de mapa de bits 5x7 (sólo las letras que necesita el proyecto) ----
FONT = {
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "N": ["10001", "11001", "10101", "10101", "10011", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    " ": ["00000", "00000", "00000", "00000", "00000", "00000", "00000"],
}

GLYPH_W = 5
GLYPH_H = 7

# Colores del cuerpo (cromado cian -> azul).
COL_TOP = (236, 252, 255)
COL_MID = (86, 214, 255)
COL_BOT = (26, 86, 196)
COL_DARK = (8, 16, 44)
COL_WHITE = (255, 255, 255)
COL_OUTLINE = (8, 14, 40)
COL_GLOW = (70, 190, 255)


def _lerp(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def _blend(a, b, t):
    return _lerp(a, b, t)


def _gradient(t):
    t = max(0.0, min(1.0, t))
    if t < 0.5:
        return _lerp(COL_TOP, COL_MID, t / 0.5)
    return _lerp(COL_MID, COL_BOT, (t - 0.5) / 0.5)


def _text_width(text, scale, advance):
    return len(text) * advance - (advance - GLYPH_W * scale)


def _draw_text(mask, text, x0, y0, scale, advance):
    d = ImageDraw.Draw(mask)
    x = x0
    for ch in text:
        rows = FONT.get(ch, FONT[" "])
        for gy, row in enumerate(rows):
            for gx, c in enumerate(row):
                if c == "1":
                    px = x + gx * scale
                    py = y0 + gy * scale
                    d.rectangle([px, py, px + scale - 1, py + scale - 1], fill=255)
        x += advance


def _star(draw, cx, cy, r, color):
    """Destello de 4 puntas (estrella fina)."""
    draw.polygon([(cx, cy - r), (cx + r // 3, cy - r // 3), (cx + r, cy),
                  (cx + r // 3, cy + r // 3), (cx, cy + r),
                  (cx - r // 3, cy + r // 3), (cx - r, cy),
                  (cx - r // 3, cy - r // 3)], fill=color)


def _shade_body(mask, bands, W, H):
    """Rellena la máscara con degradado por línea + bisel claro/oscuro."""
    grid = [[mask.getpixel((x, y)) > 0 for x in range(W)] for y in range(H)]
    body = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bpx = body.load()
    for y in range(H):
        for x in range(W):
            if not grid[y][x]:
                continue
            t = 0.5
            for (b0, b1) in bands:
                if b0 <= y < b1:
                    t = (y - b0) / float(max(1, b1 - b0 - 1))
                    break
            col = _gradient(t)
            if y > 0 and not grid[y - 1][x]:
                col = _blend(col, COL_WHITE, 0.7)
            if y < H - 1 and not grid[y + 1][x]:
                col = _blend(col, COL_DARK, 0.45)
            if 0.16 <= t <= 0.30:
                col = _blend(col, COL_WHITE, 0.35)
            bpx[x, y] = (col[0], col[1], col[2], 255)
    return body


def _compose_logo(mask, bands, W, H, star_list=()):
    """Superpone resplandor, sombra, contorno, cuerpo y destellos."""
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    glow = mask.filter(ImageFilter.GaussianBlur(9))
    glow_rgba = Image.new("RGBA", (W, H), COL_GLOW + (0,))
    glow_rgba.putalpha(glow.point(lambda v: int(v * 0.55)))
    canvas.alpha_composite(glow_rgba)

    shadow = mask.filter(ImageFilter.GaussianBlur(3))
    shadow_rgba = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow_rgba.putalpha(shadow.point(lambda v: int(v * 0.55)))
    canvas.alpha_composite(shadow_rgba, (5, 8))

    outline = mask.filter(ImageFilter.MaxFilter(7))
    outline_rgba = Image.new("RGBA", (W, H), COL_OUTLINE + (255,))
    outline_rgba.putalpha(outline)
    canvas.alpha_composite(outline_rgba)

    canvas.alpha_composite(_shade_body(mask, bands, W, H))

    if star_list:
        stars = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        sd = ImageDraw.Draw(stars)
        for (cx, cy, r, col) in star_list:
            _star(sd, cx, cy, r, col)
        canvas.alpha_composite(stars)
    return canvas


def build_title(out_path: str) -> None:
    scale = 8
    advance = GLYPH_W * scale + 6
    gap = 12
    line1, line2 = "ALONSO", "INVADER"

    w1 = _text_width(line1, scale, advance)
    w2 = _text_width(line2, scale, advance)
    content_w = max(w1, w2)
    content_h = GLYPH_H * scale * 2 + gap

    pad_x, pad_top, pad_bottom = 20, 20, 30
    W = content_w + pad_x * 2
    H = content_h + pad_top + pad_bottom

    mask = Image.new("L", (W, H), 0)
    y1 = pad_top
    y2 = pad_top + GLYPH_H * scale + gap
    _draw_text(mask, line1, pad_x + (content_w - w1) // 2, y1, scale, advance)
    _draw_text(mask, line2, pad_x + (content_w - w2) // 2, y2, scale, advance)

    bands = [(y1, y1 + GLYPH_H * scale), (y2, y2 + GLYPH_H * scale)]
    stars = [
        (pad_x - 6, y1 + 8, 9, (255, 255, 255, 220)),
        (W - pad_x + 6, y2 + 22, 11, (180, 230, 255, 220)),
        (pad_x + 4, y2 + GLYPH_H * scale + 8, 6, (255, 226, 150, 200)),
    ]
    canvas = _compose_logo(mask, bands, W, H, stars)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    canvas.save(out_path)
    print(f"Titulo: {out_path} ({W}x{H})")


def build_icon(out_path: str, size: int = 512) -> None:
    # 1) Fondo redondeado con degradado vertical (espacio profundo).
    grad = Image.new("RGB", (size, size))
    gp = grad.load()
    top, bot = (10, 18, 48), (30, 52, 110)
    for y in range(size):
        col = _lerp(top, bot, y / float(size - 1))
        for x in range(size):
            gp[x, y] = col
    rounded = Image.new("L", (size, size), 0)
    ImageDraw.Draw(rounded).rounded_rectangle([0, 0, size - 1, size - 1],
                                              radius=int(size * 0.2), fill=255)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(grad, (0, 0), rounded)

    # 2) Estrellitas de fondo.
    stars_bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sdb = ImageDraw.Draw(stars_bg)
    rng = random.Random(7)
    for _ in range(70):
        x = rng.randint(6, size - 7)
        y = rng.randint(6, size - 7)
        if rounded.getpixel((x, y)) == 0:
            continue
        r = rng.choice([1, 1, 1, 2])
        a = rng.randint(90, 210)
        sdb.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, a))
    canvas.alpha_composite(stars_bg)

    # 3) Letra "A" cromada grande (misma tipografía del título).
    scale = 44
    lw = GLYPH_W * scale
    lh = GLYPH_H * scale
    mask = Image.new("L", (size, size), 0)
    _draw_text(mask, "A", (size - lw) // 2, (size - lh) // 2, scale, 0)
    bands = [((size - lh) // 2, (size - lh) // 2 + lh)]
    logo = _compose_logo(mask, bands, size, size)

    # Recorto el logo a la zona del lettering para no pisar las estrellas del fondo.
    canvas.alpha_composite(logo)

    # 4) Filete interior dorado.
    ring = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rdr = ImageDraw.Draw(ring)
    inset = int(size * 0.055)
    rdr.rounded_rectangle([inset, inset, size - 1 - inset, size - 1 - inset],
                          radius=int(size * 0.16), outline=(255, 196, 92, 200),
                          width=max(3, size // 64))
    canvas.alpha_composite(ring)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    canvas.save(out_path)
    print(f"Icono:  {out_path} ({size}x{size})")


if __name__ == "__main__":
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ui = os.path.join(root, "assets", "sprites", "ui")
    build_title(os.path.join(ui, "title_logo.png"))
    build_icon(os.path.join(ui, "app_icon.png"))
