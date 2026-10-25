shader_type spatial;
uniform sampler2D coverage : filter_linear_mipmap, repeat_disable;
uniform sampler2D asphalt : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D pavement : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec2 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
 vec2 mask_uv=(world+vec2(2250.0,1900.0))/vec2(4500.0,3800.0);
 vec2 mask=texture(coverage,mask_uv).rg;
 vec3 lawn=mix(texture(grass,world/3.0).rgb,texture(grass,world/19.0).rgb,.18)*vec3(.62,.65,.56);
 vec3 walk=texture(pavement,world/8.0).rgb*vec3(.7,.7,.68);
 vec3 road=texture(asphalt,world/8.0).rgb;
 ALBEDO=mix(mix(lawn,walk,mask.g),road,mask.r);
 ROUGHNESS=.92;METALLIC=0.0;
}
