#!/usr/bin/env python3
"""Maakt App Store-afbeeldingen van de ruwe simulator-screenshots.

Gebruik:  python3 scripts/compose_appstore.py <fonts-map>
Invoer:   AppStore/raw/{iphone,ipad}/*.png
Uitvoer:  AppStore/screenshots/iphone-6.3/*.png   (1206 x 2622)
          AppStore/screenshots/ipad-13/*.png      (2064 x 2752)
          AppStore/promo/*.png                    (banners)
"""
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "scripts", "fonts")
RAW = os.path.join(ROOT, "AppStore", "raw")
OUT = os.path.join(ROOT, "AppStore")

NAVY = (0x1D, 0x38, 0x63)
INK = (0x0F, 0x18, 0x29)
GOLD = (0xFF, 0xBD, 0x14)
ORANGE = (0xFF, 0x66, 0x00)
RED = (0xAE, 0x1C, 0x28)
WHITE = (0xFA, 0xFA, 0xFA)
BLUE = (0x21, 0x46, 0x8B)


def font(name, size):
    for root, _, files in os.walk(FONTS):
        if name in files:
            return ImageFont.truetype(os.path.join(root, name), size)
    raise SystemExit(f"Font {name} niet gevonden in {FONTS}")


SERIF = "Fraunces_700Bold.ttf"
SANS = "Inter_500Medium.ttf"
SANS_BOLD = "Inter_700Bold.ttf"

# (raw-bestand, eyebrow, kop, onderregel) in App Store-volgorde
SLIDES = [
    ("01-vandaag-ja", "VLAGDAGEN 2.0", "Mag de vlag\nvandaag uit?", "Ja of nee, in één oogopslag."),
    ("05-meldingen", "AUTOMATISCH", "Elke vlagdag\neen seintje", "Een ochtendmelding op jouw tijd."),
    ("04-agenda", "AGENDA", "Alle vlagdagen\nop een rij", "Verschoven datums rekenen we zelf uit."),
    ("02-aftellen", "AFTELKLOK", "Tel af naar de\nvolgende vlagdag", "Met wimpel? Je ziet het meteen."),
    ("03-halfstok", "4 MEI", "Halfstok tot\nzonsondergang", "Met de exacte tijd voor jouw dag."),
    ("06-handleiding", "HANDLEIDING", "Zo hang je\nde vlag goed", "Hijsen, halfstok en de wimpel."),
    ("07-detail", "ACHTERGROND", "Weet waarom\nwe vlaggen", "Uitleg bij elke vlagdag."),
    ("08-welkom", "WELKOM", "Mis nooit meer\neen vlagdag", "Meldingen, agenda-abonnement en widgets."),
]


# ---------- tekenhulpen ----------

def gradient(w, h, c1=NAVY, c2=INK, angle=False):
    base = Image.new("RGB", (1, 256))
    for y in range(256):
        t = y / 255
        base.putpixel((0, y), tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3)))
    return base.resize((w, h), Image.BICUBIC)


def glow(img, cx, cy, r, color=GOLD, strength=70):
    w, h = img.size
    scale = 8
    m = Image.new("L", (w // scale, h // scale), 0)
    ImageDraw.Draw(m).ellipse([(cx - r) / scale, (cy - r) / scale, (cx + r) / scale, (cy + r) / scale], fill=strength)
    m = m.filter(ImageFilter.GaussianBlur(r / scale * 0.6)).resize((w, h), Image.BICUBIC)
    img.paste(Image.new("RGB", (w, h), color), (0, 0), m)


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return m


def shadow(img, box, radius, blur, opacity=120, offset=(0, 0)):
    w, h = img.size
    s = Image.new("L", (w, h), 0)
    x0, y0, x1, y1 = box
    ImageDraw.Draw(s).rounded_rectangle([x0 + offset[0], y0 + offset[1], x1 + offset[0], y1 + offset[1]], radius=radius, fill=opacity)
    s = s.filter(ImageFilter.GaussianBlur(blur))
    img.paste(Image.new("RGB", (w, h), (0, 0, 0)), (0, 0), s)


def device(img, shot, x, y, width, kind):
    """Plak screenshot in een eenvoudig apparaatframe."""
    sw, sh = shot.size
    screen_w = width
    screen_h = int(sh * screen_w / sw)
    bezel = int(width * (0.035 if kind == "iphone" else 0.03))
    r_screen = int(width * (0.13 if kind == "iphone" else 0.045))
    r_frame = r_screen + bezel
    box = (x - bezel, y - bezel, x + screen_w + bezel, y + screen_h + bezel)
    shadow(img, box, r_frame, blur=int(width * 0.05), opacity=150, offset=(0, int(width * 0.03)))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(box, radius=r_frame, fill=(0x0B, 0x0E, 0x14))
    d.rounded_rectangle([box[0] + 3, box[1] + 3, box[2] - 3, box[3] - 3], radius=r_frame - 3, outline=(0x3A, 0x41, 0x50), width=max(2, bezel // 6))
    scr = shot.resize((screen_w, screen_h), Image.LANCZOS)
    img.paste(scr, (x, y), rounded_mask((screen_w, screen_h), r_screen))


def text_block(img, x, y, max_w, eyebrow, title, sub, scale, align="center"):
    d = ImageDraw.Draw(img)
    f_eye = font(SANS_BOLD, int(34 * scale))
    f_title = font(SERIF, int(118 * scale))
    f_sub = font(SANS, int(44 * scale))

    def draw_line(txt, f, fill, yy, spacing=0):
        tw = d.textlength(txt, font=f)
        xx = x + (max_w - tw) / 2 if align == "center" else x
        d.text((xx, yy), txt, font=f, fill=fill)
        return f.getbbox("Hg")[3] + spacing

    # eyebrow met letterspatiëring
    eye = " ".join(eyebrow)  # simpele tracking
    y += draw_line(eye, f_eye, GOLD, y, int(28 * scale))
    for line in title.split("\n"):
        y += draw_line(line, f_title, (255, 255, 255), y, int(-8 * scale))
    y += int(34 * scale)
    y += draw_line(sub, f_sub, (0xC9, 0xD3, 0xE6), y)
    return y


def tricolor_ribbon(img, cx, cy, width, height, amp, pennant=True, waves=1.0):
    """Wapperende driekleur met wimpel (voor banners)."""
    W = img.size[0]
    n = 500
    x0 = cx - width / 2

    def yoff(t):
        return math.sin((t * waves * 2 - 0.25) * math.pi) * amp * (0.35 + t)

    def slope(t):
        return math.cos((t * waves * 2 - 0.25) * math.pi)

    sh = Image.new("L", img.size, 0)
    sd = ImageDraw.Draw(sh)
    pts = [(x0 + width * i / n, cy - height / 2 + yoff(i / n) + height * 0.08) for i in range(n + 1)]
    pts += [(x0 + width * i / n, cy + height / 2 + yoff(i / n) + height * 0.08) for i in range(n, -1, -1)]
    sd.polygon(pts, fill=110)
    img.paste(Image.new("RGB", img.size, (0, 0, 0)), (0, 0), sh.filter(ImageFilter.GaussianBlur(height * 0.1)))

    d = ImageDraw.Draw(img)
    if pennant:
        py = cy - height / 2 - height * 0.2
        ph = height * 0.13
        top, bot = [], []
        for i in range(n + 1):
            t = i / n
            x = x0 + width * 1.06 * t
            hh = ph * (1 - t * 0.94) / 2
            top.append((x, py + yoff(t) * 0.8 - hh))
            bot.append((x, py + yoff(t) * 0.8 + hh))
        d.polygon(top + bot[::-1], fill=ORANGE)
    for b, col in enumerate([RED, WHITE, BLUE]):
        top, bot = [], []
        for i in range(n + 1):
            t = i / n
            x = x0 + width * t
            top.append((x, cy - height / 2 + height * b / 3 + yoff(t)))
            bot.append((x, cy - height / 2 + height * (b + 1) / 3 + yoff(t) + 1))
        d.polygon(top + bot[::-1], fill=col)
    # plooien
    shade = Image.new("L", img.size, 0)
    light = Image.new("L", img.size, 0)
    sdd, ldd = ImageDraw.Draw(shade), ImageDraw.Draw(light)
    step = width / n
    for i in range(n + 1):
        t = i / n
        x = x0 + width * t
        s = slope(t)
        y1, y2 = cy - height / 2 + yoff(t), cy + height / 2 + yoff(t)
        (sdd if s < 0 else ldd).line([(x, y1), (x, y2)], fill=int(abs(s) * (70 if s < 0 else 40)), width=int(step) + 2)
    img.paste(Image.new("RGB", img.size, (0, 0, 0)), (0, 0), shade.filter(ImageFilter.GaussianBlur(height * 0.03)))
    img.paste(Image.new("RGB", img.size, (255, 255, 255)), (0, 0), light.filter(ImageFilter.GaussianBlur(height * 0.03)))
    # mast
    mw = max(6, int(height * 0.035))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x0 - mw, cy - height * 0.95, x0, cy + height * 1.6], radius=mw // 2, fill=(0xE8, 0xEC, 0xF3))
    d.ellipse([x0 - mw * 2.2, cy - height * 0.95 - mw * 2.6, x0 + mw * 1.2, cy - height * 0.95 + mw * 0.8], fill=GOLD)


# ---------- screenshots ----------

def compose_screens(kind, size, folder):
    W, H = size
    src = os.path.join(RAW, kind)
    dst = os.path.join(OUT, "screenshots", folder)
    os.makedirs(dst, exist_ok=True)
    scale = W / 1206 if kind == "iphone" else W / 2064 * 1.25
    made = []
    for idx, (raw, eyebrow, title, sub) in enumerate(SLIDES, start=1):
        path = os.path.join(src, raw + ".png")
        if not os.path.exists(path):
            print("  ontbreekt:", path)
            continue
        shot = Image.open(path).convert("RGB")
        img = gradient(W, H)
        glow(img, W * 0.85, H * 0.10, W * 0.6, (0x34, 0x63, 0xAE), 90)
        glow(img, W * 0.1, H * 0.95, W * 0.6, (0x3A, 0x6B, 0xB8), 70)
        top = int(H * 0.055)
        text_block(img, int(W * 0.06), top, int(W * 0.88), eyebrow, title, sub, scale)
        dev_w = int(W * (0.80 if kind == "iphone" else 0.78))
        dev_x = (W - dev_w) // 2
        dev_y = int(H * (0.315 if kind == "iphone" else 0.285))
        device(img, shot, dev_x, dev_y, dev_w, kind)
        out = os.path.join(dst, f"{idx:02d}-{raw[3:]}.png")
        img.save(out, optimize=True)
        made.append(out)
    return made


# ---------- promobanners ----------

def banner(W, H, shot_path, name):
    img = gradient(W, H)
    glow(img, W * 0.75, H * 0.2, H * 0.8, (0x34, 0x63, 0xAE), 90)
    glow(img, W * 0.05, H * 1.0, H * 0.9, (0x3A, 0x6B, 0xB8), 80)
    d = ImageDraw.Draw(img)
    s = H / 1280
    wide = W / H > 2

    # Links: icoon + tekst
    icon = Image.open(os.path.join(ROOT, "Vlagdagen", "Assets.xcassets", "AppIcon.appiconset", "AppIcon-1024.png")).convert("RGB")
    isz = int(190 * s)
    left = int(W * (0.06 if not wide else 0.05))
    ty = int(H * (0.2 if not wide else 0.17))
    shadow(img, (left, ty, left + isz, ty + isz), int(isz * 0.225), int(isz * 0.12), 140, (0, int(isz * 0.05)))
    img.paste(icon.resize((isz, isz), Image.LANCZOS), (left, ty), rounded_mask((isz, isz), int(isz * 0.225)))
    ty += isz + int(60 * s)
    f_title = font(SERIF, int(150 * s))
    f_tag = font(SERIF, int(66 * s))
    f_body = font(SANS, int(40 * s))
    f_pill = font(SANS_BOLD, int(34 * s))
    d = ImageDraw.Draw(img)
    d.text((left, ty), "Vlagdagen", font=f_title, fill=(255, 255, 255))
    ty += int(175 * s)
    d.text((left, ty), "Mag de vlag vandaag uit?", font=f_tag, fill=GOLD)
    ty += int(110 * s)
    for line in ["Ochtendmelding op elke vlagdag, aftelklok,", "agenda-abonnement en widgets."]:
        d.text((left, ty), line, font=f_body, fill=(0xC9, 0xD3, 0xE6))
        ty += int(56 * s)
    ty += int(40 * s)
    pill = "NIEUW · VERSIE 2.0"
    pw = d.textlength(pill, font=f_pill) + 64 * s
    d.rounded_rectangle([left, ty, left + pw, ty + 72 * s], radius=36 * s, fill=ORANGE)
    d.text((left + 32 * s, ty + 16 * s), pill, font=f_pill, fill=(255, 255, 255))

    # Rechts: wapperende vlag + telefoon
    tricolor_ribbon(img, W * (0.66 if not wide else 0.70), H * 0.40, H * 0.62, H * 0.33, H * 0.035)
    shot = Image.open(shot_path).convert("RGB")
    dev_w = int(H * 0.42)
    dev_x = int(W * (0.80 if not wide else 0.84) - dev_w / 2)
    dev_y = int(H * 0.30)
    device(img, shot, dev_x, dev_y, dev_w, "iphone")
    out = os.path.join(OUT, "promo", name)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out, optimize=True)
    return out


def main():
    made = []
    made += compose_screens("iphone", (1206, 2622), "iphone-6.3")
    made += compose_screens("ipad", (2064, 2752), "ipad-13")
    hero = os.path.join(RAW, "iphone", "01-vandaag-ja.png")
    if os.path.exists(hero):
        for (w, h) in [(5244, 2950), (3840, 1646), (3840, 2560), (1920, 1280)]:
            made.append(banner(w, h, hero, f"promo-{w}x{h}.png"))
    for m in made:
        im = Image.open(m)
        print(f"{im.size[0]}x{im.size[1]}  {os.path.relpath(m, ROOT)}")


if __name__ == "__main__":
    main()
