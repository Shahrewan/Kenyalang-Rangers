class_name RestorationRules
extends RefCounted

enum Stage { EMPTY, SEED, SAPLING, MATURE }

const SPECIES := {
	"species.strangler_fig": {"label": "Strangler Fig", "hours": 18, "funds": 3000, "fact": "fact.strangler_fig_start"},
	"species.belian": {"label": "Belian / Bornean Ironwood", "hours": 36, "funds": 8000, "fact": "fact.belian_identity"},
	"species.red_meranti": {"label": "Red Meranti", "hours": 48, "funds": 11000, "fact": "fact.red_meranti_example"},
	"species.mengaris": {"label": "Mengaris", "hours": 72, "funds": 18000, "fact": "fact.mengaris_identity"},
}
const MILESTONES := {20: 50000, 40: 150000, 60: 350000, 80: 750000, 100: 1250000}
const GUIDE_FACT := "fact.hornbill_tree_cavity"
const NEST_FACT := "fact.nest_box_habitat"

static func plot_id(slot: int) -> String:
	return "garden_plot.%02d" % (slot + 1)

static func duration(species: String) -> int:
	return SPECIES[species].hours * 3600

static func midpoint(species: String) -> int:
	return SPECIES[species].hours * 1800

static func elapsed(plot: Dictionary, now: int) -> int:
	var halfway := midpoint(plot.species)
	var reached := int(plot.get("reached_seconds", 0))
	if plot.watered_at == 0:
		return clampi(maxi(reached, now - int(plot.planted_at)), 0, halfway)
	var second_half := int(plot.watered_at)
	# Older profiles could record water before the midpoint. Keep their full growth duration.
	if not plot.has("reached_seconds") and second_half < int(plot.planted_at) + halfway:
		return clampi(now - int(plot.planted_at), 0, duration(plot.species))
	return mini(duration(plot.species), maxi(reached, halfway + maxi(0, now - second_half)))

static func stage(plot: Dictionary, now: int) -> Stage:
	if plot.is_empty():
		return Stage.EMPTY
	var seconds := elapsed(plot, now)
	if seconds >= duration(plot.species):
		return Stage.MATURE
	return Stage.SAPLING if seconds >= midpoint(plot.species) else Stage.SEED

static func needs_water(plot: Dictionary, now: int) -> bool:
	return not plot.is_empty() and plot.watered_at == 0 and stage(plot, now) == Stage.SAPLING

static func remaining(plot: Dictionary, now: int) -> int:
	var next_step := midpoint(plot.species) if plot.watered_at == 0 else duration(plot.species)
	return next_step - elapsed(plot, now)
