# C07 Scout Sniper rig pilot

Run the standalone scene in Godot 4.7.2 using **F6** on `scenes/qa/scout_rig_preview.tscn`, or from the project root:

```sh
godot --path . res://scenes/qa/scout_rig_preview.tscn
godot --headless --path . --script res://tests/unit/scout_rig_test.gd
```

The 19 independent Scout Sniper v0.2.0 PNGs use the W06 pivots, structural parents, draw order and 0.25 logical units per PNG pixel. `Facing` mirrors the complete puppet around the feet. The authored Scout faces right. The lock switch demonstrates the placement contract for future melee rigs. The preview shows the Scout on an 80-unit raised tile with a fixed underfoot HP reference.

Idle loops. Deploy, Attack, Skill and Hit return to Idle, while Retreat and Defeat hold their final pose. Scout has stationary battle placement, so this pilot has no Move clip. The animation poses use small body and head motions to preserve hand contact with the tool. The AnimationPlayer advances manually from the shared CombatClock, so visual timing follows pause and speed.

## Reuse for the rest of the roster

1. Prepare the original cutouts and a W06-compatible manifest for the canonical Ranger or enemy. Validate transparent padding, paired joint fills, ground anchor and declared draw order.
2. Generate an editable scene from the manifest. Keep a unique destination per unit. The Scout command below reproduces the existing scene.

   ```sh
   python tools/build_cutout_scene.py assets/source-art/rangers/scout_sniper/manifest.json scenes/units/scout_rig.tscn
   ```

3. Give each unit a scene-specific state driver using the generator's `--script` option. Bind tracks to that unit's authored bones, reuse the manual CombatClock step and mirror at the facing root. Add Move for units that move. Keep fixed melee facing in placement and preserve the underfoot anchor.
4. Compare neutral registration and extremes at battle scale in both directions. Check attached props, visible seams, silhouette, reserves and HP overlay. Review any new cutouts or poses on a physical phone before standardizing the atlas or starting mass production.

## Evidence and remaining device checks

Godot imported the kit, ran the standalone preview and passed 14 rig checks plus 144 existing project checks. Linux/X11 rendered a 1280×720 preview and sampled poses from all seven clips and mirrored Idle. The sampled render showed no visible detached parts. Phone-scale motion, touch targets and GPU behavior remain unverified. C05 gameplay uses its existing presentation.

The standalone ARM64 APK uses the separate development package `com.shahrewan.kenyalangrangers.rigpreview`. It passed signature, alignment, archive and 19-texture checks. The regular Android Debug preset and main scene still run C05. See the [phone procedure](../../export/README.md#c07-scout-rig-phone-review).
