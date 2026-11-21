"""Generate an editable Bone2D scene from a W06 cutout manifest."""
import argparse
import json
from pathlib import Path


def generate(manifest, script):
    parts = manifest["parts"]
    scale = manifest["godot_units_per_png_pixel"]
    anchor = manifest["ground_anchor_units"]
    by_id = {part["id"]: part for part in parts}
    bones = {}

    def emit(part):
        key = part["id"]
        if key in bones:
            return
        parent_id = part["parent"]
        if parent_id:
            parent = by_id[parent_id]
            emit(parent)
            parent_path = bones[parent_id][0]
            origin = parent["pivot_canvas_units"]
        else:
            parent_path = "Facing/Skeleton"
            origin = anchor
        x, y = (pivot - base for pivot, base in zip(part["pivot_canvas_units"], origin))
        bones[key] = (f"{parent_path}/{key}", x, y)

    for part in parts:
        emit(part)
    lines = [
        f"[gd_scene load_steps={len(parts) + 2} format=3]",
        f'[ext_resource type="Script" path="{script}" id="rig"]',
    ]
    for part in parts:
        lines.append(f'[ext_resource type="Texture2D" path="res://{part["png"]}" id="{part["id"]}"]')
    lines.extend([
        "", '[node name="ScoutRig" type="Node2D"]',
        'texture_filter = 2', 'script = ExtResource("rig")',
        "", '[node name="Facing" type="Node2D" parent="."]',
        "", '[node name="Skeleton" type="Skeleton2D" parent="Facing"]',
    ])
    for key, (path, x, y) in bones.items():
        parent_path = path.rsplit("/", 1)[0]
        lines.extend([
            "", f'[node name="{key}" type="Bone2D" parent="{parent_path}"]',
            f"position = Vector2({x:g}, {y:g})",
            f"rest = Transform2D(1, 0, 0, 1, {x:g}, {y:g})",
            "auto_calculate_length_and_angle = false", "length = 5.0",
        ])
    for part in parts:
        key = part["id"]
        x, y = (-value for value in part["pivot_local_px"])
        path = bones[key][0]
        order = part["draw_order"]
        lines.extend([
            "", f'[node name="Art" type="Sprite2D" parent="{path}"]',
            f"z_index = {order}", "z_as_relative = false",
            f'position = Vector2({x * scale:g}, {y * scale:g})',
            f"scale = Vector2({scale:g}, {scale:g})",
            f'texture = ExtResource("{key}")', "centered = false",
        ])
    lines.extend(["", '[node name="AnimationPlayer" type="AnimationPlayer" parent="."]', ""])
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("scene", type=Path)
    parser.add_argument("--script", default="res://scripts/animation/scout_rig.gd")
    args = parser.parse_args()
    args.scene.write_text(generate(json.loads(args.manifest.read_text()), args.script))


if __name__ == "__main__":
    main()
