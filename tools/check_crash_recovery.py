"""Kill a disposable Godot process at a known save boundary, then cold-launch it."""
import os
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory() as temporary:
        directory = Path(temporary)
        env = os.environ.copy()
        for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
            path = directory / key
            path.mkdir()
            env[key] = str(path)
        marker = directory / "ready"
        cmd = ["godot", "--headless", "--path", str(ROOT), "--script",
               "res://tests/crash/profile_worker.gd", "--"]
        with subprocess.Popen([*cmd, "seed", str(marker)], env=env) as writer:
            try:
                deadline = time.monotonic() + 20
                while not marker.exists():
                    if writer.poll() is not None or time.monotonic() > deadline:
                        raise RuntimeError("Worker did not reach the committed-response checkpoint")
                    time.sleep(0.02)
            finally:
                writer.kill()
                writer.wait()
        subprocess.run([*cmd, "reload"], env=env, check=True, timeout=30)


if __name__ == "__main__":
    main()
