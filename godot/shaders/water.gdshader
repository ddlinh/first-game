shader_type canvas_item;
// A living stream: a slow downstream current plus rippling glints, so the water
// reads as flowing rather than a flat teal slab. The sprite must have
// texture_repeat enabled so the scrolled UV wraps seamlessly within each tile.
uniform float flow = 0.05;      // current speed (UV/sec)
uniform float wobble = 0.014;   // ripple amount
uniform vec4 glint_col : source_color = vec4(0.7, 0.9, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	uv.y -= TIME * flow;                                  // flow downstream
	uv.x += sin((UV.y * 14.0) + TIME * 1.6) * wobble;     // side-to-side ripple
	vec4 c = texture(TEXTURE, uv);
	// Two crossing highlight bands drifting over the surface.
	float glint = sin((UV.y * 9.0) - TIME * 2.2) * 0.5 + sin((UV.x * 11.0) + TIME * 1.1) * 0.5;
	c.rgb += glint_col.rgb * max(glint, 0.0) * 0.07;
	COLOR = c;
}
