shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D source_texture : source_color, filter_linear_mipmap_anisotropic, hint_default_white;
uniform vec4 source_tint : source_color = vec4(1.0);
uniform vec4 paint_color : source_color = vec4(0.08, 0.25, 0.45, 1.0);
void fragment() {
	vec3 original = texture(source_texture, UV).rgb * source_tint.rgb;
	float hi = max(max(original.r, original.g), original.b);
	float lo = min(min(original.r, original.g), original.b);
	float paint = smoothstep(0.004, 0.03, hi-lo);
	ALBEDO = mix(original, paint_color.rgb * mix(0.55, 1.0, hi), paint);
	METALLIC = mix(0.15, 0.45, paint);
	ROUGHNESS = mix(0.42, 0.23, paint);
	CLEARCOAT = paint * 0.9;
	CLEARCOAT_ROUGHNESS = 0.12;
}
