"""Build an unsigned private-test APK from committed source for offline signing."""
import argparse
from configparser import ConfigParser
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile


ROOT = Path(__file__).resolve().parents[1]
PIN = "4.7.2.stable.official.ed1daf0bf"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--package", default="com.shahrewan.kenyalangrangers.dev")
    parser.add_argument("--icon", help="Override the preset with a tracked 192px launcher PNG")
    parser.add_argument("--version-name", default="0.1.0-rc.1")
    parser.add_argument("--version-code", type=int, default=2)
    parser.add_argument("--out", type=Path, default=ROOT / "build/android/c24")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+", args.package):
        parser.error("Invalid Android application ID")
    if not 0 < args.version_code <= 2100000000 or not re.fullmatch(r"[\w.-]+", args.version_name):
        parser.error("Expected a positive Android version code and a version label")
    icon = Path(args.icon) if args.icon else None
    if icon is not None and (icon.is_absolute() or ".." in icon.parts or icon.suffix.lower() != ".png"):
        parser.error("Expected a project-relative launcher PNG")
    executable = shutil.which(args.godot)
    if not executable:
        parser.error("Godot executable unavailable")
    godot = Path(executable).resolve()
    if subprocess.check_output([godot, "--version"], text=True).strip() != PIN:
        parser.error(f"Use the pinned Godot build {PIN}")
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    stem = f"{args.package}-{args.version_name}-{args.version_code}"
    with tempfile.TemporaryDirectory() as temporary:
        project = Path(temporary)
        archive = project / "source.tar"
        subprocess.run(["git", "archive", "-o", archive, revision], cwd=ROOT, check=True)
        with tarfile.open(archive) as source:
            source.extractall(project, filter="data")
        if icon is not None and not (project / icon).is_file():
            parser.error("Commit the launcher PNG before exporting")
        # Reuse the player resource allowlist and ABI settings from the committed preset.
        cfg = ConfigParser(interpolation=None)
        cfg.optionxform = str
        preset = project / "export_presets.cfg"
        cfg.read(preset)
        cfg["preset.0"]["name"] = '"Android Candidate"'
        options = cfg["preset.0.options"]
        icon_field = "launcher_icons/main_192x192"
        if icon is not None:
            options[icon_field] = json.dumps("res://" + icon.as_posix())
        icon_path = json.loads(options[icon_field])
        options.update({
            "package/unique_name": json.dumps(args.package), "package/name": '"Kenyalang Rangers"',
            "version/code": str(args.version_code), "version/name": json.dumps(args.version_name),
            "package/signed": "false", "permissions/internet": "false",
        })
        with preset.open("w") as destination:
            cfg.write(destination, space_around_delimiters=False)
        settings = project / "project.godot"
        # Preserve Godot's top-level config_version and section serialization.
        original = settings.read_text()
        version = "config/version=" + json.dumps(args.version_name)
        if re.search(r"^config/version=", original, re.MULTILINE):
            original = re.sub(r"^config/version=.*$", version, original, count=1, flags=re.MULTILINE)
        else:
            original = original.replace("[application]\n", "[application]\n" + version + "\n", 1)
        settings.write_text(original)
        unsigned = project / f"{stem}-unsigned.apk"
        for flags in (["--editor", "--import"], ["--export-release", "Android Candidate", str(unsigned)]):
            subprocess.run([godot, "--headless", "--path", project, *flags], check=True)
        apk = out / unsigned.name
        shutil.move(unsigned, apk)
    with apk.open("rb") as binary:
        digest = hashlib.file_digest(binary, "sha256").hexdigest()
    metadata = {"source_commit": revision, "godot": PIN, "templates": "4.7.2.stable",
                "package": args.package, "version_code": args.version_code, "version_name": args.version_name,
                "icon": icon_path, "unsigned_apk": apk.name, "unsigned_sha256": digest}
    (out / f"{stem}-build.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(apk)


if __name__ == "__main__":
    main()
