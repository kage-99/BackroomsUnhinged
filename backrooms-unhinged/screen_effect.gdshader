shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;

const float curvature = 9.0;
const float vignette_multiplier = 0.75;

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;

uniform float aberration_x : hint_range(-5.0, 5.0) = 0.4;
uniform float aberration_y : hint_range(-5.0, 5.0) = 0.4;
void fragment() {
	vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
	vec2 uv_offset = centered_uv.yx / curvature;
	vec2 warped_uv = centered_uv + centered_uv * uv_offset * uv_offset;
	vec3 cutoff = vec3(step(abs(warped_uv.x), 1.0) * step(abs(warped_uv.y), 1.0));
	vec3 scanlines = vec3(sin(2.0 * warped_uv.y * 180.0) * 0.1 + 0.9);
	vec3 vignette = vec3(length(pow(abs(centered_uv), vec2(4.0)) / 3.0));
	
	vec3 screen_color = textureLod(screen_texture, (warped_uv + 1.0) / 2.0, 0.2).rgb * cutoff * scanlines;
	screen_color -= vignette * vignette_multiplier;

	vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
	vec2 offset = vec2(aberration_x * pixel_size.x, aberration_y * pixel_size.y);
	
	vec3 final_color;
	final_color.r = texture(SCREEN_TEXTURE, SCREEN_UV + offset).r;
	final_color.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
	final_color.b = texture(SCREEN_TEXTURE, SCREEN_UV - offset).b;
	
	//COLOR.rgb = final_color;
	COLOR = vec4(screen_color, 1.0);
}