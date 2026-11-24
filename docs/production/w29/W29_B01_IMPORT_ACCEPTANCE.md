# W29-B01 · E02 Poacher import acceptance

24 November 2026 · `E02` · Asset v0.3.0 · Godot `4.7.2.stable.official.ed1daf0bf`

**Revised export and isolated import passed.** The owner approved v0.3's hairstyle and outfit, with the shared proportions from v0.2. The E02 kit is ready for live C1-02 binding. D-014 release review remains open.

- [Editable Inkscape source, pivot and animation manifests](../../../assets/source-art/enemies/e02/)
- [Nine variant cutouts and the derived 96 × 96 badge](../../../assets/imported/enemies/e02/) · [Six shared E01 cutouts](../../../assets/imported/enemies/e01/)
- [Field-scale comparison, pose samples and independent parts](w29-b01-review.png)
- [Exact Codex handoff](W29_C01_HOLD_THE_LINE_HANDOFF.md)

## Checks performed

| Check | Observed evidence |
|---|---|
| Duplicate search on C28-A main | E02 definition and a generic current marker were present. No E02 imported textures, source, scene or badge existed. Reviewed the external enemy sheet and used it as a guide. Existing E01, Scout, Patrolman, Logistics Post, T01 and HUD were retained. |
| Source identity | The approved W27 E01 master supplies the common face details, body proportions, mask outlines and overlaps. E02's bare head has a short side-part. Ochre sleeves, a brick-red utility vest with a diagonal strap and charcoal trousers distinguish its outfit. Forearms, fists and boots share the six E01 PNGs. GDD p. 12 §§ H.2–H.2a supplies the standard melee role. |
| Transparent export and neutral assembly | Inkscape 1.4 rerendered all 15 parts and the badge. The exporter verified the six shared raster parts byte for byte and regenerated the nine E02-only cutouts. All parts have continuous alpha support and four transparent pixels per crop edge. The assembled neutral differs from its SVG raster by at most 1/255 premultiplied channel. E02 and E01 both measure 67.25 units tall, with the same pivots and socket positions. |
| Joints and socket | All 14 child pivots had at least 2 logical units of opaque fill in both parts at rest. The satchel attachment tracked the torso socket throughout both facings. The manifest records the near-hand `attack_fx` origin for Codex. |
| Pinned Godot isolated verification | All 15 field textures and offsets, independent absolute draw order and texture dimensions passed. Six pose contracts, 386 samples across neutral and mirrored playback, zero failures. Sampled shoulder, elbow, wrist, hip, knee and ankle overlap stayed connected. Loop, transient return to Move/Blocked, hold, pause and double delta passed. |
| Existing project regression | Pinned editor import and headless startup passed. The existing suite passed 2,037 checks across 29 runners. The C28-A validator confirmed 76 stage textures, 56 atlas regions, T01 occlusion at 80/60 and original geometry. W27's Patrolman/E01 check passed 916 samples with zero failures. The ledger passed 475 file/asset rows, all 116 storyboard mappings and six map geometries against the source archive. |

```sh
python3 -B tools/export_w27_cutouts.py --unit enemies/e02
python3 -B tools/verify_w27_art.py --unit enemies/e02
python3 -B tools/export_w27_cutouts.py
python3 -B tools/verify_w27_art.py
python3 -B tools/run_regression.py --logs build/qa/w29
python3 -B tools/build_first_contact_data.py --check
python3 -B tools/verify_first_contact_art.py
python3 -B docs/production/w21/validate.py
```

The review sheet composites the actual PNGs in declared order. The pose strip uses the transforms sampled from the isolated Godot AnimationPlayer. The project includes no live W29-B01 binding yet. C1-02 continues with its existing fallback until the integration ticket. See the handoff acceptance table for native and Android checks.
