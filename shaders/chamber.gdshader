shader_type canvas_item;
render_mode unshaded;

// The chamber's whole look, driven entirely by the simulated LightField.
//
// The field arrives as a tiny texture — one texel per cell:
//   r = light level 0..1     g = wall mask     b = exit mask
// Linear filtering between texels is what turns a grid of numbers into soft
// pools of light, so the picture is smooth while the rules stay square.

uniform sampler2D light_tex : filter_linear, repeat_disable;
uniform vec2 grid_size = vec2(40.0, 22.0);
uniform float shade_max = 0.35;
uniform float time_seconds = 0.0;
uniform float dread = 0.0;  // 0 safe .. 1 scattering: the room reacts to her

uniform vec3 void_color : source_color = vec3(0.031, 0.031, 0.059);
uniform vec3 shade_color : source_color = vec3(0.071, 0.086, 0.157);
uniform vec3 rim_color : source_color = vec3(0.243, 0.196, 0.235);
uniform vec3 warm_color : source_color = vec3(1.0, 0.867, 0.596);
uniform vec3 wall_color : source_color = vec3(0.063, 0.055, 0.094);
uniform vec3 wall_lit_color : source_color = vec3(0.451, 0.353, 0.294);
uniform vec3 exit_color : source_color = vec3(0.290, 0.949, 0.780);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Ordered dithering: the gradient between palette bands breaks into pixel
// stipple instead of a smooth ramp, which is what makes it read as pixel art.
float bayer(vec2 pixel) {
	vec2 p = floor(mod(pixel, 4.0));
	int index = int(p.x + p.y * 4.0);
	float m[16] = {
		0.0, 8.0, 2.0, 10.0,
		12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0,
		15.0, 7.0, 13.0, 5.0
	};
	return m[index] / 16.0;
}

void fragment() {
	vec4 sampled = texture(light_tex, UV);
	float level = sampled.r;
	float wall = sampled.g;
	float exit_mask = sampled.b;

	vec2 cell = UV * grid_size;
	vec2 pixel = floor(cell * 16.0);

	// Lights breathe. A candle that never flickers is a number, not a flame.
	float flicker = 0.94 + 0.06 * sin(time_seconds * 7.3 + hash(floor(cell)) * 24.0);
	level *= mix(1.0, flicker, step(0.02, level));

	level = clamp(level + (bayer(pixel) - 0.5) * 0.07, 0.0, 1.0);

	vec3 color;
	if (level <= shade_max) {
		color = mix(void_color, shade_color, level / shade_max);
	} else {
		float t = (level - shade_max) / (1.0 - shade_max);
		color = mix(rim_color, warm_color, t * t);
	}

	// Dust hanging in the beams: only visible where there is light to catch it.
	float mote = hash(floor(pixel * 0.5) + floor(vec2(time_seconds * 1.7)));
	color += vec3(0.10, 0.09, 0.06) * step(0.995, mote) * smoothstep(shade_max, 1.0, level);

	// Walls are lit by whatever spills onto them, so a room has depth without
	// a single hand-placed highlight.
	vec3 stone = mix(wall_color, wall_lit_color, smoothstep(0.1, 0.9, level));
	stone *= 0.92 + 0.08 * hash(floor(pixel));
	color = mix(color, stone, wall);

	// The way out pulses, slowly, and only in the dark where you can see it.
	float pulse = 0.5 + 0.5 * sin(time_seconds * 2.2);
	color = mix(color, exit_color, exit_mask * (0.25 + 0.35 * pulse));

	// As she burns away the frame closes in and the colour drains out.
	float vignette = 1.0 - length(UV - vec2(0.5)) * (0.55 + 0.75 * dread);
	color *= clamp(vignette, 0.0, 1.0);
	color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))), dread * 0.55);

	COLOR = vec4(color, 1.0);
}
