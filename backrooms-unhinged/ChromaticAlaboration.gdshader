shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;

uniform float aberration_x : hint_range(-5.0, 5.0) = 0.4;
uniform float aberration_y : hint_range(-5.0, 5.0) = 0.4;

void fragment() {
	vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
	vec2 offset = vec2(aberration_x * pixel_size.x, aberration_y * pixel_size.y);
	
	vec3 final_color;
	final_color.r = texture(SCREEN_TEXTURE, SCREEN_UV + offset).r;
	final_color.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
	final_color.b = texture(SCREEN_TEXTURE, SCREEN_UV - offset).b;
	
	COLOR.rgb = final_color;
}