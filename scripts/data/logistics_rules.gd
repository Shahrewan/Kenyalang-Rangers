class_name LogisticsRules
extends Resource

const FIXED_STOCKPILE := 120
const PAYOUT_TICKS := 10 * CombatClock.TICKS_PER_SECOND
const YIELD_DENOMINATOR := 9900

@export var fixed_stockpile := false
@export var starter_only := false
@export var yield_percent := 100
@export var later_post_base_cost := 20
@export var later_post_cost_step := 5

func post_yield_numerator(level: int) -> int:
	return (990 + 5 * (clampi(level, 1, 100) - 1)) * yield_percent
