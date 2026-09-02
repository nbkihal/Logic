"""Generates the app icon: a NAND gate mark in the Caldera palette.

Draws at 4x and downsamples, which is cheaper than hand-rolling antialiasing
and gives clean curves on the D-shaped gate body.

    python tool/generate_icon.py

Writes assets/icon/icon.png (full-bleed, for iOS/web/legacy Android) and
assets/icon/icon_foreground.png (transparent, inset to Android's adaptive
safe zone). Re-run after changing the mark, then `dart run
flutter_launcher_icons`.
"""

import os

from PIL import Image, ImageDraw

EMBER = (0xFC, 0x50, 0x00, 255)
OBSIDIAN = (0x07, 0x06, 0x07, 255)
CLEAR = (0, 0, 0, 0)

SIZE = 1024
SS = 4  # supersample factor


def draw_mark(draw, cx, cy, scale, color, hole):
    """Draws the NAND gate centred on (cx, cy).

    `scale` is 1.0 for a mark sized to a 1024px canvas. `hole` is what shows
    through the inversion bubble — the background colour for a full-bleed
    icon, or nothing when the caller wants the bubble knocked out.
    """
    def u(value):
        return value * scale

    lead = u(34)          # lead thickness
    body_h = u(430)
    body_w = u(400)
    radius = body_h / 2

    left = cx - u(210)
    top = cy - body_h / 2
    right = left + body_w

    # Body: a flat left edge running into a semicircular right edge.
    flat_right = right - radius
    draw.rectangle([left, top, flat_right, top + body_h], fill=color)
    draw.pieslice(
        [flat_right - radius, top, flat_right + radius, top + body_h],
        start=-90,
        end=90,
        fill=color,
    )

    # Inversion bubble, which is what makes it read as NAND rather than AND.
    bubble_r = u(40)
    bubble_cx = right + bubble_r + u(10)
    draw.ellipse(
        [bubble_cx - bubble_r, cy - bubble_r,
         bubble_cx + bubble_r, cy + bubble_r],
        fill=color,
    )
    inner = bubble_r - lead * 0.8
    draw.ellipse(
        [bubble_cx - inner, cy - inner, bubble_cx + inner, cy + inner],
        fill=hole,
    )

    # Output lead and its port dot.
    out_start = bubble_cx + bubble_r
    out_end = cx + u(390)
    draw.rectangle(
        [out_start, cy - lead / 2, out_end, cy + lead / 2], fill=color
    )
    dot = u(30)
    draw.ellipse([out_end - dot, cy - dot, out_end + dot, cy + dot], fill=color)

    # Two input leads, spaced the way the gate widget spaces its ports.
    in_start = cx - u(390)
    for offset in (-u(107), u(107)):
        y = cy + offset
        draw.rectangle(
            [in_start, y - lead / 2, left, y + lead / 2], fill=color
        )
        draw.ellipse(
            [in_start - dot, y - dot, in_start + dot, y + dot], fill=color
        )


def render(path, background, mark_scale, hole):
    canvas = Image.new('RGBA', (SIZE * SS, SIZE * SS), background)
    draw = ImageDraw.Draw(canvas)
    centre = SIZE * SS / 2
    draw_mark(draw, centre, centre, SS * mark_scale, OBSIDIAN, hole)
    canvas.resize((SIZE, SIZE), Image.LANCZOS).save(path)
    print('wrote', path)


def main():
    out = os.path.join('assets', 'icon')
    os.makedirs(out, exist_ok=True)

    # Full-bleed: ember ground, with enough margin that the leads do not
    # graze the rounded corners iOS and the web apply.
    render(os.path.join(out, 'icon.png'), EMBER, 0.86, EMBER)

    # Adaptive foreground: transparent, and inset so Android's mask cannot
    # clip the leads. The bubble is knocked all the way through.
    render(os.path.join(out, 'icon_foreground.png'), CLEAR, 0.62, CLEAR)


if __name__ == '__main__':
    main()
