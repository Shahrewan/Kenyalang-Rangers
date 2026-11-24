# W29-C01 · Bind reviewed art to Hold the Line

**Ticket for Codex.** The owner approved E02 v0.3. Start from `art/w29-production-art` and read the [pack delivery](W29_PRODUCTION_DELIVERY.md). Add the illustrated T01 presentation to the Story operation `C1-02` and bind the prepared E02 rig. Use the shipped C28-A path for C1-01 as the technical reference. Bring C1-01 and C1-02 into the same presentation adapter where that is small and verifiable. Keep C1-03 through C2-10 and other modes on their existing presentation for this ticket.

## Exact inputs and destinations

| Input | Codex destination or use |
|---|---|
| [E02 v0.3 SVG, manifest and keys](../../../assets/source-art/enemies/e02/) · [Prepared E02 rig](../../../assets/imported/enemies/e02/rig.tscn) | The prepared scene uses the same presentation driver as E01. Its runtime clip is `res://data/presentation/w29/animation/enemies__e02.json`. Both rigs share the existing forearm, fist and boot files. Keep source art outside Godot's import scan. |
| [T01 registration](../../../data/presentation/first_contact/field.json), [field adapter](../../../scripts/ui/first_contact_field.gd), [C28-A QA](../../qa/C28_A_FIRST_CONTACT.md) | Reuse its exact geometry registration, crops, textures, 56 atlas IDs and east woodland layers. Existing Scout, Patrolman, E01 and Post assets stay at their current paths. |
| [C1-02 stage](../w13/stages/c1-02.json) and [E02 definition](../../../data/enemies/e02_poacher.tres) | Read-only truth for map, waves, dialogue triggers, source names, E02 stats, attack and outcome. Preserve the original resources, save contracts and evaluation code. |
| [E02 field badge](../../../assets/imported/enemies/e02/field_badge.png) | Register the derived image under the exact `E02` badge key for existing Intel surfaces. Keep existing name, HP, tags and counterplay text. Use one badge across planning and pause. |

Validate the generated art catalog and use its E02 rig and clip paths.

```sh
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/build_first_contact_data.py --check
```

## Implementation steps

1. **Stage and fallback.** Inspect `CampaignBattle._prepare_campaign`, `_open_operation` and `SampleBoard._draw`. Allow the illustrated path for `C1-02` on `T01` in addition to C1-01, with the same registration checks. The illustrated draw returns before its legacy enemy loop, so retain a labeled fallback for any supported encounter actor without a live art registration. Keep deployment fallback for later unlocked Ranger/Facility IDs that a returning player can legally bring. Keep the C1-01 starter hint and tutorial-only availability on their existing gates.
2. **Actor, timing and overlays.** Register E02 by exact definition ID in the existing rig table and use it in `FirstContactField._spawned` by live serial. Keep the external route anchor, 80-unit scale basis, and E01 mirror behavior on turns. Wire `Move`, `Blocked`, `Attack`, `Hit`, `Defeat` and `Exit` to current combat events/reads. Keep manual animation advancement once per combat step. E02 has standard melee, with a near-hand socket available for a short visual accent. HP and status remain on the board overlay. A short terminal pose under the east foreground cannot alter the escape tick or produce a second resolution. Preserve the existing C1-01 muzzle/bolts/hits and layered Post.
3. **Post and badges.** C1-02 uses ordinary loadout semantics and may omit the Post subject to existing planning rules. Use C28-A's four Post layers for Ready and its existing build/placement visuals for construction. Check `build_ticks_left` before painting Ready. Current illustrated Post drawing assumes instant completion, so an unfinished repeat Post needs build/countdown art at the same occupied pair. No new Token timing or refund rule. Resolve the E02 badge in Intel without replacing or packing a second E01 image. Use the existing result marks and portrait aliases on C1-02.
4. **Resource selection.** Register the E02 badge, packed scene and runtime clip used by the game in the resource-selected Android presets or through scene dependencies. Include the E02 JSON under `data/presentation/w29/animation/` alongside the existing First Contact clip include. Confirm that the export traverses the 15 texture dependencies and the clip. Update asset and binding evidence once the runtime check passes.

## Acceptance tests

| Check | Pass condition |
|---|---|
| Source art | W29-B01 owner review recorded. `python3 -B tools/export_w27_cutouts.py --unit enemies/e02` and `python3 -B tools/verify_w27_art.py --unit enemies/e02` pass from the checked-in sources. |
| Story and visual scope | Launcher selects C1-02 through the existing C1-01-clear and Control gates. C1-02 shows the illustrated T01 field, stock nodes, dynamic HUD, readable field and Intel identities, and Manager/Leader in the existing sequence. C1-01 retains all its completed art. C1-03 and Chapter 2 still follow their existing rendering choices. |
| Two enemy rigs | E01 and E02 coexist in an actual C1-02 scene through natural spawns. Verify independently walking and blocked poses, mirror on horizontal directions, vertically retained facing, attack connection, Hit, and one terminal visual per actor. Woodland occlusion in an escape capture leaves no body, HP or outline visible at the real escape tick. |
| Placement, clock and state | Drive live Story with touch gestures, valid/invalid drops, an ordinary Post instant opening where eligible, a repeated Post building with countdown and a later retreat/cancel. Check spend, refund, per-type delay, D02, repeated copies and HP, at 1×/2× and during pause/dialogue. The starter tray/guide still appears only where allowed. Exercise an advanced replay loadout with active registered or labeled fallback art. |
| Gameplay parity | Run the [C26 ordinary clear](../../qa/C26_CAMPAIGN_MATRIX.md#android-manual-check) arrangement using the existing C1-02 resources. Compare against the same baseline build, input and ticks. Expected baseline with that fixture is 17 defeated, one escaped, 90 Integrity, resolution at tick 8169. Compare both actual battle state and report, mission and reward keys, Funds and unlock settlement, and save/continue. Run the established C28-A scenarios for C1-01. No injected damage in the ordinary-clear comparison. |
| Screens and player payload | Native captures at 1280×720 and 960×540 show E01/E02 together, E02 Intel, normal construction and the escape tick. Run the pinned full regression and a resource-selected APK dependency audit. On an offline landscape phone, verify normal/130% text, thumb drag, safe insets, depth ordering, stacked HP, fallback legibility, Continue/Skip and both speeds. Record actual hardware and results separately. |

From a pinned editor import, run `python3 -B tools/run_regression.py --logs build/qa/w29/c1-02`, `python3 -B tools/verify_first_contact_art.py`, and the two W29-B01 commands above. Add or extend the native C28 runner to exercise C1-02 specifically. Record actual captures, exported dependency check, and any device limitation. Gameplay, stage content, balances and later art batches are outside this ticket.
