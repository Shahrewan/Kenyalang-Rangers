# C34 host performance

Baseline main is `0546dbd`. The C34 candidate and baseline used Godot 4.7.2 stable, the Compatibility renderer, a native 960×540 X11 window, Mesa llvmpipe (LLVM 19.1.7), and a 90 fps cap on the same AMD EPYC 9V74 host. Each row samples 240 rendered intervals using Godot's frame-post-draw signal. This is a shared software-rendered host. The physical device's frame time, memory, long-session stability and 60/30 fps targets remain unverified.

Campaign scenarios advance normal production deployments, skills and clocks to a defined condition, then accumulate rendered frames at live speed. The Chaos configuration uses five populated slots of 50 enemies each. A separate synthetic stress variant uses 50 simultaneous production rigs, with compressed spawn intervals and extended HP in the local fixture. The seeded Headquarters profile opens all 11 rooms at their maximum level. Timing uses initial frame completion from the UI route transition. Engine static allocation and Linux peak RSS measure different things, and a few runs could not read RSS.

## Rendered samples

Measurements are main → C34.

| Scenario | p50 / p95 frame time (ms) | Draw calls, median | Active enemies during sample | Godot static memory (MiB) | Texture memory (MiB) | Peak host RSS (MiB) |
| --- | ---: | ---: | --- | ---: | ---: | ---: |
| First Contact active | 13.8 / 19.8 → 16.6 / 31.3 | 163 → 163 | 3–4 → 3–5 | 53.3 → 54.4 | 52.8 → 52.9 | unavailable → 250.0 |
| First Contact paused | 18.2 / 27.2 → 21.0 / 39.6 | 196 → 214 | 4–4 → 5–5 | 53.9 → 54.9 | 52.9 → 53.0 | unavailable → 259.1 |
| C2-04 Jammed Communications, wave 3 | 41.2 / 58.7 → 65.7 / 145.6 | 764 → 733 | 4–7 → 1–7 | 62.8 → 62.1 | 65.0 → 64.9 | unavailable → 313.3 |
| C2-08 Breaking the Line, Heat active | 18.1 / 26.3 → 26.2 / 48.2 | 243 → 243 | 4–5 → 4–5 | 57.1 → 57.8 | 63.6 → 63.6 | unavailable → 274.7 |
| C1-05 Diversion Captain | 19.1 / 36.3 → 20.3 / 37.5 | 187 → 187 | 1–1 → 1–1 | 56.5 → 57.3 | 59.8 → 59.8 | unavailable → 263.1 |
| C2-10 Final Interception, wave 4 | 33.3 / 47.9 → 35.0 / 58.0 | 666 → 671 | 6–14 → 6–14 | 64.2 → 64.0 | 67.2 → 67.2 | 329.4 → 316.9 |
| Chaos composer, 250 configured total | 14.0 / 30.3 → 11.2 / 23.5 | 107 → 95 | 0–0 → 0–0 | 54.9 → 55.5 | 50.8 → 51.0 | 247.4 → 245.8 |
| Chaos stress, 50 resident at once | 55.1 / 130.8 → 46.1 / 81.1 | 1,132 → 1,132 | 50–50 → 50–50 | 63.2 → 61.9 | 57.8 → 57.9 | 320.4 → 329.6 |
| Headquarters, all rooms | 21.5 / 35.9 → 24.1 / 39.6 | 164 → 164 | 0–0 → 0–0 | 50.1 → 50.7 | 98.0 → 98.1 | 286.7 → 287.1 |

| Transition | First frame (ms), main → C34 |
| --- | ---: |
| First Contact active | 98.9 → 113.8 |
| C2-04 Jammed Communications, wave 3 | 104.1 → 170.7 |
| C2-08 Breaking the Line, Heat active | 123.3 → 146.7 |
| C1-05 Diversion Captain | 193.4 → 135.3 |
| C2-10 Final Interception, wave 4 | 114.9 → 163.2 |
| Chaos composer, 250 configured total | 72.3 → 95.9 |
| Chaos stress, 50 resident at once | 98.9 → 159.2 |
| Headquarters, all rooms | 155.5 → 185.8 |

Frame timing varies with host contention and the number of combat ticks and actors reached during a sample. First Contact remained at the same tick within each paused sample, and board redraw callbacks fell from 515 to zero. In dense Chaos, draw calls remained at 1,132 per rendered frame, and the static allocation measure fell by 1.3 MiB. The headless microbenchmark below isolates the animation change from rendering and layout changes.

A consecutive C2-04 repeat with two llvmpipe worker threads measured 88.4 / 264.0 ms p50 / p95 on main and 47.1 / 73.3 ms on C34. Both samples started on tick 14,774 with 24 deployed units. The reference render times varied enough between runs to leave active-battle performance acceptance open. The target frame budgets are 16.7 ms for 60 fps and 33.3 ms for 30 fps on actual phones.

## Rig setup and disposal

Seven headless runs instantiate 50 identical W29 Shield Carrier rigs. The median batch time fell from **41.606 ms to 7.795 ms** and the median added Godot static memory fell from **7,480,796 B to 4,867,476 B**. Each rig keeps its own playback and pose while sharing immutable animation tracks. The weak cache releases a library after the final instance. Seven assertions passed in [the cache test](../../../../tests/unit/c34_animation_cache_test.gd), including independent movement and facing, multiple scene contracts, teardown and re-entry.

The rebuilt package scopes the weak entries to the root window. A seven-run headless check of that scope measured a 6.069 ms median and 4,867,476 B of added static memory for the same 50 rigs. The exported visual and teardown checks cover this final ownership scheme.

## Repeated transitions

Each run re-enters First Contact from the menu and returns eight times. These samples measure resource disposal after returning to the Home screen.

| Measure | Main | C34 |
| --- | ---: | ---: |
| Median plan → battle first frame (ms) | 72.1 | 68.9 |
| Menu nodes after first and last return | 43 → 43 | 42 → 42 |
| Resource count after first and last return | 456 → 456 | 453 → 453 |
| RSS after first and last return (KiB) | 291,048 → 291,048 | 291,736 → 291,736 |

The separate 64-cycle host run completed 192 screen transitions per build. Node and resource counts returned to the same value on each re-entry. Menu RSS was measured after each return and excludes later idle platform management.

| 64-cycle return metric | Main | C34 |
| --- | ---: | ---: |
| Menu nodes | 43 → 43 | 42 → 42 |
| Menu resource count | 456 → 456 | 453 → 453 |
| Menu RSS (KiB) | 291,612 → 291,612 | 292,600 → 292,600 |

## Commands

Run each command with disposable user-data directories when comparing versions. Use the same benchmark script and window size on the baseline and candidate. The raw scenario logs are copied into `build/qa/c34/performance`.

```sh
godot --disable-vsync --audio-driver Dummy --path . --script res://tests/playtest/c34_android_host_benchmark.gd -- first 960x540
godot --disable-vsync --audio-driver Dummy --path . --script res://tests/playtest/c34_android_host_benchmark.gd -- hq 960x540 64
godot --headless --path . --script res://tests/playtest/c34_android_host_benchmark.gd -- rigs
godot --headless --path . --script res://tests/unit/c34_animation_cache_test.gd
```

The other native scenario names are `chapter2`, `heat`, `boss`, `final` and `chaos`.
