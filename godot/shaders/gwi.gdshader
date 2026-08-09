shader_type canvas_item;
// Global Warmth Index full-screen grade. Applied via a screen-covering ColorRect
// that samples the rendered frame and colour-grades it from cold desaturated ash
// (gwi = 0) toward warm ember radiance (gwi = 1). A vignette closes in when cold
// and opens up as the settlement reignites.

uniform float gwi : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 cold = mix(vec3(lum), col, 0.55) * vec3(0.80, 0.88, 1.10);
	vec3 warm = col * vec3(1.12, 1.02, 0.86) + vec3(0.06, 0.025, 0.0) * gwi;
	vec3 graded = mix(cold, warm, clamp(gwi, 0.0, 1.0));

	vec2 d = SCREEN_UV - vec2(0.5);
	float vig = smoothstep(0.85, 0.30, length(d));
	float vig_amt = mix(0.55, 0.16, gwi);
	graded *= mix(1.0, vig, vig_amt);

	COLOR = vec4(graded, 1.0);
}
