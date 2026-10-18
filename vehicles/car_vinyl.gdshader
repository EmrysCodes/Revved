shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.1, 0.1, 0.8, 1.0);
uniform vec4 vinyl_color : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform float base_metallic = 0.35;
uniform float base_roughness = 0.32;
uniform int vinyl_style = 0;
uniform mat4 mesh_to_car = mat4(1.0);
varying vec3 car_position;
varying vec3 car_normal;

void vertex() {
	car_position = (mesh_to_car * vec4(VERTEX, 1.0)).xyz;
	car_normal = normalize(mat3(mesh_to_car) * NORMAL);
}

void fragment() {
	float mask = 0.0;
	if (vinyl_style == 1 && car_normal.y > 0.55 && car_position.z < -0.65 && car_position.z > -1.88 && car_position.y > 0.40) {
		mask = 1.0 - smoothstep(0.055, 0.065, abs(abs(car_position.x) - 0.22));
	}
	if (vinyl_style == 2 && abs(car_normal.x) > 0.7 && car_position.z > -0.8 && car_position.z < 0.95) {
		float center_height = 0.47 + 0.06 * (car_position.z + 0.8);
		mask = 1.0 - smoothstep(0.027, 0.035, abs(car_position.y - center_height));
	}
	ALBEDO = mix(base_color.rgb, vinyl_color.rgb, mask);
	METALLIC = mix(base_metallic, 0.05, mask);
	ROUGHNESS = mix(base_roughness, 0.5, mask);
}
