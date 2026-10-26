// Floating city block: function colour, procedural lit windows, darker with depth.
// Works in Forward+ and Compatibility. Per-instance data comes from the MultiMesh:
// COLOR = function colour, INSTANCE_CUSTOM.x = per-block window seed.
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Scene-space y of the top of the roof layer (updated by CityWorld on rebase).
uniform float roof_y = 64.0;
// Metres below the roof over which daylight fades (80 layers of 64 m).
uniform float depth_falloff = 5120.0;
uniform vec3 window_warm : source_color = vec3(1.0, 0.72, 0.4);
uniform vec3 window_cool : source_color = vec3(0.5, 0.8, 1.0);
uniform float floor_height = 4.0;
uniform float bay_width = 4.5;
// Share of windows that are lit.
uniform float lit_share = 0.38;

varying vec3 v_local;
varying vec3 v_normal;
varying float v_world_y;
varying flat vec4 v_tint;
varying flat float v_seed;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	v_local = VERTEX * scale;
	v_normal = NORMAL;
	v_world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	v_tint = COLOR;
	v_seed = INSTANCE_CUSTOM.x;
}

void fragment() {
	float depth = max(roof_y - v_world_y, 0.0);
	float openness = exp(-depth / depth_falloff);
	float side = 1.0 - step(0.5, abs(v_normal.y));
	float top = step(0.5, v_normal.y);

	// Facade grid: one window per bay and floor on the side faces.
	float u = abs(v_normal.x) > 0.5 ? v_local.z : v_local.x;
	vec2 grid = vec2(u, v_local.y) / vec2(bay_width, floor_height);
	vec2 id = floor(grid);
	vec2 f = fract(grid);
	float window = step(0.16, f.x) * step(f.x, 0.84) * step(0.3, f.y) * step(f.y, 0.8) * side;
	// Integer face id: hashing raw interpolated values would flicker inside a window.
	float face_seed = floor(v_seed * 997.0) + round(v_normal.x) * 13.0 + round(v_normal.z) * 29.0;
	float lit = step(1.0 - lit_share, hash21(id + face_seed));
	float warm = step(0.3, hash21(id * 1.7 + face_seed + 5.0));
	vec3 glow = mix(window_cool, window_warm, warm);

	// Fade the window grid out where it gets smaller than a few pixels (no shimmering);
	// far facades show the average glow instead.
	vec2 footprint = fwidth(grid);
	float detail = clamp(1.5 - max(footprint.x, footprint.y) * 4.0, 0.0, 1.0);
	float window_area = 0.68 * 0.5;

	// Roof panels on top faces.
	vec2 panels = fract(v_local.xz / 8.0);
	float seam = step(0.94, max(panels.x, panels.y)) * top * detail;

	vec3 shade = v_tint.rgb * mix(0.4, 1.0, openness);
	vec3 glass = shade * 0.35;
	vec3 facade = mix(shade, glass, window * detail);
	vec3 far_facade = mix(shade, glass, window_area * side);
	vec3 albedo = mix(far_facade, facade, detail);
	albedo *= 1.0 - seam * 0.3;
	albedo *= mix(1.0, 0.82, top);

	float intensity = mix(1.7, 1.1, openness);
	vec3 near_glow = glow * window * lit;
	vec3 far_glow = mix(window_cool, window_warm, 0.7) * window_area * lit_share * side;
	ALBEDO = albedo;
	ROUGHNESS = mix(0.75, 0.2, window * detail);
	METALLIC = 0.2;
	// Faint bounce light from the windows all around, so deep facades stay readable.
	vec3 bounce = v_tint.rgb * (1.0 - openness) * 0.06;
	EMISSION = mix(far_glow, near_glow, detail) * intensity + bounce;
}
