"""Audit the installed WAVs or independently check extracted C36 production deliveries."""
import argparse
import csv
from hashlib import sha256
import io
import json
import math
from pathlib import Path
import shutil
import struct
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "data/audio/sfx_manifest.json"
MIRROR = ROOT / "docs/production/audio/C36_SFX_MANIFEST.csv"
CATALOG = ROOT / "data/presentation/sfx_catalog.json"
SCALE = 32768
QUIET_DB = -56
QUIET = SCALE * 10 ** (QUIET_DB / 20)
SOURCES = {"https://opengameart.org/node/86682", "https://kenney.nl/assets/impact-sounds"}


def digest(data):
    return sha256(data).hexdigest()


def db(amplitude):
    return round(20 * math.log10(max(amplitude / SCALE, 1e-12)), 3)


def measure(path, specification, ffmpeg=None):
    raw = path.read_bytes()
    if path.suffix != ".wav" or raw[:4] != b"RIFF" or raw[8:12] != b"WAVE":
        raise ValueError("expected a RIFF/WAVE file")
    if struct.unpack_from("<I", raw, 4)[0] + 8 != len(raw):
        raise ValueError("RIFF length does not match file length")
    seen = set()
    cursor = 12
    while cursor + 8 <= len(raw):
        tag, size = struct.unpack_from("<4sI", raw, cursor)
        if tag in seen or tag not in {b"fmt ", b"data", b"LIST", b"JUNK"}:
            raise ValueError(f"unsupported, looping, or duplicate WAV chunk {tag!r}")
        seen.add(tag)
        cursor += 8 + size + (size % 2)
    if cursor != len(raw) or not {b"fmt ", b"data"} <= seen:
        raise ValueError("misaligned or incomplete RIFF chunks")
    with wave.open(io.BytesIO(raw)) as wav:
        rate, channels, depth = wav.getframerate(), wav.getnchannels(), 8 * wav.getsampwidth()
        expected = specification["sample_rate_hz"], specification["channel_count"], specification["bit_depth"]
        if (rate, channels, depth) != expected or wav.getcomptype() != "NONE" or expected != (22050, 1, 16):
            raise ValueError("expected uncompressed 22,050 Hz mono signed PCM16")
        frames = wav.getnframes()
        pcm = wav.readframes(frames)
    if len(pcm) != frames * 2 or not pcm:
        raise ValueError("empty or truncated PCM data")
    if ffmpeg:
        decoded = subprocess.run(
            [ffmpeg, "-v", "error", "-i", str(path), "-f", "s16le", "-"],
            capture_output=True, check=True,
        ).stdout
        if pcm != decoded:
            raise ValueError("FFmpeg PCM differs from standard WAV decoder")
    samples = [s[0] for s in struct.iter_unpack("<h", pcm)]
    peak = max(map(abs, samples))
    clipped = sum(sample in {-32768, 32767} for sample in samples)
    active = [i for i, sample in enumerate(samples) if abs(sample) >= QUIET]
    duration = frames * 1000 / rate
    if not active or db(peak) < -40 or clipped or db(peak) > -2:
        raise ValueError("silent, exceptionally quiet, clipped, or above acceptance peak")
    if duration > specification["max_duration_ms"]:
        raise ValueError(f"{duration:.3f} ms exceeds the canonical duration maximum")
    leading = round(1000 * active[0] / rate, 6)
    trailing = round(1000 * (frames - active[-1] - 1) / rate, 6)
    if leading > 30 or trailing > min(110, duration * 0.55):
        raise ValueError(f"excessive quiet edges ({leading:.1f} / {trailing:.1f} ms)")
    return {
        "encoding": "pcm_s16le", "sample_rate_hz": rate, "channel_count": channels,
        "bit_depth": depth, "sample_frames": frames, "actual_duration_ms": round(duration, 6),
        "target_delta_ms": round(duration - specification["target_duration_ms"], 6),
        "size_bytes": len(raw), "sha256": digest(raw), "pcm_sha256": digest(pcm),
        "sample_peak_dbfs": db(peak), "rms_dbfs": db(math.sqrt(sum(s * s for s in samples) / frames)),
        "clipped_samples": clipped, "quiet_threshold_dbfs": QUIET_DB,
        "leading_below_threshold_ms": leading, "trailing_below_threshold_ms": trailing,
        "embedded_loop": False,
    }, samples[active[0]:active[-1] + 1:4]


def verify_delivery(folder, canonical, used, receipts):
    actual_path, = folder.glob("*_actual_manifest.json")
    actual = json.loads(actual_path.read_text())
    delivered = set()
    bank_path = folder / "synthesis_source/foley_bank"
    bank = json.loads((bank_path / "bank_provenance.json").read_text())
    source_names = {}
    for sample in bank:
        name = sample["file"]
        if (Path(name).name != name or sample["source"] not in SOURCES or sample["license"] != "CC0-1.0"
                or digest((bank_path / name).read_bytes()) != sample["bank_sha256"]
                or not 0 <= sample["crop_start_s"] < sample["crop_end_s"]):
            raise ValueError(f"unverified source receipt {name}")
        source_names[sample["name"]] = sample
    for item in actual["assets"]:
        key = item["cue_id"]
        spec = canonical[key]
        if key in used or actual["batch"].upper() != spec["batch"]:
            raise ValueError(f"duplicate cue or invalid batch for {key}")
        compared = set(spec) - {"production_status", "measured_audio_properties", "provenance", "integration_status", "import_compression", "runtime_priority"}
        if any(spec[k] != item.get(k) for k in compared):
            raise ValueError(f"canonical designation mismatch: {key}")
        record = item["measured_audio_properties"]
        names = item["foley_bank_sample_ids"].split(" | ")
        if not item["provenance"] or not all(name in source_names for name in names):
            raise ValueError(f"missing source receipt for {key}")
        path = folder / item["relative_filename"]
        delivered.add(path)
        used[key] = (path, record, {
            "production": "Kenyalang Rangers original arrangement and procedural processing",
            "revision": actual["revision"],
            "foley": names,
            "ledger": "docs/production/audio/C36_SFX_PROVENANCE.json",
        })
    shipped = set((folder / "assets/audio/sfx").rglob("*"))
    if {p for p in shipped if p.is_file()} != delivered:
        raise ValueError(f"undeclared runtime files in {folder.name}")
    receipts.update(source_names)


def registry(manifest):
    groups = {}
    for item in manifest["assets"]:
        group = groups.setdefault(item["variant_group"], {
            "priority": item.get("runtime_priority", item["priority"]), "gain_db": item["relative_playback_gain_db"],
            "category": item["category"], "cooldown_ms": item["retrigger_cooldown_ms"],
            "limit": item["polyphony_limit"], "fallback": item["fallback_cue"], "paths": [],
        })
        if item["production_status"] == "accepted":
            group["paths"].append("res://" + item["relative_filename"])
    entities = {
        row["canonical_entity_id"]: row["planned_bindings"]
        for row in manifest["entity_coverage"]
    }
    return {
        "groups": groups,
        "aliases": {k: v["direct_asset_cue"] for k, v in manifest["legacy_cues"].items()},
        "entities": entities,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--batch", action="append", type=Path, default=[], help="Extracted package directory")
    parser.add_argument("--ffmpeg", action="store_true", help="Cross-check the PCM with FFmpeg")
    parser.add_argument("--accept", action="store_true", help="Copy the validated files and refresh the acceptance records")
    parser.add_argument("--report", type=Path, help="Write independent validation results")
    args = parser.parse_args()
    if args.accept and not args.batch:
        parser.error("--accept requires extracted production deliveries")
    manifest = json.loads(MANIFEST.read_text())
    specs = {item["cue_id"]: item for item in manifest["assets"]}
    provided, receipts, measured, signatures, fingerprints = {}, {}, {}, {}, {}
    for directory in args.batch:
        verify_delivery(directory, specs, provided, receipts)
    errors, missing = {}, []
    ffmpeg = shutil.which("ffmpeg") if args.ffmpeg else None
    if args.ffmpeg and not ffmpeg:
        parser.error("FFmpeg is required by --ffmpeg")
    for cue, spec in specs.items():
        path, expected, provenance = provided.get(cue, (
            ROOT / spec["relative_filename"] if not args.batch else None,
            spec["measured_audio_properties"], spec["provenance"],
        ))
        if path is None or not path.is_file():
            missing.append(cue)
            continue
        try:
            result, fingerprint = measure(path, spec, ffmpeg)
            if expected and any(result[k] != expected[k] for k in ("sha256", "pcm_sha256", "size_bytes", "sample_frames")):
                raise ValueError("file, PCM, length or frame count disagrees with actual manifest")
            if not provenance:
                raise ValueError("missing provenance")
            if result["pcm_sha256"] in signatures:
                raise ValueError("duplicates PCM of " + signatures[result["pcm_sha256"]])
        except (ValueError, wave.Error, struct.error, subprocess.CalledProcessError) as error:
            errors[cue] = str(error)
            continue
        signatures[result["pcm_sha256"]] = cue
        fingerprints[cue] = fingerprint
        measured[cue] = result
    near_duplicates = []
    for key, one in fingerprints.items():
        for other, two in fingerprints.items():
            if key >= other or not 0.91 <= len(one) / len(two) <= 1.10:
                continue
            length = min(len(one), len(two))
            left, right = one[:length], two[:length]
            dot = sum(a * b for a, b in zip(left, right))
            score = dot / math.sqrt(sum(a * a for a in left) * sum(b * b for b in right))
            if abs(score) >= 0.97:
                near_duplicates.append([key, other, round(score, 4)])
    if not args.batch:
        expected_paths = {ROOT / row["relative_filename"] for row in specs.values()}
        extras = sorted(p for p in (ROOT / "assets/audio/sfx").rglob("*.wav") if p not in expected_paths)
        for extra in extras:
            errors[str(extra.relative_to(ROOT))] = "undeclared WAV"
        if CATALOG.is_file() and json.loads(CATALOG.read_text()) != registry(manifest):
            errors["runtime catalog"] = "does not match accepted manifest"
    summary = {"accepted": len(measured), "missing": missing, "rejected": errors,
               "near_duplicate_pairs": near_duplicates, "bytes": sum(r["size_bytes"] for r in measured.values())}
    print(json.dumps(summary, indent=2))
    if args.report:
        args.report.write_text(json.dumps(summary, indent=2) + "\n")
    if missing or errors or near_duplicates:
        return 1
    if args.accept:
        for cue, spec in specs.items():
            source, _, provenance = provided[cue]
            target = ROOT / spec["relative_filename"]
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            spec.update(production_status="accepted", measured_audio_properties=measured[cue], provenance=provenance)
        MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
        with MIRROR.open("w", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=list(manifest["assets"][0]), lineterminator="\n")
            writer.writeheader()
            for row in manifest["assets"]:
                writer.writerow({k: json.dumps(v, ensure_ascii=False) if isinstance(v, dict) else v for k, v in row.items()})
        ledger = MIRROR.with_name("C36_SFX_PROVENANCE.json")
        ledger.write_text(json.dumps(list(receipts.values()), indent=2, ensure_ascii=False) + "\n")
        CATALOG.write_text(json.dumps(registry(manifest), separators=(",", ":")) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
