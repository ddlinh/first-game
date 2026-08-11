extends Node
## Global palette and display constants shared across every scene.
## Autoloaded first so Assets can reference these colors while baking sprites.

# --- Display scaling ---
# Storybook/vector art: sprites are baked smooth at 2x their on-screen size
# (for crispness when the camera zooms in) and drawn back down at PX = 0.5 with
# a linear filter. CELL is one village grid cell in on-screen pixels.
# Invariant kept from the old pixel build: CELL == TILE * PX == 48.
const PX := 0.5
const TILE := 96
const CELL := TILE * PX  # 48

# --- 2.5D ground plane ("Hades" camera) ---
# The world is simulated on a flat XY plane but *presented* as a floor tilted away
# from the camera: every ground distance along Y is drawn compressed by SQUASH,
# while actors stay upright, un-squashed billboards standing on it. See Iso.
#   ground cell  = CELL x CELL   (simulation)
#   screen cell  = CELL x CELL_Y (what you see)
const SQUASH := 0.625
const CELL_Y := CELL * SQUASH   # 30.0

# Ground tiles are baked already-squashed (TILE_W x TILE_H, drawn CELL x CELL_Y),
# but the grids place cells a full CELL apart on BOTH axes. Drawing a squashed
# tile into a square cell leaves a gap under every row, so ground sprites take an
# anisotropic scale: PX across, PX/SQUASH down, which stretches the CELL_Y-tall
# texture back up to fill the whole CELL-tall cell. Circles stay circles because
# only the flat floor art is stretched, never an actor or a collider.
const TILE_SX := PX             # 0.5
const TILE_SY := PX / SQUASH    # 0.8

# Upright cast billboards (hero, survivors, husks) draw a touch smaller than the
# environment so the world reads at a Hades remove rather than a chibi close-up.
# One knob, applied on top of PX wherever a body sprite is built.
const ACTOR_SCALE := 0.68

# Ground textures are baked at 2x their on-screen footprint, already in the
# squashed aspect, so they draw at uniform PX scale with no per-sprite squashing.
const TILE_W := 96              # -> CELL   (48 px) on screen
const TILE_H := 60              # -> CELL_Y (30 px) on screen

# How tall a wall block's visible front face is, in on-screen px. Its collider is
# extended by the same amount so actors can never stand "inside" the drawn face.
const WALL_H := 22.0
# Texture-space height of that face (baked at 2x, hence the PX division).
const WALL_H_TEX := WALL_H / PX  # 44

# --- Warm surface (village) palette ---
const EMBER   := Color("ff6b35")
const EMBER_D := Color("c24e22")
const AMBER   := Color("f7c59f")
const GOLD    := Color("ffb703")
const TEAL    := Color("2ec4b6")
const SPROUT  := Color("38b000")
const SOIL    := Color("6b4a2b")
const SOIL_D  := Color("4f3620")
const GRASS   := Color("4d7a3a")
const GRASS_D := Color("3d6330")
const WOOD    := Color("8a5a34")
const WOOD_D  := Color("5f3d22")
const ROOF    := Color("47342a")
const STONE   := Color("9aa1ad")
const STONE_D := Color("6d7481")
const IRON    := Color("c2cad6")
const SKIN    := Color("f2c9a0")
const HAIR    := Color("3a2a20")
const WHITE   := Color("f5efe1")
const BLACK   := Color("161119")
const BLOOD   := Color("c8402f")

# --- Cold subterranean (dungeon) palette ---
const COLD_FLOOR  := Color("2a2f3c")
const COLD_FLOOR2 := Color("222633")
const COLD_WALL   := Color("14171f")
const STEEL       := Color("47536b")
const INDIGO      := Color("2b2440")
const HUSK        := Color("5b6472")
const HUSK_D      := Color("3c4350")
const HUSK_SKIN   := Color("9aa0ab")

# --- GWI (Global Warmth Index) tint endpoints, cold -> warm ---
const GWI_COLD := Color("5a6a86")
const GWI_WARM := Color("ffb26b")

# ===========================================================================
# Storybook / "Cult of the Lamb"-style palette (vector baker). Bold flat fills,
# thick dark outlines, soft rounded shapes, moody warm-dark ambience.
# ===========================================================================
const OUTLINE  := Color("241a15")   # thick sticker outline (warm near-black)
const OUTLINE2 := Color("3a2a20")   # softer inner line

# Cat hero: warm ginger with a cream belly and an ember scarf.
const CAT      := Color("e8964e")
const CAT_D    := Color("c46f34")
const CAT_BELLY:= Color("f5dcb4")
const CAT_EAR  := Color("f2b98c")   # inner ear / nose pink-tan

# Cast + world tones
const CREAM    := Color("f2e6cf")
const BONE     := Color("e8dcc0")
const RED      := Color("c8322b")
const RED_D    := Color("8f2420")
const LEAF     := Color("6aa84a")   # brighter foliage accent
const MOSS     := Color("46683a")
const NIGHT    := Color("11161a")   # deep ambient shadow

# Warmer, moodier ground/wood than the pixel build used
const GRASS2   := Color("55823f")
const GRASS2_D := Color("41652f")
const DIRT     := Color("6a4a30")
const DIRT_D   := Color("533826")
const WOOD2    := Color("946438")
const WOOD2_D  := Color("6a4526")
const ROOF2    := Color("8f3f34")   # warm red-brown thatch/roof
const ROOF2_D  := Color("6e2f27")
const STONE2   := Color("8b93a1")
const STONE2_D := Color("5f6675")

# Dungeon husk creature (spooky critter)
const SHADOW   := Color("3b3350")
const SHADOW_D := Color("272138")
const EYE_RED  := Color("ff4d4d")

# ===========================================================================
# 2.5D presentation palette. The scene is lit, not flat: a dark ambient wash
# (AMBIENT_*) is multiplied over the world and warm point lights add back into
# it, so these tones are chosen to survive that squeeze. Deep plum/ink darks,
# gold key light, wine and cyan accents — a Hades-style contrast ladder.
# ===========================================================================
const VOID      := Color("06050a")   # the nothing beyond a room's edge
const INK       := Color("110d17")   # deepest in-world dark
const PLUM      := Color("241732")   # cool shadow mass
const PLUM_L    := Color("39264d")   # lit plum (wall top faces)
const WINE      := Color("6d1f2e")   # blood/banner accent
const TORCH     := Color("ff8c3a")   # flame body
const TORCH_L   := Color("ffd08a")   # flame core
const GOLD_L    := Color("ffe1a3")   # brightest highlight / rim light
const CYAN      := Color("53e0d8")   # cold arcane accent (portal, rifts)
const CYAN_D    := Color("1f7f7d")
const MOSS_L    := Color("7fb355")   # lit foliage
const EARTH     := Color("4a3324")   # platform rim / cliff face
const EARTH_D   := Color("2e1f16")

# Ambient multiplier per layer (CanvasModulate). White = unlit/flat.
const AMBIENT_VILLAGE := Color("6a5f7a")   # dusk; bonfire + windows warm it back
const AMBIENT_DUNGEON := Color("403c58")   # darker near-black so braziers + hero light carve real islands (QA F-24)

# Rim-light tint painted along the top-left of actor silhouettes so they lift off
# the dark floor the way Hades' cel-shaded cast does.
const RIM       := Color("ffd9a8")

# --- UI (ornate HUD chrome) ---
const UI_BG     := Color("13101c")   # panel interior
const UI_BG2    := Color("1d1729")   # panel interior, lighter band
const UI_EDGE   := Color("c9a227")   # gilded border
const UI_EDGE_L := Color("f0d47a")   # border highlight
const UI_EDGE_D := Color("6b4f12")   # border shade
const UI_TEXT   := Color("f6e7cd")   # body copy
const UI_DIM    := Color("9a8b78")   # disabled / secondary copy
const UI_HP     := Color("e0413a")   # health fill
const UI_HP_D   := Color("6d1a19")   # health trough
