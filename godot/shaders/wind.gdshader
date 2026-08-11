shader_type canvas_item;
// Gentle wind sway for feet-anchored foliage (bushes, reeds, flowers, trees). The
// base of the sprite (UV.y≈1) stays planted; the crown (UV.y≈0) leans with a gust
// that travels across the world, so the whole field ripples together instead of
// each plant wobbling on its own. Lighting is untouched — only the geometry moves.
uniform float amplitude = 10.0;   // local (texture) px of lean at the very top
uniform float speed = 1.25;
uniform float wave_len = 0.016;   // spatial frequency of the travelling gust

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float gust = 0.65 + 0.35 * sin(TIME * 0.4 + world.x * 0.004);
	float phase = TIME * speed + world.x * wave_len + world.y * wave_len * 0.6;
	float lean = sin(phase) * amplitude * gust;
	float up = clamp(1.0 - UV.y, 0.0, 1.0);   // 0 at the feet, 1 at the crown
	VERTEX.x += lean * up * up;                // ease so only the top really travels
}
