extends HBoxContainer

@onready var _wave: Label = %WaveCount
@onready var _defeated: Label = %DefeatedCount
@onready var _integrity: Label = %IntegrityCount
@onready var _tokens: Label = %TokenCount

func render(battle: BattleSimulation, total: int, tokens: int) -> void:
	_wave.text = "Wave %d/%d" % [battle.wave_number, battle.wave_count]
	_defeated.text = "Defeated %d/%d" % [battle.defeated, total]
	_integrity.text = "Integrity %d" % battle.integrity
	_tokens.text = "%d Tokens" % tokens
