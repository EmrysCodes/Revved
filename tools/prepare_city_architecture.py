"""Extract reusable Modern City building models for the actual Hartford map."""
from pathlib import Path
import argparse
from prepare_night_showcase import build

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    args = parser.parse_args()
    destination = Path(__file__).resolve().parents[1]/"assets/licensed/modern_city_architecture"
    for label, parts, bounds, nodes in [
        ("stone_corner", ["Building"], None, ["Building 11"]),
        ("modern_office", ["Building"], [-150,160,-150,160], ["Building 12"]),
        ("retail_a", ["Building"], [-47.5,-4.5,4.5,47.5], ["Path and Imperfections"]),
        ("retail_b", ["Building"], [-100,-57,4.5,47.5], ["Path and Imperfections"]),
        ("tower", ["Towers"], [-150,160,-150,160], ["Amar Tower"]),
        ("tree_ash", ["Building"], [-101,-87,-55,-41], ["Grass"]),
        ("tree_linden", ["Building"], [-54,-40,32,47], ["Grass"]),
    ]:
        # A wide bound retains the whole selected object for standalone models.
        build(args.source, destination, parts, bounds or [-150,160,-150,160], nodes, label)
        print("CITY MODEL PREPARED", label, flush=True)
