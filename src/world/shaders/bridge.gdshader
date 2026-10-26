// Bridge deck: dark wet metal with glowing guide strips along both edges; sunlight only on
// the uppermost layer (same mask as the block shader).
shader_type spatial;
render_mode cull_back;

uniform float roof_bottom_y = 0.0;
uniform float sun_fade = 16.0;
uniform vec3 deck_color : source_color = vec3(0.16, 0.17, 0.2);
uniform vec3 strip_color : source_color = vec3(0.2, 0.9, 1.0);

varying vec3 v_local;
varying flat vec3 v_scale;
varying vec3 v_world;

float sun_mask(float y) {
	return smoothstep(-sun_fade, sun_fade, y - roof_bottom_y);
}

void vertex() {
	v_scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	v_local = VERTEX * v_scale;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	bool along_x = v_scale.x > v_scale.z;
	float lateral = along_x ? v_local.z : v_local.x;
	float half_width = (along_x ? v_scale.z : v_scale.x) * 0.5;
	float strip = step(half_width - 0.35, abs(lateral));
	ALBEDO = deck_color;
	ROUGHNESS = 0.25;
	METALLIC = 0.6;
	EMISSION = strip_color * strip * 2.2 + deck_color * 0.12 * sun_mask(v_world.y);
}

void light() {
	float visible = LIGHT_IS_DIRECTIONAL ? sun_mask(v_world.y) : 1.0;
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	DIFFUSE_LIGHT += ndl * ATTENUATION * LIGHT_COLOR / PI * visible;
	vec3 half_vector = normalize(VIEW + LIGHT);
	float spec = pow(max(dot(NORMAL, half_vector), 0.0), 64.0);
	SPECULAR_LIGHT += spec * ndl * ATTENUATION * LIGHT_COLOR * 0.5 * visible;
}
