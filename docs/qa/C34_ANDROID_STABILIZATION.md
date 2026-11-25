# C34 Android stabilization and mobile controls

The work starts from `0546dbd` on `main`, including PR #46. The player build uses Godot `4.7.2.stable.official.ed1daf0bf`, the matching Android export template and the Compatibility renderer. The fixes run through the existing combat clock, deployment state, reward settlement and local saves.

## Deployment crash investigation

The owner reported that the APK installed and launched on a physical Android phone, then crashed while dragging a deployable. The handset and the crash buffer were unavailable to this session. The specific build digest, device model, Android version, chip, RAM, cutout, deployable, stage and point in the gesture where the crash occurred remain unknown. **The reported physical crash remains open.**

The pinned Godot Android handler delivers cancellation for each tracked touch ID. Godot then delivers a generated mouse event **before** its native touch or drag. On desktop Compatibility rendering, a C33 production run at 1200×540 using that engine path observed eight native plus eight emulated button events and four native plus four emulated motion events. Eight checks passed, including the real Starter Post ghost, invalid drop and cancellation. The owner’s native crash did not reproduce there. [Pinned Android handler](https://github.com/godotengine/godot/blob/ed1daf0bf/platform/android/android_input_handler.cpp#L145-L225) · [Pinned emulation order](https://github.com/godotengine/godot/blob/ed1daf0bf/core/input/input.cpp#L896-L969)

The old deployment handler excluded emulated mouse events from its own gesture logic, but left those events available to the tray ScrollContainer and other GUI controls. A physical touch could therefore drive native battlefield logic and a GUI pointer stream together. Secondary touches were allowed through while a drag owned the board, and an interrupted gesture could leave Release feedback after the preview had disappeared. The old board conversion inverted the canvas and cast to integers before validating the point. These are confirmed source-level failure paths. Attributing the reported native crash to any one path requires the handset trace.

The new controller owns the touch and its emulated pair until release, consumes competing pointers, and leaves ordinary UI taps to Godot. It clears transient state on canceled touches, focus loss, application pause, combat pause, dialogue, restart and viewport resize. Grid conversion rejects non-finite points, singular transforms and off-board points before integer conversion. The original W29 Facility ghost, legal-cell previews and exact placement policy remain active. [Reproduction and handset trace steps](../../export/README.md#capture-the-reported-drag-failure)

### Explicit facing

A legal directional drop opens a footer outside the board with the unit and cost, **Face left**, **Face right**, **Deploy** and **Cancel**. Neither side starts selected. Choosing a side mirrors the approved ghost, updates a high-contrast arrow and highlights the exact attack tiles. The combat clock continues as usual. **Deploy** calls the same validator that owns footprint, occupancy, Tokens, cooldown and combat state. Pending placement owns no game cells and spends nothing. The last failure stays in the footer when the panel closes.

Patrolman, Guard Veteran, Barricade Ops, Woods Tracker, Saboteurist and Strike Team use this flow. For two-cell Rangers, the same anchor and both occupied cells remain, and rightward coverage starts beyond the second cell. K9 is the ground-ranged exception. The five elevated Rangers and all thirteen Facilities deploy on a legal release. Sentry Tower still reserves the cell above and accepts eligible elevated Rangers. Existing skill confirm, building cancellation, retreat, compact orbs, and 1×/2× combat time use their original rules.

## Issue register

| ID | Severity and system | Reproduction and cause | Implemented fix | Verification and acceptance |
| --- | --- | --- | --- | --- |
| C34-01 | P0 · physical Android drag crash | Owner’s installed game launched and crashed on drag. Handset build and faulting stack remain unknown. | Hardened the input, validation and preview paths below. | **Open on physical hardware.** Host, APK payload and emulator results are listed separately. |
| C34-02 | P1 · battle gesture ownership | Press or scroll the tray, cross the board, add a second finger or cancel the touch. Godot supplies a GUI mouse stream before native touch. | A single controller owns field/tray gestures and paired emulated events. It rejects unrelated contacts and releases ownership on interruption. | C34 native-event runner, dropped-invalid and single-commit checks. Physical repeat test pending. |
| C34-03 | P1 · facing and transactions | A choice formerly depended on the half of the tile under the finger. The final drop could spend before the selected direction was visually apparent. | Explicit directional choices and confirmation, with real field ghost, coverage preview and live revalidation. | Human-facing footer at six host sizes. All 25 deployable IDs exercised. Injected affordability/occupancy changes retain costs and the other occupant. |
| C34-04 | P1 · lifecycle and audio | Focus loss followed by Android pause could leave an active gesture. On returning, audio could briefly use the previous held state. | One suspension path clears input and pauses a running battle. Audio hold is recomputed immediately from battle or quiz state. Back respects modal/foreground state. | Lifecycle runner and synthetic pause/return. Physical notification, lock and process-death checks pending. |
| C34-05 | P1/P2 · animation and idle rendering | Paused physics redrew the board continuously, and repeated actor spawns compiled the same relative animation tracks. | Suppressed frozen-state refreshes and drag-time tray rebuilds. Share weakly cached animation libraries with independent playheads. Deployment badges load through one catalog instance. | Paired host measurements below. Physical frame times, battery and GPU/RAM measurements pending. |
| C34-06 | P2 · home and Story | Mode images previously consumed space outside the action. Distant Story medallions and wide planning panels left narrower tap targets. | Entire home cards take taps. Story adds a list beside the illustrated map, uses expandable rows and gives the planning and result actions larger fixed footer space. | Native before/after and player navigation checks. |
| C34-07 | P2 · Headquarters and progression | Illustrated rooms worked as navigation, while room action, roster and paid upgrade controls occupied small parts of otherwise open panes. | Keep illustrated room registration, enlarge room/upgrade controls, make roster cards act as one target, separate safe cancellation from payment. | Native comparisons and returning profile checks for legal room, Ranger and Facility purchases. |
| C34-08 | P2 · Rainforest Chaos | Wasted route-area space, small wave/quantity targets and modifier rows with intermittent exclusions. | Full-width route and quantity actions, responsive map and trophy workspace, fuller modifier rows and reachable Start, Apply and result actions. | Real scored clear and three outcome paths. Five wave slots, 50-per-wave cap and C32-E effective payout retain their formulas. |
| C34-09 | P2 · Outreach and Records | Long prompts left little vertical area for answers, and progression buttons left the question panel on scroll. | Context and answers use separate responsive panes, tall distinct rows and fixed continuation actions. | Real Outreach replies and one-time receipts, Records article and timed quiz. |
| C34-10 | P2 · Habitat Restoration | Illustration and detached plot controls shared small activation areas. Species choices clipped at high text scale. | Plot hitboxes align to the illustration. Species choices use a grid and fixed planting, watering and collecting actions. | Plant, water, collect and reload in the existing deterministic clock fixture. |
| C34-11 | P2 · settings, pause and dialogue | Long mission labels clipped. The old pause panel and Settings had compact controls amid large unused areas. | Inset pause panel uses the height for scrollable Intel and broad actions. Dialogue has larger Continue and Skip. Settings divides audio/text from local progress and focuses Cancel on reset. | Native comparisons at 100%, 115% and 130%. Destructive action confirmation tested only with disposable profiles. |
| C34-12 | P3 · Android template warning | Android resource dump reports missing optional themed-icon XML in C33 and C34. | Regular W29 icon remains in the candidate under the existing package and signer. | Recorded platform-template issue. The themed-icon path needs physical launcher verification. |
| C34-13 | P1 · package resource teardown | Package regression completed its visual checks but reported leaked engine objects from a static animation cache. | Store weak cache entries on the root window, which releases them at tree teardown. | Targeted visual and independent-playback tests pass without exit diagnostics. |

## Screen-by-screen review

For host tests a common minimum is 52 logical units. An example 960×540 window at 0.75 scale turns a 64-unit button into 48 raster pixels. On Android the application uses viewport-to-screen scaling and platform density to request approximately 48 dp. The cutout transform is also based on the viewport. Host pixel dimensions and synthetic notch rectangles provide layout evidence. Actual physical system bars, gesture strips, reported DPI and cutout clearance require the real handset.

| Production screen | Touch and layout review |
| --- | --- |
| Leader naming | Centered input and raised confirmation targets. Keyboard submit and explicit confirmation remain usable. |
| Main Menu | Art passes input through to each large mode card, with secondary Settings, guide and Restoration actions separated. |
| Story selection | Illustrated medallions and full-width operations list share the current stage gates. List gives the lock or replay reason without hover. |
| Operation planning | Loadout swipes and selection keep the wave preview reachable. Controls use explicit states and the Start footer stays accessible while scrolling. |
| Battle deployment and skills | The tray retains a dedicated swipe area. The facing panel sits outside tactical tiles. Hold-to-Retreat and Cancel build are larger targets. Skill timeout and target confirmation use the underlying state. |
| Dialogue, pause, abandon, results | Continue and Skip occupy a lower action row. Pause scrolls Intel above fixed controls. Abandon has a separate confirmation. Results provide clear exit and Review actions. |
| HQ building and all eleven departments | Existing approved room art covers Control, Human Resources, Finance, Mechanical, Ecology, Outreach, Records, and Ecology, Combat, Guard and Crisis research rooms. Registered room rectangles remain the navigation. Room transactions show the exact quote, gate and upgrade action. |
| Ranger and Facility roster and upgrade pages | Full-card touch targets, visible owned/locked and level text, broad level-step and milestone controls, separate purchase confirmation. |
| Chaos routes, waves, loadout, modifiers, score, rewards | Route selection and map fit share space, wave tabs and enemy quantities retain large targets, the modifier picker keeps eligibility visible, and score/receipt actions stay reachable as panels scroll. |
| PR Outreach | Layout separates question selection from grade choices. Fixed continuation and refresh use existing rotation and settlement. |
| Records archive, article, timed quiz, receipt | Independent scroll panes and reachable Back. Quiz answer rows use most of the width available to them. Timer and confirmation remain visible around long questions. |
| Habitat Restoration | Whole plots, seed grid and dedicated Plant/Water/Collect/Cancel row. Growth and the 60% Ecology gate still read the same persistent state. |
| Settings, battle Settings and reset | Large sliders and text choices, separate local progression and Developer section, Back preserves pause, explicit reset confirmation. |
| Field Guide, FAQ, citations and credits | Main index and article content remain scrollable and offline. Battle-control text describes the explicit facing flow. |
| Save recovery | Centered status and reachable Continue or Settings. Scoped recovery/replace tests use disposable saves. |

## Player journeys and evidence

| Journey | Verification tier |
| --- | --- |
| A · Name Leader, play First Contact and settle | Production UI with host input dispatched through Godot’s native event/emulation path. Free Starter Post, ranged Scout, canceled and confirmed Patrolman facing, suspension, authentic combat and cold-load receipt. |
| B · Build Mechanical and continue Story | Production UI purchase/navigation tests and the established actual-combat Campaign fixtures. |
| C · Upgrade, restart and deploy upgraded gear | Paid UI upgrades, stored levels and Android-package Story/Chaos growth tests. |
| D · Configure and complete Chaos | Actual capped T01 clear in the C33/C34 launcher suite, plus withdrawal, non-qualifying escape and fatal loss paths. |
| E · Outreach | Production UI answers, grade receipts and refresh-limit tests. |
| F · Records | Production UI archive and timed quiz, first-correct/perfect flags, save reload and no duplicate payout. |
| G · Habitat Restoration | Production UI seed, watering checkpoint, collection and cold reload using the existing programmable clock. |
| H · Settings, pause, put in background and return | Host lifecycle notification tests with armed/pending combat state and audio checks. Actual physical Android backgrounding and interruption remain pending. |

## Build and replay

```sh
python3 -B tools/run_regression.py --logs build/qa/c34/regression
godot --audio-driver Dummy --path . --script res://tests/unit/c34_deployment_touch_test.gd -- "$PWD/build/qa/c34/deployment/960x540-130" 960x540 130
./.android/godot-android --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c34-debug.apk
```

Use the existing debug signer for a returning installation. Record Android build and game logs before reproducing. The procedure uses `adb install -r` and preserves the profile. [Android diagnostic and performance procedure](../../export/README.md#c34-android-deployment-and-performance-checks)

## Captures and hit areas

| Area | Before | After |
| --- | --- | --- |
| Placement preview at 1200×540 | [Facility](c34/deployment/before/starter-ghost-before-release.png) · [Melee inferred from drop](c34/deployment/before/patrolman-ghost-and-coverage.png) | [Facility](c34/deployment/after/starter-post-preview.png) · [Explicit left](c34/deployment/after/face-left.png) · [Explicit right](c34/deployment/after/face-right.png) |
| Battle and outcomes | [C33 battle](c33/960x540-130/battle-t01.png) · [C33 pause](c33/960x540-130/chaos-pause.png) | [Pause](c34/deployment/after/pause-960x540.png) · [Dialogue](c34/deployment/after/briefing-960x540.png) · [Perfect-clear receipt](c34/deployment/after/result-960x540.png) · [1920×1080 facing](c34/deployment/after/facing-1920x1080.png) |
| Home and Story | [Home](c34/menus/before/main.png) · [Planning](c34/menus/before/story-planning.png) · [Results](c34/menus/before/results.png) | [Home](c34/menus/after/main.png) · [Planning](c34/menus/after/story-planning.png) · [Results](c34/menus/after/results.png) |
| Headquarters and purchased levels | [Rooms](c34/menus/before/headquarters.png) · [Rosters and upgrades](c34/menus/before/roster-upgrades.png) | [Rooms](c34/menus/after/headquarters.png) · [Rosters and upgrades](c34/menus/after/roster-upgrades.png) |

The menu regression taps the body of each large artwork card and all 11 illustrated room hitboxes. Story map targets are at least 84×84 logical units and avoid overlap. Mission list rows are at least 80 units tall. The planning Start button is 76 units tall and modifier action 68. HQ room targets are at least 84×72. Roster cards are at least 108 units tall and level and purchase actions at least 64. At 960×540 with 130% text, the two facing choices measure approximately 196×55 raster pixels each, Deploy 177×55 and Cancel 128×55. The same touch path bought Mechanical and both Lv.20 upgrades, reloaded their exact balance and placed the upgraded Post and Scout in C1-02.

The native deployment runner rendered First Contact at 960×540, 1280×720, 1920×1080, 1170×540 (19.5:9), 1200×540 (20:9) and 800×450, covering 100%, 115% and 130% text. It exercised coordinate conversion and touch at each size. The final battle receipt was a real perfect clear with 14 defeated, 0 escaped and 100 Integrity. It credited 15,000 Funds and cold-loaded a balance of 25,000.

## Host rendering and memory

Paired runs covered First Contact, a dense Chapter 2 wave, Imbak Canyon Heat, a boss encounter, Final Interception, dense Chaos and a fully developed HQ. The weak animation cache cut median setup for 50 identical rigs from 41.606 to 7.795 ms and added Godot static allocation from 7,480,796 to 4,867,476 bytes. Paused First Contact board redraws fell from 515 to zero in 240 sampled frames. Sixty-four menu-to-battle cycles per build returned to stable node/resource counts and within-build RSS values. Dense Chaos still drew a median of 1,132 calls with 50 resident rigs. Host frame times varied by workload and repeated run. [Full measurements and methodology](c34/performance/HOST_BENCHMARK.md)

## Activities, navigation and lifecycle workstreams

Baseline was `0546dbd` (after PR #46), rendered through Godot 4.7.2 Compatibility on Linux. These suites drive real Godot controls through synthetic pointer events or explicitly delivered lifecycle notifications. Pixel figures are measured on the 960×540 host capture at 130% text. App touch floors in Android derive from device density and the viewport scale. Physical target size, cutout, system-bar, screen-reader and finger acceptance remain pending.

| Screen or state | Before and after investigation | Host evidence | Before / after |
| --- | --- | --- | --- |
| Outreach prompt tabs | Tabs share the row, prompt and Manager portrait occupy the context panel, and answers have their own separated tall rows. Example tab 39×40 → 177×48 px. Best-answer receipt offers a distinct Next unanswered action. | Level 2 Best credits 60,000 exactly once. Refresh is disabled until 20 hours. Next moves to the next unanswered item, and a cold reload retains the completed response. | [Before](c34/activities/before/outreach.png) · [After](c34/activities/after/outreach.png) · [Receipt](c34/activities/after/outreach-receipt.png) |
| Outreach answer area | Example answer 924×39 → 556×74 px. The answer column remains separate from the question and has a height floor and wrapping with finger separation. | All four accessible answer names and visible hit rectangles checked. Correct grade and attached receipt displayed. | [After](c34/activities/after/outreach.png) |
| Records archive and articles | Larger chapter/article actions and two independently scrolling columns. Decorative cards and actionable archive rows pass drag events to the enclosing scroll. The post-drag tap still opens the exact article. | A synthetic touchscreen swipe beginning on Read article scrolls without opening it. Tap then opens the framed offline article. Back restores the archive. | [Before](c34/activities/before/records.png) · [After](c34/activities/after/records.png) · [Article](c34/activities/after/records-article.png) |
| Records timed quiz | The topic and chapter plate occupy the context pane, with a dedicated answer lane and persistent next action. Example answer 924×39 → 556×89 px. Pause 124×40 → 132×48 px. Next 924×40 → 924×48 px. | Scout chapter starts at 15 seconds. Synthetic pause and background preserve 13 seconds in the activity journey, and a separate save reload retains the exact tick in the lifecycle test. Ten correct answers each paid 30,000 and the first-perfect result credited 50,000. | [Before](c34/activities/before/records-question.png) · [After](c34/activities/after/records-question.png) |
| Restoration plots and primary actions | Illustrated plot hit area grew from the narrow footer label to the bed. Plot 2 measured 91×39 → 115×80 px. Water grew from 310×40 to 338×56 px. Sticky primary and Back-to-plot actions make the current task reachable beside the art. | A tap in the upper bed selects Plot 2 without crossing Plot 1. Seed is free, watering resumes the checkpoint, collection credits 53,000, and reload retains 20% restoration. | [Before](c34/activities/before/garden.png) · [After](c34/activities/after/garden.png) · [Water](c34/activities/after/garden-water.png) · [Receipt](c34/activities/after/garden-receipt.png) |
| Restoration seed picker | Four 2×2 cards and a persistent Cancel. Example Strangler Fig 321×68 → 266×94 px. During seed choice the board outlines the selected bed and leaves the art free of competing plot labels. | Cancel restores the plot targets with the empty plot intact. The lower seed card remains reachable at the tested widths. | [Before](c34/activities/before/garden-seeds.png) · [After](c34/activities/after/garden-seeds.png) |
| Leader naming | Wider centered form, visible field, soft-keyboard submit route and deeper action. Both input and Continue went from 323×41 to 419×51 px. | Host confirmation and early campaign journey use the original naming contract. Physical soft-keyboard insets remain pending. | [Before](c34/lifecycle/before/naming.png) · [After](c34/lifecycle/after/naming.png) |
| Settings and reset | Audio and text use one column while Help, Developer and Local progress use the other. Sliders are taller and have percent labels. Text-size example 294×41 → 146×50 px. Reset is separated in Local progress. Both confirmation buttons retain their size floor and Cancel gets initial focus. | Simulated Android Back cancels reset and retains the Leader. The saved text size persists after cold load. | [Before](c34/lifecycle/before/settings.png) · [After](c34/lifecycle/after/settings.png) · [Reset before](c34/lifecycle/before/reset.png) · [Reset after](c34/lifecycle/after/reset.png) |
| Save recovery | A focused card holds the explanation and recovery action. The exhausted-recovery Settings action measured 900×41 → 471×50 px. | A deliberately damaged copy of a disposable save reopens its valid backup. Continue restores the menu and saved text scaling. | [Before](c34/lifecycle/before/recovery.png) · [After](c34/lifecycle/after/recovery.png) |
| Suspended combat, quiz and Finance | Immediate audio hold reconciliation across out-of-order focus/resume notifications. Back is gated while suspended. Settings and help return to their original screens. | In synthetic lifecycle testing, 2× combat holds at tick 2, preserves active dialogue and resumes only after the explicit Resume control. Funds accrue only while active. Interrupted quiz ticks persist. | [Lifecycle test](../../tests/unit/c34_lifecycle_test.gd) |
| Field Guide, FAQ, references and credits | Full-width separated guide actions and a scrollable reading area. The deployment article gives explicit Face left / Face right and Deploy / Cancel instructions. | Guide opens from the real menu and Back returns to its origin. Credits and references retain the existing offline contents. | [Guide layout](../../scripts/ui/field_guide.gd) |
| Chaos route selection | Two-column route/overview layout keeps the W29 map and thresholds in the larger scrolling panel. Configure and Modifier trial expand along the footer. T02 target 335×48 px, Configure 578×54 px. | Touch chooses Imbak Canyon and shows Heat. Native route screenshot verifies both Mulu lanes and three trophy thresholds. | [Before](c34/chaos/before/route-t02.png) · [After](c34/chaos/after/route-t02.png) |
| Chaos waves and loadout | Wave tab 117×68 px, quantity slider 184×48 px, each plus/minus 51×49 px, Start challenge 339×54 px. Full-width editor tabs and independent loadout preserve space for the live score. | Increment/decrement affect the current wave only. Wave five preserves its own composition. Start remains inside the viewport while switching tabs. | [Waves before](c34/chaos/before/chaos-waves.png) · [Waves after](c34/chaos/after/chaos-waves.png) · [Loadout before](c34/chaos/before/chaos-loadout.png) · [Loadout after](c34/chaos/after/chaos-loadout.png) |
| Chaos and Story modifier catalog | Two columns on normal widths and one under simulated side insets. Controls use the whole description face and keep Apply visible. Typical D02 card 431×63 px, footer Apply 924×53 px. | Tapping the description toggles the exact ID. A second tap reverses it. A swipe beginning inside the card scrolls without toggling. Apply returns to the previously selected composer tab. | [Before](c34/chaos/before/modifiers-debuffs.png) · [After](c34/chaos/after/modifiers-debuffs.png) |
| Chaos results | Larger Back to routes and Review configuration strip. The existing settled reward controls the receipt. | Existing story/Chaos runtime suites cover 130 points and 2,600 credited Funds for the qualifying example, and 0 payout on a fatal escape. | [Victory before](c34/chaos/before/chaos-victory.png) · [Victory after](c34/chaos/after/chaos-victory.png) · [Defeat after](c34/chaos/after/chaos-defeat.png) |

### Reproducible host evidence

- `c34_activities_test` passed 87 headless assertions. Each native pass added 13 real rendered captures and passed 100 assertions at 960×540 / 130%, 1280×720 / 100%, 1404×648 / 115%, 1440×648 / 115% and 800×360 / 100%. The baseline native journey passed 77 compatible checks. Captures and logs are available under `build/qa/c34/activities` and `/tmp/kr-c34-evidence`.
- `c34_lifecycle_test` passed 37 checks. Settings, reset, naming and recovery captures were made across 960×540, 1280×720, 1560×720 and 1600×720 each at 100%, 115% and 130%.
- `c34_chaos_layout_test` passed 111 headless checks over 960×540, 1280×720, 1920×1080, 1170×540 and 1200×540. Additional native render passes verify the visual and touch layout at 960×540 and 1440×648 with 130% text. The tested side insets use synthetic layout margins rather than a physical cutout.
- `education_ui_test` passed 25 checks, `restoration_ui_test` passed 26, and `c31_c_education_test` passed 18. All use disposable profiles. The pure safe-area smoke test covers physical-pixel to logical margin transforms with simulated cutout rectangles.

## Android build and emulator evidence

The release candidate is `build/android/kenyalang-rangers-c34-debug.apk` with SHA-256 `e2c0b1406d0a1017de7f4a3bc4b6bbff6f7e651958e35bc7781585d51437d041`. Package `com.shahrewan.kenyalangrangers.dev` remains ARM64, landscape and Compatibility. The editor and Android templates match at 4.7.2 stable. Tooling is Temurin JDK 17.0.21.1, platform 36, Build-Tools 36.1.0 and Platform-Tools/ADB 37.0.3. The APK passes signature schemes v2/v3 and 16 KiB alignment. API 24 is the minimum and API 36 is the target. The existing debug certificate SHA-256 remains `0b79cac72bf38357eb4aa0dcb68e0b34bff7d2a9503a32e0928186f00b1bf052`.

- **Emulator install.** The exact signed release installed with `adb install --no-incremental -r` on the same disposable API 30 / Android 11 x86_64 emulator. It used 720×1600 at 300 dpi, about 2.9 GiB guest RAM, SwiftShader OpenGL ES 3.0 and QEMU software CPU emulation. The AVD was offline for the attempts, and PackageManager confirmed that it retained its data. [Exact release installation log](c34/android/arm64-release-install.txt)
- **Emulator startup.** C33 and earlier C34 ARM64 candidates failed before a Godot frame after initializing NDK ARM translation 0.2.2. Android terminated the process at the attach timeout. The exact release kept that same native library. Its launch command timed out after 19,283 ms, and extended observation reached native initialization and the Godot engine banner with a blank surface. No playable screen was observed. A separately exported x86_64 diagnostic reached Godot’s Compatibility startup. The guest System UI became unresponsive and SwiftShader reported fragment uniform limits, so the emulator provided no successful drag journey or representative frame-time data. Production packaging remains ARM64. [Earlier ARM64 launch log](c34/android/arm64-emulator-timeout.txt) · [Exact release launch log](c34/android/arm64-release-launch.txt) · [Diagnostic renderer log](c34/android/x86-emulator-renderer.txt) · [System UI screenshot](c34/android/x86-system-ui-anr.png)
- **Physical Android.** The connected-device list contained no handset. The exact reported crash, physical finger interaction, Android Back gesture edges, soft-keyboard insets, cutout clearance, notifications, process death and the FPS targets remain pending. The first handset pass should record the installed digest and scoped crash trace before applying the signed update. [Phone test and logcat procedure](../../export/README.md#c34-android-deployment-and-performance-checks)

The initial package replay exposed an engine-exit leak when the animation cache was owned by a GDScript static. The rebuilt candidate gives ownership of the weak entries to the scene tree’s root window. The variant with the corrected scope retained 4,867,476 median extra static bytes and measured 6.069 ms for 50 rigs in a separate seven-run host check.

## Change ownership

- `07f0f38` covers battlefield touch ownership, facing controls, preview conversion, pause/dialogue and the affected combat fixtures.
- `b5b9231` covers Home, Story, Headquarters, Chaos, education, Garden, Settings and navigation. It also binds the weak animation cache to the scene tree and adds focused regression and benchmark runners.
- `f173cfa` retains the paused-render optimization while publishing combat outcomes reached between physics ticks, with the original result navigation check passing.

## Release validation

| Check | Result |
| --- | --- |
| Pinned Godot editor import, startup and full regression | 5,797 checks across 48 runners. The six C34 additions cover native touch sequences and explicit facing (134), menus and paid upgrade journeys (67), activities (87), Chaos controls and swipes (111), lifecycle (37), and cache independence and teardown (7). |
| Native layout and touch | The deployment runner passed 141 checks for each of six viewport configurations. Separate real renderer runs cover menus, Chaos, lifecycle and activities, including 800×360 for activities and 1920×1080 for deployment. This uses desktop windows and injected input. |
| Deterministic Campaign | The existing one-save combat run reproduced 15 actual clears and 7,885,000 earned Campaign Funds, with 3,355,121 left after purchases. Hold the Line stayed at tick 8,169 with 17 defeated, 1 escaped and 90 Integrity. |
| W29/W27 artwork | W29 passed 732 checks, both W29 data validators matched approved receipts, First Contact loaded 76 registered textures, and W27 passed 916 rig samples. |
| Exact ARM64 APK payload | Clean boot and 3,881 checks across 29 test runs using the exported resource pack. The seed/resume/verify runs covered a disposable fresh save and a returning C33 profile. This is a host resource and save check. |
| ARM64 signing and update | APK v2/v3, 16 KiB alignment and a same-signer AVD update with retained data. |

```sh
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c34-debug.apk \
  --previous build/android/kenyalang-rangers-c33-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals \
  --combat-balance --skill-orbs --ranger-kits --education \
  --facility-growth --ranger-growth --economy-rewards --previous-economy-active \
  --chaos-cap --previous-chaos-capped --production-presentation --android-stabilization \
  --logs build/qa/c34/payload
```

Full regression, exported-pack and renderer logs are retained under `build/qa/c34`. Known open items are listed in the issue register. Upgrade confirmations use larger touch buttons and retain some vertical whitespace around short quotes.
