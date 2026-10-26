// Outer shell of an entered block: dark concrete like the block shader, a glowing roofline in
// the block's function colour, and sunlight only on the uppermost layer and only on surfaces
// facing away from the block (so the inside of the outer walls stays dark).
// Per instance: COLOR = function colour, INSTANCE_CUSTOM.x = roof height relative to the node
// (the cell centre), so one material serves every entered block.
shader_type spatial;
render_mode cull_back;

// Scene-space y of the bottom of the roof layer (updated by CityWorld on rebase).
uniform float roof_bottom_y = 0.0;
uniform float sun_fade = 16.0;
uniform float skylight = 0.12;
uniform vec3 base_color : source_color = vec3(0.075, 0.08, 0.095);

varying vec3 v_world;
varying float v_outward;
varying float v_height;
varying float v_up;
varying flat vec4 v_tint;
varying flat float v_top;

float sun_mask(float y) {
	return smoothstep(-sun_fade, sun_fade, y - roof_bottom_y);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_outward = dot(n, v_world - NODE_POSITION_WORLD);
	v_height = v_world.y - NODE_POSITION_WORLD.y;
	v_up = n.y;
	v_tint = COLOR;
	v_top = INSTANCE_CUSTOM.x;
}

void fragment() {
	float outside = step(0.0, v_outward);
	float side = 1.0 - step(0.5, abs(v_up));
	float roofline = step(v_top - 0.6, v_height) * step(v_height, v_top + 0.01) * side * outside;
	vec3 albedo = mix(base_color, v_tint.rgb, 0.12) * mix(1.0, 1.35, step(0.5, v_up));
	ALBEDO = albedo;
	ROUGHNESS = 0.8;
	METALLIC = 0.1;
	EMISSION = v_tint.rgb * roofline * 2.2 + albedo * skylight * sun_mask(v_world.y) * outside;
}

void light() {
	float visible = LIGHT_IS_DIRECTIONAL ? sun_mask(v_world.y) * step(0.0, v_outward) : 1.0;
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	DIFFUSE_LIGHT += ndl * ATTENUATION * LIGHT_COLOR / PI * visible;
}
