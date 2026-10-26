// Space above the city: black with stars and one bright light source. Below the horizon, and
// all around when deep inside the city, the endless city fades into haze (= fog colour), so
// the streaming edge blends into the sky.
shader_type sky;

uniform vec3 space_color : source_color = vec3(0.004, 0.006, 0.018);
uniform vec3 haze_color : source_color = vec3(0.42, 0.5, 0.72);
// 0 at or above the roof, 1 a few layers below it (set by CityWorld).
uniform float inside = 0.0;
uniform vec3 sun_color : source_color = vec3(1.0, 0.93, 0.78);
// Angular radius of the light source, in radians.
uniform float sun_radius = 0.035;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void sky() {
	vec3 dir = normalize(EYEDIR);

	vec3 p = dir * 240.0;
	vec3 id = floor(p);
	float star = step(0.9962, hash31(id)) * smoothstep(0.42, 0.0, length(fract(p) - 0.5));
	vec3 space = space_color + vec3(star) * (0.5 + 1.5 * hash31(id + 7.0));

	if (LIGHT0_ENABLED) {
		float d = dot(dir, LIGHT0_DIRECTION);
		float disc = smoothstep(cos(sun_radius), cos(sun_radius * 0.75), d);
		float halo = pow(max(d, 0.0), 300.0) * 1.5 + pow(max(d, 0.0), 24.0) * 0.12;
		space += sun_color * (disc * 16.0 + halo);
	}

	float below = smoothstep(0.03, -0.1, dir.y);
	float through_gap = smoothstep(0.8, 0.98, dir.y);
	float hazed = max(below, inside * (1.0 - through_gap));
	COLOR = mix(space, haze_color, hazed);
}
