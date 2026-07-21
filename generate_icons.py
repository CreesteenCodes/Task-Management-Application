from PIL import Image, ImageOps
from pathlib import Path

# Project path
root = Path(r"c:/Users/chris/Desktop/Academics/Final Projects/tazk_application")

# Source logo (1024x1024 PNG)
source = root / "assets/images/logo.png"

# Open logo
logo = Image.open(source).convert("RGBA")

# Create canvases for legacy icon and adaptive foreground
canvas_size = 1024
legacy_canvas = Image.new("RGBA", (canvas_size, canvas_size), (255, 255, 255, 255))
foreground_canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

# Resize logo to fit inside the canvas with padding, preserving aspect ratio
logo_size = int(canvas_size * 0.64)
logo = ImageOps.contain(logo, (logo_size, logo_size), method=Image.LANCZOS)

# Center logo
left = (canvas_size - logo.width) // 2
top = (canvas_size - logo.height) // 2

legacy_canvas.alpha_composite(logo, (left, top))
foreground_canvas.alpha_composite(logo, (left, top))

# Save master icons
master_icon = root / "assets/images/ic_launcher_master.png"
master_foreground_icon = root / "assets/images/ic_launcher_foreground_master.png"
legacy_canvas.save(master_icon)
foreground_canvas.save(master_foreground_icon)

# Android launcher icon sizes
sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, px in sizes.items():
    path = root / "android/app/src/main/res" / folder
    path.mkdir(parents=True, exist_ok=True)

    legacy_canvas.resize((px, px), Image.LANCZOS).save(path / "ic_launcher.png")
    foreground_canvas.resize((px, px), Image.LANCZOS).save(path / "ic_launcher_foreground.png")

# Create adaptive icon XML for Android 8+
anydpi_path = root / "android/app/src/main/res/mipmap-anydpi-v26"
anydpi_path.mkdir(parents=True, exist_ok=True)
anydpi_icon = """<?xml version='1.0' encoding='utf-8'?>
<adaptive-icon xmlns:android='http://schemas.android.com/apk/res/android'>
    <background android:drawable='@android:color/white'/>
    <foreground android:drawable='@mipmap/ic_launcher_foreground'/>
</adaptive-icon>
"""
(anydpi_path / "ic_launcher.xml").write_text(anydpi_icon, encoding="utf-8")

print("Android launcher icons created successfully!")
