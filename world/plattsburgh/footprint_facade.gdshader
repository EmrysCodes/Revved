shader_type spatial;
render_mode cull_back;
uniform vec4 wall_color:source_color=vec4(.6,.5,.4,1);
uniform float seed=0.;
uniform bool house=true;
varying vec2 meters;
varying vec2 frontage;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float rect(vec2 p,vec2 lo,vec2 hi){return step(lo.x,p.x)*step(p.x,hi.x)*step(lo.y,p.y)*step(p.y,hi.y);}
void vertex(){meters=UV;frontage=UV2;}
void fragment(){
 vec2 pitch=vec2(house?3.1:2.9,house?3.05:3.3);
 vec2 cell=fract((meters-vec2(.35,.0))/pitch);
 vec2 id=floor((meters-vec2(.35,.0))/pitch);
 float border=rect(cell,vec2(.19,.23),vec2(.76,.82))*step(.65,meters.y);
 float win=rect(cell,vec2(.23,.27),vec2(.72,.77))*step(.65,meters.y);
 float mullion=max(1.-step(.012,abs(cell.x-.475)),1.-step(.012,abs(cell.y-.52)));
 win*=1.-mullion;
 float lit=step(.75,hash(id+seed));
 vec2 brick=vec2(meters.x*3.2+step(.5,fract(meters.y*3.4))*.5,meters.y*6.8);
 float mortar=max(1.-step(.035,fract(brick.x)),1.-step(.065,fract(brick.y)));
 float noise=hash(floor(brick)+seed);
 float siding=.91+.09*step(.06,fract(meters.y*5.));
 bool clapboard=house && mod(seed,3.)<1.;
 vec3 base=wall_color.rgb*(clapboard?siding:(.83+.17*noise));
 if(!clapboard)base=mix(base,vec3(.37,.35,.31),mortar*.6);
 float sill=rect(cell,vec2(.17,.19),vec2(.78,.235))*step(.65,meters.y);
 base=mix(base,vec3(.65,.62,.54),max(border-win,sill));
 float foundation=1.-smoothstep(.25,.55,meters.y);
 base=mix(base,vec3(.26,.28,.27),foundation*.8);
 vec3 warm=vec3(.9,.52,.22);
 base=mix(base,mix(vec3(.025,.055,.08),warm*.45,lit),win);
 float door=rect(vec2(meters.x-frontage.y*.5,meters.y),vec2(-.55,.05),vec2(.55,2.2))*frontage.x;
 float shop=(!house?rect(vec2(cell.x,meters.y),vec2(.08,.35),vec2(.89,2.35))*frontage.x:0.);
 base=mix(base,vec3(.035,.075,.085),max(door,shop));
 float bands=(!house?1.-smoothstep(.07,.13,abs(meters.y-2.8)):0.);
 base=mix(base,wall_color.rgb*.45,bands);
 ALBEDO=base;ROUGHNESS=mix(.93,.30,max(win,shop));
 EMISSION=warm*(win*lit*.65+shop*.12);
}
