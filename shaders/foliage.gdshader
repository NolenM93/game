shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha, diffuse_burley, specular_schlick_ggx;

uniform vec4 root_color : source_color = vec4(0.16, 0.28, 0.12, 1.0);
uniform vec4 tip_color : source_color = vec4(0.42, 0.62, 0.24, 1.0);
uniform float wind = 0.12;
uniform float cutoff = 0.42;

varying vec3 tint;
varying vec3 world_pos;

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = UV.y * UV.y;
	float sway = sin(TIME * 1.7 + origin.x * 0.37 + origin.z * 0.29) * wind * h;
	float sway2 = cos(TIME * 1.25 + origin.z * 0.41) * wind * 0.65 * h;
	VERTEX.x += sway;
	VERTEX.z += sway2;
	tint = COLOR.rgb;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float nx = abs(UV.x - 0.5) * 2.0;
	float blade = 1.0 - smoothstep(0.55, 1.0, nx + UV.y * 0.35);
	float speckle = fract(sin(dot(world_pos.xz, vec2(19.1, 47.7))) * 43758.5);
	if (blade < cutoff) {
		discard;
	}
	vec3 col = mix(root_color.rgb, tip_color.rgb, UV.y);
	col *= mix(vec3(0.82), vec3(1.08, 1.04, 0.9), speckle);
	vec3 shade = tint;
	if (dot(shade, shade) < 0.02) {
		shade = vec3(1.0);
	}
	ALBEDO = col * shade;
	ROUGHNESS = mix(0.82, 0.55, UV.y);
	SPECULAR = 0.18;
	BACKLIGHT = vec3(0.45, 0.62, 0.22);
}
