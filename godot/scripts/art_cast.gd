class_name ArtCast
extends RefCounted
## The cast: the ember-bearing cat hero, the three survivors, and the husks that
## hold the ruins. Upright billboards lit from the upper left.
##
## Baked through the shared `Art` engine and registered with the Assets autoload
## via `a.put(key, image)`.
##
## WHY THESE READ AS DIFFERENT CREATURES
## The failure mode of a procedural cast is that everyone becomes the same
## snowman: round head, oval torso, two feet, dead-centre symmetry. Three rules
## keep that from happening here.
##
## 1. ONE SILHOUETTE IDEA EACH. Read at thumbnail size with the fill blacked out,
##    every character must still be nameable. Hero = light in one hand, steel in
##    the other. Farmer = a walking cloud under a hat. Smith = a wedge with a
##    hammer. Builder = a low slab with a plank. Husk = a hunched question mark.
## 2. NOBODY STANDS TO ATTENTION. Weight sits on the back leg, the front foot is
##    forward, shoulders tilt against the hips and the head turns off-axis. A
##    still frame should look like one moment of a walk cycle.
## 3. ASYMMETRIC WEIGHT. Every character carries something on exactly one side,
##    with a counterweight (tail, scarf, cloak) on the other.
##
## All figures are drawn FEET-DOWN: the contact point is a few px above the
## bottom edge, so Iso.anchor_feet() plants them on the floor.

# Depth trick used everywhere: limbs and tails on the far side of the body are
# painted first, darkened, so the near side reads as closer to the light.
const BACK_SHADE := 0.30

static func bake(a: Node) -> void:
	_hero(a)
	_farmer(a)
	_smith(a)
	_builder(a)
	_husk(a, "enemy_husk", 1.0)
	_husk(a, "enemy_brute", 1.34)

# ===========================================================================
# The hero — a ginger cat carrying the last ember
# ===========================================================================
## The whole game is "carry fire home", so the hero literally does: a lantern in
## the off hand, a cleaver in the other. That reads instantly in silhouette and
## it gives the sprite a baked-in warm light the rest of the cast doesn't have.
static func _hero(a: Node) -> void:
	var im := Art.img(152, 156)

	# --- Behind the body -----------------------------------------------------
	# Tail sweeps out low and right, balancing the raised lantern on the left.
	Art.paint(im, [
		Art.s(92, 116, 116, 114, 8.0),
		Art.s(116, 114, 132, 92, 6.0),
		Art.c(133, 88, 5.0),
	], Palette.CAT.darkened(BACK_SHADE), Palette.OUTLINE, 4.5, 0.16)

	# Back leg — the weight-bearing one, planted and further from camera.
	Art.paint(im, [Art.e(86, 130, 10, 15), Art.e(88, 145, 12, 7)],
			Palette.CAT.darkened(BACK_SHADE), Palette.OUTLINE, 4.5, 0.14)

	# --- The body: one union, one sticker outline ----------------------------
	# The head sits right of the torso centre while the hips shift left, so the
	# figure spirals instead of stacking like a snowman.
	var body := [
		Art.e(68, 106, 26, 30),                            # torso
		Art.e(70, 86, 25, 18),                             # chest / shoulders
		Art.c(72, 52, 29),                                 # head
		Art.t(49, 35, 58, 6, 70, 32),                      # left ear
		Art.t(96, 32, 87, 4, 74, 34),                      # right ear
		Art.e(58, 132, 11, 16), Art.e(56, 148, 13, 7),     # front leg + foot
		Art.s(48, 86, 27, 66, 8.0), Art.c(25, 63, 7.5),    # lantern arm, raised
		Art.s(90, 86, 106, 72, 8.0), Art.c(108, 70, 7.5),  # blade arm
	]
	Art.paint(im, body, Palette.CAT, Palette.OUTLINE, 5.0, 0.20, [], 0.75)

	# Cream belly and muzzle, clipped so they never spill past the outline.
	Art.paint(im, [Art.e(68, 112, 15, 21)], Palette.CAT_BELLY, Palette.OUTLINE, 0.001, 0.10, body)
	Art.paint(im, [Art.e(72, 62, 15, 11)], Palette.CAT_BELLY, Palette.OUTLINE, 0.001, 0.0, body)

	# Inner ears. The right one is notched — an old fight the hero walked away from.
	Art.flat(im, [Art.t(54, 32, 59, 14, 66, 31)], Palette.CAT_EAR)
	Art.flat(im, [Art.t(91, 30, 86, 12, 79, 32)], Palette.CAT_EAR)
	Art.paint(im, [Art.t(89, 15, 97, 11, 93, 25)], Palette.OUTLINE, Palette.OUTLINE, 0.001, 0.0)

	# Tabby stripes, swept to follow the turn of the skull.
	Art.flat(im, [Art.s(71, 25, 69, 35, 2.4)], Palette.CAT_D)
	Art.flat(im, [Art.s(59, 28, 54, 37, 2.0)], Palette.CAT_D)
	Art.flat(im, [Art.s(84, 27, 88, 36, 2.0)], Palette.CAT_D)

	# Face. The far eye is slightly smaller — the head is turned, not flat-on.
	_eye(im, 62, 52, 6.4, 8.6)
	_eye(im, 84, 51, 5.6, 8.2)
	Art.flat(im, [Art.t(68, 60, 76, 60, 72, 65)], Palette.CAT_EAR)   # nose
	Art.flat(im, [Art.s(72, 65, 72, 68, 1.6)], Palette.OUTLINE)      # philtrum
	# Whiskers: three light strokes a side. Cheap, and they sell "cat" instantly.
	for i in range(3):
		var wy: float = 60.0 + float(i) * 4.5
		Art.flat(im, [Art.s(58, wy, 36, wy - 4.0 + float(i) * 3.0, 1.1)], Palette.CAT_BELLY)
		Art.flat(im, [Art.s(87, wy - 1.0, 106, wy - 5.0 + float(i) * 3.0, 1.1)], Palette.CAT_BELLY)

	# Ember scarf: wrapped at the throat with two short ends hanging down the
	# chest. Kept small — the lantern and the blade are the loud elements.
	Art.paint(im, [Art.rr(72, 78, 21, 6, 5)], Palette.EMBER, Palette.OUTLINE, 3.5, 0.14)
	Art.paint(im, [Art.rr(62, 90, 4.5, 10, 3)], Palette.EMBER_D, Palette.OUTLINE, 2.8, 0.16)
	Art.paint(im, [Art.rr(72, 88, 4.0, 8, 3)], Palette.EMBER_D, Palette.OUTLINE, 2.8, 0.16)

	# --- The cleaver ---------------------------------------------------------
	# Wide and bright so it reads at thumbnail size, angled clear of the ears.
	Art.paint(im, [Art.rr(109, 66, 10, 4, 2)], Palette.WOOD2_D, Palette.OUTLINE, 3.0, 0.10)
	# Broad and pale: at 76 px on screen a thin blade just becomes a dark line, so
	# the cleaver is deliberately oversized and lighter than the outline around it.
	Art.paint(im, [
		Art.t(100, 64, 118, 54, 140, 24),
		Art.t(100, 64, 140, 24, 122, 14),
	], Palette.IRON.lightened(0.20), Palette.OUTLINE, 3.5, 0.18, [], 1.0, Palette.GOLD_L)
	# A hot line down the spine of the blade — the steel remembers the forge.
	Art.flat(im, [Art.s(112, 50, 132, 25, 2.4)], Palette.GOLD_L)

	# --- The lantern: the sprite carries its own light source ----------------
	# The cage is kept thin and the flame large: at thumbnail size the fire has to
	# win, or the lantern reads as a satchel.
	Art.glow(im, 24, 88, 54.0, Palette.TORCH, 0.55)
	Art.paint(im, [Art.s(24, 69, 24, 76, 2.0)], Palette.IRON, Palette.OUTLINE, 2.0, 0.0)
	Art.paint(im, [Art.rr(24, 88, 11, 12, 5)], Palette.IRON, Palette.OUTLINE, 3.0, 0.22,
			[], 0.7, Palette.GOLD_L)
	Art.flat(im, [Art.rr(24, 88, 8.5, 9.5, 4)], Palette.EMBER_D)
	Art.flat(im, [Art.e(24, 90, 7.0, 7.6)], Palette.TORCH)
	Art.flat(im, [Art.t(17, 90, 31, 90, 24, 76)], Palette.TORCH)
	Art.flat(im, [Art.e(24, 91, 4.2, 4.8)], Palette.TORCH_L)
	Art.flat(im, [Art.t(20, 91, 28, 91, 24, 81)], Palette.TORCH_L)
	Art.flat(im, [Art.e(24, 91, 2.0, 2.4)], Color(1, 1, 1, 0.98))
	# Two bars across the glass so it still reads as a lantern, not a fireball.
	Art.flat(im, [Art.s(15, 84, 33, 84, 1.3)], Palette.OUTLINE)
	Art.flat(im, [Art.s(15, 94, 33, 94, 1.3)], Palette.OUTLINE)

	a.put("player", im)

# ===========================================================================
# Survivors — the three pillars
# ===========================================================================

## Farmer: a lamb. Silhouette idea = a walking cloud wearing a hat. The bumpy
## wool outline is the whole read, so nothing else is allowed to be round.
static func _farmer(a: Node) -> void:
	var im := Art.img(140, 150)

	# Back legs first (thin dark sticks under a big soft mass).
	Art.paint(im, [Art.rr(84, 128, 5, 16, 3), Art.e(85, 144, 9, 6)],
			Palette.SOIL_D, Palette.OUTLINE, 4.0, 0.10)

	# The wool: an irregular ring of circles. Deliberately uneven — a symmetric
	# cloud reads as a machine part.
	var wool := [
		Art.e(66, 96, 32, 27),
		Art.c(38, 84, 15), Art.c(42, 62, 14), Art.c(62, 52, 15),
		Art.c(84, 58, 13), Art.c(95, 76, 14), Art.c(92, 98, 13),
		Art.c(72, 112, 15), Art.c(46, 108, 14), Art.c(30, 98, 11),
	]
	Art.paint(im, wool, Palette.CREAM, Palette.OUTLINE, 5.0, 0.16, [], 0.7)

	# Front legs.
	Art.paint(im, [Art.rr(58, 130, 5, 16, 3), Art.e(57, 146, 10, 6)],
			Palette.SOIL, Palette.OUTLINE, 4.0, 0.12)

	# The face pokes out of the wool low and to one side, not centred.
	var face := [Art.e(60, 82, 17, 15)]
	Art.paint(im, face, Palette.BONE, Palette.OUTLINE, 4.0, 0.12, [], 0.5)
	Art.paint(im, [Art.e(40, 80, 8, 12)], Palette.BONE, Palette.OUTLINE, 3.5, 0.10)  # ear
	_eye(im, 54, 80, 3.4, 4.4)
	_eye(im, 68, 79, 3.2, 4.2)
	Art.flat(im, [Art.e(60, 89, 4.5, 3.0)], Palette.CAT_EAR)                          # muzzle
	Art.flat(im, [Art.s(56, 92, 64, 92, 1.4)], Palette.OUTLINE)                        # mouth

	# Straw hat, tipped. The broken brim is the character beat: still working.
	Art.paint(im, [Art.e(58, 58, 34, 9)], Palette.GOLD, Palette.OUTLINE, 4.0, 0.18)
	Art.paint(im, [Art.e(60, 47, 17, 12)], Palette.GOLD, Palette.OUTLINE, 4.0, 0.16, [], 0.6)
	Art.paint(im, [Art.rr(60, 55, 17, 3, 2)], Palette.WOOD2_D, Palette.WOOD2_D, 0.001, 0.0)
	# A snapped-off wedge of brim, drawn as a separate darker shard.
	Art.paint(im, [Art.t(84, 55, 93, 61, 83, 63)], Palette.GOLD.darkened(0.35),
			Palette.OUTLINE, 2.0, 0.0)

	# Sickle over the shoulder — the counterweight to the tipped hat.
	Art.paint(im, [Art.s(100, 116, 112, 74, 4.0)], Palette.WOOD2, Palette.OUTLINE, 3.5, 0.14)
	Art.paint(im, [Art.s(112, 74, 126, 66, 3.5), Art.s(126, 66, 130, 52, 3.0)],
			Palette.IRON, Palette.OUTLINE, 3.5, 0.20, [], 0.8, Palette.GOLD_L)

	a.put("survivor_farmer", im)

## Smith: a badger. Silhouette idea = a wedge. Huge shoulders, tiny legs, a
## hammer head sticking out of the top corner.
static func _smith(a: Node) -> void:
	var im := Art.img(148, 150)

	# Far arm hanging behind the body.
	Art.paint(im, [Art.s(42, 92, 32, 116, 9.0), Art.c(31, 119, 8.0)],
			Palette.STONE2_D.darkened(BACK_SHADE), Palette.OUTLINE, 4.5, 0.12)

	# The wedge: shoulders far wider than the hips.
	var body := [
		Art.e(72, 90, 36, 24),                # shoulder slab
		Art.e(70, 116, 26, 22),               # hips
		Art.c(70, 54, 28),                    # head
		Art.c(48, 34, 11), Art.c(92, 33, 11), # small round ears
		Art.e(56, 138, 11, 9), Art.e(84, 138, 11, 9),   # stubby feet
	]
	Art.paint(im, body, Palette.STONE2_D, Palette.OUTLINE, 5.0, 0.20, [], 0.7)

	# Badger face stripe — the species read, straight down the middle of the mask.
	Art.paint(im, [Art.rr(70, 52, 8, 22, 6)], Palette.CREAM, Palette.OUTLINE, 2.5, 0.06, body)
	Art.flat(im, [Art.e(70, 74, 6, 4)], Palette.OUTLINE)     # snout
	_eye(im, 59, 54, 3.6, 4.4)
	_eye(im, 81, 53, 3.6, 4.4)

	# Goggles pushed up on the forehead: he was working when the world ended.
	Art.paint(im, [Art.rr(70, 32, 26, 5, 3)], Palette.WOOD2_D, Palette.OUTLINE, 2.5, 0.10)
	Art.paint(im, [Art.c(58, 32, 8), Art.c(82, 32, 8)], Palette.CYAN, Palette.OUTLINE, 3.0, 0.18)
	Art.flat(im, [Art.e(56, 30, 2.6, 3.0)], Color(1, 1, 1, 0.8))
	Art.flat(im, [Art.e(80, 30, 2.6, 3.0)], Color(1, 1, 1, 0.8))

	# Leather apron, scorched along the bottom edge.
	Art.paint(im, [Art.rr(70, 112, 20, 24, 5)], Palette.WOOD2, Palette.OUTLINE, 3.5, 0.22, body)
	Art.flat(im, [Art.s(52, 128, 88, 128, 3.0)], Palette.WOOD2_D)
	Art.flat(im, [Art.e(62, 120, 3, 3)], Palette.EMBER_D)     # burn marks
	Art.flat(im, [Art.e(78, 126, 2.4, 2.4)], Palette.EMBER_D)

	# Near arm gripping the hammer haft.
	Art.paint(im, [Art.s(100, 90, 112, 106, 9.0), Art.c(114, 108, 8.0)],
			Palette.STONE2_D, Palette.OUTLINE, 4.5, 0.14, [], 0.6)

	# The hammer, shouldered. Its head is the far corner of the wedge.
	Art.paint(im, [Art.s(114, 110, 122, 46, 4.5)], Palette.WOOD2, Palette.OUTLINE, 3.5, 0.14)
	Art.paint(im, [Art.rr(123, 38, 17, 12, 4)], Palette.STONE2, Palette.OUTLINE, 4.5, 0.24,
			[], 0.85, Palette.GOLD_L)
	Art.flat(im, [Art.rr(133, 38, 5, 11, 2)], Palette.IRON)

	a.put("survivor_smith", im)

## Builder: a toad. Silhouette idea = a low wide slab, almost no neck, with a
## plank cantilevered out one side. The only cast member wider than tall.
static func _builder(a: Node) -> void:
	var im := Art.img(156, 132)

	# Squat body: the head IS the top of the body, no neck at all.
	var body := [
		Art.e(70, 96, 38, 26),                # belly
		Art.e(70, 62, 34, 26),                # head/skull
		Art.c(50, 40, 14), Art.c(90, 40, 14), # eye turrets
		Art.e(40, 112, 13, 10), Art.e(100, 112, 13, 10),   # splayed feet
	]
	Art.paint(im, body, Palette.LEAF, Palette.OUTLINE, 5.0, 0.22, [], 0.7)

	# Pale throat sack, offset low — the frog read.
	Art.paint(im, [Art.e(70, 100, 22, 15)], Color("cfe3a0"), Palette.OUTLINE, 0.001, 0.08, body)
	# Dorsal mottling.
	Art.flat(im, [Art.e(52, 74, 6, 4)], Palette.MOSS)
	Art.flat(im, [Art.e(88, 78, 5, 3.4)], Palette.MOSS)
	Art.flat(im, [Art.e(70, 66, 4.5, 3)], Palette.MOSS)

	# Bulging eyes with slit pupils.
	Art.paint(im, [Art.c(50, 40, 9)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.10)
	Art.paint(im, [Art.c(90, 40, 9)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.10)
	Art.flat(im, [Art.e(50, 41, 2.4, 6.5)], Palette.OUTLINE)
	Art.flat(im, [Art.e(90, 41, 2.4, 6.5)], Palette.OUTLINE)
	Art.flat(im, [Art.e(47, 36, 2.2, 2.2)], Color(1, 1, 1, 0.85))
	Art.flat(im, [Art.e(87, 36, 2.2, 2.2)], Color(1, 1, 1, 0.85))
	# Wide flat mouth.
	Art.flat(im, [Art.s(48, 80, 92, 80, 2.2)], Palette.OUTLINE)

	# Hard hat, sitting low between the eye turrets.
	Art.paint(im, [Art.e(70, 26, 32, 8)], Palette.GOLD, Palette.OUTLINE, 4.0, 0.18)
	Art.paint(im, [Art.e(70, 17, 17, 11)], Palette.GOLD, Palette.OUTLINE, 4.0, 0.16, [], 0.6)
	Art.flat(im, [Art.s(70, 8, 70, 24, 2.4)], Palette.GOLD.darkened(0.28))

	# Tool belt with a hanging mallet.
	Art.paint(im, [Art.rr(70, 110, 30, 5, 3)], Palette.WOOD2_D, Palette.OUTLINE, 3.0, 0.12, body)
	Art.paint(im, [Art.rr(56, 118, 4, 9, 2)], Palette.WOOD2, Palette.OUTLINE, 2.5, 0.10)

	# The plank, carried one-handed and cantilevered right — the asymmetry that
	# stops the sprite reading as a symmetric lump.
	Art.paint(im, [Art.s(104, 92, 150, 78, 8.0)], Palette.WOOD2, Palette.OUTLINE, 4.0, 0.20,
			[], 0.6)
	Art.flat(im, [Art.s(108, 92, 146, 80, 1.8)], Palette.WOOD2_D)
	Art.paint(im, [Art.c(102, 94, 8.0)], Palette.LEAF, Palette.OUTLINE, 4.0, 0.14)  # gripping hand

	a.put("survivor_builder", im)

# ===========================================================================
# Husks — what the cold makes of people who stopped burning
# ===========================================================================
## Deliberately built on a DIFFERENT skeleton to the heroes: hunched so the skull
## hangs below the shoulder line, no legs (a ragged skirt of ash instead), and
## long arms that end in claws near the floor. The chest is cracked open with a
## dying ember still inside — the thing the player is trying not to become.
static func _husk(a: Node, key: String, k: float) -> void:
	var w := int(round(132.0 * k))
	var h := int(round(146.0 * k))
	var im := Art.img(w, h)
	var cx: float = w * 0.5

	# Scale helpers so both husk sizes share one layout.
	var X := func(v: float) -> float: return cx + (v - 66.0) * k
	var Y := func(v: float) -> float: return v * k
	var S := func(v: float) -> float: return v * k

	# --- Far arm, hanging long behind ---------------------------------------
	Art.paint(im, [
		Art.s(X.call(44), Y.call(78), X.call(28), Y.call(112), S.call(7)),
		Art.s(X.call(28), Y.call(112), X.call(24), Y.call(126), S.call(5)),
	], Palette.SHADOW_D.darkened(BACK_SHADE), Palette.OUTLINE, S.call(4.5), 0.16)

	# --- The hunch ----------------------------------------------------------
	# Shoulders ride high and the head hangs forward and low between them.
	var body := [
		Art.e(X.call(66), Y.call(112), S.call(34), S.call(26)),   # ragged ash skirt
		Art.e(X.call(66), Y.call(78), S.call(30), S.call(24)),    # ribcage
		Art.e(X.call(46), Y.call(58), S.call(15), S.call(13)),    # left shoulder blade
		Art.e(X.call(88), Y.call(56), S.call(16), S.call(14)),    # right shoulder blade
		Art.e(X.call(68), Y.call(62), S.call(22), S.call(18)),    # skull, slung low
	]
	# Strong rim: in a dark chamber the lit edge is most of what separates a husk
	# from the floor behind it.
	Art.paint(im, body, Palette.SHADOW, Palette.OUTLINE, S.call(5.0), 0.26, [], 0.85,
			Color("b9a9e0"))

	# Spines along the back — uneven, more of them on the brute.
	var spikes: int = 3 if k < 1.2 else 5
	for i in range(spikes):
		var t: float = float(i) / float(maxi(spikes - 1, 1))
		var sx: float = lerpf(52.0, 92.0, t)
		var sy: float = lerpf(46.0, 40.0, t) + Art.hash01(i * 37 + 5) * 6.0
		var sh: float = 10.0 + Art.hash01(i * 91 + 3) * 8.0
		Art.paint(im, [Art.t(X.call(sx - 5), Y.call(sy + 6),
				X.call(sx + 5), Y.call(sy + 6), X.call(sx + 1), Y.call(sy - sh))],
				Palette.SHADOW_D, Palette.OUTLINE, S.call(3.0), 0.20)

	# --- Face: hollow sockets, cold pinpricks --------------------------------
	Art.flat(im, [Art.e(X.call(59), Y.call(61), S.call(7.0), S.call(5.4))], Palette.NIGHT)
	Art.flat(im, [Art.e(X.call(78), Y.call(60), S.call(7.0), S.call(5.4))], Palette.NIGHT)
	Art.glow(im, X.call(59), Y.call(61), S.call(9), Palette.EYE_RED, 0.45)
	Art.glow(im, X.call(78), Y.call(60), S.call(9), Palette.EYE_RED, 0.45)
	Art.flat(im, [Art.e(X.call(59), Y.call(61), S.call(2.4), S.call(2.4))], Palette.EYE_RED)
	Art.flat(im, [Art.e(X.call(78), Y.call(60), S.call(2.4), S.call(2.4))], Palette.EYE_RED)
	# A lipless grin of ash-teeth, kept high inside the skull so it never reads
	# as part of the chest ember below it.
	Art.flat(im, [Art.s(X.call(60), Y.call(73), X.call(77), Y.call(72), S.call(2.0))], Palette.NIGHT)
	for i in range(3):
		var tx: float = lerpf(62.0, 75.0, float(i) / 2.0)
		Art.flat(im, [Art.t(X.call(tx - 1.6), Y.call(71.5), X.call(tx + 1.6), Y.call(71.5),
				X.call(tx), Y.call(75.5))], Palette.BONE)

	# --- The cracked chest: a dying ember, still lit -------------------------
	# Sits low in the ribcage, well clear of the jaw. Drawn as fissures with one
	# small hot core rather than a bright blob, so it reads as damage, not a mouth.
	Art.glow(im, X.call(66), Y.call(95), S.call(19), Palette.EMBER, 0.22)
	Art.flat(im, [
		Art.s(X.call(56), Y.call(84), X.call(64), Y.call(95), S.call(1.8)),
		Art.s(X.call(64), Y.call(95), X.call(58), Y.call(106), S.call(1.5)),
		Art.s(X.call(64), Y.call(95), X.call(76), Y.call(91), S.call(1.5)),
		Art.s(X.call(76), Y.call(91), X.call(80), Y.call(102), S.call(1.2)),
	], Palette.EMBER_D)
	Art.flat(im, [Art.e(X.call(65), Y.call(95), S.call(3.4), S.call(4.2))], Palette.TORCH)
	Art.flat(im, [Art.e(X.call(65), Y.call(94), S.call(1.7), S.call(2.1))], Palette.TORCH_L)

	# --- Near arm, ending in claws just above the floor ----------------------
	Art.paint(im, [
		Art.s(X.call(90), Y.call(74), X.call(104), Y.call(108), S.call(7.5)),
		Art.s(X.call(104), Y.call(108), X.call(106), Y.call(122), S.call(5.5)),
	], Palette.SHADOW, Palette.OUTLINE, S.call(4.5), 0.18, [], 0.4, Color("8a7fb0"))
	for i in range(3):
		var fx: float = 100.0 + float(i) * 6.0
		Art.paint(im, [Art.s(X.call(fx), Y.call(124), X.call(fx + 2), Y.call(136), S.call(2.0))],
				Palette.BONE, Palette.OUTLINE, S.call(1.8), 0.0)

	# --- Tattered hem: the skirt frays into the floor rather than ending flat -
	for i in range(7):
		var hx: float = lerpf(38.0, 94.0, float(i) / 6.0)
		var hh: float = 128.0 + Art.hash01(i * 53 + 11) * 12.0
		Art.paint(im, [Art.t(X.call(hx - 6), Y.call(120), X.call(hx + 6), Y.call(120),
				X.call(hx), Y.call(hh))], Palette.SHADOW_D, Palette.OUTLINE, S.call(3.0), 0.20)

	# The brute has a broken slab of ruin masonry fused into its shoulder — a
	# jagged wedge, not a tidy box, so it reads as wreckage rather than cargo.
	if k >= 1.2:
		Art.paint(im, [
			Art.t(X.call(78), Y.call(50), X.call(104), Y.call(38), X.call(110), Y.call(56)),
			Art.t(X.call(78), Y.call(50), X.call(110), Y.call(56), X.call(92), Y.call(66)),
		], Palette.STONE2_D, Palette.OUTLINE, S.call(4.5), 0.26, [], 0.55)
		Art.flat(im, [Art.s(X.call(86), Y.call(48), X.call(103), Y.call(52), S.call(1.8))],
				Palette.STONE2)
		Art.flat(im, [Art.s(X.call(94), Y.call(44), X.call(97), Y.call(60), S.call(1.4))],
				Palette.STONE2)

	a.put(key, im)

# ===========================================================================
# Shared face parts
# ===========================================================================

## A big dark eye with a catchlight in the upper left (matching Art.LIGHT_DIR)
## and a faint lower bounce, which is what stops the cast looking dead-eyed.
static func _eye(im: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	Art.flat(im, [Art.e(cx, cy, rx, ry)], Palette.OUTLINE)
	Art.flat(im, [Art.e(cx - rx * 0.32, cy - ry * 0.34, rx * 0.34, ry * 0.30)],
			Color(1, 1, 1, 0.95))
	Art.flat(im, [Art.e(cx + rx * 0.28, cy + ry * 0.40, rx * 0.20, ry * 0.16)],
			Color(1, 1, 1, 0.35))
