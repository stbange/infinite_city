// Floating city block in cyberpunk style: dark concrete, the block's function colour as glowing
// roofline/corner strips, world-aligned lit windows (4 m floors and bays), and sunlight that
// only reaches the uppermost layer of the city (mask mirrors Atmosphere.sun_visibility()).
// Per instance: COLOR = function colour, INSTANCE_CUSTOM.x = per-block seed.
shader_type spatial;
render_mode cull_back;

// Scene-space y of the bottom of the roof layer (updated by CityWorld on rebase).
uniform float roof_bottom_y = 0.0;
uniform float sun_fade = 16.0;
uniform float skylight = 0.12;
uniform float floor_height = 4.0;
uniform float bay_width = 4.0;
uniform float lit_share = 0.22;
uniform vec3 base_color : source_color = vec3(0.075, 0.08, 0.095);

varying vec3 v_world;
varying vec3 v_normal;
varying flat vec3 v_min;
varying flat vec3 v_max;
varying flat vec4 v_tint;
varying flat float v_seed;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float sun_mask(float y) {
	return smoothstep(-sun_fade, sun_fade, y - roof_bottom_y);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_min = (MODEL_MATRIX * vec4(-0.5, -0.5, -0.5, 1.0)).xyz;
	v_max = (MODEL_MATRIX * vec4(0.5, 0.5, 0.5, 1.0)).xyz;
	v_normal = NORMAL;
	v_tint = COLOR;
	v_seed = INSTANCE_CUSTOM.x;
}

void fragment() {
	float side = 1.0 - step(0.5, abs(v_normal.y));
	float top = step(0.5, v_normal.y);
	bool x_face = abs(v_normal.x) > 0.5;

	// World-aligned window grid, indexed from the block's own corner so the pattern is stable
	// when the floating origin moves (it moves in whole multiples of 4 m).
	float u = x_face ? v_world.z : v_world.x;
	float u_min = x_face ? v_min.z : v_min.x;
	float u_max = x_face ? v_max.z : v_max.x;
	vec2 grid = vec2(u / bay_width, v_world.y / floor_height);
	vec2 id = floor(grid) - floor(vec2(u_min / bay_width, v_min.y / floor_height));
	vec2 f = fract(grid);
	float window = step(0.3, f.x) * step(f.x, 0.7) * step(0.3, f.y) * step(f.y, 0.72) * side;
	float face_id = round(v_normal.x) * 13.0 + round(v_normal.z) * 29.0;
	float face_seed = floor(v_seed * 997.0) + face_id;
	float lit = step(1.0 - lit_share, hash21(id + face_seed));
	float hue = hash21(id * 1.7 + face_seed + 5.0);
	vec3 glow = hue < 0.62 ? vec3(1.0, 0.62, 0.3) : (hue < 0.82 ? vec3(0.4, 0.72, 1.0) : (hue < 0.93 ? vec3(1.0, 0.28, 0.7) : vec3(0.3, 1.0, 0.8)));
	glow *= mix(0.45, 1.0, hash21(id * 3.1 + face_seed));

	// Fade the window grid where it gets smaller than a few pixels; far facades glow on average.
	vec2 footprint = fwidth(grid);
	float detail = clamp(1.5 - max(footprint.x, footprint.y) * 4.0, 0.0, 1.0);
	float window_area = 0.4 * 0.42;

	// Accent strips in the function colour: roofline band on every block, corner strips on half.
	float edge = min(u - u_min, u_max - u);
	float corner = step(edge, 0.35) * side * step(0.5, v_seed);
	float roofline = step(v_max.y - v_world.y, 0.6) * side;
	float accent = max(corner, roofline);

	vec2 panels = fract(v_world.xz / 8.0);
	float seam = step(0.94, max(panels.x, panels.y)) * top * detail;

	vec3 shade = mix(base_color, v_tint.rgb, 0.12) * mix(1.0, 1.35, top) * (1.0 - seam * 0.35);
	vec3 glass = vec3(0.02, 0.022, 0.03);
	vec3 albedo = mix(mix(shade, glass, window_area * side), mix(shade, glass, window), detail);
	vec3 near_glow = glow * window * lit;
	vec3 far_glow = vec3(0.9, 0.62, 0.5) * window_area * lit_share * side * 0.75;

	ALBEDO = albedo;
	ROUGHNESS = mix(0.8, 0.12, window * detail);
	METALLIC = 0.1;
	EMISSION = mix(far_glow, near_glow, detail) * 1.1
			+ v_tint.rgb * accent * 2.2
			+ albedo * skylight * sun_mask(v_world.y);
}

void light() {
	float visible = LIGHT_IS_DIRECTIONAL ? sun_mask(v_world.y) : 1.0;
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	DIFFUSE_LIGHT += ndl * ATTENUATION * LIGHT_COLOR / PI * visible;
	vec3 half_vector = normalize(VIEW + LIGHT);
	float shininess = mix(8.0, 128.0, 1.0 - ROUGHNESS);
	float spec = pow(max(dot(NORMAL, half_vector), 0.0), shininess) * (1.0 - ROUGHNESS);
	SPECULAR_LIGHT += spec * ndl * ATTENUATION * LIGHT_COLOR * 0.3 * visible;
}
