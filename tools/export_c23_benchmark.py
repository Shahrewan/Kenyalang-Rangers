"""Export the committed C23 benchmark as a separate Android debug app."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    args = parser.parse_args()
    godot = shutil.which(args.godot)
    if not godot:
        parser.error("Godot executable not found")
    godot = Path(godot).resolve()
    apk = ROOT / "build/android/kenyalang-rangers-c23-benchmark.apk"
    apk.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temporary:
        project = Path(temporary)
        archive = project / "source.tar"
        subprocess.run(["git", "archive", "HEAD", "-o", archive], cwd=ROOT, check=True)
        with tarfile.open(archive) as source:
            source.extractall(project, filter="data")
        project_file = project / "project.godot"
        preset = project / "export_presets.cfg"
        menu = 'run/main_scene="res://scenes/menus/launcher.tscn"'
        entry = "res://scenes/qa/c23_load.tscn"
        settings = project_file.read_text()
        config = preset.read_text()
        package = 'package/unique_name="com.shahrewan.kenyalangrangers.dev"'
        if menu not in settings or package not in config or "export_files=PackedStringArray(" not in config:
            raise SystemExit("Update the benchmark exporter for the current launcher or Android preset")
        project_file.write_text(settings.replace(menu, f'run/main_scene="{entry}"'))
        config = config.replace(package, 'package/unique_name="com.shahrewan.kenyalangrangers.c23bench"')
        config = config.replace('package/name="Kenyalang Rangers (Dev)"', 'package/name="Kenyalang Rangers C23 Benchmark"')
        preset.write_text(config.replace("export_files=PackedStringArray(", f'export_files=PackedStringArray("{entry}", ', 1))
        for flags in (["--editor", "--import"], ["--export-debug", "Android Debug", str(apk)]):
            subprocess.run([godot, "--headless", "--path", project, *flags], check=True)
    print(apk)


if __name__ == "__main__":
    main()
