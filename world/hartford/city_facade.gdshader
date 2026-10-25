shader_type spatial;
render_mode cull_back;
uniform sampler2D brick : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 wall_color : source_color = vec4(0.5,0.45,0.4,1.0);
uniform int family = 0;
uniform float bay_width = 3.0;
uniform float floor_height = 3.5;
varying vec2 meters;
varying float roof;
varying flat float seed;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void vertex(){
 float w=length(MODEL_MATRIX[0].xyz);float h=length(MODEL_MATRIX[1].xyz);float d=length(MODEL_MATRIX[2].xyz);
 meters=vec2((abs(NORMAL.x)>.5?VERTEX.z+.5:VERTEX.x+.5)*(abs(NORMAL.x)>.5?d:w),VERTEX.y*h);
 roof=abs(NORMAL.y);
 seed=hash(MODEL_MATRIX[3].xz);
}
void fragment(){
 vec2 grid=vec2(meters.x/bay_width,meters.y/floor_height);
 vec2 cell=fract(grid);vec2 id=floor(grid);
 float lintel=smoothstep(.025,.04,cell.y)*(1.0-smoothstep(.065,.08,cell.y));
 vec3 masonry=wall_color.rgb;
 if(family==0 || family==4){masonry*=texture(brick,meters/3.5).rgb*1.5;}
 else {float courses=1.0-smoothstep(.012,.025,abs(fract(meters.y/.65)-.5));masonry*=.94+.06*courses;}
 float window=step(.21,cell.x)*step(cell.x,.79)*step(.2,cell.y)*step(cell.y,.79);
 if(family==2){window=step(.025,cell.x)*step(cell.x,.975)*step(.035,cell.y)*step(cell.y,.965);}
 if(family==4){window=step(.14,cell.x)*step(cell.x,.86)*step(.34,cell.y)*step(cell.y,.78);}
 float frame=step(.18,cell.x)*step(cell.x,.82)*step(.17,cell.y)*step(cell.y,.82);
 float lit=step(.7,hash(id+vec2(seed*73.0,seed*137.0)));
 vec2 room_uv=vec2((cell.x-.21)/.58,(cell.y-.2)/.59);
 float blind=step(.72,hash(id+seed*21.0))*step(.47,room_uv.y);
 float room_detail=.64+.36*step(.1,fract(room_uv.y*7.0));
 vec3 glass=mix(vec3(.035,.068,.09),vec3(.29,.34,.36),smoothstep(.1,1.0,cell.y))*.45;
 vec3 warm=mix(vec3(.9,.55,.23),vec3(.53,.72,.83),step(.78,hash(id+seed*41.0)));
 vec3 interior=warm*(.22+.18*room_detail)*(1.0-blind*.7);
 ALBEDO=mix(masonry,vec3(.055,.065,.068),frame);
 ALBEDO=mix(ALBEDO,mix(glass,interior,lit),window);
 ALBEDO+=masonry*lintel*.15;
 ROUGHNESS=mix(.88,.31,window);METALLIC=window*.18;
 EMISSION=interior*window*lit*.65;
 if(roof>.5){ALBEDO=wall_color.rgb*.38;ROUGHNESS=.95;METALLIC=0.0;EMISSION=vec3(0.0);}
}
