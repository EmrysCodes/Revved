shader_type spatial;
uniform sampler2D macro_map:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D detail_map:source_color,repeat_enable,filter_linear_mipmap_anisotropic;
uniform vec4 bounds=vec4(-8192.,-12288.,9216.,11264.);
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 uv=(world.xz-bounds.xy)/(bounds.zw-bounds.xy);
 vec3 macro=texture(macro_map,uv).rgb;
 vec3 detail=texture(detail_map,world.xz*.30).rgb;
 float grain=dot(detail,vec3(.299,.587,.114));
 ALBEDO=macro*(.72+grain*.75);
 ROUGHNESS=.98;
}
