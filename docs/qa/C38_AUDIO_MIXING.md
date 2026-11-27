# C38 audio mixing

27 November 2026 · Godot `4.7.2.stable.official.ed1daf0bf` · FFmpeg `7.1.5`

## Soundtrack measurements

The input is each uploaded loop OGG at unity gain. The previous build played procedural music. The delivery's prior encoding gain is recorded separately from the new fixed playback correction. The result is measured from the same decoded OGG after applying that correction with the user and Master sliders at unity. EBU R128 supplies integrated loudness, LRA and true peak. The short-term column gives the median and maximum of valid three-second windows. RMS is the combined-channel `astats` value in dBFS.

| Track | Delivery gain (dB) | Runtime correction (dB) | LUFS-I before → after | Short-term median / max, before → after (LUFS) | LRA before → after (LU) | True peak before → after (dBTP) | RMS before → after (dBFS) |
| --- | ---: | ---: | ---: | --- | --- | --- | --- |
| Fajar Baram | 0.00 | −3.25 | −14.7 → −18.0 | −15.0 / −12.3 → −18.3 / −15.6 | 3.3 → 3.3 | −2.3 → −5.5 | −16.23 → −19.48 |
| Bali | −1.60 | −4.62 | −13.4 → −18.0 | −13.3 / −12.2 → −17.9 / −16.8 | 1.6 → 1.6 | −0.9 → −5.5 | −14.71 → −19.33 |
| Epic Nusantara | −1.50 | −5.72 | −12.2 → −18.0 | −11.9 / −10.7 → −17.7 / −16.4 | 3.5 → 3.5 | −1.2 → −6.9 | −14.31 → −20.03 |
| The Tribe | −4.30 | −3.14 | −14.8 → −18.0 | −14.7 / −13.2 → −17.9 / −16.3 | 2.4 → 2.4 | −0.5 → −3.7 | −16.76 → −19.90 |
| Epic Gamelan Instrumental | −3.20 | −5.12 | −12.8 → −18.0 | −12.8 / −12.3 → −17.9 / −17.4 | 0.8 → 0.8 | −1.7 → −6.8 | −13.97 → −19.09 |
| Moonlight Wood | 0.00 | −4.16 | −13.8 → −17.9 | −13.9 / −10.7 → −18.0 / −14.8 | 3.2 → 3.2 | −2.1 → −6.2 | −15.39 → −19.55 |

Every track is within ±0.5 LU of −18 LUFS-I and below −1.5 dBTP. The highest normalized true peak is −3.7 dBTP. All six OGG hashes match the supplied loop files, and LRA is unchanged to the measured precision. [Reproducible audit](../../tools/audit_soundtrack.py) · [Manifest with the exact gains](../../data/presentation/music_manifest.json)

## Buses and sliders

| Bus | Signal and control |
| --- | --- |
| Music → Master | Two bounded players. Fixed per-track correction × transition envelope × the Music slider's amplitude curve `(position / 100)^1.5`. Zero hard-mutes the bus. |
| SFX → Master | Existing catalog gains, cooldowns, category limits and priorities. The SFX slider controls bus amplitude with an independent hard mute. |
| Master → output | Existing Master amplitude and hard mute apply to both categories. A Godot hard limiter protects the combined mix with a −1.5 dBFS sample ceiling. |

At **0%, 25%, 50%, 75% and 100%** the Music bus is muted, −18.06 dB, −9.03 dB, −3.75 dB and 0.00 dB relative to each normalized track. The existing 45% Music default contributes −10.40 dB and the existing 80% Master default contributes another −1.94 dB. Settings apply through the existing saved preferences as soon as the value changes. Tests exercised the five positions on six distinct cues and their aliases, confirmed the bus and per-track gains independently, and checked that music mode switches and launcher restarts retain the selected values.

A mode switch uses a 450 ms complementary linear crossfade. The two fade weights total at most one. Related routes retain the active decoder, and the existing pause and suspend flow freezes playback and any transition in progress. Each OGG loops through the baked seam at offset zero. [Loop and route evidence](C38_SOUNDTRACK_INTEGRATION.md)

## Balance, peaks and concurrency

The revision 3 SFX library, cue gains and voice rules are carried forward intact. Tactical warnings and results retain higher priority, and Android retains eight SFX voices with two held for critical feedback. Attack, UI, healing, repair and resource cues keep their individual gains rather than being normalized to music. The existing game has no continuous ambience bed.

A Godot mixer probe used the production cues and master bus at 100% Master, Music and SFX. Four attacks and four tactical warnings were admitted concurrently at the indicated placements near each track's highest measured short-term window. Captured values are **sample peaks**, distinct from the oversampled per-track true peaks above.

| Mixer probe | Admitted SFX | Captured sample peak | RMS |
| --- | ---: | ---: | ---: |
| Epic Nusantara at 111.8 s | 8 | −6.46 dBFS | −17.80 dBFS |
| The Tribe at 98.9 s | 8 | −4.40 dBFS | −18.01 dBFS |
| Epic Gamelan Instrumental at 11.7 s | 8 | −5.36 dBFS | −17.94 dBFS |
| Fajar Baram → Bali crossfade | 0 | −8.26 dBFS | −21.70 dBFS |

The Music-only signal at 0% measured zero amplitude while a boss alert still produced signal. With SFX muted, music still produced signal. With Master muted, both post-fader meters were at Godot's floor. A synthetic overload measured +4.66 dBFS with protection bypassed and −1.50 dBFS through the limiter. [Mixer probe](../../tests/playtest/c38_audio_mix.gd)

These are host decoder, meter and event-concurrency measurements. Android speakers, headphones, Windows playback and subjective scene balance or musical seam quality remain pending. ADB found no attached handset. [Device checks](../../export/README.md#c38-soundtrack-candidate)

## Reproduce the measurements

```sh
mkdir -p build/qa/c38
python3 -B tools/audit_soundtrack.py --output build/qa/c38/loudness.json
godot --headless --path . --script res://tests/playtest/c38_audio_mix.gd
```
