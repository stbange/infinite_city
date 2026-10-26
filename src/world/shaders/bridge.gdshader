// Bridge deck: light metal with glowing guide strips along both edges.
shader_type spatial;
render_mode cull_back;

uniform vec3 deck_color : source_color = vec3(0.6, 0.64, 0.7);
uniform vec3 strip_color : source_color = vec3(0.3, 0.9, 1.0);

varying vec3 v_local;
varying vec3 v_scale;

void vertex() {
	v_scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	v_local = VERTEX * v_scale;
}

void fragment() {
	bool along_x = v_scale.x > v_scale.z;
	float lateral = along_x ? v_local.z : v_local.x;
	float half_width = (along_x ? v_scale.z : v_scale.x) * 0.5;
	float strip = step(half_width - 0.4, abs(lateral));
	ALBEDO = deck_color;
	ROUGHNESS = 0.45;
	METALLIC = 0.6;
	EMISSION = strip_color * strip * 2.5;
}
