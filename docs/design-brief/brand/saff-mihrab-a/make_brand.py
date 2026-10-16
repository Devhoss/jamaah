"""Generates the Saff + Mihrab (A) icon kit: SVG masters, Android vector drawables and PNGs.

All shapes come from one geometry in Android's 108-unit adaptive-icon grid
(the launcher shows the middle 72 units; the safe zone is a 66-unit circle).
Usage: python -I make_brand.py <output dir>
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

OUT = sys.argv[1]

# ---------------------------------------------------------------- geometry
BG_STOPS = [(0.0, '#1F2A5E'), (0.35, '#3A3470'), (0.55, '#9A4C78'), (0.72, '#E0805E'), (0.80, '#8A3E5A'), (1.0, '#2A1630')]
CREAM = '#FFF4EA'
AMBER = '#FFC979'
GLOW = '#FFD9A0'
ARCH = 'M30,76 V52 C30,40 44,31 54,26 C64,31 78,40 78,52 V76'
ARCH_W = 3.2
FIGS = [37.0, 45.5, 54.0, 62.5]   # cream figures (x centre)
YOU = 71.0                         # the lit figure: you, joining the row
HEAD_Y, HEAD_R = 52.0, 3.1
BODY_Y, BODY_W, BODY_H = 57.0, 7.4, 15.0
GLOW_C, GLOW_R = (71.0, 62.0), 12.0


def head_path(cx, r=HEAD_R):
    return f'M{cx - r:g},{HEAD_Y:g} a{r:g},{r:g} 0 1,0 {2 * r:g},0 a{r:g},{r:g} 0 1,0 {-2 * r:g},0 Z'


def body_path(cx, bw=BODY_W):
    r = bw / 2
    top, bot = BODY_Y + r, BODY_Y + BODY_H - r
    return (f'M{cx - r:g},{top:g} A{r:g},{r:g} 0 0,1 {cx + r:g},{top:g} V{bot:g} '
            f'A{r:g},{r:g} 0 0,1 {cx - r:g},{bot:g} Z')


def figure_path(cx, head_r=HEAD_R, body_w=BODY_W):
    return head_path(cx, head_r) + ' ' + body_path(cx, body_w)


# Status-bar icon: all five figures, slimmer, so the gaps survive at 24 dp (~1 dp each).
STAT_HEAD_R, STAT_BODY_W, STAT_ARCH_W = 2.6, 5.6, 4.5


def hexa(h, a=1.0):
    """#RRGGBB -> Android #AARRGGBB."""
    return '#%02X%s' % (round(a * 255), h[1:].upper())


# ---------------------------------------------------------------- SVG masters
def svg_doc(body, view='0 0 108 108', size=432):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view}" width="{size}" height="{size}">\n'
            f'{body}\n</svg>\n')


def svg_defs():
    stops = '\n'.join(f'      <stop offset="{o}" stop-color="{c}"/>' for o, c in BG_STOPS)
    return (f'  <defs>\n    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">\n{stops}\n    </linearGradient>\n'
            f'    <radialGradient id="glow" cx="{GLOW_C[0]}" cy="{GLOW_C[1]}" r="{GLOW_R}" gradientUnits="userSpaceOnUse">\n'
            f'      <stop offset="0" stop-color="{GLOW}" stop-opacity="0.6"/>\n'
            f'      <stop offset="1" stop-color="{GLOW}" stop-opacity="0"/>\n    </radialGradient>\n  </defs>')


def svg_fg(c1=CREAM, c2=AMBER, glow=True, arch_w=ARCH_W, figs=FIGS, hr=HEAD_R, bw=BODY_W):
    parts = []
    if glow:
        parts.append(f'  <circle cx="{GLOW_C[0]}" cy="{GLOW_C[1]}" r="{GLOW_R}" fill="url(#glow)"/>')
    parts.append(f'  <path d="{ARCH}" fill="none" stroke="{c1}" stroke-width="{arch_w}" stroke-linecap="round" stroke-linejoin="round"/>')
    for x in figs:
        parts.append(f'  <path d="{figure_path(x, hr, bw)}" fill="{c1}"/>')
    parts.append(f'  <path d="{figure_path(YOU, hr, bw)}" fill="{c2}"/>')
    return '\n'.join(parts)


def write(rel, text):
    path = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


def masters():
    bg = '  <rect width="108" height="108" fill="url(#sky)"/>'
    write('svg/icon-full.svg', svg_doc(svg_defs() + '\n' + bg + '\n' + svg_fg(), view='18 18 72 72', size=512))
    write('svg/ic_launcher_background.svg', svg_doc(svg_defs() + '\n' + bg))
    write('svg/ic_launcher_foreground.svg', svg_doc(svg_defs() + '\n' + svg_fg()))
    write('svg/ic_launcher_monochrome.svg', svg_doc(svg_fg('#000000', '#000000', glow=False)))
    # In-app mark: transparent, tinted by the app (currentColor) with the lit figure kept amber.
    write('svg/mark.svg', svg_doc(svg_fg('currentColor', AMBER, glow=False), view='26 22 56 58', size=224))
    write('svg/mark-mono.svg', svg_doc(svg_fg('currentColor', 'currentColor', glow=False), view='26 22 56 58', size=224))
    notif = svg_fg('#FFFFFF', '#FFFFFF', glow=False, arch_w=STAT_ARCH_W, hr=STAT_HEAD_R, bw=STAT_BODY_W)
    write('svg/ic_stat_jamaah.svg', svg_doc(notif, view='26 22 56 58', size=96))


# ---------------------------------------------------------------- Android vector drawables
def vd_paths(c1, c2, arch_w, figs, glow, hr=HEAD_R, bw=BODY_W):
    out = []
    if glow:
        out.append(f'''    <path android:pathData="M{GLOW_C[0] - GLOW_R:g},{GLOW_C[1]:g} a{GLOW_R:g},{GLOW_R:g} 0 1,0 {2 * GLOW_R:g},0 a{GLOW_R:g},{GLOW_R:g} 0 1,0 {-2 * GLOW_R:g},0 Z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="radial" android:centerX="{GLOW_C[0]:g}" android:centerY="{GLOW_C[1]:g}" android:gradientRadius="{GLOW_R:g}">
                <item android:offset="0" android:color="{hexa(GLOW, 0.6)}"/>
                <item android:offset="1" android:color="{hexa(GLOW, 0.0)}"/>
            </gradient>
        </aapt:attr>
    </path>''')
    out.append(f'    <path android:pathData="{ARCH}" android:strokeColor="{c1}" android:strokeWidth="{arch_w:g}" '
               f'android:strokeLineCap="round" android:strokeLineJoin="round"/>')
    for x in figs:
        out.append(f'    <path android:fillColor="{c1}" android:pathData="{figure_path(x, hr, bw)}"/>')
    out.append(f'    <path android:fillColor="{c2}" android:pathData="{figure_path(YOU, hr, bw)}"/>')
    return '\n'.join(out)


VD_HEAD = '''<?xml version="1.0" encoding="utf-8"?>
<!-- Jama’ah icon, Saff + Mihrab (A). Generated by make_brand.py; edit the script, not this file. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="{w}dp"
    android:height="{w}dp"
    android:viewportWidth="{v}"
    android:viewportHeight="{v}">
'''


def drawables():
    stops = '\n'.join(f'                <item android:offset="{o}" android:color="{hexa(c)}"/>' for o, c in BG_STOPS)
    write('android/res/drawable/ic_launcher_background.xml', VD_HEAD.format(w=108, v=108) + f'''    <path android:pathData="M0,0h108v108h-108z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="linear" android:startX="54" android:startY="0" android:endX="54" android:endY="108">
{stops}
            </gradient>
        </aapt:attr>
    </path>
</vector>
''')
    write('android/res/drawable/ic_launcher_foreground.xml',
          VD_HEAD.format(w=108, v=108) + vd_paths(hexa(CREAM), hexa(AMBER), ARCH_W, FIGS, True) + '\n</vector>\n')
    write('android/res/drawable/ic_launcher_monochrome.xml',
          VD_HEAD.format(w=108, v=108) + vd_paths('#FF000000', '#FF000000', ARCH_W, FIGS, False) + '\n</vector>\n')
    # Splash (Android 12+): same layer drawn at 288 dp; the system shows the middle 192 dp circle,
    # the same 2/3 ratio as the launcher, so the foreground geometry fits unchanged.
    write('android/res/drawable/splash_icon.xml',
          VD_HEAD.format(w=288, v=108) + vd_paths(hexa(CREAM), hexa(AMBER), ARCH_W, FIGS, True) + '\n</vector>\n')
    # Status bar: white on transparent, the arch and all five figures, slimmer so the gaps survive at 24 dp.
    s = 20 / 58
    tx, ty = 2 - 26 * s, 2 - 22 * s
    write('android/res/drawable/ic_stat_jamaah.xml',
          VD_HEAD.format(w=24, v=24).replace(
              "Jama’ah icon", "Status-bar icon (white, alpha only)") +
          f'    <group android:scaleX="{s:.5f}" android:scaleY="{s:.5f}" android:translateX="{tx:.4f}" android:translateY="{ty:.4f}">\n' +
          vd_paths('#FFFFFFFF', '#FFFFFFFF', STAT_ARCH_W, FIGS, False, STAT_HEAD_R, STAT_BODY_W).replace('    <path', '        <path') +
          '\n    </group>\n</vector>\n')
    adaptive = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
'''
    write('android/res/mipmap-anydpi-v26/ic_launcher.xml', adaptive)
    write('android/res/mipmap-anydpi-v26/ic_launcher_round.xml', adaptive)
    write('android/res/values/brand_colors.xml', '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Splash background (top of the icon's sky) and the mark's colours. -->
    <color name="brand_splash">#1F2A5E</color>
    <color name="brand_cream">#FFF4EA</color>
    <color name="brand_amber">#FFC979</color>
</resources>
''')


# ---------------------------------------------------------------- PNG rendering (supersampled)
def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def cubic(p0, p1, p2, p3, n=48):
    pts = []
    for i in range(n + 1):
        t = i / n
        a, b, c, d = (1 - t) ** 3, 3 * (1 - t) ** 2 * t, 3 * (1 - t) * t * t, t ** 3
        pts.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return pts


ARCH_PTS = [(30, 76), (30, 52)] + cubic((30, 52), (30, 40), (44, 31), (54, 26))[1:] + cubic((54, 26), (64, 31), (78, 40), (78, 52))[1:] + [(78, 76)]


def render(size, window=(18, 90), shape='bleed', bg=True, c1=CREAM, c2=AMBER, glow=True, arch_w=ARCH_W, figs=FIGS, hr=HEAD_R, bw=BODY_W):
    ss = 4
    S = size * ss
    u0, u1 = window
    k = S / (u1 - u0)
    P = lambda x, y: ((x - u0) * k, (y - u0) * k)
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    if bg:
        ys = u0 + (np.arange(S) + 0.5) / k
        t = ys / 108
        cols = np.zeros((S, 3))
        for (o0, h0), (o1, h1) in zip(BG_STOPS, BG_STOPS[1:]):
            m = (t >= o0) & (t <= o1)
            f = ((t[m] - o0) / (o1 - o0))[:, None]
            cols[m] = np.array(rgb(h0)) * (1 - f) + np.array(rgb(h1)) * f
        arr = np.repeat(cols[:, None, :], S, axis=1)
        img = Image.fromarray(np.dstack([arr, np.full((S, S), 255)]).astype('uint8'), 'RGBA')
    if glow:
        yy, xx = np.mgrid[0:S, 0:S]
        gx, gy = P(*GLOW_C)
        d = np.sqrt((xx - gx) ** 2 + (yy - gy) ** 2) / (GLOW_R * k)
        a = np.clip(1 - d, 0, 1) * 0.6
        layer = np.zeros((S, S, 4))
        layer[..., :3] = rgb(GLOW)
        layer[..., 3] = a * 255
        img = Image.alpha_composite(img, Image.fromarray(layer.astype('uint8'), 'RGBA'))
    dr = ImageDraw.Draw(img)
    w = arch_w * k
    pts = [P(x, y) for x, y in ARCH_PTS]
    # Stroke as a dense chain of discs: round joins and caps with no spikes.
    step = max(1.0, w / 6)
    for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(xb - xa, yb - ya) / step))
        for i in range(n + 1):
            x, y = xa + (xb - xa) * i / n, ya + (yb - ya) * i / n
            dr.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=rgb(c1) + (255,))

    def fig(cx, col):
        hx, hy = P(cx, HEAD_Y)
        r = hr * k
        dr.ellipse([hx - r, hy - r, hx + r, hy + r], fill=rgb(col) + (255,))
        x0, y0 = P(cx - bw / 2, BODY_Y)
        x1, y1 = P(cx + bw / 2, BODY_Y + BODY_H)
        dr.rounded_rectangle([x0, y0, x1, y1], radius=bw / 2 * k, fill=rgb(col) + (255,))

    for x in figs:
        fig(x, c1)
    fig(YOU, c2)
    if shape != 'bleed':
        mask = Image.new('L', (S, S), 0)
        md = ImageDraw.Draw(mask)
        if shape == 'round':
            md.ellipse([0, 0, S - 1, S - 1], fill=255)
        else:
            md.rounded_rectangle([0, 0, S - 1, S - 1], radius=S * 0.2, fill=255)
        img.putalpha(Image.fromarray(np.minimum(np.array(img.split()[3]), np.array(mask))))
    return img.resize((size, size), Image.LANCZOS)


def pngs():
    os.makedirs(os.path.join(OUT, 'png'), exist_ok=True)
    render(512).save(os.path.join(OUT, 'png/playstore-512.png'))
    for dens, px in (('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)):
        d = os.path.join(OUT, f'android/res/mipmap-{dens}')
        os.makedirs(d, exist_ok=True)
        render(px, shape='square').save(os.path.join(d, 'ic_launcher.png'))
        render(px, shape='round').save(os.path.join(d, 'ic_launcher_round.png'))
    # Preview sheet: launcher (round, squircle-ish, small), themed light/dark, status-bar icon, splash.
    W, H = 1400, 620
    sheet = Image.new('RGBA', (W, H), (243, 241, 236, 255))
    x = 40
    for px, shape in ((220, 'round'), (220, 'square'), (96, 'round'), (48, 'round')):
        sheet.alpha_composite(render(px, shape=shape), (x, 40 + (220 - px) // 2))
        x += px + 40
    themed_l = render(140, shape='round', bg=False, c1='#253463', c2='#253463', glow=False)
    pad = Image.new('RGBA', (140, 140), (0, 0, 0, 0))
    ImageDraw.Draw(pad).ellipse([0, 0, 139, 139], fill=(221, 228, 244, 255))
    pad.alpha_composite(themed_l)
    sheet.alpha_composite(pad, (40, 300 + 40))
    themed_d = render(140, shape='round', bg=False, c1='#C9D2F0', c2='#C9D2F0', glow=False)
    pad2 = Image.new('RGBA', (140, 140), (0, 0, 0, 0))
    ImageDraw.Draw(pad2).ellipse([0, 0, 139, 139], fill=(46, 50, 66, 255))
    pad2.alpha_composite(themed_d)
    sheet.alpha_composite(pad2, (220, 300 + 40))
    notif = render(72, window=(26, 84), bg=False, c1='#FFFFFF', c2='#FFFFFF', glow=False, arch_w=STAT_ARCH_W, hr=STAT_HEAD_R, bw=STAT_BODY_W)
    box = Image.new('RGBA', (160, 140), (26, 27, 33, 255))
    box.alpha_composite(notif, (44, 34))
    sheet.alpha_composite(box, (400, 300 + 40))
    splash = Image.new('RGBA', (240, 300), rgb('#1F2A5E') + (255,))
    splash.alpha_composite(render(150, shape='round'), (45, 60))
    sheet.alpha_composite(splash, (600, 300))
    sheet.convert('RGB').save(os.path.join(OUT, 'png/preview.png'))


def stat_compare():
    """Status-bar icon at the A53's real size (24 dp ~ 63 px), old four-figure vs five slim figures."""
    sheet = Image.new('RGBA', (560, 220), (26, 27, 33, 255))
    old = render(63, window=(26, 84), bg=False, c1='#FFFFFF', c2='#FFFFFF', glow=False, arch_w=4.5, figs=FIGS[1:])
    new = render(63, window=(26, 84), bg=False, c1='#FFFFFF', c2='#FFFFFF', glow=False, arch_w=STAT_ARCH_W, hr=STAT_HEAD_R, bw=STAT_BODY_W)
    sheet.alpha_composite(old, (40, 40))
    sheet.alpha_composite(new, (140, 40))
    sheet.alpha_composite(old.resize((126, 126), Image.LANCZOS), (260, 10))
    sheet.alpha_composite(new.resize((126, 126), Image.LANCZOS), (400, 10))
    sheet.convert('RGB').save(os.path.join(OUT, 'png/status-bar-compare.png'))


masters()
drawables()
pngs()
stat_compare()
print('ok')
