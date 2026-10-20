"""Prepare runtime PBR street materials directly from the locally licensed source."""
from pathlib import Path
from urllib.parse import unquote
import argparse
import hashlib
import json
from PIL import Image

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    args = parser.parse_args()
    output = Path(__file__).resolve().parents[1] / "assets/licensed/modern_city_architecture"
    (output / "textures").mkdir(parents=True, exist_ok=True)
    for part, label, phrase, scale, roughness in [("Road", "road", "icity_road_ashphalt", .125, .45), ("Sidewalk", "sidewalk", "icity_sidewalk1_default.001", .2, .82)]:
        source = next((args.source / (part+"_unpacked_joined_GLTF")).glob("*.gltf"))
        data = json.loads(source.read_text(encoding="utf-8"))
        mat = next(m for m in data["materials"] if phrase in m.get("name", "").lower().replace(" ", ""))
        pbr = mat["pbrMetallicRoughness"]
        references = []
        for index, entry in enumerate([pbr["baseColorTexture"], pbr["metallicRoughnessTexture"], mat["normalTexture"]], 1):
            image = source.parent / unquote(data["images"][data["textures"][entry["index"]]["source"]]["uri"])
            filename = hashlib.sha256(image.read_bytes()).hexdigest()[:20]+".png"
            if not (output / "textures" / filename).exists():
                with Image.open(image) as texture:
                    texture.thumbnail((1024,1024), Image.Resampling.LANCZOS)
                    texture.save(output / "textures" / filename, optimize=True)
            references.append(f'[ext_resource type="Texture2D" path="res://assets/licensed/modern_city_architecture/textures/{filename}" id="{index}"]')
        text = '[gd_resource type="StandardMaterial3D" format=3]\n\n'+'\n'.join(references)+f'''

[resource]
resource_name = "{part} / {mat['name']}"
cull_mode = 2
albedo_texture = ExtResource("1")
metallic_texture = ExtResource("2")
metallic_texture_channel = 2
roughness = {roughness}
roughness_texture = ExtResource("2")
roughness_texture_channel = 1
normal_enabled = true
normal_scale = 0.65
normal_texture = ExtResource("3")
uv1_scale = Vector3({scale}, {scale}, {scale})
uv1_triplanar = true
uv1_world_triplanar = true
texture_filter = 5
'''
        (output / (label+".tres")).write_text(text, encoding="utf-8")
        print("CITY STREET MATERIAL PREPARED", label)
