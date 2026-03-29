#version 330 compatibility
#include "/lib/shadowDistort.glsl"
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform float frameTimeCounter;
in vec2 texcoord;
layout(location = 0) out vec4 color;
const vec3 blocklightColor = vec3(1.0, 0.6, 0.2);
const vec3 skylightColor = vec3(0.4, 0.4, 0.4);
const vec3 sunlightColor = vec3(0.4, 0.4, 0.45);
const vec3 ambientColor = vec3(0.9, 0.9, 0.95);
const float DAYLIGHT_DARKNESS_FACTOR = 0.95; 
const float CLOUD_INTENSITY = 0.9; 
const float CLOUD_SPEED = 0.05; 
const vec3 DEAD_SKY_COLOR = vec3(0.45, 0.45, 0.5);
const vec3 CLOUD_DARKNESS = vec3(0.3, 0.3, 0.35);
float hash(vec3 p){
p = fract(p * vec3(123.34, 456.21, 789.92));
p += dot(p, p + 45.32);
return fract(p.x * p.y * p.z);
}
float noise(vec3 p){
vec3 i = floor(p);
vec3 f = fract(p);
f = f * f * (3.0 - 2.0 * f);
float n000 = hash(i);
float n100 = hash(i + vec3(1.0, 0.0, 0.0));
float n010 = hash(i + vec3(0.0, 1.0, 0.0));
float n110 = hash(i + vec3(1.0, 1.0, 0.0));
float n001 = hash(i + vec3(0.0, 0.0, 1.0));
float n101 = hash(i + vec3(1.0, 0.0, 1.0));
float n011 = hash(i + vec3(0.0, 1.0, 1.0));
float n111 = hash(i + vec3(1.0, 1.0, 1.0));
return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),f.z);
}
float fbm(vec3 p){
float value = 0.0;
float amplitude = 0.5;
for(int i = 0; i < 4; i++){
value += amplitude * noise(p);
p *= 2.0;
amplitude *= 0.5;
  }
return value;
}
vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
vec4 homPos = projectionMatrix * vec4(position, 1.0);
return homPos.xyz / homPos.w;
 }
vec3 getShadow(vec3 shadowScreenPos){
float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);
if(transparentShadow==1.0)
return vec3(1.0);
float opaqueShadow=step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r);
if(opaqueShadow==0.0)
return vec3(0.0);
vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);
return shadowColor.rgb*(1.0 - shadowColor.a);
}
void main(){
vec3 sceneColor = texture(colortex0, texcoord).rgb;
float depth = texture(depthtex0, texcoord).r;
sceneColor = max(sceneColor, vec3(0.0));
if(depth >= 0.9999){
vec3 ndcPos = vec3(texcoord.xy, 1.0) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
vec3 worldDir = normalize((gbufferModelViewInverse * vec4(viewPos, 0.0)).xyz);
float density = 0.0;
if (abs(worldDir.y) > 0.001){
float tMin = (128.0 - cameraPosition.y) / worldDir.y;
float tMax = (160.0 - cameraPosition.y) / worldDir.y;
float tStart = max(0.0, min(tMin, tMax));
float tEnd = max(0.0, max(tMin, tMax));
if(tEnd > 0.0){
int steps = 16;
float stepSize = (tEnd - tStart)/float(steps);
float t = tStart;
for(int i = 0; i < steps; i++){
vec3 p = cameraPosition + worldDir * t;
p.x += frameTimeCounter * CLOUD_SPEED * 150.0;
float n = fbm(p * 0.015);
float d = max(0.0, n - 0.4) * 3.5;
density += d * stepSize * 0.02;
if(density >= 1.0)
break;
t += stepSize;
   }
 }
}
float horizonFade = smoothstep(0.0, 0.1, abs(worldDir.y));
density*= horizonFade;
density=clamp(density, 0.0, 1.0);
sceneColor = mix(DEAD_SKY_COLOR, CLOUD_DARKNESS, density * CLOUD_INTENSITY);
}
else{
sceneColor = pow(sceneColor, vec3(2.2));
vec2 lightmap = texture(colortex1, texcoord).xy;
vec3 encodedNormal = texture(colortex2, texcoord).rgb;
vec3 rawNormal = (encodedNormal - 0.5) * 2.0;
vec3 normal = vec3(0.0, 1.0, 0.0);
if(length(rawNormal) > 0.05){
normal = normalize(rawNormal);
}
vec3 lightVector = normalize(shadowLightPosition);
vec3 worldLightVector = mat3(gbufferModelViewInverse)*lightVector;
vec3 ndcPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
shadowClipPos.z -= 0.001;
shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
vec3 shadowScreenPos = shadowNdcPos * 0.5 + 0.5;
vec3 shadow = getShadow(shadowScreenPos);
vec3 blocklight = lightmap.x * blocklightColor;
vec3 skylight = lightmap.y * skylightColor;
vec3 ambient = ambientColor;
vec3 sunlight = sunlightColor * clamp(dot(worldLightVector, normal), 0.0, 1.0) * shadow;
sceneColor *= blocklight + skylight + ambient + sunlight;
sceneColor *= DAYLIGHT_DARKNESS_FACTOR;
  }
color.rgb = clamp(sceneColor, 0.0, 1.0);
color.a = 1.0;
}