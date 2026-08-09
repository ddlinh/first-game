class_name ArtProps
extends RefCounted
## Standing props and carryables: the return portal, the cage, the supply gate,
## the material pickups, and the fire sources that light both layers.
##
## Baked through the shared `Art` engine and registered with the Assets autoload
## via `a.put(key, image)`.
##
## The pickups are the one place in the catalogue where READABILITY AT 32 PX beats
## detail: they are seen small, on a busy floor, and the player has to know what
## they grabbed without reading a label. So each one is a distinct silhouette and
## a distinct hue — bundled logs, angular grey chunks, a stamped ingot, a warm
## loaf — rather than four differently-tinted eggs.

static func bake(a: Node) -> void:
	_portal(a)
	_cage(a)
	_supply_gate(a)
	_materials(a)
	_fires(a)
	_dressing(a)

# ===========================================================================
# The return portal
# ===========================================================================
## A ruin arch with something cold and turning inside it. Cyan is reserved for
## arcane cold throughout the game, so this never competes with the warm palette.
static func _portal(a: Node) -> void:
	var im := Art.img(140, 168)

	# The rift's bloom, painted before the stone so the arch occludes it.
	Art.glow(im, 70, 104, 62.0, Palette.CYAN, 0.34)

	# Swirling interior: nested ellipses stepped in hue and offset along one
	# diagonal, which reads as rotation without needing an animation.
	Art.paint(im, [Art.e(70, 104, 30, 44)], Palette.CYAN_D, Palette.OUTLINE, 4.0, 0.0)
	Art.flat(im, [Art.e(69, 102, 24, 36)], Palette.CYAN_D.lightened(0.18))
	Art.flat(im, [Art.e(67, 99, 18, 27)], Palette.CYAN)
	Art.flat(im, [Art.e(65, 96, 12, 18)], Palette.CYAN.lightened(0.30))
	Art.flat(im, [Art.e(64, 94, 6, 9)], Color(0.92, 1.0, 1.0, 0.95))
	# Motes drifting up out of the rift.
	for i in range(6):
		var k := i * 173 + 5
		var mx: float = 52.0 + Art.hash01(k) * 36.0
		var my: float = 68.0 + Art.hash01(k + 1) * 72.0
		Art.flat(im, [Art.e(mx, my, 1.8, 2.4)], Color(0.75, 1.0, 0.98, 0.75))

	# The arch: two jambs and a keystoned lintel, weathered.
	Art.paint(im, [Art.rr(22, 104, 11, 54, 4)], Palette.STONE2, Palette.OUTLINE, 5.0, 0.24,
			[], 0.6)
	Art.paint(im, [Art.rr(118, 104, 11, 54, 4)], Palette.STONE2_D, Palette.OUTLINE, 5.0, 0.24)
	Art.paint(im, [Art.rr(70, 48, 54, 11, 5)], Palette.STONE2, Palette.OUTLINE, 5.0, 0.22,
			[], 0.55)
	Art.paint(im, [Art.rr(70, 38, 13, 10, 3)], Palette.STONE2, Palette.OUTLINE, 4.0, 0.20,
			[], 0.7)
	# Block joints on the jambs.
	for i in range(4):
		var jy: float = 66.0 + float(i) * 22.0
		Art.flat(im, [Art.s(12, jy, 32, jy, 1.4)], Palette.STONE2_D)
		Art.flat(im, [Art.s(108, jy, 128, jy, 1.4)], Palette.STONE2_D)
	# Cold runes cut into the lintel.
	for i in range(3):
		var rx: float = 54.0 + float(i) * 16.0
		Art.flat(im, [Art.s(rx, 44, rx, 52, 1.6)], Palette.CYAN)
		Art.flat(im, [Art.s(rx - 3, 48, rx + 3, 48, 1.6)], Palette.CYAN)

	a.put("portal", im)

# ===========================================================================
# The cage
# ===========================================================================
## Drawn with the bars in front and nothing behind them: Survivor layers this
## over the captive's body sprite, so the gaps must stay fully transparent.
static func _cage(a: Node) -> void:
	var im := Art.img(128, 136)
	var bars: Array = []
	for i in range(5):
		bars.append(Art.rr(26.0 + float(i) * 19.0, 72, 3.5, 46, 2))
	bars.append(Art.rr(64, 26, 46, 5, 3))     # top rail
	bars.append(Art.rr(64, 116, 46, 5, 3))    # bottom rail
	Art.paint(im, bars, Palette.STONE2, Palette.OUTLINE, 3.0, 0.14, [], 0.5)
	# Rivets on the rails.
	for i in range(5):
		var rx: float = 26.0 + float(i) * 19.0
		Art.flat(im, [Art.e(rx, 26, 2.2, 2.2)], Palette.STONE2_D)
		Art.flat(im, [Art.e(rx, 116, 2.2, 2.2)], Palette.STONE2_D)
	# Rust bleeding down two of the bars — nobody has opened this in a long time.
	Art.flat(im, [Art.s(45, 60, 45, 96, 1.6)], Color(0.55, 0.32, 0.20, 0.55))
	Art.flat(im, [Art.s(83, 70, 83, 108, 1.4)], Color(0.55, 0.32, 0.20, 0.45))
	# Padlock, dead centre, gold so the eye goes straight to the thing you press E on.
	Art.paint(im, [Art.s(64, 66, 64, 74, 2.4)], Palette.IRON, Palette.OUTLINE, 2.2, 0.0)
	Art.paint(im, [Art.rr(64, 80, 9, 8, 3)], Palette.GOLD, Palette.OUTLINE, 3.2, 0.20,
			[], 0.7, Palette.GOLD_L)
	Art.flat(im, [Art.e(64, 80, 1.8, 2.6)], Palette.OUTLINE)
	a.put("cage", im)

# ===========================================================================
# The supply gate
# ===========================================================================
## The run-start landmark. Deliberately the tallest thing in the village so it
## reads as "the way out" from anywhere on the grid.
static func _supply_gate(a: Node) -> void:
	var im := Art.img(176, 168)

	# Posts, sunk into stone footings.
	Art.paint(im, [Art.rr(30, 106, 11, 54, 4)], Palette.WOOD2, Palette.OUTLINE, 5.0, 0.22,
			[], 0.6)
	Art.paint(im, [Art.rr(146, 106, 11, 54, 4)], Palette.WOOD2_D, Palette.OUTLINE, 5.0, 0.22)
	Art.paint(im, [Art.rr(30, 158, 16, 8, 3)], Palette.STONE2_D, Palette.OUTLINE, 4.0, 0.20)
	Art.paint(im, [Art.rr(146, 158, 16, 8, 3)], Palette.STONE2_D, Palette.OUTLINE, 4.0, 0.20)
	# Lintel with a slight sag, plus corner braces.
	Art.paint(im, [Art.rr(88, 50, 70, 11, 5)], Palette.WOOD2, Palette.OUTLINE, 5.0, 0.24,
			[], 0.55)
	Art.paint(im, [Art.s(40, 72, 62, 58, 5.0), Art.s(136, 72, 114, 58, 5.0)],
			Palette.WOOD2_D, Palette.OUTLINE, 3.5, 0.16)

	# Ember banner hanging from the lintel.
	Art.paint(im, [Art.rr(88, 92, 26, 32, 3)], Palette.RED, Palette.OUTLINE, 4.0, 0.20, [], 0.4)
	Art.paint(im, [Art.t(62, 122, 114, 122, 88, 140)], Palette.RED, Palette.OUTLINE, 4.0, 0.10)
	Art.flat(im, [Art.s(64, 66, 112, 66, 2.0)], Palette.RED_D)
	# The ember sigil on the banner.
	Art.glow(im, 88, 96, 22.0, Palette.EMBER, 0.30)
	Art.paint(im, [Art.e(88, 96, 11, 13)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.16)
	Art.flat(im, [Art.t(83, 100, 93, 100, 88, 84)], Palette.EMBER)
	Art.flat(im, [Art.e(88, 98, 3.4, 4.2)], Palette.TORCH_L)

	# A lantern on each post — the gate is always lit, even when the village isn't.
	_lantern(im, 30, 74)
	_lantern(im, 146, 74)

	a.put("supply_gate", im)

## Small hanging lantern used on the gate posts.
static func _lantern(im: Image, cx: float, cy: float) -> void:
	Art.glow(im, cx, cy + 8, 30.0, Palette.TORCH, 0.34)
	Art.paint(im, [Art.s(cx, cy - 8, cx, cy - 2, 1.8)], Palette.IRON, Palette.OUTLINE, 1.8, 0.0)
	Art.paint(im, [Art.rr(cx, cy + 8, 9, 10, 4)], Palette.IRON, Palette.OUTLINE, 3.5, 0.20,
			[], 0.6, Palette.GOLD_L)
	Art.flat(im, [Art.e(cx, cy + 8, 4.4, 5.4)], Palette.TORCH)
	Art.flat(im, [Art.e(cx, cy + 9, 2.2, 2.8)], Palette.TORCH_L)

# ===========================================================================
# Material pickups
# ===========================================================================
static func _materials(a: Node) -> void:
	# Wood: two logs lashed together, cut ends toward camera so the rings show.
	var wd := Art.img(72, 60)
	Art.paint(wd, [Art.rr(38, 38, 22, 8, 8)], Palette.WOOD2_D, Palette.OUTLINE, 3.5, 0.20)
	Art.paint(wd, [Art.rr(34, 26, 24, 9, 9)], Palette.WOOD2, Palette.OUTLINE, 3.5, 0.20,
			[], 0.6)
	Art.paint(wd, [Art.e(12, 26, 6, 9)], Palette.AMBER, Palette.OUTLINE, 3.0, 0.14)
	Art.flat(wd, [Art.e(12, 26, 3.4, 5.2)], Palette.WOOD2)
	Art.flat(wd, [Art.e(12, 26, 1.4, 2.2)], Palette.AMBER)
	Art.paint(wd, [Art.rr(40, 30, 3, 14, 1)], Palette.BONE, Palette.OUTLINE, 2.0, 0.10)  # twine
	a.put("material_wood", wd)

	# Stone: three angular chunks. Angular is the whole read — nothing else in
	# the pickup set has straight edges.
	var st := Art.img(72, 60)
	Art.paint(st, [Art.t(10, 42, 22, 22, 36, 42)], Palette.STONE2_D, Palette.OUTLINE, 3.0, 0.22)
	Art.paint(st, [Art.t(30, 44, 48, 18, 62, 44)], Palette.STONE2, Palette.OUTLINE, 3.5, 0.24,
			[], 0.7)
	Art.flat(st, [Art.t(40, 38, 48, 24, 54, 38)], Palette.STONE2.lightened(0.22))
	a.put("material_stone", st)

	# Iron: a stamped ingot, cold and bright, with a chisel mark on the face.
	var ir := Art.img(72, 60)
	Art.paint(ir, Art.quad(Vector2(14, 40), Vector2(24, 24), Vector2(58, 24), Vector2(64, 40)),
			Palette.IRON, Palette.OUTLINE, 3.5, 0.26, [], 0.85, Palette.GOLD_L)
	Art.flat(ir, [Art.s(26, 28, 54, 28, 2.0)], Color(1, 1, 1, 0.55))
	Art.flat(ir, [Art.rr(39, 34, 7, 3, 1)], Palette.STONE2_D)
	a.put("material_iron", ir)

	# Food: a scored loaf. Warm, round, obviously edible next to the grey chunks.
	var fd := Art.img(72, 60)
	Art.paint(fd, [Art.e(36, 34, 22, 15)], Palette.GOLD, Palette.OUTLINE, 3.5, 0.24,
			[], 0.7, Palette.GOLD_L)
	for i in range(3):
		var sx: float = 26.0 + float(i) * 10.0
		Art.flat(fd, [Art.s(sx, 26, sx + 5, 34, 2.0)], Palette.AMBER.darkened(0.30))
	Art.flat(fd, [Art.e(30, 27, 5, 3)], Palette.AMBER)
	a.put("material_food", fd)

# ===========================================================================
# Fire sources
# ===========================================================================
static func _fires(a: Node) -> void:
	# Village bonfire: the heart of the settlement and the GWI made physical.
	var bf := Art.img(148, 132)
	Art.glow(bf, 74, 74, 66.0, Palette.TORCH, 0.34)
	# Stone ring.
	for i in range(9):
		var ang: float = TAU * float(i) / 9.0
		var sx: float = 74.0 + cos(ang) * 46.0
		var sy: float = 106.0 + sin(ang) * 16.0
		if sy < 100.0:
			continue
		Art.paint(bf, [Art.e(sx, sy, 9, 7)], Palette.STONE2_D, Palette.OUTLINE, 3.0, 0.24)
	# Log pyre, crossed rather than stacked flat.
	Art.paint(bf, [Art.s(46, 106, 100, 88, 8.0)], Palette.WOOD2_D, Palette.OUTLINE, 4.0, 0.22)
	Art.paint(bf, [Art.s(102, 106, 48, 88, 8.0)], Palette.WOOD2, Palette.OUTLINE, 4.0, 0.22,
			[], 0.5)
	# Flame: three overlapping teardrops, hottest at the base.
	_flame(bf, 74, 70, 1.0)
	_flame(bf, 60, 82, 0.58)
	_flame(bf, 90, 80, 0.50)
	a.put("bonfire", bf)

	# Dungeon brazier: a shallow bowl on a tripod, the only warm thing down there.
	var br := Art.img(104, 152)
	Art.glow(br, 52, 52, 52.0, Palette.TORCH, 0.32)
	Art.paint(br, [
		Art.s(52, 118, 30, 146, 4.0), Art.s(52, 118, 74, 146, 4.0), Art.s(52, 118, 52, 148, 4.0),
	], Palette.STEEL, Palette.OUTLINE, 3.5, 0.20)
	Art.paint(br, [Art.rr(52, 108, 8, 14, 3)], Palette.STEEL, Palette.OUTLINE, 3.5, 0.18)
	Art.paint(br, [Art.t(24, 84, 80, 84, 68, 106), Art.t(24, 84, 68, 106, 36, 106)],
			Palette.STEEL, Palette.OUTLINE, 4.0, 0.24, [], 0.7, Palette.GOLD_L)
	Art.flat(br, [Art.e(52, 84, 26, 6)], Palette.EMBER_D)
	Art.flat(br, [Art.e(52, 83, 20, 4)], Palette.EMBER)
	_flame(br, 52, 62, 0.82)
	_flame(br, 40, 72, 0.42)
	a.put("brazier", br)

## One teardrop flame: dark-orange body, ember mid, gold core, white heart.
static func _flame(im: Image, cx: float, cy: float, k: float) -> void:
	Art.flat(im, [Art.e(cx, cy + 10 * k, 15 * k, 14 * k),
			Art.t(cx - 13 * k, cy + 12 * k, cx + 13 * k, cy + 12 * k, cx + 2 * k, cy - 26 * k)],
			Palette.EMBER_D)
	Art.flat(im, [Art.e(cx, cy + 10 * k, 11 * k, 11 * k),
			Art.t(cx - 9 * k, cy + 11 * k, cx + 9 * k, cy + 11 * k, cx + 1 * k, cy - 17 * k)],
			Palette.TORCH)
	Art.flat(im, [Art.e(cx, cy + 11 * k, 6 * k, 7 * k),
			Art.t(cx - 5 * k, cy + 11 * k, cx + 5 * k, cy + 11 * k, cx, cy - 6 * k)],
			Palette.TORCH_L)
	Art.flat(im, [Art.e(cx, cy + 11 * k, 3 * k, 3.4 * k)], Color(1, 1, 1, 0.9))

# ===========================================================================
# Scenery dressing
# ===========================================================================
static func _dressing(a: Node) -> void:
	# Rubble: collapsed masonry to break up long dungeon walls.
	var rb := Art.img(124, 80)
	Art.paint(rb, [Art.t(8, 66, 26, 38, 48, 66)], Palette.STONE2_D, Palette.OUTLINE, 3.5, 0.24)
	Art.paint(rb, Art.quad(Vector2(38, 66), Vector2(46, 42), Vector2(78, 46), Vector2(74, 66)),
			Palette.STONE2, Palette.OUTLINE, 4.0, 0.26, [], 0.6)
	Art.paint(rb, [Art.t(70, 68, 92, 48, 112, 68)], Palette.STONE2_D, Palette.OUTLINE, 3.5, 0.22)
	Art.flat(rb, [Art.s(50, 52, 74, 56, 1.6)], Palette.STONE2_D)
	Art.scatter(rb, Palette.STONE2_D, 8, 91, 124, 80, 1.6, 3.4, 0.7, 0.7)
	a.put("rubble", rb)

	# Banner: hung cloth for ruin walls and the village hall.
	var bn := Art.img(80, 140)
	Art.paint(bn, [Art.rr(40, 12, 32, 4, 2)], Palette.WOOD2_D, Palette.OUTLINE, 3.0, 0.14)
	Art.paint(bn, [Art.rr(40, 70, 24, 54, 2)], Palette.WINE, Palette.OUTLINE, 4.0, 0.26, [], 0.35)
	Art.paint(bn, [Art.t(16, 124, 64, 124, 40, 138)], Palette.WINE, Palette.OUTLINE, 4.0, 0.10)
	Art.flat(bn, [Art.s(28, 24, 28, 122, 1.6)], Palette.RED_D)
	Art.flat(bn, [Art.s(52, 24, 52, 122, 1.6)], Palette.RED_D)
	Art.glow(bn, 40, 62, 22.0, Palette.EMBER, 0.22)
	Art.paint(bn, [Art.e(40, 62, 10, 12)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.16)
	Art.flat(bn, [Art.t(35, 66, 45, 66, 40, 50)], Palette.EMBER)
	a.put("banner", bn)
