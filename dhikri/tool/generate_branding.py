"""يولّد صور الهوية البصرية لتطبيق ذكري من الأيقونة المصدر.

    python3 tool/generate_branding.py

المدخل : assets/branding/app_icon_source.png
المخرجات:
    assets/branding/app_icon.png            أيقونة مربعة نظيفة الحواف
    assets/branding/app_icon_foreground.png طبقة أمامية لأيقونة أندرويد المتكيّفة
    assets/branding/splash_logo.png         شعار شاشة البداية
"""

from PIL import Image, ImageDraw

SOURCE = "assets/branding/app_icon_source.png"
ICON = "assets/branding/app_icon.png"
FOREGROUND = "assets/branding/app_icon_foreground.png"
SPLASH = "assets/branding/splash_logo.png"

ICON_SIZE = 1024
# منطقة الأمان في أيقونة أندرويد المتكيّفة: القناع قد يقتطع ما خرج عن 66% الوسطى.
SAFE_ZONE = 0.66
SPLASH_SIZE = 512
# نصف قطر الزوايا كنسبة من ضلع العمل الفني.
CORNER_RADIUS = 0.135
# عيّنة فوقية لحواف ناعمة بلا تسنين.
SUPERSAMPLE = 4


def artwork_bounds(image):
    """حدود العمل الفني: كل ما ليس خلفية سوداء."""
    rgb = image.convert("RGB")
    mask = rgb.point(lambda v: 255 if v > 24 else 0).convert("L")
    box = mask.getbbox()
    if box is None:
        return (0, 0, image.width, image.height)
    return box


def rounded_mask(size, radius_ratio):
    """قناع مربع بزوايا دائرية، مرسوم بعيّنة فوقية ثم مصغَّر لحواف ناعمة."""
    big = size * SUPERSAMPLE
    mask = Image.new("L", (big, big), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        (0, 0, big - 1, big - 1),
        radius=int(big * radius_ratio),
        fill=255,
    )
    return mask.resize((size, size), Image.LANCZOS)


def build_icon(source):
    """يقصّ العمل الفني ويجعل ما خارج المربع المدوّر شفافًا."""
    cropped = source.crop(artwork_bounds(source))
    side = max(cropped.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(
        cropped,
        ((side - cropped.width) // 2, (side - cropped.height) // 2),
    )
    icon = square.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)
    icon.putalpha(rounded_mask(ICON_SIZE, CORNER_RADIUS))
    return icon


def build_foreground(icon):
    """يضع الأيقونة داخل منطقة الأمان على لوحة شفافة."""
    canvas = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    inner = int(ICON_SIZE * SAFE_ZONE)
    scaled = icon.resize((inner, inner), Image.LANCZOS)
    offset = (ICON_SIZE - inner) // 2
    canvas.paste(scaled, (offset, offset), scaled)
    return canvas


def main():
    source = Image.open(SOURCE).convert("RGBA")

    icon = build_icon(source)
    icon.save(ICON, optimize=True)

    build_foreground(icon).save(FOREGROUND, optimize=True)

    icon.resize((SPLASH_SIZE, SPLASH_SIZE), Image.LANCZOS).save(
        SPLASH, optimize=True
    )

    print(f"تم توليد: {ICON}، {FOREGROUND}، {SPLASH}")


if __name__ == "__main__":
    main()
