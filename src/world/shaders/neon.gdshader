// Neon signs and lamp heads. Per instance: COLOR = neon colour,
// INSTANCE_CUSTOM = (pattern seed, flicker flag, solid flag, 0).
// Signs show a glowing tube border and hashed glyph strokes; solid instances glow evenly.
shader_type spatial;
render_mode cull_back;

varying flat vec4 v_color;
varying flat vec4 v_custom;
varying vec3 v_local;
varying flat vec3 v_scale;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void vertex() {
	v_scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	v_local = VERTEX * v_scale;
	v_color = COLOR;
	v_custom = INSTANCE_CUSTOM;
}

void fragment() {
	// The panel is thin along x or z; read the pattern on its broad faces.
	bool thin_x = v_scale.x < v_scale.z;
	vec2 size = thin_x ? v_scale.zy : v_scale.xy;
	vec2 p = (thin_x ? v_local.zy : v_local.xy) + size * 0.5;

	float edge = min(min(p.x, size.x - p.x), min(p.y, size.y - p.y));
	float border = step(edge, 0.32) * step(0.14, edge);

	vec2 g = (p - 0.55) / 0.85;
	vec2 cell = floor(g);
	vec2 f = fract(g);
	float h = hash21(cell + v_custom.x * 91.7);
	float inside = step(0.55, edge);
	float bar_h = step(0.42, f.y) * step(f.y, 0.58) * step(0.15, f.x) * step(f.x, 0.85) * step(0.35, h);
	float bar_v = step(0.42, f.x) * step(f.x, 0.58) * step(0.15, f.y) * step(f.y, 0.85) * step(0.5, fract(h * 7.3));
	float bar_t = step(0.8, f.y) * step(f.y, 0.94) * step(0.15, f.x) * step(f.x, 0.85) * step(0.6, fract(h * 13.1));
	float glyph = clamp(bar_h + bar_v + bar_t, 0.0, 1.0) * inside;

	float flicker = 1.0;
	if (v_custom.y > 0.5) {
		float t = floor(TIME * 9.0 + v_custom.x * 50.0);
		flicker = step(0.2, hash21(vec2(t, v_custom.x * 17.0)));
	}
	float pattern = max(border, glyph) * 3.2 + 0.18;
	float intensity = mix(pattern, 3.0, v_custom.z) * flicker;
	ALBEDO = vec3(0.02);
	ROUGHNESS = 0.4;
	EMISSION = v_color.rgb * intensity;
}
