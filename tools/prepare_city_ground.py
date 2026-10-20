"""Prepare a small runtime lawn texture from the locally licensed city source."""
from pathlib import Path
from urllib.parse import unquote
import argparse
import json
from PIL import Image

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    args = parser.parse_args()
    source = next((args.source / "Building_unpacked_joined_GLTF").glob("*.gltf"))
    data = json.loads(source.read_text(encoding="utf-8"))
    material = next(item for item in data["materials"] if item.get("name") == "Grass Lawn")
    index = material["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    image = source.parent / unquote(data["images"][data["textures"][index]["source"]]["uri"])
    output = Path(__file__).resolve().parents[1] / "assets/licensed/modern_city_architecture/grass_albedo.jpg"
    with Image.open(image) as texture:
        texture.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
        texture.convert("RGB").save(output, quality=92)
    print("CITY LAWN PREPARED", output)
