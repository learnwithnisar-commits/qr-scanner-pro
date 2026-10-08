#!/usr/bin/env python3
"""Generate a professional QR-themed launcher icon for QR Scanner Pro.

Dark navy rounded-square with a stylized white QR module pattern,
cyan->violet gradient finder squares and a subtle scan-line accent.
Writes legacy mipmap PNGs (mdpi..xxxhdpi).
"""
import os
from PIL import Image, ImageDraw

RES = "android/app/src/main/res"
SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
BASE = 1024


def vgrad(size, top, bottom):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        px[0, 0]  # warm cache
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        for x in range(size):
            px[x, y] = (r, g, b)
    return img


def rounded_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def draw_icon(size):
    # Background: deep navy gradient.
    bg = vgrad(size, (13, 18, 38), (7, 11, 24))
    bg.putalpha(255)
    bg = bg.convert("RGBA")
    bg.putalpha(rounded_mask(size, int(size * 0.225)))

    d = ImageDraw.Draw(bg, "RGBA")

    # QR module grid (deterministic pattern).
    n = 13
    margin = int(size * 0.20)
    cell = (size - 2 * margin) / n
    mod = cell * 0.86
    ox, oy = margin + (cell - mod) / 2, margin + (cell - mod) / 2

    def finder(cx, cy):
        return (cx < 4 or cx > n - 5) and (cy < 4 or cy > n - 5)

    # Pseudo-random inner modules (fixed seed pattern, symmetric-ish).
    import hashlib
    def on(cx, cy):
        if finder(cx, cy):
            return False
        h = hashlib.md5(f"{cx},{cy}".encode()).digest()[0]
        return h % 10 < 4

    white = (240, 245, 255, 255)
    for cy in range(n):
        for cx in range(n):
            if on(cx, cy):
                x0 = ox + cx * cell
                y0 = oy + cy * cell
                d.rounded_rectangle(
                    [x0, y0, x0 + mod, y0 + mod],
                    radius=int(mod * 0.28),
                    fill=white,
                )

    # Finder squares with cyan->violet gradient.
    def grad_square(x0, y0, x1, y1, steps=48):
        for i in range(steps):
            t = i / (steps - 1)
            c = lerp((0, 229, 204), (124, 77, 255), t) + (255,)
            d.line([(x0, y0 + i * (y1 - y0) / steps),
                    (x1, y0 + (i + 1) * (y1 - y0) / steps)], fill=c,
                   width=int((y1 - y0) / steps) + 1)

    def finder_at(gx, gy):
        x0 = ox + gx * cell - cell * 0.12
        y0 = oy + gy * cell - cell * 0.12
        s = 4 * cell + cell * 0.24
        # outer ring
        d.rounded_rectangle([x0, y0, x0 + s, y0 + s],
                            radius=int(s * 0.22), outline=None)
        # gradient fill clipped to rounded rect
        tmp = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        td = ImageDraw.Draw(tmp)
        td.rounded_rectangle([x0, y0, x0 + s, y0 + s],
                             radius=int(s * 0.22), fill=(255, 255, 255, 255))
        grad = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        gd = ImageDraw.Draw(grad)
        for i in range(64):
            t = i / 63
            c = lerp((0, 229, 204), (124, 77, 255), t) + (255,)
            gd.line([(x0, y0 + i * s / 64), (x0 + s, y0 + (i + 1) * s / 64)],
                    fill=c, width=int(s / 64) + 1)
        grad = Image.composite(grad, Image.new("RGBA", (size, size), (0, 0, 0, 0)), tmp)
        bg.alpha_composite(grad)
        # punch dark hole
        hole = Image.new("L", (size, size), 0)
        hd = ImageDraw.Draw(hole)
        ix0, iy0 = x0 + cell * 0.85, y0 + cell * 0.85
        ix1, iy1 = x0 + s - cell * 0.85, y0 + s - cell * 0.85
        hd.rounded_rectangle([ix0, iy0, ix1, iy1], radius=int((ix1 - ix0) * 0.22), fill=255)
        dark = Image.new("RGBA", (size, size), (10, 14, 28, 255))
        bg.paste(Image.composite(dark, Image.new("RGBA", (size, size), (0, 0, 0, 0)), hole), (0, 0), hole)
        # inner dot with gradient
        dot = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        dd = ImageDraw.Draw(dot)
        jx0, jy0 = ix0 + cell * 0.55, iy0 + cell * 0.55
        jx1, jy1 = ix1 - cell * 0.55, iy1 - cell * 0.55
        for i in range(32):
            t = i / 31
            c = lerp((0, 229, 204), (124, 77, 255), t) + (255,)
            dd.line([(jx0, jy0 + i * (jy1 - jy0) / 32),
                     (jx1, jy0 + (i + 1) * (jy1 - jy0) / 32)],
                    fill=c, width=int((jy1 - jy0) / 32) + 1)
        dmask = Image.new("L", (size, size), 0)
        dmd = ImageDraw.Draw(dmask)
        dmd.rounded_rectangle([jx0, jy0, jx1, jy1], radius=int((jx1 - jx0) * 0.3), fill=255)
        dot = Image.composite(dot, Image.new("RGBA", (size, size), (0, 0, 0, 0)), dmask)
        bg.alpha_composite(dot)

    finder_at(0, 0)
    finder_at(n - 4, 0)
    finder_at(0, n - 4)

    # Scan-line accent under the QR block.
    d2 = ImageDraw.Draw(bg, "RGBA")
    ly = oy + n * cell + cell * 0.9
    lw = n * cell * 0.55
    lx0 = (size - lw) / 2
    for i in range(40):
        t = i / 39
        c = lerp((0, 229, 204), (124, 77, 255), t) + (235,)
        d2.line([(lx0 + i * lw / 40, ly), (lx0 + (i + 1) * lw / 40, ly)],
                fill=c, width=max(2, int(size * 0.008)))
    return bg


os.chdir(os.path.expanduser("~/workspace/qr-scanner-app"))
full = draw_icon(BASE)
for folder, px in SIZES.items():
    out = full.resize((px, px), Image.LANCZOS)
    path = os.path.join(RES, folder, "ic_launcher.png")
    out.save(path)
    print("wrote", path)
