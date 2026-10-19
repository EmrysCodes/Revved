shader_type spatial;
uniform sampler2D pavement : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world_position.xz;
	float west=step(-1840.0,p.x)*(1.0-step(490.0,p.x))*step(-1360.0,p.y)*(1.0-step(1460.0,p.y));
	float east=step(990.0,p.x)*(1.0-step(1440.0,p.x))*step(-420.0,p.y)*(1.0-step(1440.0,p.y));
	float park=1.0-smoothstep(0.85,1.05,length((p-vec2(-565.0,190.0))/vec2(310.0,165.0)));
	float urban=max(west,east)*(1.0-park);
	vec3 concrete=texture(pavement,p/9.0).rgb*vec3(0.65,0.63,0.59);
	float noise=0.96+0.04*sin(p.x*0.17)*sin(p.y*0.13);
	ALBEDO=mix(vec3(0.20,0.27,0.17)*noise,concrete,urban);
	ROUGHNESS=0.94;
}
