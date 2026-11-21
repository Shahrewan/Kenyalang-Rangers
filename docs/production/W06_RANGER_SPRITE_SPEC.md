# W06 Ranger sprite production specification

**Pilot v0.2.0 · 21 November 2026**

W06 covers art specifications for the 12 canonical Rangers and one editable Scout Sniper kit. The Scout Sniper is the C1-01 elevated ranged pilot for the C07 cutout rig. The redrawn pilot follows the upper-left human Ranger in the supplied lineup `b69016e9-403d-410a-bce7-d72884d602d6.png`. The 11 other roster rows translate the lineup's drawing style to their canonical equipment. Scale and the separate dialogue portrait family follow GDD pp. 17, 29–30 and UI storyboard pp. 2–3, 11 and 22 (S10). [Ranger catalog](../canon/SYSTEMS_INDEX.md#rangers) · [Art and UI spec](../canon/ART_AND_UI_SPEC.md#visual-language-and-screen-sizing) · [D-012 and D-014](../canon/DECISION_LOG.md#approved-decisions)

## On-field style and neutral poses

- **Follow the lineup proportions.** Head and headgear occupy about 55–60% of standing height. Use a long tapered brim, clear blocks of hair around the face, a rounded-square peach face and two short vertical eyes with rounded ends. Keep the face mouthless with a small warm cheek tint. Boots are squat and slightly splayed. Hands read as simple rounded shapes.
- **Match the ink and cloth.** Use warm near-black `#2B2622`, round stroke ends and joins, and a broad 2.2–2.4-unit outer stroke at the Scout's scale. Taper the visual weight with thinner seams. Build outfits from olive, oat, sand and bark brown. Use one large shade or a low-contrast tone change across the brim, hair and cloth, and reserve cream for insignia, cuffs and gear accents. Use large panel and camouflage shapes with readable edges.
- **Read equipment by shape.** Give each Ranger one defining silhouette and at most one support prop. Show the tool as a few broad silhouettes and keep its accent localized. Separate jacket, gear and ground in value. Show outline continuity and gear at native scale on Olive elevation and Sand ground.
- **Compose at phone size.** Use the 1280 × 720 storyboard reference and the 80-unit displayed tile. Visible standing height is 62–78 logical units, excluding the HP bar and tile. Use the ground anchor for visual registration so the HP bar can sit below the character. Keep separate airborne effects and weapon flashes out of the cutout alpha.
- **Start facing screen-right.** Use a relaxed 3/4 field stance, both boots with a clear sole line, and elbows slightly flexed so limbs separate when animated. Test ranged artwork mirrored about the facing root. For melee, use the selected left/right deployment direction and hold it for the deployment. The project already defines each unit's footprint and facing behavior. The art adapts to it, including the two-cell ground footprints for Barricade Ops and Strike Team.
- **Keep portraits separate.** Dialogue portraits may have facial detail and full expressions. They use their own source, scale, anchors and expression layers. The on-field kit has its own proportions and simpler shapes.

The Scout palette uses olive `#8E895E`, olive shade `#6F6C4A`, chestnut `#5B4941`, cream `#F0DEC2`, sand `#B5A17B` and warm peach `#F8C9A6`. Keep the line color shared across the roster. The habitat and interface palette comes from UI storyboard p. 3. Battle style and readability follow GDD pp. 17, 29–30 and UI pp. 2–3, 11.

## Twelve Ranger art briefs

Height and hex accents are W06 visual targets within the source range. Footprints, legal tiles and role behavior come from the canonical catalog. An accent appears on one prominent band, tool head or panel. The pose and silhouette keep the role readable when the accent is hard to distinguish.

| Ranger and fixed ID | Height | Distinguishing silhouette and neutral hold | Accent | Facing and separate attachments |
|---|---:|---|---|---|
| Scout Sniper `ranger.scout_sniper` | 72 | Broad downturned olive brim, cream bird marks, thick bangs, low tufted ponytail and patterned shoulder mantle above a tan roll. Hold the scoped tranquilizer diagonally down across the chest. | Oat cream `#F0DEC2` | Elevated ranged mirror. Separate the hat, ponytail, mantle, utility roll, tool and both hands. |
| Crowd Controller `ranger.crowd_controller` | 74 | Blocky padded ear covers and a broad forearm EMP projector across the jacket. One rounded emitter collar outlines its face. | Gray olive `#888F75` | Elevated ranged mirror. Separate the projector so a later pulse effect can align with its emitting face. |
| Guard Veteran `ranger.guard_veteran` | 76 | Weathered olive brim, square shoulder flap and long tapered stun prod. Hold the tool forward and low for a clear leading edge. | Ochre `#AE8A58` | Ground melee lock. Keep the prod on the grip part and show left/right at placement. |
| Patrolman `ranger.patrolman` | 68 | Rounded short brim, narrow curved shield and short baton. Keep the shield close to the olive jacket with the baton down on the open side. | Sand `#B5A17B` | Ground melee lock. The movable shield has a narrower outline than Barricade Ops. |
| Barricade Ops `ranger.barricade_ops` | 78 | Oversized shoulder pads, broad rectangular shield with rounded corners and a planted short stance. Keep the shield nearly upright. | Clay `#A47056` | Two-cell ground melee lock. Separate shield and braced hands. Align to the stage anchor and placement footprint. |
| K9 Ranger `ranger.k9_ranger` | 70 | Olive cap with amber goggles on the brim and a compact tranquilizer tool. Give the dog pointed ears, a broad dark muzzle and a simple olive harness. | Warm khaki `#B4A36B` | Ground ranged mirror. Give the dog a separate anchor and silhouette with neutral, move and howl poses. |
| Combat Medic `ranger.combat_medic` | 66 | Short cream field cap and broad rounded treatment satchel held forward. Place a single large cream flap on the olive kit. | Linen `#DFD0AC` | Elevated support mirror. Separate the satchel/lid as needed for treatment and keep the attachment clear of the face. |
| Kenyalang Seer `ranger.kenyalang_seer` | 74 | Angled olive brim with a cream panel and a wide open boomerang with a clear central notch. Hold it away from the shoulder. | Warm gold `#D2AD64` | Elevated ranged mirror. Separate the boomerang and provide a grip position for the later throw pose. |
| Outpost Mechanic `ranger.outpost_mechanic` | 70 | Low rounded cap, thick forked repair tool and squat toolbox with a broad clasp. Tool forward and box low at the rear hip. | Dull brass `#AF8B59` | Elevated support mirror. Separate tool and box, keeping the repair tip readable during use. |
| Woods Tracker `ranger.woods_tracker` | 70 | Wide sand brim, rolled net pouch and a short net rim with one open interior. Hold the rim low with a compact forward crouch. | Moss `#9C9D6E` | Ground melee lock. Separate the net/rim from hands so deploy and retreat poses can release it. |
| Saboteurist `ranger.saboteurist` | 70 | Close-fitting hood, broad wrist panel and a short interference device with a blunt fork. Hold the device clear of the face and chest. | Warm slate `#82887D` | Supply both visual orientations by root mirroring. Use authored ground placement facing and ability direction for the runtime pose. |
| Strike Team `ranger.strike_team` | 76 | Forward hat tilt, stacked shoulder flap and compact baton. Keep a clear split between the gripping hand and forward knee. | Muted rust `#AB775E` | Two-cell ground melee lock. Separate baton's grip and torso layers. Use the footprint for the span while retaining one readable on-field figure. |

The supplied lineup governs the art style. Use the game's Ranger catalog for the roster, equipment functions and approved companions. The K9 companion only howls to reveal and slow. The other animals in the reference are study material. Role and gear references are GDD pp. 9–11 §§ H.1–1a, p. 17 § J.3 and UI p. 11.

## Cutout and export contract

| Field | W06 pilot contract |
|---|---|
| Source | A layered vector master. Use one named editable layer for each rigid cutout. Draw the entire head/hair, garment pieces and hidden tapered continuations at joints. Keep independent props as actual shapes and layers. |
| Authoring canvas | 96 × 96 logical units. Origin top-left, +x right and +y down. Ground anchor `[48, 84]`, normalized to `[0.5, 0.875]`. Place standing soles on this baseline and record small silhouette overhangs as bounds. |
| Raster density | 4 PNG px per logical unit. The normalized full raster canvas is 384 × 384 px. Export tight independent RGBA crops with at least 4 px of fully transparent padding on each edge. Record each crop's absolute top-left and size in `canvas_rect_px`. |
| Pivot per part | Record canvas coordinates, normalized canvas coordinates and pivot pixels relative to the crop top-left. Keep joint centers inside opaque fill in both the relevant child and its parent. Use the name of the structural parent and a separate draw order. |
| Import scale | Use 0.25 logical units per PNG pixel. Set art to linear filtered, lossless alpha for the pilot. Check at 1:1 and actual viewport scale before tuning resolution or packaging an atlas for later Rangers. |
| Stacking | The manifest orders the utility roll, ponytail and far limbs behind the jacket. The near mantle covers its shoulder and upper arm. The tool sits under both palms. The face and bangs overlap the collar, and the hat brim crosses the hair. Apply draw order independently of the skeleton parenting order. |
| Occluded areas | Aim for at least 2 logical units of overlap under the adjoining neutral part. Continue the dark hair beneath the brim and ponytail tie. Fill shoulders and elbows under the mantle, cuffs under the hands, and leg joints under the jacket and boots. Rotate each join in an edit preview to check for gaps and doubled outlines. |
| Mirroring | Mirror the visual facing root about the ground anchor. The puppet hierarchy, held props and drawn order stay together. Recheck off-center equipment, bound edges and both hand contacts at facing changes. |
| Naming and versions | Use canonical `ranger.<snake_case>` IDs for the manifest and matching directory names. Part IDs and PNG stems use `snake_case`. Use `_near` and `_far` for the sides of the authored view. Keep stable IDs across visual edits. Increment `asset_version` on source and export revisions and `schema_version` only for breaking manifest shape changes. Re-export affected crops and update hashes, bounds and pivots together. |

The manifest's crop positions reconstruct the common canvas. At neutral, place each part's joint at `pivot_canvas_units - ground_anchor_units` from the art root, or at the difference from its parent's joint when parenting. Its crop top-left relative to the joint is `-pivot_local_px × 0.25`. Confirm this placement at neutral before posing, then rotate about the joints. For connected poses, check that the support hand follows the scoped tool without opening the shoulder, elbow or wrist overlaps. Geometry registrations are visual references for C07. See GDD pp. 29–30 and D-012.

### Roster acceptance at 62–78 units

1. Inspect the neutral and mirrored drawings on the 80-unit elevated and ground tile colors. Identify each Ranger from equipment shape at native visual size.
2. Confirm the pivot sits within both joint fills. Check rest pose and the most extreme pose planned for the state. Grip attachments remain coherent due to separate parts.
3. Reassemble the dimensions and order in the manifest. Approve cutouts that retain part padding, show no stray background pixels, and keep their ground registration.
4. Check Idle, Deploy, Attack/Heal/Repair, Skill, Hit and Retreat/Defeat, plus Move where used. The source's approximate 60 fps sampling/rendering is a target for the real rig and phone test at C07.
5. Compare two-cell and one-cell placements against their legal footprint markers. Run the C07 physical-phone check before standardizing the rest of the kits or runtime atlas.

## Scout Sniper pilot handoff

| Deliverable | File |
|---|---|
| Editable art | [scout_sniper.svg](../../assets/source-art/rangers/scout_sniper/scout_sniper.svg), with 19 independently editable vector layers |
| Independent alpha cutouts | [Scout Sniper PNG directory](../../assets/imported/rangers/scout_sniper/) |
| Rig and import metadata | [manifest.json](../../assets/source-art/rangers/scout_sniper/manifest.json), including layer IDs, hierarchy, order, canvas/crop mappings, pivots and hashes |
| Reference sheet | [scout_sniper_reference.png](../../assets/source-art/rangers/scout_sniper/scout_sniper_reference.png), assembled from the editable geometry, with exploded parts, pivot positions and 1:1 comparison |
| Provenance record | [asset_register.csv](../../assets/source-art/rangers/scout_sniper/asset_register.csv) |

The isolated Scout illustration is a visual study of the supplied lineup. The production pilot redraws it in independent vector shapes, with full hidden joint areas. Each transparent PNG comes from its matching vector layer. The sheet assembles and labels the actual cutouts. Godot imports the cropped PNGs, while the adjacent source directory holds the master and pivot data.

To prepare revisions, open the master in Inkscape and edit individual named layers. Re-export the affected layer against the padded crop at the manifest density. Keep the transparent padding, top-left offset and local/canvas pivot values recorded for each crop. Refresh the hashes and reference sheet when the silhouette or poses change. Keep the Scout pilot's proportion, outline and anchor aligned before producing the other Rangers.

## Verification and next handoff

The neutral Scout Sniper measured 72.157 logical units tall. All 19 PNGs matched their manifest dimensions, crop positions, padding and hashes. Reassembly matched the layered master's bounds and visible colors at 4× export size. The 18 parent-child pivots sat in opaque fill on both parts. The neutral pose and two static joint previews stayed connected.

The pinned Godot 4.7.2 editor imported all 19 textures in an isolated checkout. Headless resource loads confirmed their recorded dimensions and transparency. Project startup and 144 existing checks passed.

C07 builds the rig from the authored parent chains and neutral registration. On an Android landscape phone, review the rig on a legal C1-01 elevated cell. Compare its cap, tool and HP bar against the background at the usual camera scale. Flip the facing root without shifting the ground anchor. Watch the shoulders, elbows, knees and hands through each state at 1× and 2×, then pause and resume to check clock behavior. The C05 physical-phone playtest remains open in the [progress tracker](PROGRESS_TRACKER.md).
