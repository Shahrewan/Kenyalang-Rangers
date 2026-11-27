# C36 · Revision 3 sound replacement

27 November 2026 · Godot `4.7.2.stable.official.ed1daf0bf` · Baseline `d043adc` (PR #49)

Revision 3 is a replacement for the 133 installed clips. It uses recorded CC0 material documented in the batch receipts. The cue registry, all 114 cue groups, variant assignments, gains, import settings, playback code, and export allowlist retain their previous definitions.

[Measured manifest](../../data/audio/sfx_manifest.json) · [CSV mirror](../production/audio/C36_SFX_MANIFEST.csv) · [Recording receipts](../production/audio/C36_SFX_PROVENANCE.json)

| Delivery | Accepted | Source bytes | ZIP SHA-256 |
| --- | ---: | ---: | --- |
| Batch A, revision 3 | 41 | 1,264,852 | `312023a6d7ce1e12348146e20b46926fd2747a6db7fa96bd7a77f8485875b677` |
| Batch B, revision 3 | 92 | 2,104,688 | `a5d6487fbf3478b51cc2fe4c789ec510696668736da29d4975f12e3a5e843c7f` |
| Total | **133** | **3,369,540** | |

All 79 required and 54 optional files passed. Both embedded planning CSV hashes match the original C36-A ledger. The Python WAV and FFmpeg decoders agree for each file. All 133 WAV and decoded PCM hashes changed from revision 2. Paths, sample counts, file lengths and cue durations match revision 2. The checks found zero missing files, zero duplicate PCM and zero pairs over the waveform duplicate threshold. Sample peaks range from −19.69 to −7.50 dBFS, with zero clipped samples. The 53 distinct recording excerpts match their supplied SHA-256 values, and all 18 public source pages showed CC0.

**Trim exception.** At the project’s −56 dBFS threshold, `ui_radio_continue` begins after 7.302 ms and has a 68.163 ms quiet tail. The general threshold is 55% of duration, about 60.512 ms for this 110.023 ms clip. The supplied press still starts within 8 ms and occupies the same playback window, so acceptance retains the exact PCM with a hash-specific limit of 69 ms. A test verified that changing the reviewed hash restores rejection under the general rule.

## Android candidate

Godot imported 121 clips as bit-identical PCM. The same 12 longer clips remain QOA. Godot playback comparison against the revised PCM renders gave at least 30.77 dB signal-to-error and a maximum 0.152 dB peak change. Imported audio occupied 2,749,171 bytes before ZIP compression and 2,164,657 bytes inside the APK.

The signed candidate is `build/android/kenyalang-rangers-c36-rev3-debug.apk`, SHA-256 `2c567a886cfec890879dd55f1160bfeb63cca6179a574508142b0e0de8259f93`. It is 43,399,111 bytes, 4,096 bytes larger than the retained C36-D APK. Each of the 133 packaged audio resources changed. Every other APK entry matched byte for byte apart from the regenerated pack index and signature metadata. The same package identity and certificate passed v2/v3 and 16 KiB alignment checks. The retained C35 and C36-D APK hashes match their prior QA records.

Godot editor import and startup passed. The full source regression passed **6,023 checks across 50 runners**. The exact signed payload passed **4,107 checks across 31 runs**, including all 133 imported playback streams and fresh and returning C36-D save rehearsals on the host.

ADB found no attached device. Physical listening, audio focus and in-place installation remain pending. Use the existing Android audio test procedure with the revision 3 filename. [Physical Android procedure](../../export/README.md#c36-d-sound-effects-candidate)

## Reproduce the source checks

```sh
python3 -B tools/audit_sfx.py --batch /tmp/revision-3-batch-a --batch /tmp/revision-3-batch-b --ffmpeg
python3 -B tools/audit_sfx.py --ffmpeg
python3 -B tools/run_regression.py --logs build/qa/c36-refresh/regression
```

The input arguments point to extracted batches. Their source banks and production tools stay outside the project. Local logs are under `build/qa/c36-refresh`.
