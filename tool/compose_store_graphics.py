#!/usr/bin/env python3
"""Build Play / App Store icon, feature graphic, and screenshots."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
GFX = ROOT / "store" / "graphics"
ICON_SRC = ROOT / "assets" / "icon" / "app_icon_1024_square.png"
ANDROID_SPLASH = ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi" / "launch_bg.png"
IOS_LAUNCH = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"

CREAM = (255, 246, 229)
BLUSH = (255, 221, 238)
PINK = (255, 126, 182)
PINK_DARK = (224, 85, 143)
YELLOW = (255, 216, 77)
YELLOW_DARK = (224, 177, 0)
MINT = (99, 221, 180)
MINT_DARK = (47, 179, 138)
SKY = (114, 200, 255)
SKY_DARK = (58, 155, 224)
INK = (91, 58, 94)
WHITE = (255, 255, 255)


def font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "/Library/Fonts/Arial.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def flatten(im: Image.Image, bg=CREAM) -> Image.Image:
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    base = Image.new("RGBA", im.size, bg + (255,))
    base.alpha_composite(im)
    return base.convert("RGB")


def gradient(size: tuple[int, int]) -> Image.Image:
    w, h = size
    im = Image.new("RGB", size, CREAM)
    px = im.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(CREAM[0] * (1 - t) + BLUSH[0] * t)
        g = int(CREAM[1] * (1 - t) + BLUSH[1] * t)
        b = int(CREAM[2] * (1 - t) + BLUSH[2] * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    return im


def rounded(draw: ImageDraw.ImageDraw, box, fill, outline=None, width=6, radius=36, shadow=None):
    x0, y0, x1, y1 = box
    if shadow:
        draw.rounded_rectangle((x0, y0 + 8, x1, y1 + 8), radius=radius, fill=shadow)
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width if outline else 0)


def center_text(draw: ImageDraw.ImageDraw, xy, text, fnt, fill):
    x, y = xy
    bbox = draw.textbbox((0, 0), text, font=fnt)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text((x - w / 2, y - h / 2), text, font=fnt, fill=fill)


def pill(draw, xy, text, fill, fnt):
    pad_x, pad_y = 28, 14
    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x, y = xy
    box = (x, y, x + tw + pad_x * 2, y + th + pad_y * 2)
    draw.rounded_rectangle(box, radius=40, fill=fill)
    draw.text((x + pad_x, y + pad_y - 2), text, font=fnt, fill=WHITE)
    return box[2], box[3]


def button(draw, box, text, fill, shadow, fnt):
    rounded(draw, box, fill=fill, shadow=shadow, radius=28)
    x0, y0, x1, y1 = box
    center_text(draw, ((x0 + x1) / 2, (y0 + y1) / 2 - 2), text, fnt, WHITE)


def crop_bolt(icon: Image.Image) -> Image.Image:
    w, h = icon.size
    return icon.crop((int(w * 0.18), int(h * 0.10), int(w * 0.82), int(h * 0.90)))


def paste_badge(base: Image.Image, src: Image.Image, xy: tuple[int, int], size: tuple[int, int]) -> None:
    badge = src.resize(size, Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius=int(min(size) * 0.22), fill=255)
    base.paste(badge, xy, mask)


def phone_canvas() -> Image.Image:
    return gradient((1080, 1920))


def shot_home(bolt: Image.Image) -> Image.Image:
    im = phone_canvas()
    draw = ImageDraw.Draw(im)
    paste_badge(im, bolt, (270, 160), (540, 560))
    center_text(draw, (540, 780), "Chớp Chớp", font(72), PINK_DARK)
    center_text(draw, (540, 860), "QUIZ", font(48), SKY_DARK)
    pill(draw, (350, 910), "Kỷ lục: 9 sao", YELLOW_DARK, font(28))
    button(draw, (180, 1080, 900, 1188), "CHƠI NGAY", MINT, MINT_DARK, font(36))
    button(draw, (180, 1230, 900, 1328), "Bảng xếp hạng", SKY, SKY_DARK, font(32))
    button(draw, (180, 1370, 900, 1468), "Cách chơi", PINK, PINK_DARK, font(32))
    return im


def shot_play(bolt: Image.Image) -> Image.Image:
    im = phone_canvas()
    draw = ImageDraw.Draw(im)
    pill(draw, (40, 70), "87s", SKY, font(28))
    pill(draw, (820, 70), "4 sao", YELLOW_DARK, font(28))
    draw.rounded_rectangle((40, 160, 1040, 184), radius=12, fill=WHITE)
    draw.rounded_rectangle((40, 160, 40 + int(1000 * 0.72), 184), radius=12, fill=MINT)
    for i in range(10):
        x = 140 + i * 80
        draw.regular_polygon((x, 240, 22), 5, fill=YELLOW if i < 4 else (235, 220, 232))
    rounded(draw, (40, 290, 1040, 620), fill=WHITE, outline=PINK, width=8, shadow=PINK_DARK, radius=40)
    center_text(draw, (540, 360), "Địa lý  ·  Vừa", font(26), SKY_DARK)
    q_font = font(40)
    center_text(draw, (540, 460), "Thủ đô của Việt Nam", q_font, INK)
    center_text(draw, (540, 520), "là thành phố nào?", q_font, INK)
    # center the multiline roughly
    answers = [
        ("A  Hà Nội", MINT, MINT_DARK, WHITE),
        ("B  Huế", WHITE, SKY, INK),
        ("C  Hải Phòng", WHITE, SKY, INK),
        ("D  Đà Nẵng", WHITE, SKY, INK),
    ]
    y = 660
    for label, fill, shadow, fg in answers:
        rounded(draw, (40, y, 1040, y + 120), fill=fill, outline=shadow, width=6, shadow=shadow, radius=28)
        draw.text((80, y + 36), label, font=font(34), fill=fg)
        y += 150
    return im


def shot_guide(bolt: Image.Image) -> Image.Image:
    im = phone_canvas()
    draw = ImageDraw.Draw(im)
    draw.text((60, 70), "Cách chơi", font=font(48), fill=PINK_DARK)
    paste_badge(im, bolt, (390, 140), (300, 320))
    rules = [
        ("120 giây mỗi lượt. Trả lời càng nhanh càng tốt!", "120s"),
        ("Trả lời đúng: được +1 sao.", "+1"),
        ("Trả lời sai: số sao quay về 0.", "0"),
        ("Càng nhiều sao, câu hỏi càng khó.", "!"),
        ("Điểm = số sao cao nhất trong lượt.", "*"),
    ]
    y = 460
    for text, badge in rules:
        rounded(draw, (40, y, 1040, y + 160), fill=WHITE, outline=BLUSH, width=6, radius=32)
        draw.ellipse((70, y + 40, 170, y + 140), fill=PINK)
        center_text(draw, (120, y + 90), badge, font(22), WHITE)
        draw.multiline_text((200, y + 48), text, font=font(28), fill=INK, spacing=6)
        y += 180
    return im


def splash(bolt: Image.Image) -> Image.Image:
    im = phone_canvas()
    draw = ImageDraw.Draw(im)
    paste_badge(im, bolt, (220, 420), (640, 680))
    center_text(draw, (540, 1220), "Chớp Chớp", font(80), PINK_DARK)
    center_text(draw, (540, 1320), "QUIZ", font(52), SKY_DARK)
    return im


def main() -> None:
    GFX.mkdir(parents=True, exist_ok=True)
    icon = flatten(Image.open(ICON_SRC))
    icon.save(ICON_SRC)
    icon.save(GFX / "app_icon_1024.png")
    icon.resize((512, 512), Image.Resampling.LANCZOS).save(GFX / "play_icon_512.png")

    bolt = crop_bolt(icon)

    feature = gradient((1024, 500))
    left = bolt.resize((390, 420), Image.Resampling.LANCZOS)
    feature.paste(left, (30, 40))
    d = ImageDraw.Draw(feature)
    d.text((430, 130), "Chớp Chớp", font=font(64), fill=PINK_DARK)
    d.text((430, 220), "QUIZ", font=font(52), fill=SKY_DARK)
    d.text((430, 320), "120 giây  ·  Đúng +1 sao  ·  Sai về 0", font=font(24, bold=False), fill=INK)
    feature.save(GFX / "play_feature_1024x500.png")

    shots = {
        "play_phone_01_home.png": shot_home(bolt),
        "play_phone_02_play.png": shot_play(bolt),
        "play_phone_03_guide.png": shot_guide(bolt),
    }
    for name, im in shots.items():
        im.save(GFX / name)
        im.resize((1290, 2796), Image.Resampling.LANCZOS).save(GFX / name.replace("play_phone", "appstore_67"))

    splash_im = splash(bolt)
    splash_im.save(GFX / "splash_1080x1920.png")
    ANDROID_SPLASH.parent.mkdir(parents=True, exist_ok=True)
    splash_im.save(ANDROID_SPLASH)
    splash_im.save(IOS_LAUNCH / "LaunchImage@3x.png")
    splash_im.resize((720, 1280), Image.Resampling.LANCZOS).save(IOS_LAUNCH / "LaunchImage@2x.png")
    splash_im.resize((360, 640), Image.Resampling.LANCZOS).save(IOS_LAUNCH / "LaunchImage.png")

    print("Wrote", len(list(GFX.glob("*.png"))), "files in", GFX)


if __name__ == "__main__":
    main()
