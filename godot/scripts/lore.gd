class_name Lore
extends RefCounted
## The knowledge layer's content — "the Ember's memories" (QA D-06 / F-08 / VISION.md).
## A static namespace (like Vfx / Iso), so it needs no autoload: the HUD reads
## `Lore.ENTRIES` to draw the Codex, and GameState tracks which ids are unlocked.
##
## Every entry is written to the PROGRESSION_DESIGN §7 standard: state the REAL
## mechanism, order by IMPACT not date, and FLAG every deliberate liberty. No
## invented technology, no wrong causal story — the game teaches *why an advance
## changed the world*, honestly, or it says nothing.

# Ordered list. `id` is the unlock key; `era` is a rough, honest date; `fact` is
# one paragraph. `title` names the world-changing advance, not the game building.
const ENTRIES := [
	{
		"id": "ember", "title": "Civilisation is Carried", "era": "the premise",
		"fact": "Civilisation is not stone or steel — it is knowledge, remembered and "
			+ "handed on. Every survivor you carry home remembers how something was "
			+ "made; every building re-enacts why it mattered. To rekindle a dead world "
			+ "is to remember it.",
	},
	{
		"id": "agriculture", "title": "Agriculture", "era": "~10,000 BCE",
		"fact": "As the last Ice Age ended, people in at least seven regions — the "
			+ "Fertile Crescent, China, Mesoamerica, the Andes, New Guinea among them — "
			+ "independently began domesticating plants and animals. A stored surplus "
			+ "meant a village could feed people who did not farm: potters, smiths, "
			+ "scribes. Cities, writing, states, even new diseases all rest on that "
			+ "grain. (Liberty: one tended plot stands in for a millennia-long, "
			+ "many-crop revolution.)",
	},
	{
		"id": "metallurgy", "title": "Metallurgy", "era": "~5,000 BCE",
		"fact": "To win metal from stone you must out-heat the rock. Smelting copper "
			+ "from ore appeared ~7,000 years ago; a tenth part tin gave bronze, harder "
			+ "than either parent. Iron came later — a poorer metal at first, but its "
			+ "ore is everywhere, so ploughs and tools reached ordinary hands. The trick "
			+ "was always the fire: charcoal and forced air (bellows) reach the "
			+ "~1,150 °C that frees copper, hotter still for iron. Metallurgy is applied "
			+ "thermodynamics — the same heat you carry.",
	},
	{
		"id": "construction", "title": "Durable Construction", "era": "~9,000 BCE",
		"fact": "Durable building is what let people stop moving. Mudbrick and rammed "
			+ "earth are ~10,000 years old; the load-bearing arch — which turns a roof's "
			+ "downward weight into a sideways thrust its supports can hold — was "
			+ "mastered by the Romans and spanned aqueducts and domes that still stand. "
			+ "A permanent roof stores labour the way a granary stores grain: build "
			+ "once, shelter for generations. (Liberty: a timber cabin stands in for the "
			+ "whole art of durable construction.)",
	},
]

# building type / rescued pillar → the Codex entry it recovers. Farmer and the
# Crop Bed both teach Agriculture; Smith / Forge → Metallurgy; Builder / Cabin →
# Construction. Either raising the building OR rescuing the survivor unlocks it.
const BUILDING_ENTRY := {"crop_bed": "agriculture", "forge": "metallurgy", "cabin": "construction"}
const PILLAR_ENTRY := {"farmer": "agriculture", "smith": "metallurgy", "builder": "construction"}

# One honest line the Ember speaks the first time an invention is recovered (F-08:
# teach *why it changed the world* at the moment of use, not in a popup wall).
const EMBER_LINE := {
	"agriculture": "Agriculture. Store a surplus and a village can feed those who "
		+ "don't farm — the first free hands that ever built anything else.",
	"metallurgy": "Metallurgy. Out-heat the stone and it gives up its metal. It is "
		+ "the same fire I carry — knowledge is only heat, aimed.",
	"construction": "Construction. A roof that outlasts its builder is stored labour. "
		+ "Raise one, and people can stop merely surviving.",
}

# Look up an entry dict by id (empty dict if unknown).
static func entry(id: String) -> Dictionary:
	for e: Dictionary in ENTRIES:
		if String(e.get("id", "")) == id:
			return e
	return {}
