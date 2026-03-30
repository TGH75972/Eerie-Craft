#version 330 compatibility
uniform sampler2D texture;
uniform float frameTimeCounter;
in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 worldPos;
in float isWater;
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 outLightmap;
layout(location = 2) out vec4 outNormal;
float hash(vec2 p){
p = fract(p*vec2(123.34, 456.21));
p += dot(p, p + 45.32);
return fract(p.x*p.y);
 }
float noise(vec2 p){
vec2 i = floor(p);
vec2 f = fract(p);
vec2 u = f*f*(3.0 - 2.0*f);
return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
  }
void main(){
vec4 albedo = texture(texture, texcoord)*glcolor;
vec3 normal = vec3(0.0, 1.0, 0.0);
if(isWater > 0.5){
vec2 waveCoords = worldPos.xz * 2.5;
float time = frameTimeCounter * 2.0;
float n = noise(waveCoords + time);
n += noise(waveCoords * 3.0 - time * 1.5) * 0.5;
vec3 deepWater = vec3(0.05, 0.2, 0.4);
vec3 shallowRipple = vec3(0.2, 0.5, 0.7);
vec3 finalWaterColor = mix(deepWater, shallowRipple, n * 0.6);
albedo.rgb = mix(albedo.rgb, finalWaterColor, 0.85);
albedo.a = 0.8; 
   }
color = albedo;
outLightmap = vec4(lmcoord, 0.0, 1.0);
outNormal = vec4(normal * 0.5 + 0.5, 1.0);
 }