"""Crop the locally licensed Modern City source into a bounded street art test.

Usage: python tools/prepare_night_showcase.py --source <City_Exports folder>
Requires numpy and Pillow. Source models are never downloaded or published here.
"""
import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import unquote

import numpy as np
from PIL import Image

DTYPES = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def build(source: Path, destination: Path, parts=None, bounds=None, nodes=None, label="street"):
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "textures").mkdir(exist_ok=True)
    out = dict(asset={"version": "2.0", "generator": "REVVED bounded street preparation"}, scenes=[{"nodes": []}], scene=0,
               nodes=[], meshes=[], accessors=[], bufferViews=[], buffers=[], materials=[], textures=[], images=[], samplers=[])
    blob = bytearray()
    image_cache = {}
    counts = {}

    def put(values, kind, component, normalized=False):
        while len(blob) % 4:
            blob.append(0)
        offset = len(blob)
        blob.extend(values.tobytes())
        view = len(out["bufferViews"])
        out["bufferViews"].append(dict(buffer=0, byteOffset=offset, byteLength=values.nbytes))
        item = dict(bufferView=view, componentType=component, count=len(values), type=kind)
        if normalized:
            item["normalized"] = True
        if kind == "VEC3" and component == 5126:
            item["min"] = values.min(axis=0).tolist()
            item["max"] = values.max(axis=0).tolist()
        out["accessors"].append(item)
        return len(out["accessors"]) - 1

    for part in (parts or ["Road", "Sidewalk", "Building"]):
        path = next((source / (part + "_unpacked_joined_GLTF")).glob("*.gltf"))
        data = json.loads(path.read_text(encoding="utf-8"))
        buffers = [(path.parent / unquote(b["uri"])).read_bytes() for b in data["buffers"]]
        material_map, texture_map = {}, {}
        chunks = {}
        total = kept = 0

        def read(index):
            a = data["accessors"][index]
            v = data["bufferViews"][a["bufferView"]]
            dtype = np.dtype(DTYPES[a["componentType"]]).newbyteorder("<")
            width = WIDTHS[a["type"]]
            return np.ndarray((a["count"], width), dtype=dtype, buffer=buffers[v["buffer"]],
                              offset=v.get("byteOffset", 0)+a.get("byteOffset", 0),
                              strides=(v.get("byteStride", dtype.itemsize*width), dtype.itemsize))

        def texture(index):
            if index in texture_map:
                return texture_map[index]
            original = data["textures"][index]
            src = path.parent / unquote(data["images"][original["source"]]["uri"])
            checksum = hashlib.sha256(src.read_bytes()).hexdigest()
            if checksum not in image_cache:
                filename = "textures/" + checksum[:20] + ".png"
                if not (destination / filename).exists():
                    with Image.open(src) as image:
                        image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
                        image.save(destination / filename, optimize=True)
                image_cache[checksum] = len(out["images"])
                out["images"].append({"uri": filename})
            result = {"source": image_cache[checksum]}
            if "sampler" in original:
                result["sampler"] = len(out["samplers"])
                out["samplers"].append(data["samplers"][original["sampler"]])
            out["textures"].append(result)
            texture_map[index] = len(out["textures"]) - 1
            return texture_map[index]

        def material(index):
            if index in material_map:
                return material_map[index]
            value = json.loads(json.dumps(data["materials"][index]))
            value["name"] = part + " / " + value.get("name", str(index))

            def rewrite(obj):
                if isinstance(obj, dict):
                    for key, val in obj.items():
                        if key.endswith("Texture") and isinstance(val, dict) and "index" in val:
                            val["index"] = texture(val["index"])
                        else:
                            rewrite(val)
            rewrite(value)
            out["materials"].append(value)
            material_map[index] = len(out["materials"]) - 1
            return material_map[index]

        for node in data["nodes"]:
            if "mesh" not in node:
                continue
            if nodes and node.get("name") not in nodes:
                continue
            assert not any(k in node for k in ["matrix", "rotation", "scale", "translation"]), "Bake source node transforms first"
            for primitive in data["meshes"][node["mesh"]]["primitives"]:
                positions = read(primitive["attributes"]["POSITION"])
                indices = read(primitive["indices"]).reshape(-1, 3) if "indices" in primitive else np.arange(len(positions), dtype=np.uint32).reshape(-1,3)
                total += len(indices)
                points = positions[indices]
                # Central east/west street with complete adjacent facades and cross-streets.
                low, high = points.min(axis=1), points.max(axis=1)
                if bounds:
                    centers = points.mean(axis=1)
                    selected = (centers[:,0] >= bounds[0]) & (centers[:,0] <= bounds[1]) & (centers[:,2] >= bounds[2]) & (centers[:,2] <= bounds[3])
                else:
                    selected = (high[:,0] >= -108) & (low[:,0] <= 110) & (high[:,2] >= -32) & (low[:,2] <= 32)
                triangles = indices[selected]
                if not len(triangles):
                    continue
                centers = positions[triangles].mean(axis=1)
                cells = np.floor(centers[:,[0,2]] / 48).astype(np.int32)
                for cell in np.unique(cells, axis=0):
                    subset = triangles[(cells == cell).all(axis=1)]
                    used, remap = np.unique(subset, return_inverse=True)
                    attributes = {}
                    for attribute_name, accessor_index in primitive["attributes"].items():
                        desc = data["accessors"][accessor_index]
                        attributes[attribute_name] = put(read(accessor_index)[used].copy(), desc["type"], desc["componentType"], desc.get("normalized", False))
                    entry = dict(attributes=attributes, indices=put(remap.astype(np.uint32).reshape(-1,1), "SCALAR", 5125), mode=4)
                    if "material" in primitive:
                        entry["material"] = material(primitive["material"])
                    chunks.setdefault(tuple(cell), []).append(entry)
                    kept += len(subset)
        for cell, primitives in sorted(chunks.items()):
            name = f"{part}_{cell[0]}_{cell[1]}"
            out["meshes"].append(dict(name=name, primitives=primitives))
            out["nodes"].append(dict(name=name, mesh=len(out["meshes"])-1))
            out["scenes"][0]["nodes"].append(len(out["nodes"])-1)
        counts[part] = dict(source_triangles=total, retained_triangles=kept, chunks=len(chunks))
        print(part, counts[part], flush=True)
    out["buffers"] = [dict(uri=label+".bin", byteLength=len(blob))]
    (destination / (label+".bin")).write_bytes(blob)
    (destination / (label+".gltf")).write_text(json.dumps(out, separators=(",", ":")), encoding="utf-8")
    (destination / (label+"-preparation.json")).write_text(json.dumps(dict(parts=counts, textures=len(out["images"]), texture_max=1024, bounds=bounds), indent=2))
    (destination / "LICENSE-NOTES.txt").write_text("Modern City Environment — OTOY360studios. Acquired under Fab Standard license.\nhttps://www.fab.com/listings/6e72d76b-9cf9-4391-aa38-69772d666ac4\nLocally prepared street subset, reduced texture resolution, original materials and geometry retained.\nLicensed source assets stay private; distribute only as permitted in a compiled game.\n", encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--destination", type=Path, default=Path(__file__).resolve().parents[1]/"assets/licensed/modern_city_showcase")
    args = parser.parse_args()
    build(args.source, args.destination)
