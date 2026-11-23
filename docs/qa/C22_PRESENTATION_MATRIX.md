# C22 presentation and accessibility checks

23 November 2026 · Godot 4.7.2 stable · Compatibility

| Area | Evidence |
|---|---|
| Storyboard coverage | The updated W21 register maps 116 frames to 35 components and tracks 39 placeholder surfaces. This is a source inventory. The regression runners exercise the live state changes. |
| Navigation | FAQ topics, References and approved articles open offline. Back returns to the originating FAQ, Records archive or selected Garden guide. Both the Settings and Main Menu entries reach help. Back cancels an open wipe confirmation. |
| Accessibility | Master, Music, SFX and 100/115/130% text settings survive a cold launch. An unwritable preferences path restores the slider and explains the failure. New controls inherit the chosen scale. Valid footprints use an outline and invalid footprints add a cross and reason. |
| Battle and dialogue | The 8-Ranger/6-Facility layout test uses seven existing Ranger kits and an eighth test identity. The last card is reachable with enlarged text. Existing touch tests exercise tray swipe, deploy, Hold, Retreat and target confirmation. Backgrounding opens pause inspection. The opening portrait and scrolling dialogue text render separately from the pinned Continue and Skip controls. |
| Sound and visual feedback | Four original development loops and synthesized cue families cover menus, combat, quiz and garden events. Alert and interaction players have independent voices. Recon, Siege, Heat, skill, deployment, Integrity and result text remain available with sound muted. |
| Linux playback | The Compatibility renderer recorded the Settings and Story views at 1152×648. Sampled output contained music, digital silence with Master muted, and a Siege cue with Music muted. The opening dialogue held combat at tick zero. |
| Android | The signed ARM64 development APK passed host packaging checks. A physical phone is required for installation, density-adjusted 48dp measurements, cutouts, speaker mix and touch reach. |

Run the commands in the project README. The 25 runners passed 1,838 assertions, including 37 C22 checks. Education article navigation uses an isolated approved-format fixture. The player build includes game-design references and the W18 approval gate. The portrait silhouettes and procedural sound palette are development treatments. D-014 tracks production clearance. [Test commands](../../tests/README.md) · [Device procedure](../../export/README.md#c22-presentation-phone-check)
