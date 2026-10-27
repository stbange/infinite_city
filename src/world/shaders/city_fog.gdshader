// Heavy city fog as a full-screen pass (spec city-fog). Drawn on a quad in front of every camera
// that sees the FOG layer; it reads the depth buffer, marches along each view ray and blends the
// in-scattered fog over the frame.
// - density and colour follow the height of each sample (mirrors Atmosphere.local_density()):
//   heavy below the roof layer, thinning above the roof so the light source stays visible;
// - fog in and above the roof layer is lit by the sun, deeper fog is dark violet;
// - drifting fog banks: two octaves of periodic value noise, anchored to absolute world
//   positions through `noise_offset` (the floating origin modulo the noise period);
// - neon and lamps get their halo from the environment's glow, which runs after this pass;
// - no fog inside the entered blocks (`clear_*` boxes) or in front of the camera's near plane
//   (a portal camera's near plane sits at the far door).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, blend_mix, fog_disabled, shadows_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

// Scene-space heights of the top (roof surface) and bottom of the roof layer.
uniform float roof_top_y = 64.0;
uniform float roof_bottom_y = 0.0;
uniform float layer_height = 64.0;
// Atmosphere.local_density(): `density_above` (a light haze) in the roof layer, the heavy fog sea
// (`density_below`) from `sea_depth` layers below the roof surface down, blended over ±`sea_band`
// layers; above the roof surface the haze falls by e every `clear_layers` layers.
uniform float density_below = 0.02;
uniform float density_above = 0.0015;
uniform float clear_layers = 0.5;
uniform float sea_depth = 1.0;
uniform float sea_band = 0.5;
uniform vec3 color_below : source_color = vec3(0.15, 0.085, 0.22);
uniform vec3 color_above : source_color = vec3(0.17, 0.16, 0.27);
// Sunlit haze in and above the roof layer (sun mask of the block shader).
uniform vec3 sun_haze : source_color = vec3(0.3, 0.24, 0.27);
uniform float sun_fade = 16.0;
// Drifting fog banks.
uniform vec3 noise_offset = vec3(0.0);
uniform float noise_period = 1024.0;
uniform float bank_size = 64.0;
uniform float bank_strength = 0.9;
uniform vec3 wind = vec3(2.2, 0.35, 1.3);
uniform float max_distance = 900.0;
uniform int steps = 12;
// Boxes without fog (entered blocks), scene space; min > max disables a box.
uniform vec3 clear_min_0 = vec3(1.0);
uniform vec3 clear_max_0 = vec3(-1.0);
uniform vec3 clear_min_1 = vec3(1.0);
uniform vec3 clear_max_1 = vec3(-1.0);

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float hash3(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

// Value noise with period `period` lattice cells along every axis.
float value_noise(vec3 q, float period) {
	vec3 i = floor(q);
	vec3 f = fract(q);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float n000 = hash3(mod(i, period));
	float n100 = hash3(mod(i + vec3(1, 0, 0), period));
	float n010 = hash3(mod(i + vec3(0, 1, 0), period));
	float n110 = hash3(mod(i + vec3(1, 1, 0), period));
	float n001 = hash3(mod(i + vec3(0, 0, 1), period));
	float n101 = hash3(mod(i + vec3(1, 0, 1), period));
	float n011 = hash3(mod(i + vec3(0, 1, 1), period));
	float n111 = hash3(mod(i + vec3(1, 1, 1), period));
	return mix(mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
			mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}

float banks(vec3 p) {
	vec3 a = mod(p + noise_offset + wind * TIME, noise_period);
	float cells = noise_period / bank_size;
	float n = 0.65 * value_noise(a / bank_size, cells) + 0.35 * value_noise(a * 4.0 / bank_size, cells * 4.0);
	return clamp(1.0 + bank_strength * (2.0 * n - 1.0), 0.05, 2.0);
}

float depth_layers(float y) {
	return (roof_top_y - y) / layer_height;
}

float sea(float d) {
	return smoothstep(sea_depth - sea_band, sea_depth + sea_band, d);
}

float local_density(float y) {
	float d = depth_layers(y);
	if (d >= 0.0) {
		return mix(density_above, density_below, sea(d));
	}
	return density_above * exp(d / clear_layers);
}

vec3 local_color(float y) {
	float d = depth_layers(y);
	vec3 base = mix(color_above, color_below, sea(d));
	return base + sun_haze * smoothstep(-sun_fade, sun_fade, y - roof_bottom_y);
}

bool inside(vec3 p, vec3 lo, vec3 hi) {
	return all(greaterThan(p, lo)) && all(lessThan(p, hi));
}

// Distance along the ray at which it leaves a box it starts in (0 when it starts outside).
float exit_distance(vec3 ro, vec3 rd, vec3 lo, vec3 hi) {
	if (!inside(ro, lo, hi)) {
		return 0.0;
	}
	vec3 inv = 1.0 / max(abs(rd), vec3(1e-5)) * sign(rd + vec3(1e-7));
	vec3 t_hi = (hi - ro) * inv;
	vec3 t_lo = (lo - ro) * inv;
	vec3 t_far = max(t_hi, t_lo);
	return min(t_far.x, min(t_far.y, t_far.z));
}

// Interleaved gradient noise: per-pixel jitter of the march start, hides banding.
float ign(vec2 pixel) {
	return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
#endif
	// Both renderers use reversed Z: the near plane is at clip-space z = 1.
	vec4 near_view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, 1.0, 1.0);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	vec3 world = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	vec3 ro = CAMERA_POSITION_WORLD;
	vec3 rd = normalize(world - ro);
	float dist = min(length(world - ro), max_distance);
	float t0 = length(near_view.xyz / near_view.w);
	t0 = max(t0, exit_distance(ro, rd, clear_min_0, clear_max_0));
	t0 = max(t0, exit_distance(ro, rd, clear_min_1, clear_max_1));
	if (dist <= t0) {
		ALBEDO = vec3(0.0);
		ALPHA = 0.0;
	} else {
		float jitter = ign(FRAGCOORD.xy);
		float seg = (dist - t0) / float(steps);
		float transmittance = 1.0;
		vec3 light = vec3(0.0);
		for (int i = 0; i < steps; i++) {
			vec3 p = ro + rd * (t0 + (float(i) + jitter) * seg);
			float bank = banks(p);
			float dens = local_density(p.y) * bank;
			if (inside(p, clear_min_0, clear_max_0) || inside(p, clear_min_1, clear_max_1)) {
				dens = 0.0;
			}
			float a = exp(-dens * seg);
			// Denser banks catch a little more of the city's light.
			light += transmittance * (1.0 - a) * local_color(p.y) * (0.8 + 0.25 * bank);
			transmittance *= a;
		}
		float alpha = 1.0 - transmittance;
		ALBEDO = light / max(alpha, 1e-4);
		ALPHA = alpha;
	}
}
