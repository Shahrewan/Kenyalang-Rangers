# C20 Habitat Restoration verification

23 November 2026 · Godot `4.7.2.stable.official.ed1daf0bf` · Compatibility

| Area | Verified result |
|---|---|
| Entrances and capacity | Main Menu Reforestation and the Ecology room open `HeadquartersGarden`. An unbuilt room explains the build requirement. Upgrades open two to six plots. Lv.5 requires both 60% restoration and 900,000 Funds. |
| Growth and watering | Each of the four tree species has Seed, Sapling and Mature art. Off-screen local time stops at the halfway checkpoint until watered. One watering starts a full second half. Early and duplicate watering fail. |
| Offline persistence | Cold reopen restores both phases and retained scenery. Observed checkpoints survive a backward clock jump. A timestamp-only v2 fixture continues to grow. Invalid slots, occupied plots and invalid species or times cannot plant. |
| Collection | Only the active mature cycle settles. The transaction keeps the tree in scenery, frees the slot for replanting, caps Funds and records discovery IDs. Stale callbacks and save retries cannot pay twice. A failed write leaves the old plot and wallet usable on reload. |
| Milestones | The first mature collection of each distinct species adds 20%. The fourth installs the nest box and triggers the visitor. A further mature collection reaches 100%. The five milestone payouts total 2,550,000 Funds. Repeat cycles continue to pay their base reward. |
| Knowledge | Guide, first species and nest-box discoveries persist by stable fact ID. The Garden and Records displayed synthetic approved-format text and citations in QA. The player APK keeps the W18 approval gate closed. |
| Linux and input | The launcher test sent synthetic screen touch to a locked plot. Native pointer input at 960×540 opened the seed picker, planted the Fig, watered after a simulated three-day delay, collected 53,000 Funds and reopened the same garden through Ecology. |
| Android debug APK | Signed ARM64 package passed APK v2/v3 signature verification, 16 KiB ZIP alignment and archive integrity. The extracted package booted on Linux, loaded all 19 W19b textures at manifest dimensions, and passed the 121 C20 checks with the UI fixture supplied outside the APK. |
| Physical Android | The cloud environment exposes no USB phone. Installation, touch size and cutout fit are still open. |

Pinned editor import, headless startup and **1,801 checks across 24 runners** passed. C20 adds 95 rules checks and 26 live launcher checks. [Test commands](../../tests/README.md) · [Physical Android procedure](../../export/README.md#c20-restoration-phone-check)

The game uses local device time for the simulation. Clock changes can advance or delay future growth. The garden saves elapsed observations when the view opens or closes, when it backgrounds and when growth crosses a stage boundary. An abrupt stop can restore the previous observation. GDD cycle and milestone values are provisional, and the separate first-species Funds award remains unset. [Decision log](../canon/DECISION_LOG.md#c20-habitat-restoration--2026-11-23)
