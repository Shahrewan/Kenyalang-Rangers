# C36-A · Work asset lists

Write only the filenames in your assigned batch. Each row is one planned WAV. Use the full path and metadata in the JSON or its CSV mirror. The asset counts include optional variants. Rows within each group start at `_01`. Send the assets and provenance receipts for review separately from any Godot project changes.

[Production brief](C36_SFX_PRODUCTION_BRIEF.md) · [JSON](../../../data/audio/sfx_manifest.json) · [CSV](C36_SFX_MANIFEST.csv)

| Batch | Required | Optional | Target PCM | All files at maximum |
| --- | ---: | ---: | ---: | ---: |
| A | 24 | 17 | 1,264,852 bytes | 1,804,186 bytes |
| B | 55 | 37 | 2,104,688 bytes | 3,042,168 bytes |

## Batch A

UI, progression, education, restoration and results.

| Path under `assets/audio/sfx/` | Cue ID | Delivery | Target ms |
| --- | --- | --- | ---: |
| `ui/ui_confirm_01.wav` | `ui_confirm` | required | 110 |
| `ui/ui_navigate_01.wav` | `ui_navigate` | optional | 190 |
| `ui/ui_back_01.wav` | `ui_back` | optional | 150 |
| `ui/ui_toggle_01.wav` | `ui_toggle` | optional | 100 |
| `ui/ui_cancel_01.wav` | `ui_cancel` | required | 160 |
| `ui/ui_invalid_01.wav` | `ui_invalid` | required | 210 |
| `ui/ui_save_problem_01.wav` | `ui_save_problem` | required | 420 |
| `ui/ui_notice_01.wav` | `ui_notice` | optional | 200 |
| `ui/ui_radio_continue_01.wav` | `ui_radio_continue` | optional | 110 |
| `ui/ui_battle_pause_01.wav` | `ui_battle_pause` | optional | 160 |
| `ui/ui_chaos_quantity_commit_01.wav` | `ui_chaos_quantity_commit` | optional | 75 |
| `progression/progression_hq_room_built_01.wav` | `progression_hq_room_built` | required | 730 |
| `progression/progression_hq_room_upgraded_01.wav` | `progression_hq_room_upgraded` | required | 680 |
| `progression/progression_level_purchase_01.wav` | `progression_level_purchase` | required | 460 |
| `progression/progression_level_milestone_01.wav` | `progression_level_milestone` | required | 1140 |
| `progression/progression_funds_claim_01.wav` | `progression_funds_claim` | required | 480 |
| `progression/progression_funds_discard_01.wav` | `progression_funds_discard` | optional | 330 |
| `progression/progression_recruit_01.wav` | `progression_recruit` | required | 1000 |
| `progression/progression_story_unlock_01.wav` | `progression_story_unlock` | optional | 610 |
| `progression/progression_profile_saved_01.wav` | `progression_profile_saved` | optional | 485 |
| `results/result_victory_01.wav` | `result_victory` | required | 2120 |
| `results/result_defeat_01.wav` | `result_defeat` | required | 1640 |
| `results/result_perfect_clear_01.wav` | `result_perfect_clear` | required | 2750 |
| `results/result_chaos_trophy_01.wav` | `result_chaos_trophy` | required | 1490 |
| `results/result_chaos_personal_best_01.wav` | `result_chaos_personal_best` | optional | 770 |
| `results/result_campaign_complete_01.wav` | `result_campaign_complete` | optional | 3030 |
| `education/education_response_01.wav` | `education_response` | required | 270 |
| `education/outreach_response_positive_01.wav` | `outreach_response_positive` | required | 310 |
| `education/outreach_response_reflect_01.wav` | `outreach_response_reflect` | optional | 300 |
| `education/outreach_batch_refresh_01.wav` | `outreach_batch_refresh` | optional | 310 |
| `education/records_correct_01.wav` | `records_correct` | required | 290 |
| `education/records_incorrect_01.wav` | `records_incorrect` | optional | 260 |
| `education/records_time_expired_01.wav` | `records_time_expired` | required | 390 |
| `education/records_chapter_complete_01.wav` | `records_chapter_complete` | required | 810 |
| `education/records_first_perfect_01.wav` | `records_first_perfect` | required | 1420 |
| `restoration/restoration_plant_01.wav` | `restoration_plant` | required | 530 |
| `restoration/restoration_water_01.wav` | `restoration_water` | required | 620 |
| `restoration/restoration_growth_ready_01.wav` | `restoration_growth_ready` | optional | 470 |
| `restoration/restoration_collect_01.wav` | `restoration_collect` | required | 790 |
| `restoration/restoration_visitor_01.wav` | `restoration_visitor` | required | 1370 |
| `restoration/restoration_milestone_01.wav` | `restoration_milestone` | optional | 900 |

## Batch B

One-shot battle, Ranger, Facility, enemy and boss feedback.

| Path under `assets/audio/sfx/` | Cue ID | Delivery | Target ms |
| --- | --- | --- | ---: |
| `combat/combat_deploy_01.wav` | `combat_deploy` | required | 300 |
| `combat/combat_facing_select_01.wav` | `combat_facing_select` | optional | 130 |
| `combat/combat_retreat_01.wav` | `combat_retreat` | required | 335 |
| `combat/combat_ranger_down_01.wav` | `combat_ranger_down` | required | 475 |
| `combat/combat_facility_destroyed_01.wav` | `combat_facility_destroyed` | required | 620 |
| `combat/combat_block_contact_01.wav` | `combat_block_contact` | optional | 185 |
| `combat/combat_impact_light_01.wav` | `combat_impact_light` | optional | 140 |
| `combat/combat_enemy_resolved_01.wav` | `combat_enemy_resolved` | optional | 210 |
| `combat/combat_support_01.wav` | `combat_support` | required | 375 |
| `combat/combat_skill_01.wav` | `combat_skill` | required | 385 |
| `combat/combat_skill_ready_01.wav` | `combat_skill_ready` | required | 260 |
| `combat/combat_tokens_01.wav` | `combat_tokens` | required | 300 |
| `combat/combat_wave_start_01.wav` | `combat_wave_start` | optional | 630 |
| `combat/combat_wave_rest_01.wav` | `combat_wave_rest` | optional | 595 |
| `combat/combat_recon_01.wav` | `combat_recon` | required | 580 |
| `combat/combat_siege_warning_01.wav` | `combat_siege_warning` | required | 690 |
| `combat/combat_heat_overflow_01.wav` | `combat_heat_overflow` | required | 785 |
| `combat/combat_integrity_loss_01.wav` | `combat_integrity_loss` | required | 625 |
| `combat/combat_fatal_escape_01.wav` | `combat_fatal_escape` | required | 900 |
| `combat/combat_boss_alert_01.wav` | `combat_boss_alert` | required | 930 |
| `combat/combat_messenger_withdrawal_01.wav` | `combat_messenger_withdrawal` | optional | 580 |
| `combat/combat_siege_telegraph_01.wav` | `combat_siege_telegraph` | optional | 620 |
| `rangers/ranger_melee_attack_01.wav` | `ranger_melee_attack` | required | 225 |
| `rangers/ranger_melee_attack_02.wav` | `ranger_melee_attack_v02` | optional | 225 |
| `rangers/ranger_melee_attack_03.wav` | `ranger_melee_attack_v03` | optional | 225 |
| `rangers/ranger_guard_attack_01.wav` | `ranger_guard_attack` | required | 315 |
| `rangers/ranger_guard_attack_02.wav` | `ranger_guard_attack_v02` | optional | 315 |
| `rangers/ranger_guard_attack_03.wav` | `ranger_guard_attack_v03` | optional | 315 |
| `rangers/ranger_scout_sniper_attack_01.wav` | `ranger_scout_sniper_attack` | required | 245 |
| `rangers/ranger_scout_sniper_attack_02.wav` | `ranger_scout_sniper_attack_v02` | optional | 245 |
| `rangers/ranger_scout_sniper_attack_03.wav` | `ranger_scout_sniper_attack_v03` | optional | 245 |
| `rangers/ranger_scout_sniper_focus_01.wav` | `ranger_scout_sniper_focus` | required | 650 |
| `rangers/ranger_combat_medic_heal_01.wav` | `ranger_combat_medic_heal` | required | 400 |
| `rangers/ranger_combat_medic_heal_02.wav` | `ranger_combat_medic_heal_v02` | optional | 400 |
| `rangers/ranger_combat_medic_heal_03.wav` | `ranger_combat_medic_heal_v03` | optional | 400 |
| `rangers/ranger_combat_medic_treatment_01.wav` | `ranger_combat_medic_treatment` | required | 775 |
| `rangers/ranger_guard_veteran_stun_prod_01.wav` | `ranger_guard_veteran_stun_prod` | required | 585 |
| `rangers/ranger_woods_tracker_net_01.wav` | `ranger_woods_tracker_net` | required | 690 |
| `rangers/ranger_k9_ranger_attack_01.wav` | `ranger_k9_ranger_attack` | required | 260 |
| `rangers/ranger_k9_ranger_attack_02.wav` | `ranger_k9_ranger_attack_v02` | optional | 260 |
| `rangers/ranger_k9_ranger_howl_01.wav` | `ranger_k9_ranger_howl` | required | 850 |
| `rangers/ranger_outpost_mechanic_attack_01.wav` | `ranger_outpost_mechanic_attack` | optional | 225 |
| `rangers/ranger_outpost_mechanic_repair_01.wav` | `ranger_outpost_mechanic_repair` | required | 490 |
| `rangers/ranger_kenyalang_seer_attack_01.wav` | `ranger_kenyalang_seer_attack` | required | 385 |
| `rangers/ranger_kenyalang_seer_attack_02.wav` | `ranger_kenyalang_seer_attack_v02` | optional | 385 |
| `rangers/ranger_kenyalang_seer_scan_01.wav` | `ranger_kenyalang_seer_scan` | required | 585 |
| `rangers/ranger_crowd_controller_attack_01.wav` | `ranger_crowd_controller_attack` | required | 390 |
| `rangers/ranger_crowd_controller_attack_02.wav` | `ranger_crowd_controller_attack_v02` | optional | 390 |
| `rangers/ranger_crowd_controller_emp_01.wav` | `ranger_crowd_controller_emp` | required | 860 |
| `rangers/ranger_saboteurist_emp_retreat_01.wav` | `ranger_saboteurist_emp_retreat` | required | 810 |
| `rangers/ranger_strike_team_arrival_01.wav` | `ranger_strike_team_arrival` | required | 825 |
| `facilities/facility_construction_start_01.wav` | `facility_construction_start` | required | 410 |
| `facilities/facility_construction_ready_01.wav` | `facility_construction_ready` | required | 660 |
| `facilities/facility_construction_cancel_01.wav` | `facility_construction_cancel` | required | 455 |
| `facilities/facility_medic_cabin_kit_01.wav` | `facility_medic_cabin_kit` | required | 625 |
| `facilities/facility_sentry_tower_mount_01.wav` | `facility_sentry_tower_mount` | optional | 400 |
| `facilities/facility_sonic_turret_attack_01.wav` | `facility_sonic_turret_attack` | required | 415 |
| `facilities/facility_sonic_turret_attack_02.wav` | `facility_sonic_turret_attack_v02` | optional | 415 |
| `facilities/facility_electric_pulse_turret_attack_01.wav` | `facility_electric_pulse_turret_attack` | required | 375 |
| `facilities/facility_electric_pulse_turret_attack_02.wav` | `facility_electric_pulse_turret_attack_v02` | optional | 375 |
| `facilities/facility_canopy_defense_launcher_attack_01.wav` | `facility_canopy_defense_launcher_attack` | required | 480 |
| `facilities/facility_canopy_defense_launcher_attack_02.wav` | `facility_canopy_defense_launcher_attack_v02` | optional | 480 |
| `facilities/facility_specialist_calltower_claim_01.wav` | `facility_specialist_calltower_claim` | optional | 635 |
| `enemies/enemy_melee_light_01.wav` | `enemy_melee_light` | required | 190 |
| `enemies/enemy_melee_light_02.wav` | `enemy_melee_light_v02` | optional | 190 |
| `enemies/enemy_melee_light_03.wav` | `enemy_melee_light_v03` | optional | 190 |
| `enemies/enemy_melee_heavy_01.wav` | `enemy_melee_heavy` | required | 312 |
| `enemies/enemy_melee_heavy_02.wav` | `enemy_melee_heavy_v02` | optional | 312 |
| `enemies/enemy_ranged_light_01.wav` | `enemy_ranged_light` | required | 242 |
| `enemies/enemy_ranged_light_02.wav` | `enemy_ranged_light_v02` | optional | 242 |
| `enemies/enemy_ranged_light_03.wav` | `enemy_ranged_light_v03` | optional | 242 |
| `enemies/enemy_e03_sprint_01.wav` | `enemy_e03_sprint` | optional | 585 |
| `enemies/enemy_e05_attack_01.wav` | `enemy_e05_attack` | optional | 290 |
| `enemies/enemy_e06_smoke_01.wav` | `enemy_e06_smoke` | required | 610 |
| `enemies/enemy_e07_jam_01.wav` | `enemy_e07_jam` | required | 690 |
| `enemies/enemy_e08_attack_01.wav` | `enemy_e08_attack` | optional | 252 |
| `enemies/enemy_e09_track_01.wav` | `enemy_e09_track` | required | 585 |
| `enemies/enemy_e10_net_01.wav` | `enemy_e10_net` | required | 630 |
| `enemies/enemy_e11_siege_01.wav` | `enemy_e11_siege` | optional | 555 |
| `enemies/enemy_e12_siege_01.wav` | `enemy_e12_siege` | optional | 620 |
| `enemies/enemy_e13_breach_01.wav` | `enemy_e13_breach` | required | 730 |
| `enemies/enemy_e15_priority_warning_01.wav` | `enemy_e15_priority_warning` | required | 780 |
| `bosses/boss_diversion_captain_intro_01.wav` | `boss_diversion_captain_intro` | required | 1000 |
| `bosses/boss_diversion_captain_phase_01.wav` | `boss_diversion_captain_phase` | required | 1110 |
| `bosses/boss_diversion_captain_capture_01.wav` | `boss_diversion_captain_capture` | required | 835 |
| `bosses/boss_illegal_logging_foreman_intro_01.wav` | `boss_illegal_logging_foreman_intro` | required | 1100 |
| `bosses/boss_illegal_logging_foreman_phase_01.wav` | `boss_illegal_logging_foreman_phase` | required | 1260 |
| `bosses/boss_illegal_logging_foreman_attack_01.wav` | `boss_illegal_logging_foreman_attack` | optional | 405 |
| `bosses/boss_poacher_leader_intro_01.wav` | `boss_poacher_leader_intro` | required | 1180 |
| `bosses/boss_poacher_leader_phase_call_01.wav` | `boss_poacher_leader_phase_call` | required | 1050 |
| `bosses/boss_poacher_leader_phase_surge_01.wav` | `boss_poacher_leader_phase_surge` | required | 1200 |
| `bosses/boss_poacher_leader_defeated_01.wav` | `boss_poacher_leader_defeated` | optional | 900 |
