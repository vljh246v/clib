from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
PUBLIC = ROOT / "public"
OUT = ROOT / "output" / "ko" / "phone"
OUT_FEATURE = ROOT / "output" / "ko" / "feature-graphic"
OUT_TABLET_7 = ROOT / "output" / "ko" / "tablet-7"
OUT_TABLET_10 = ROOT / "output" / "ko" / "tablet-10"

CANVAS_W = 1080
CANVAS_H = 1920
FEATURE_W = 1024
FEATURE_H = 500
TABLET_7_W = 1920
TABLET_7_H = 1080
TABLET_10_W = 2560
TABLET_10_H = 1440
ACCENT = "#7bd2a2"
SOURCE_CROP_TOP = 180

SLIDES = [
    {
        "id": "home",
        "image": "screenshots/android/phone/ko/01-home.png",
        "eyebrow": "Clib",
        "headline": ["읽어야 했던 링크들", "밀어서 해치우세요"],
        "subcopy": "스와이프로 읽기 시작",
        "accent_word": "해치우세요",
        "top": 360,
        "rotate": 0,
        "scale": 1.0,
    },
    {
        "id": "swipe",
        "image": "screenshots/android/phone/ko/02-swipe.png",
        "eyebrow": "Swipe",
        "headline": ["읽음 / 나중에", "스와이프로 끝"],
        "subcopy": "밀린 콘텐츠를 빠르게 분류",
        "accent_word": "스와이프로",
        "top": 364,
        "rotate": 0,
        "scale": 1.04,
    },
    {
        "id": "library",
        "image": "screenshots/android/phone/ko/03-library.png",
        "eyebrow": "Library",
        "headline": ["안 읽은 것만", "바로 확인"],
        "subcopy": "보관함에서 읽기 현황 확인",
        "accent_word": "바로 확인",
        "top": 360,
        "rotate": 0,
        "scale": 1.0,
    },
    {
        "id": "labels",
        "image": "screenshots/android/phone/ko/04-labels.png",
        "eyebrow": "Labels",
        "headline": ["관심사끼리", "따로 모으세요"],
        "subcopy": "라벨로 정리하면 깔끔",
        "accent_word": "모으세요",
        "top": 360,
        "rotate": 0,
        "scale": 1.0,
    },
    {
        "id": "reminders",
        "image": "screenshots/android/phone/ko/05-reminders.png",
        "eyebrow": "Reminder",
        "headline": ["안 읽으면", "알려드릴게요"],
        "subcopy": "요일별 읽기 알림",
        "accent_word": "알려드릴게요",
        "top": 360,
        "rotate": 0,
        "scale": 1.0,
    },
]

TABLET_CAPTURES = [
    {
        "id": "home",
        "image": "screenshots/android/tablet/ko/01-home.png",
        "headline": ["읽어야 했던 링크들", "밀어서 해치우세요"],
        "subcopy": "스와이프로 읽기 시작",
        "accent": "해치우세요",
    },
    {
        "id": "swipe",
        "image": "screenshots/android/tablet/ko/02-swipe.png",
        "headline": ["읽음 / 나중에", "스와이프로 끝"],
        "subcopy": "밀린 콘텐츠를 빠르게 분류",
        "accent": "스와이프로",
    },
    {
        "id": "library",
        "image": "screenshots/android/tablet/ko/03-library.png",
        "headline": ["안 읽은 것만", "바로 확인"],
        "subcopy": "보관함에서 읽기 현황 확인",
        "accent": "바로 확인",
    },
    {
        "id": "labels",
        "image": "screenshots/android/tablet/ko/04-labels.png",
        "headline": ["관심사끼리", "따로 모으세요"],
        "subcopy": "라벨로 정리하면 깔끔",
        "accent": "모으세요",
    },
]


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(PUBLIC / "fonts" / name), size)


FONT_REGULAR = font("Pretendard-Regular.otf", 28)
FONT_BOLD_28 = font("Pretendard-Bold.otf", 28)
FONT_BOLD_30 = font("Pretendard-Bold.otf", 30)
FONT_HEADLINE = font("Pretendard-ExtraBold.otf", 72)
FONT_FEATURE_TITLE = font("Pretendard-ExtraBold.otf", 74)
FONT_FEATURE_SUBTITLE = font("Pretendard-Bold.otf", 34)
FONT_FEATURE_NAME = font("Pretendard-ExtraBold.otf", 34)
FONT_TABLET_EYEBROW = font("Pretendard-Bold.otf", 34)
FONT_TABLET_TITLE = font("Pretendard-ExtraBold.otf", 78)
FONT_TABLET_SUBTITLE = font("Pretendard-Bold.otf", 36)
FONT_TABLET_META = font("Pretendard-Bold.otf", 30)
FONT_TABLET_MARKETING_7 = font("Pretendard-ExtraBold.otf", 64)
FONT_TABLET_MARKETING_10 = font("Pretendard-ExtraBold.otf", 84)
FONT_TABLET_MARKETING_SUB_7 = font("Pretendard-Bold.otf", 32)
FONT_TABLET_MARKETING_SUB_10 = font("Pretendard-Bold.otf", 42)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def draw_background(canvas: Image.Image) -> None:
    top = (29, 29, 31)
    bottom = (16, 17, 18)
    pixels = canvas.load()
    for y in range(CANVAS_H):
        t = y / (CANVAS_H - 1)
        color = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(CANVAS_W):
            pixels[x, y] = color

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    draw.ellipse((190, -220, 890, 480), fill=(123, 210, 162, 42))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(72)))


def draw_landscape_background(canvas: Image.Image) -> None:
    width, height = canvas.size
    top = (28, 30, 30)
    bottom = (13, 15, 15)
    pixels = canvas.load()
    for y in range(height):
        ty = y / (height - 1)
        for x in range(width):
            tx = x / (width - 1)
            pixels[x, y] = (
                round(top[0] * (1 - ty) + bottom[0] * ty + 6 * tx),
                round(top[1] * (1 - ty) + bottom[1] * ty + 12 * tx),
                round(top[2] * (1 - ty) + bottom[2] * ty + 5 * tx),
                255,
            )

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    draw.ellipse((round(width * 0.50), round(height * -0.35), round(width * 1.10), round(height * 1.05)), fill=(123, 210, 162, 54))
    draw.ellipse((round(width * -0.20), round(height * 0.58), round(width * 0.42), round(height * 1.35)), fill=(123, 210, 162, 22))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(round(width * 0.045))))


def draw_centered_segments(
    draw: ImageDraw.ImageDraw,
    y: int,
    line: str,
    accent_word: str,
) -> None:
    parts = line.split(accent_word)
    segments: list[tuple[str, str]] = []
    if len(parts) == 1:
        segments.append((line, "#ffffff"))
    else:
        if parts[0]:
            segments.append((parts[0], "#ffffff"))
        segments.append((accent_word, ACCENT))
        if parts[1]:
            segments.append((parts[1], "#ffffff"))

    widths = [
        draw.textbbox((0, 0), text, font=FONT_HEADLINE)[2]
        for text, _ in segments
    ]
    x = (CANVAS_W - sum(widths)) // 2
    for (text, fill), width in zip(segments, widths, strict=True):
        draw.text((x, y), text, fill=fill, font=FONT_HEADLINE)
        x += width


def paste_icon(canvas: Image.Image, draw: ImageDraw.ImageDraw, eyebrow: str) -> None:
    icon = Image.open(PUBLIC / "app-icon.png").convert("RGBA").resize((72, 72), Image.Resampling.LANCZOS)
    canvas.alpha_composite(icon, (72, 64))
    draw.text((164, 82), eyebrow.upper(), fill=ACCENT, font=FONT_BOLD_30)


def make_phone(slide: dict[str, object]) -> Image.Image:
    src = Image.open(PUBLIC / str(slide["image"])).convert("RGB")
    phone_w = round(660 * float(slide["scale"]))
    phone_h = round(phone_w * ((2796 - SOURCE_CROP_TOP) / 1290))
    padding = 10
    outer_w = phone_w + padding * 2
    outer_h = phone_h + padding * 2

    phone = Image.new("RGBA", (outer_w, outer_h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (outer_w + 120, outer_h + 120), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((60, 60, outer_w + 60, outer_h + 60), radius=64, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(34))

    frame = Image.new("RGBA", (outer_w, outer_h), (32, 33, 35, 255))
    frame_mask = rounded_mask((outer_w, outer_h), 64)
    phone.alpha_composite(Image.composite(frame, Image.new("RGBA", (outer_w, outer_h)), frame_mask))

    src = src.crop((0, SOURCE_CROP_TOP, src.width, src.height))
    screen = src.resize((phone_w, phone_h), Image.Resampling.LANCZOS).convert("RGBA")
    screen_mask = rounded_mask((phone_w, phone_h), 54)
    phone.alpha_composite(Image.composite(screen, Image.new("RGBA", (phone_w, phone_h)), screen_mask), (padding, padding))

    combined = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
    combined.alpha_composite(shadow)
    combined.alpha_composite(phone, (60, 60))
    angle = float(slide["rotate"])
    if angle:
        combined = combined.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
    return combined


def render_slide(index: int, slide: dict[str, object]) -> Path:
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (17, 18, 19, 255))
    draw_background(canvas)
    draw = ImageDraw.Draw(canvas)

    paste_icon(canvas, draw, str(slide["eyebrow"]))

    y = 116
    for line in slide["headline"]:
        draw_centered_segments(draw, y, str(line), str(slide["accent_word"]))
        y += 72
    draw.text(
        ((CANVAS_W - draw.textlength(str(slide["subcopy"]), font=FONT_BOLD_28)) / 2, y + 26),
        str(slide["subcopy"]),
        fill=(255, 255, 255, 122),
        font=FONT_BOLD_28,
    )

    phone = make_phone(slide)
    x = (CANVAS_W - phone.width) // 2
    canvas.alpha_composite(phone, (x, int(slide["top"]) - 60))

    draw.rounded_rectangle(
        ((CANVAS_W - 180) // 2, CANVAS_H - 48, (CANVAS_W + 180) // 2, CANVAS_H - 42),
        radius=3,
        fill=(123, 210, 162, 180),
    )

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{index:02d}-{slide['id']}-ko-1080x1920.png"
    canvas.convert("RGB").save(path, "PNG", optimize=True)
    return path


def make_feature_phone() -> Image.Image:
    src = Image.open(PUBLIC / "screenshots/android/phone/ko/02-swipe.png").convert("RGB")
    src = src.crop((0, SOURCE_CROP_TOP, src.width, src.height))

    phone_w = 240
    phone_h = round(phone_w * (src.height / src.width))
    padding = 8
    outer_w = phone_w + padding * 2
    outer_h = phone_h + padding * 2

    phone = Image.new("RGBA", (outer_w, outer_h), (0, 0, 0, 0))
    frame = Image.new("RGBA", (outer_w, outer_h), (31, 32, 34, 255))
    phone.alpha_composite(Image.composite(frame, Image.new("RGBA", (outer_w, outer_h)), rounded_mask((outer_w, outer_h), 42)))

    screen = src.resize((phone_w, phone_h), Image.Resampling.LANCZOS).convert("RGBA")
    phone.alpha_composite(
        Image.composite(screen, Image.new("RGBA", (phone_w, phone_h)), rounded_mask((phone_w, phone_h), 34)),
        (padding, padding),
    )
    return phone.rotate(-5, expand=True, resample=Image.Resampling.BICUBIC)


def render_feature_graphic() -> Path:
    canvas = Image.new("RGBA", (FEATURE_W, FEATURE_H), (17, 18, 19, 255))
    pixels = canvas.load()
    for y in range(FEATURE_H):
        for x in range(FEATURE_W):
            tx = x / (FEATURE_W - 1)
            ty = y / (FEATURE_H - 1)
            pixels[x, y] = (
                round(30 * (1 - ty) + 14 * ty + 14 * tx),
                round(31 * (1 - ty) + 35 * ty + 26 * tx),
                round(31 * (1 - ty) + 24 * ty + 20 * tx),
                255,
            )

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((410, -230, 1110, 520), fill=(123, 210, 162, 56))
    glow_draw.ellipse((-180, 260, 460, 760), fill=(123, 210, 162, 25))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(58)))

    draw = ImageDraw.Draw(canvas)
    icon = Image.open(PUBLIC / "app-icon.png").convert("RGBA").resize((88, 88), Image.Resampling.LANCZOS)
    canvas.alpha_composite(icon, (70, 64))
    draw.text((178, 78), "Clib", fill=(255, 255, 255, 245), font=FONT_FEATURE_NAME)
    draw.text((178, 120), "Link reading, simplified", fill=(123, 210, 162, 210), font=FONT_BOLD_28)

    draw.text((70, 205), "읽을 링크를", fill=(255, 255, 255, 248), font=FONT_FEATURE_TITLE)
    draw.text((70, 282), "한곳에", fill=ACCENT, font=FONT_FEATURE_TITLE)
    draw.text((70, 376), "스와이프로 빠르게 정리", fill=(255, 255, 255, 178), font=FONT_FEATURE_SUBTITLE)

    phone = make_feature_phone()
    shadow = Image.new("RGBA", (phone.width + 90, phone.height + 90), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((45, 45, phone.width + 45, phone.height + 45), radius=48, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.alpha_composite(shadow, (690, 6))
    canvas.alpha_composite(phone, (735, 51))

    OUT_FEATURE.mkdir(parents=True, exist_ok=True)
    path = OUT_FEATURE / "clib-feature-graphic-ko-1024x500.png"
    canvas.convert("RGB").save(path, "PNG", optimize=True)
    return path


def cover_resize(src: Image.Image, size: tuple[int, int]) -> Image.Image:
    width, height = size
    scale = max(width / src.width, height / src.height)
    resized = src.resize((round(src.width * scale), round(src.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - width) // 2
    top = (resized.height - height) // 2
    return resized.crop((left, top, left + width, top + height))


def contain_16_9_tablet_capture(src: Image.Image, size: tuple[int, int]) -> Image.Image:
    width, height = size
    target_ratio = width / height
    src_ratio = src.width / src.height

    if src_ratio > target_ratio:
        crop_w = round(src.height * target_ratio)
        left = (src.width - crop_w) // 2
        src = src.crop((left, 0, left + crop_w, src.height))
    else:
        crop_h = round(src.width / target_ratio)
        top = (src.height - crop_h) // 2
        src = src.crop((0, top, src.width, top + crop_h))

    return src.resize(size, Image.Resampling.LANCZOS)


def draw_tablet_marketing_copy(
    image: Image.Image,
    capture: dict[str, object],
    canvas_size: tuple[int, int],
) -> Image.Image:
    width, height = canvas_size
    scale = width / TABLET_7_W
    canvas = image.convert("RGBA")

    scrim = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    scrim_draw = ImageDraw.Draw(scrim)
    scrim_draw.rounded_rectangle(
        (
            round(width * 0.025),
            round(height * 0.04),
            round(width * 0.50),
            round(height * 0.31),
        ),
        radius=round(34 * scale),
        fill=(255, 255, 255, 222),
    )
    canvas.alpha_composite(scrim)

    draw = ImageDraw.Draw(canvas)
    x = round(width * 0.055)
    y = round(height * 0.075)
    headline_font = FONT_TABLET_MARKETING_10 if width >= TABLET_10_W else FONT_TABLET_MARKETING_7
    sub_font = FONT_TABLET_MARKETING_SUB_10 if width >= TABLET_10_W else FONT_TABLET_MARKETING_SUB_7
    line_gap = round(76 * scale)

    for line in capture["headline"]:
        line_text = str(line)
        if line_text == capture["accent"]:
            fill = ACCENT
        else:
            fill = (24, 25, 26)
        draw.text((x, y), line_text, fill=fill, font=headline_font)
        y += line_gap

    draw.text((x, y + round(16 * scale)), str(capture["subcopy"]), fill=(79, 85, 91), font=sub_font)
    return canvas.convert("RGB")


def draw_nav_item(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    label: str,
    active: bool,
    radius: int,
) -> None:
    fill = (31, 64, 45) if active else (30, 31, 32)
    outline = (92, 171, 126) if active else (55, 57, 58)
    text = ACCENT if active else (255, 255, 255, 150)
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=1)
    draw.text((box[0] + 24, box[1] + 17), label, fill=text, font=FONT_TABLET_META)


def draw_article_card(
    canvas: Image.Image,
    draw: ImageDraw.ImageDraw,
    image: Image.Image,
    box: tuple[int, int, int, int],
    title: str,
    tag: str,
    scale: float,
) -> None:
    x1, y1, x2, y2 = box
    width = x2 - x1
    height = y2 - y1
    radius = round(26 * scale)
    draw.rounded_rectangle(box, radius=radius, fill=(26, 27, 28), outline=(56, 58, 59), width=1)

    image_h = round(height * 0.62)
    image_box = (x1 + 14, y1 + 14, x2 - 14, y1 + image_h)
    thumb = cover_resize(image, (image_box[2] - image_box[0], image_box[3] - image_box[1])).convert("RGBA")
    mask = rounded_mask(thumb.size, round(20 * scale))
    canvas.alpha_composite(Image.composite(thumb, Image.new("RGBA", thumb.size), mask), (image_box[0], image_box[1]))

    tag_box = (x1 + 24, y1 + image_h + 28, x1 + 24 + round(70 * scale), y1 + image_h + round(62 * scale))
    draw.rounded_rectangle(tag_box, radius=round(14 * scale), fill=(31, 64, 45), outline=(92, 171, 126))
    draw.text((tag_box[0] + 16, tag_box[1] + 7), tag, fill=ACCENT, font=FONT_TABLET_META)
    draw.text((x1 + 24, tag_box[3] + 18), title, fill=(255, 255, 255, 230), font=FONT_TABLET_SUBTITLE)


def render_tablet_app_screen(
    out_dir: Path,
    canvas_size: tuple[int, int],
    index: int,
    slide: dict[str, object],
    suffix: str,
) -> Path:
    width, height = canvas_size
    scale = width / TABLET_7_W
    canvas = Image.new("RGBA", canvas_size, (17, 18, 19, 255))
    draw_landscape_background(canvas)
    draw = ImageDraw.Draw(canvas)

    margin = round(width * 0.04)
    sidebar_w = round(width * 0.20)
    top_h = round(height * 0.13)
    radius = round(30 * scale)

    app_box = (margin, margin, width - margin, height - margin)
    draw.rounded_rectangle(app_box, radius=radius, fill=(15, 16, 17), outline=(64, 66, 67), width=1)

    icon_size = round(height * 0.07)
    icon = Image.open(PUBLIC / "app-icon.png").convert("RGBA").resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    icon_x = margin + 34
    icon_y = margin + 32
    canvas.alpha_composite(icon, (icon_x, icon_y))
    draw.text((icon_x + icon_size + 22, icon_y + 10), "Clib", fill=(255, 255, 255, 236), font=FONT_FEATURE_NAME)
    draw.text((icon_x + icon_size + 22, icon_y + 48), "읽을 링크 관리", fill=(123, 210, 162, 180), font=FONT_BOLD_28)

    nav_x = margin + 34
    nav_y = margin + top_h + 32
    nav_w = sidebar_w - 68
    nav_items = [
        ("home", "읽을 링크"),
        ("swipe", "스와이프"),
        ("library", "보관함"),
        ("labels", "라벨"),
        ("reminders", "알림"),
    ]
    for nav_id, label in nav_items:
        draw_nav_item(draw, (nav_x, nav_y, nav_x + nav_w, nav_y + round(68 * scale)), label, str(slide["id"]) == nav_id, round(18 * scale))
        nav_y += round(84 * scale)

    main_x = margin + sidebar_w + round(width * 0.025)
    main_y = margin + 34
    main_w = width - margin - main_x - 34
    draw.text((main_x, main_y), str(slide["headline"][0]), fill=(255, 255, 255, 245), font=FONT_TABLET_TITLE)
    draw.text((main_x, main_y + round(82 * scale)), str(slide["subcopy"]), fill=(255, 255, 255, 150), font=FONT_TABLET_SUBTITLE)

    chip_y = main_y + round(150 * scale)
    chip_x = main_x
    for label, active in [("전체", True), ("개발", False), ("디자인", False), ("생산성", False), ("자기개발", False)]:
        chip_w = round((76 + len(label) * 16) * scale)
        draw.rounded_rectangle(
            (chip_x, chip_y, chip_x + chip_w, chip_y + round(46 * scale)),
            radius=round(23 * scale),
            fill=(31, 64, 45) if active else (30, 31, 32),
            outline=(92, 171, 126) if active else (55, 57, 58),
        )
        draw.text((chip_x + round(24 * scale), chip_y + round(10 * scale)), label, fill=ACCENT if active else (255, 255, 255, 135), font=FONT_TABLET_META)
        chip_x += chip_w + round(14 * scale)

    src = Image.open(PUBLIC / str(slide["image"])).convert("RGB")
    src = src.crop((0, SOURCE_CROP_TOP, src.width, src.height))
    related = [
        Image.open(PUBLIC / str(item["image"])).convert("RGB").crop((0, SOURCE_CROP_TOP, 1290, 2796))
        for item in SLIDES[:4]
    ]
    related[0] = src

    card_y = chip_y + round(86 * scale)
    gap = round(26 * scale)
    card_w = round((main_w - gap * 2) / 3)
    card_h = round(height * 0.48)
    titles = [
        "디자인 시스템 구축기",
        "집중력을 높이는 방법",
        "읽을 거리 다시 보기",
    ]
    tags = ["디자인", "생산성", "개발"]
    for card_index in range(3):
        x = main_x + card_index * (card_w + gap)
        draw_article_card(
            canvas,
            draw,
            related[card_index],
            (x, card_y, x + card_w, card_y + card_h),
            titles[card_index],
            tags[card_index],
            scale,
        )

    status_y = height - margin - round(74 * scale)
    draw.rounded_rectangle(
        (main_x, status_y, width - margin - 34, status_y + round(44 * scale)),
        radius=round(22 * scale),
        fill=(30, 31, 32),
    )
    draw.text((main_x + 24, status_y + 9), "8개의 아이템", fill=(255, 255, 255, 125), font=FONT_TABLET_META)
    draw.text((width - margin - round(210 * scale), status_y + 9), "동기화됨", fill=ACCENT, font=FONT_TABLET_META)

    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{index:02d}-{slide['id']}-ko-{suffix}.png"
    canvas.convert("RGB").save(path, "PNG", optimize=True)
    return path


def make_tablet_screen(slide: dict[str, object], width: int, height: int) -> Image.Image:
    src = Image.open(PUBLIC / str(slide["image"])).convert("RGB")
    src = src.crop((0, SOURCE_CROP_TOP, src.width, src.height))

    tablet = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    frame = Image.new("RGBA", (width, height), (30, 31, 33, 255))
    tablet.alpha_composite(Image.composite(frame, Image.new("RGBA", (width, height)), rounded_mask((width, height), round(width * 0.04))))

    inset = round(width * 0.018)
    screen_w = width - inset * 2
    screen_h = height - inset * 2
    screen = Image.new("RGBA", (screen_w, screen_h), (20, 22, 22, 255))
    screen_draw = ImageDraw.Draw(screen)

    panel_w = round(screen_w * 0.52)
    panel_h = screen_h
    resized_h = panel_h
    resized_w = round(src.width * (resized_h / src.height))
    app = src.resize((resized_w, resized_h), Image.Resampling.LANCZOS).convert("RGBA")
    app_x = round((panel_w - resized_w) / 2)
    screen.alpha_composite(app, (app_x, 0))

    copy_x = panel_w + round(screen_w * 0.05)
    copy_y = round(screen_h * 0.22)
    screen_draw.rounded_rectangle(
        (copy_x, copy_y - 48, copy_x + 112, copy_y - 36),
        radius=6,
        fill=(123, 210, 162, 210),
    )
    for line in slide["headline"]:
        screen_draw.text((copy_x, copy_y), str(line), fill=(255, 255, 255, 242), font=FONT_TABLET_META)
        copy_y += 42
    screen_draw.text((copy_x, copy_y + 26), str(slide["subcopy"]), fill=(255, 255, 255, 138), font=FONT_REGULAR)

    tablet.alpha_composite(
        Image.composite(screen, Image.new("RGBA", screen.size), rounded_mask(screen.size, round(width * 0.032))),
        (inset, inset),
    )
    return tablet


def render_tablet_slide(
    out_dir: Path,
    canvas_size: tuple[int, int],
    screen_size: tuple[int, int],
    index: int,
    slide: dict[str, object],
    suffix: str,
) -> Path:
    width, height = canvas_size
    canvas = Image.new("RGBA", canvas_size, (17, 18, 19, 255))
    draw_landscape_background(canvas)
    draw = ImageDraw.Draw(canvas)

    margin_x = round(width * 0.07)
    icon_size = round(height * 0.085)
    icon = Image.open(PUBLIC / "app-icon.png").convert("RGBA").resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    canvas.alpha_composite(icon, (margin_x, round(height * 0.09)))
    draw.text((margin_x + icon_size + 28, round(height * 0.108)), "CLIB", fill=ACCENT, font=FONT_TABLET_EYEBROW)

    y = round(height * 0.25)
    for line in slide["headline"]:
        draw.text((margin_x, y), str(line), fill=(255, 255, 255, 248), font=FONT_TABLET_TITLE)
        y += round(height * 0.08)
    draw.text((margin_x, y + round(height * 0.04)), str(slide["subcopy"]), fill=(255, 255, 255, 150), font=FONT_TABLET_SUBTITLE)

    tablet = make_tablet_screen(slide, *screen_size)
    shadow = Image.new("RGBA", (tablet.width + 120, tablet.height + 120), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((60, 60, tablet.width + 60, tablet.height + 60), radius=64, fill=(0, 0, 0, 135))
    shadow = shadow.filter(ImageFilter.GaussianBlur(30))

    tablet_x = width - tablet.width - round(width * 0.035)
    tablet_y = round((height - tablet.height) / 2)
    canvas.alpha_composite(shadow, (tablet_x - 60, tablet_y - 60))
    canvas.alpha_composite(tablet, (tablet_x, tablet_y))

    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{index:02d}-{slide['id']}-ko-{suffix}.png"
    canvas.convert("RGB").save(path, "PNG", optimize=True)
    return path


def render_tablet_sets() -> list[Path]:
    outputs: list[Path] = []
    for index, capture in enumerate(TABLET_CAPTURES, start=1):
        capture_id = str(capture["id"])
        src = Image.open(PUBLIC / str(capture["image"])).convert("RGB")

        OUT_TABLET_7.mkdir(parents=True, exist_ok=True)
        tablet_7 = contain_16_9_tablet_capture(src, (TABLET_7_W, TABLET_7_H))
        tablet_7 = draw_tablet_marketing_copy(tablet_7, capture, (TABLET_7_W, TABLET_7_H))
        tablet_7_path = OUT_TABLET_7 / f"{index:02d}-{capture_id}-ko-1920x1080.png"
        tablet_7.save(tablet_7_path, "PNG", optimize=True)
        outputs.append(tablet_7_path)

        OUT_TABLET_10.mkdir(parents=True, exist_ok=True)
        tablet_10 = contain_16_9_tablet_capture(src, (TABLET_10_W, TABLET_10_H))
        tablet_10 = draw_tablet_marketing_copy(tablet_10, capture, (TABLET_10_W, TABLET_10_H))
        tablet_10_path = OUT_TABLET_10 / f"{index:02d}-{capture_id}-ko-2560x1440.png"
        tablet_10.save(tablet_10_path, "PNG", optimize=True)
        outputs.append(tablet_10_path)
    return outputs


def main() -> None:
    for index, slide in enumerate(SLIDES, start=1):
        path = render_slide(index, slide)
        print(path)
    print(render_feature_graphic())
    for path in render_tablet_sets():
        print(path)


if __name__ == "__main__":
    main()
