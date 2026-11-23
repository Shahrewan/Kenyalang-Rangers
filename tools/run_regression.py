"""Run the pinned editor, startup and every Godot test with disposable user profiles."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
DIAGNOSTIC = re.compile(r"^(?:SCRIPT ERROR:|ERROR:|WARNING:|FAIL )", re.MULTILINE)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--logs", type=Path, default=ROOT / "build/qa/c23")
    args = parser.parse_args()
    args.logs.mkdir(parents=True, exist_ok=True)
    runners = sorted(ROOT.glob("tests/smoke/*.gd")) + sorted(ROOT.glob("tests/unit/*_test.gd"))
    cases = [("import", ["--editor", "--import"]), ("boot", ["--quit-after", "4"])]
    cases += [(p.stem, ["--script", f"res://{p.relative_to(ROOT)}"]) for p in runners]
    total = 0
    with tempfile.TemporaryDirectory() as temp:
        for name, flags in cases:
            env = os.environ.copy()
            for key in ("XDG_DATA_HOME", "XDG_CACHE_HOME", "XDG_CONFIG_HOME"):
                directory = Path(temp, name, key)
                directory.mkdir(parents=True)
                env[key] = str(directory)
            if name == "import":
                version = subprocess.check_output([args.godot, "--version"], env=env, text=True).strip()
                if version != "4.7.2.stable.official.ed1daf0bf":
                    raise SystemExit(f"Unexpected Godot build {version}")
            result = subprocess.run([args.godot, "--headless", "--path", ROOT, *flags], env=env,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=180)
            output = result.stdout
            path = args.logs / f"{name}.log"
            path.write_text(output)
            summary = re.search(r"^.*?: (\d+) checks, (\d+) failures$", output, re.MULTILINE)
            checks = int(summary[1]) if summary else len(re.findall(r"^PASS ", output, re.MULTILINE))
            if (result.returncode or DIAGNOSTIC.search(output) or (summary and int(summary[2]))
                    or ("--script" in flags and not checks)):
                raise SystemExit(f"FAILED {name}, see {path}\n{output[-2000:]}")
            print(f"{name}: PASS ({checks} checks)", flush=True)
            total += checks
    print(f"{version} · {total} checks across {len(runners)} runners")


if __name__ == "__main__":
    main()
