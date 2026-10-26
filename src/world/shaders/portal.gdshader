// Doorway surface. Idle: an animated violet shimmer. Live: the portal camera's image,
// sampled at the same screen position, so the doorway looks like an opening.
shader_type spatial;
render_mode unshaded, cull_back, fog_disabled, shadows_disabled;

uniform sampler2D portal_texture : source_color, filter_linear, repeat_disable;
uniform float live = 0.0;
uniform vec3 rim_color : source_color = vec3(0.8, 0.45, 1.0);

void fragment() {
	vec2 uv = UV;
	float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float rim = smoothstep(0.06, 0.0, edge);
	float t = TIME * 0.7;
	float swirl = sin(uv.x * 11.0 + t * 3.0 + sin(uv.y * 7.0 + t)) * sin(uv.y * 8.0 - t * 2.0) * 0.5 + 0.5;
	vec3 idle = mix(vec3(0.05, 0.02, 0.12), rim_color, swirl * 0.7);
	vec3 view = texture(portal_texture, SCREEN_UV).rgb;
	ALBEDO = mix(idle, view, live) + rim_color * rim * 1.5;
}
