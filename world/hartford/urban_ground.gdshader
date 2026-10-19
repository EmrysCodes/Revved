shader_type spatial;
uniform sampler2D pavement : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world_position.xz;
	float west=step(-1840.0,p.x)*(1.0-step(490.0,p.x))*step(-1360.0,p.y)*(1.0-step(1460.0,p.y));
	float east=step(990.0,p.x)*(1.0-step(1440.0,p.x))*step(-420.0,p.y)*(1.0-step(1440.0,p.y));
	float park=1.0-smoothstep(0.85,1.05,length((p-vec2(-565.0,190.0))/vec2(310.0,165.0)));
	// Compact paved downtown; highway buffers and outlying vacant parcels are meadow.
	float core=1.0-smoothstep(0.6,1.0,length((p-vec2(-320.0,100.0))/vec2(760.0,690.0)));
	float east_core=1.0-smoothstep(0.45,1.0,length((p-vec2(1190.0,480.0))/vec2(220.0,520.0)));
	float urban=max(west*core,east*east_core)*(1.0-park);
	vec3 concrete=texture(pavement,p/9.0).rgb*vec3(0.65,0.63,0.59);
	float noise=0.96+0.04*sin(p.x*0.17)*sin(p.y*0.13);
	float meadow=0.98+0.02*sin(p.x*0.073+sin(p.y*0.041))*sin(p.y*0.083);
	ALBEDO=mix(vec3(0.17,0.24,0.105)*noise*meadow,concrete,urban);
	ROUGHNESS=0.94;
}
