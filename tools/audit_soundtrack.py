"""Measure the supplied OGGs before and after the exact in-game fixed gain using FFmpeg."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from hashlib import sha256
import json
from pathlib import Path
import re
import statistics
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "data/presentation/music_manifest.json"
SHORT_TERM = re.compile(r"t:\s*([0-9.]+).*?\bS:\s*(-?[0-9.]+)")


def measure(path, gain_db):
    filters = f"volume={gain_db}dB,astats=reset=0,ebur128=peak=true"
    run = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostdin", "-i", str(path), "-af", filters, "-f", "null", "-"],
        text=True, capture_output=True, check=True,
    )
    log = run.stderr
    summary = log.rsplit("Summary:", 1)[1]
    short = [float(level) for t, level in SHORT_TERM.findall(log) if float(t) >= 3 and float(level) > -70]
    stats = log.rsplit("Overall", 1)[1]
    return {
        "integrated_lufs": float(re.search(r"\bI:\s*([\d.-]+)", summary)[1]),
        "short_term_median_lufs": round(statistics.median(short), 1),
        "short_term_max_lufs": max(short),
        "lra_lu": float(re.search(r"\bLRA:\s*([\d.-]+)", summary)[1]),
        "true_peak_dbtp": float(re.search(r"\bPeak:\s*([\d.-]+)", summary)[1]),
        "rms_dbfs": float(re.search(r"RMS level dB:\s*([\d.-]+)", stats)[1]),
    }


def check(track):
    path = ROOT / track["runtime_path"]
    raw = path.read_bytes()
    if sha256(raw).hexdigest() != track["actual"]["sha256"]:
        raise ValueError(f"Supplied OGG hash differs for {path.name}")
    probe = subprocess.check_output(
        ["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_streams", "-of", "json", str(path)],
        text=True,
    )
    stream = json.loads(probe)["streams"][0]
    if (stream["codec_name"], int(stream["sample_rate"]), stream["channels"]) != ("vorbis", 32000, 2):
        raise ValueError(f"Unexpected soundtrack format for {path.name}")
    if abs(float(stream["duration"]) - track["loop_points"]["end_seconds"]) > 0.001:
        raise ValueError(f"Unexpected loop duration for {path.name}")
    gain = track["normalization_gain_db"]
    return {"title": track["title"], "cue_id": track["cue_id"], "bytes": len(raw), "gain_db": gain,
            "before": measure(path, 0), "after": measure(path, gain)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text())
    with ThreadPoolExecutor(max_workers=3) as pool:
        rows = list(pool.map(check, manifest["tracks"]))
    report = json.dumps(rows, indent=2, ensure_ascii=False)
    print(report)
    if args.output:
        args.output.write_text(report + "\n")
    for row in rows:
        after = row["after"]
        if (abs(after["integrated_lufs"] - manifest["normalization_target_lufs_i"]) > 0.5
                or after["true_peak_dbtp"] > manifest["normalization_max_dbtp"]):
            raise SystemExit(f"Normalized {row['cue_id']} is outside target")


if __name__ == "__main__":
    main()
