"""Enable mipmaps and GPU compression for prepared city textures.

Run after Godot's first import, then import the project again. Only generated
texture caches are invalidated; licensed source images are never removed.
"""
from pathlib import Path
import re

if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    folder = root / "assets/licensed/modern_city_architecture"
    cache = (root / ".godot/imported").resolve()
    count = 0
    for source in sorted(folder.rglob("*.import")):
        if not source.name.endswith((".png.import", ".jpg.import")):
            continue
        text = source.read_text(encoding="utf-8")
        updated = text.replace("compress/mode=0", "compress/mode=2").replace("compress/high_quality=false", "compress/high_quality=true").replace("mipmaps/generate=false", "mipmaps/generate=true")
        if updated == text:
            continue
        # Missing generated output makes the next editor import unambiguous.
        for match in re.findall(r'res://\.godot/imported/[^"\s]+\.ctex', text):
            generated = (root / match.removeprefix("res://")).resolve()
            assert generated.is_relative_to(cache) and generated.suffix == ".ctex"
            generated.unlink(missing_ok=True)
        source.write_text(updated, encoding="utf-8")
        count += 1
    print("CITY TEXTURE SETTINGS", count, "imports updated; reimport before playing/exporting")
