import os
from PIL import Image, ImageDraw

def draw_upajo_icon(size, is_round=False):
    # Create RGBA canvas
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    pad = size * 0.04
    radius = size * 0.22 if not is_round else size * 0.5

    # Background shape (Rounded rectangle or circle)
    bg_color = (250, 247, 240, 255) # #FAF7F0
    border_color = (226, 215, 195, 255) # #E2D7C3

    draw.rounded_rectangle(
        [pad, pad, size - pad, size - pad],
        radius=radius,
        fill=bg_color,
        outline=border_color,
        width=max(1, int(size * 0.02))
    )

    # Scale factor
    scale = size / 512.0

    # Soil furrow lines (base)
    # Line 1
    draw.arc(
        [64 * scale, 360 * scale, 448 * scale, 460 * scale],
        start=0, end=180,
        fill=(110, 95, 68, 255), # #6E5F44
        width=max(2, int(18 * scale))
    )
    # Line 2
    draw.arc(
        [112 * scale, 320 * scale, 400 * scale, 410 * scale],
        start=0, end=180,
        fill=(158, 141, 110, 255), # #9E8D6E
        width=max(2, int(15 * scale))
    )
    # Line 3
    draw.arc(
        [160 * scale, 280 * scale, 352 * scale, 360 * scale],
        start=0, end=180,
        fill=(216, 151, 44, 255), # #D8972C
        width=max(2, int(14 * scale))
    )

    # Sprout Stem
    draw.line(
        [(256 * scale, 340 * scale), (256 * scale, 130 * scale)],
        fill=(27, 73, 44, 255), # #1B492C
        width=max(3, int(22 * scale))
    )

    # Left Leaf
    left_leaf = [
        (256 * scale, 240 * scale),
        (160 * scale, 210 * scale),
        (130 * scale, 150 * scale),
        (180 * scale, 110 * scale),
        (230 * scale, 140 * scale),
        (256 * scale, 240 * scale)
    ]
    draw.polygon(left_leaf, fill=(63, 166, 91, 255)) # #3FA65B

    # Right Leaf
    right_leaf = [
        (256 * scale, 190 * scale),
        (330 * scale, 160 * scale),
        (360 * scale, 100 * scale),
        (310 * scale, 70 * scale),
        (270 * scale, 110 * scale),
        (256 * scale, 190 * scale)
    ]
    draw.polygon(right_leaf, fill=(37, 96, 58, 255)) # #25603A

    # Center Seed
    r = 12 * scale
    draw.ellipse(
        [256 * scale - r, 310 * scale - r, 256 * scale + r, 310 * scale + r],
        fill=(216, 151, 44, 255)
    )

    return img

def main():
    densities = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
    }

    base_res = "android/app/src/main/res"

    for d, s in densities.items():
        folder = os.path.join(base_res, f"mipmap-{d}")
        os.makedirs(folder, exist_ok=True)

        # Standard icon
        icon = draw_upajo_icon(s, is_round=False)
        icon_path = os.path.join(folder, "ic_launcher.png")
        icon.save(icon_path, "PNG")

        # Round icon
        round_icon = draw_upajo_icon(s, is_round=True)
        round_path = os.path.join(folder, "ic_launcher_round.png")
        round_icon.save(round_path, "PNG")

        print(f"Generated {d}: {s}x{s} -> {icon_path} and {round_path}")

    # Play Store 512x512
    os.makedirs("brand/playstore", exist_ok=True)
    play_icon = draw_upajo_icon(512, is_round=False)
    play_path = "brand/playstore/icon_512.png"
    play_icon.save(play_path, "PNG")
    print(f"Generated Play Store icon: 512x512 -> {play_path}")

if __name__ == "__main__":
    main()

