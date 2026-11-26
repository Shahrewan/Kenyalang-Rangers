# AGENTS.md — Kenyalang Rangers Godot repository

## Mission
Build the complete Kenyalang Rangers single-player, offline, Android-landscape game in Godot 4 with GDScript. Work incrementally through the approved milestone prompts and keep the project launchable after every change.

## Stable Android baseline
Preserving the currently stable Android build is the first priority for every milestone. Keep the last known-good signed APK available and check candidates against it for startup, touch, lifecycle, gameplay and save continuity where relevant. Keep the existing package and signing identity for compatible updates. Record host, exported-resource and actual handset evidence separately. A candidate with a demonstrated regression stays out of the stable build until the affected behavior passes again.

## Sources and precedence
1. User-approved explicit decisions recorded in `docs/canon/DECISION_LOG.md`.
2. Approved canonical rules in `docs/canon/GAME_RULES.md` and associated data contracts.
3. `docs/reference/SimSimi.pdf` GDD v1.0, pp. 2–33 (source of gameplay rules).
4. `docs/reference/Kenyalang_Rangers_Tileset_UI_Storyboard.pdf`, pp. 1–127 (source of visual and UI guidance; explicitly says GDD is rule authority).
5. Earlier screenshots/ideas are **style references only** unless promoted by a documented user decision.

If a cited or referenced file is absent, say so and use placeholders. Do not fabricate asset files, missing scripts, factual question banks, or level parameters; put unresolved points in the decision log. Do not silently change GDD mechanics.

## Non-negotiable game rules
- Android phone, landscape, touchscreen-first, single player, offline, local saves; never require an online account, networking, ads, gacha, telemetry, or multiplayer.
- Chapter 1 has 5 missions all using identical T01 battle geometry; Chapter 2 has 10 missions arranged as 2 each across Gunung Mulu, Batang Ai, Tanjung Datu, Imbak Canyon and Sepilok-Kabili; total 15.
- 12 named Rangers (3 each Offense/Defense/Support/Specialist), 13 Facilities including Logistics Post, 15 normal enemy types E01–E15, three bosses. Use the GDD's names/abilities, not older or placeholder rosters.
- Operational Integrity starts at 100. Story perfect clear = zero escaped combat enemies. A scripted cinematic messenger is not a combat escape. Rainforest Chaos rewards require every configured enemy defeated and positive Integrity.
- Logistic Tokens are transient battle deployment currency. Funds are the **only persistent spendable currency**. No leaves, coins, Reputation, Upgrade Points, or Room Energy. No Defense/armor statistic. Named reductions are explicit effects only.
- Only tagged Siege damage can harm Facilities, including in-progress construction. Standard melee/ranged attacks cannot damage Facilities.
- Normal operation starts at zero Logistic Tokens. If the optional Logistics Post is equipped, its first normal deployment is free, instant and has no first cooldown. Later Posts cost more and have normal construction/cooldown. The fixed-stockpile debuff D05 disallows all Posts and starts the battle at 120 Tokens.
- Most Facilities require two horizontally adjacent elevated cells. Sentry Tower uses one elevated cell and reserves the cell immediately above. Some ground Rangers occupy two tiles. Melee Rangers face left/right at deployment; facing cannot change. Aerial cannot be blocked by ground Rangers.
- One shared combat clock controls pause, dialogue, speed, wave timers, cooldowns, status effects, construction and Heat.
- Headquarters has 11 rooms Lv.1–5 and Ranger/Facility levels 1–100. Each deployable's baseline cumulative upgrade cost from Lv1 to Lv100 is exactly 1,000,000 Funds. R&D has 15 distinct buffs, with no duplicate selections or level-scaled potency.
- Rainforest Chaos has up to 5 wave slots, hard limit 50 enemies **per populated wave** (across types), no rest for empty slots, additive Medal Score, and piecewise linear Funds payout with threshold jumps at 1000, 2000, 3000. Filled loadout slots deduct 100 points each. Trophy appearance stops changing at 3000.
- Outreach: up to five four-option questions every 20 hours from a 20-question bank, grading Best/Acceptable/Poor/Harmful. Records: four chapters, 15 seconds per quiz question, one-time first-correct Funds rewards and named Ranger enhancements. Restoration: up to six plots, four species, three visible growth stages, paused progress when watering is missed, offline local timestamps.
- On-field sprites are flat, mouthless, earthy chibi cutout characters with high contrast at actual phone size. Portrait rigs may be more detailed. On T01 the escape trail runs into dense woods at the east map edge. HUD must not block the field.
- The 127-page PDF is a design reference, NOT a ready-made sliceable atlas or functioning UI. Additional source files described inside it were not in the provided ZIP.

## Coding practice
- Pin exact stable Godot 4 editor/export-template version before implementing features. Prefer Compatibility renderer and GDScript unless documented changes are approved.
- Use scenes and typed resource/data contracts; never hardcode 15 missions or 25 deployables into one enormous battle script. Prefer clear object responsibilities and testable pure helper functions.
- Keep RNG seeded and stage test fixtures deterministic where possible; simulate battle time with one controlled clock.
- Separate persistent save schema from runtime battle state; version saves, maintain a last-known-good backup, avoid partially written data.
- Keep all art path references resilient to absent production assets by using conspicuous, clearly labeled placeholder art.
- Changes must not remove working features, damage unrelated resources, silently rename IDs, or broaden scope without permission.
- Before large refactors, write an implementation plan and request a review checkpoint. Avoid parallel edits to the same Godot scene/resource.

## Testing and delivery on every task
1. State which files were changed and which systems are affected.
2. Run an editor/headless parsing smoke test with the pinned Godot executable when available; use automated tests for pure logic and report test commands/results.
3. State exactly which tests were actually executed; never claim Android FPS/performance without running on a real device.
4. Note unresolved choices and all known regressions.
5. Update `docs/production/PROGRESS_TRACKER.md`, `docs/production/HANDOFF_LOG.md` (if present) and relevant decision records.
6. Provide a short on-device manual test protocol when an Android-facing behavior changes.
7. Keep version control commits scoped to a single coherent task.

## Do not assume completion
A feature is complete only when its data, gameplay effect, UI, failure states, pause/save behavior and tests are implemented and verified. A static storyboard recreation does not count as a functioning screen.
