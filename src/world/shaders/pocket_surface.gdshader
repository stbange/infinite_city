// Walls, floor and ceiling of a pocket space: dark panels with a glowing grid, so the size of
// the room can be read at a glance. Expects an inward-facing box mesh sized in metres.
shader_type spatial;
render_mode cull_back;

uniform vec3 base_color : source_color = vec3(0.16, 0.15, 0.19);
uniform vec3 line_color : source_color = vec3(1.0, 0.75, 0.35);
uniform float spacing = 8.0;
uniform float line_strength = 0.9;

varying vec3 v_local;
varying vec3 v_normal;

void vertex() {
	v_local = VERTEX;
	v_normal = NORMAL;
}

void fragment() {
	vec3 n = abs(v_normal);
	vec2 q = n.y > 0.5 ? v_local.xz : (n.x > 0.5 ? v_local.zy : v_local.xy);
	vec2 gp = q / spacing;
	vec2 g = abs(fract(gp - 0.5) - 0.5) / max(fwidth(gp), vec2(1e-4));
	float line = 1.0 - clamp(min(g.x, g.y), 0.0, 1.0);
	float floor_tint = step(0.5, v_normal.y);
	ALBEDO = base_color * mix(1.0, 1.4, floor_tint);
	ROUGHNESS = mix(0.7, 0.25, floor_tint);
	METALLIC = 0.3;
	EMISSION = line_color * line * line_strength;
}
