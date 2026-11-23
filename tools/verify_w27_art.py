"""Exercise W27 production cutouts with Godot in a disposable art project."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from build_cutout_scene import generate
from export_w27_cutouts import ROOT, UNITS, sha256


def run_engine(project, args):
    return subprocess.run(
        ["godot", "--headless", "--path", str(project), *args],
        check=True, capture_output=True, text=True, timeout=90,
    )


def copy_into(source, project):
    dest = project / source
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT / source, dest)
    return dest


def verify_post():
    source_path = ROOT / "docs/production/w27/review/logistics_post"
    manifest = json.loads((source_path / "manifest.json").read_text())
    assert sha256(source_path / manifest["source"]) == manifest["source_sha256"]
    assert [p["svg_layer_id"] for p in manifest["layers"]] == [
        "base", "supply_crate", "radio", "indicator"]
    for part in manifest["layers"]:
        assert sha256(source_path / part["png"]) == part["sha256"]
    print("Logistics Post: approved SVG and four PNG layers match their recorded hashes")


def probe(project):
    (project / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="W27 Cutout QA"\n'
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
    )
    (project / "plain_rig.gd").write_text("extends Node2D\n")
    for unit in UNITS:
        source = f"assets/source-art/{unit}"
        manifest_file = copy_into(f"{source}/manifest.json", project)
        manifest = json.loads(manifest_file.read_text())
        copy_into(f"{source}/animation_contract.json", project)
        for part in manifest["parts"]:
            copy_into(part["png"], project)
        name = unit.split("/")[-1]
        scene = generate(manifest, "res://plain_rig.gd").replace(
            'name="ScoutRig"', f'name="{name}"', 1)
        (project / f"{name}.tscn").write_text(scene)

    probe_file = copy_into("tests/art/w27_cutout_probe.gd", project)
    run_engine(project, ["--editor", "--import", "--quit"])
    result = run_engine(project, ["--script", f"res://{probe_file.relative_to(project)}"])
    print(result.stdout.strip())
    if "ERROR:" in result.stderr:
        raise RuntimeError(result.stderr)
    return (project / "probe_result.json").read_text()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--poses", type=Path, help="Optional JSON output of sampled Godot transforms")
    args = parser.parse_args()
    expected = (ROOT / ".godot-version").read_text().strip()
    actual = subprocess.check_output(["godot", "--version"], text=True).strip()
    if not actual.startswith(expected + "."):
        raise RuntimeError(f"Godot {expected} required, found {actual}")
    verify_post()
    with tempfile.TemporaryDirectory(prefix="w27-godot-") as folder:
        try:
            poses = probe(Path(folder))
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
            print(error.stdout or "")
            print(error.stderr or "")
            raise
    if args.poses:
        args.poses.write_text(poses)


if __name__ == "__main__":
    main()
