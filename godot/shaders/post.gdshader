shader_type canvas_item;
// Single full-screen grade for the whole game — the "film stock" the 2.5D world
// is shot on. Owned by Main (one ColorRect on CanvasLayer 1, below the HUD) and
// driven by the layers through Main.set_grade().
//
// Three passes, in order:
//   1. BLOOM  — the screen texture is sampled with mipmaps, so a high textureLod
//      is a free wide blur. Keep only what is already bright and add it back, so
//      embers, forge windows and the bonfire bleed light instead of sitting flat.
//   2. GRADE  — one axis, `warm`: 0 is cold ash (desaturated, blue-shifted,
//      crushed shadows), 1 is ember radiance (saturated, gold-shifted, lifted).
//      This replaces the old gwi.gdshader; the Village drives it with the GWI.
//   3. CLOSE  — a tinted vignette that clamps down hard when cold and opens up
//      as the settlement reignites, plus a whisper of grain in the shadows so
//      the flat vector fills never look like dead plastic.

// 0 = cold ash, 1 = ember radiance. The Village feeds its GWI in here.
uniform float warm : hint_range(0.0, 1.0) = 0.35;
// Overall strength of the vignette (1 = tuned default, 0 = off).
uniform float vignette : hint_range(0.0, 1.5) = 1.0;
// Strength of the additive glow lifted off bright pixels.
uniform float bloom : hint_range(0.0, 2.0) = 0.7;
// Shadow grain amount (1 = tuned default).
uniform float grain : hint_range(0.0, 1.0) = 0.35;

// Mipmapped so textureLod() below can be used as a cheap, wide gaussian.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

// Pixels dimmer than this contribute nothing to the glow.
const float BLOOM_FLOOR = 0.42;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_tex, uv).rgb;

	// --- 1. bloom -----------------------------------------------------------
	// Three mip levels: the tight one keeps a hot core welded to its source, the
	// wide ones throw the halo. Thresholding on the brightest CHANNEL (not on
	// luminance) means a saturated orange ember blooms as readily as white.
	vec3 core = textureLod(screen_tex, uv, 2.0).rgb;
	vec3 tight = textureLod(screen_tex, uv, 4.0).rgb;
	vec3 wide = textureLod(screen_tex, uv, 6.0).rgb;
	vec3 soft = core * 0.30 + tight * 0.42 + wide * 0.28;
	float peak = max(max(soft.r, soft.g), soft.b);
	float keep = smoothstep(BLOOM_FLOOR, 0.90, peak);
	// Warm scenes glow more: a lit village should feel hazy with firelight.
	col += soft * keep * bloom * (0.85 + 0.85 * warm);

	// --- 2. grade -----------------------------------------------------------
	float lum = dot(col, vec3(0.299, 0.587, 0.114));

	// Cold: bleed the colour out, crush the shadows, and let the little that is
	// left drift blue — ash under a dead sky, not a teal filter.
	vec3 cold = mix(vec3(lum), col, 0.34);
	cold = pow(max(cold, vec3(0.0)), vec3(1.20));
	cold *= vec3(0.78, 0.86, 1.06);
	cold += vec3(0.004, 0.010, 0.028) * (1.0 - clamp(lum, 0.0, 1.0));

	// Warm: open the midtones, over-saturate a touch and tilt hard to gold, then
	// lift the black point so the darks read as banked coals rather than holes.
	vec3 hot = mix(vec3(lum), col, 1.10);
	hot = pow(max(hot, vec3(0.0)), vec3(0.93));
	hot *= vec3(1.14, 0.985, 0.74);
	hot += vec3(0.046, 0.020, 0.004);

	vec3 graded = mix(cold, hot, clamp(warm, 0.0, 1.0));

	// --- 3. close in --------------------------------------------------------
	// Taller-than-wide falloff, centred slightly BELOW the middle so the top of
	// the frame — where the tilted floor recedes — falls off into darkness first.
	vec2 d = uv - vec2(0.5, 0.545);
	float r = length(d * vec2(1.02, 1.32));
	float vig = smoothstep(0.76, 0.22, r);
	float amt = clamp(vignette, 0.0, 1.5) * mix(0.90, 0.58, warm);
	// The edge is dimmed, drained of colour and tinted — cold plum when dead,
	// smoked amber when lit — so saturation itself points at the centre of frame.
	vec3 edge = mix(vec3(dot(graded, vec3(0.299, 0.587, 0.114))), graded, 0.55)
		* mix(vec3(0.16, 0.16, 0.26), vec3(0.26, 0.16, 0.12), warm);
	graded = mix(edge, graded, mix(1.0, vig, amt));

	// Grain, weighted into the shadows where real film shows it.
	vec2 gp = FRAGCOORD.xy + vec2(TIME * 61.0, TIME * 43.0);
	float n = fract(sin(dot(gp, vec2(12.9898, 78.233))) * 43758.5453);
	graded += (n - 0.5) * 0.030 * grain * (1.0 - 0.65 * clamp(lum, 0.0, 1.0));

	COLOR = vec4(max(graded, vec3(0.0)), 1.0);
}
