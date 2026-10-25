shader_type spatial;
render_mode cull_disabled;
uniform sampler2D water_mask:filter_linear;
uniform vec4 bounds=vec4(-8192.,-12288.,9216.,11264.);
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){vec2 uv=(world.xz-bounds.xy)/(bounds.zw-bounds.xy);if(texture(water_mask,uv).r<.5)discard;float ripple=sin(world.x*1.4+TIME*.5)*sin(world.z*.7+TIME*.7);ALBEDO=vec3(.025,.065,.085)+ripple*.004;ROUGHNESS=.28;METALLIC=.12;NORMAL_MAP=vec3(.5+ripple*.04,.5,1.);}
