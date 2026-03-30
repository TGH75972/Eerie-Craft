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
uniform int worldTime;
in vec2 texcoord;
layout(location = 0) out vec4 color;
const int shadowMapResolution = 2048;
const vec3 blocklightColor = vec3(1.0, 0.6, 0.2);
const float DAYLIGHT_DARKNESS_FACTOR = 0.95; 
const float CLOUD_INTENSITY = 0.9; 
const float CLOUD_SPEED = 0.05; 
const vec3 DAY_FOG = vec3(0.55, 0.56, 0.58);
const vec3 SUNSET_FOG = vec3(0.75, 0.45, 0.25);
const vec3 NIGHT_FOG = vec3(0.002, 0.003, 0.005);
const float FOG_DENSITY = 0.035;
float hash(vec3 p){
p = fract(p * vec3(123.34, 456.21, 789.92));
p += dot(p, p + 45.32);
return fract(p.x*p.y*p.z);
  }
float noise(vec3 p){
vec3 i = floor(p);
vec3 f = fract(p);
f = f*f*(3.0 - 2.0*f);
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
return homPos.xyz/homPos.w;
}
vec3 getShadow(vec3 shadowScreenPos){
if(shadowScreenPos.x < 0.0 || shadowScreenPos.x > 1.0 ||
shadowScreenPos.y < 0.0 || shadowScreenPos.y > 1.0 ||
shadowScreenPos.z < 0.0 || shadowScreenPos.z > 1.0){
return vec3(1.0);
}
float shadow = 0.0;
vec2 offsets[4] = vec2[](vec2(-0.5, -0.5), vec2(0.5, -0.5),vec2(-0.5, 0.5), vec2(0.5, 0.5));
for(int i = 0; i < 4; i++){
float depth = texture(shadowtex0, shadowScreenPos.xy + offsets[i] * 0.001).r;
shadow += step(shadowScreenPos.z, depth);
 }
shadow *= 0.25;
vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);
vec3 tintedShadow = shadowColor.rgb * (1.0 - shadowColor.a);
return mix(tintedShadow, vec3(1.0), shadow);
   } 
void main(){
vec3 sceneColor = texture(colortex0, texcoord).rgb;
float depth = texture(depthtex0, texcoord).r;
sceneColor = max(sceneColor, vec3(0.0));
vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
float sunElevation = sunDir.y;
float nightFactor = 1.0 - clamp(abs(float(worldTime) - 18000.0) / 5000.0, 0.0, 1.0);
vec3 currentSunlight = mix(vec3(1.2, 1.1, 1.0), vec3(0.05, 0.15, 0.4), nightFactor);
vec3 currentAmbient = mix(vec3(0.02, 0.02, 0.04), vec3(0.001, 0.001, 0.002), nightFactor);
vec3 currentSkyBase = mix(vec3(0.25, 0.35, 0.45), vec3(0.001, 0.002, 0.004), nightFactor);
vec3 currentCloudDarkness = mix(vec3(0.3, 0.3, 0.35), vec3(0.005, 0.005, 0.008), nightFactor);
vec3 currentSkylight = mix(vec3(0.05, 0.08, 0.12), vec3(0.001, 0.002, 0.004), nightFactor);
vec3 celestialColor = mix(vec3(1.0, 0.9, 0.7), vec3(0.2, 0.4, 0.8), nightFactor);
vec3 dayFog = mix(SUNSET_FOG, DAY_FOG, smoothstep(0.0, 0.3, sunElevation));
vec3 dynamicFogColor = mix(dayFog, NIGHT_FOG, nightFactor);
if(depth >= 0.9999){
vec3 ndcPos = vec3(texcoord.xy, 1.0) * 2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
vec3 worldDir = normalize((gbufferModelViewInverse * vec4(viewPos, 0.0)).xyz);
float sunDot = max(dot(worldDir, sunDir), 0.0);
float sunDisc = smoothstep(0.9985, 0.9995, sunDot);
float sunGlow = pow(sunDot, 45.0);
vec3 celestialVisual = celestialColor*(sunDisc*5.0 + sunGlow*1.5);
vec3 currentSky = currentSkyBase + celestialVisual;
float cloudDensity = 0.0;
if(abs(worldDir.y) > 0.001){
float tMin = (128.0 - cameraPosition.y) / worldDir.y;
float tMax = (160.0 - cameraPosition.y) / worldDir.y;
float tStart = max(0.0, min(tMin, tMax));
float tEnd = max(0.0, max(tMin, tMax));
if(tEnd > 0.0){
int steps = 16;
float stepSize = (tEnd - tStart) / float(steps);
float t = tStart;
for(int i = 0; i < steps; i++){
vec3 p = cameraPosition + worldDir*t;
p.x += frameTimeCounter * CLOUD_SPEED * 150.0; 
float n = fbm(p * 0.015);
float d = max(0.0, n - 0.4) * 3.5;
cloudDensity += d * stepSize * 0.02;
if(cloudDensity >= 1.0)
break;
t += stepSize;
}
  }
 }  
float horizonFade = smoothstep(0.0, 0.1, abs(worldDir.y));
cloudDensity *= horizonFade;
cloudDensity = clamp(cloudDensity, 0.0, 1.0);
sceneColor = mix(currentSky, currentCloudDarkness, cloudDensity * CLOUD_INTENSITY);
float skyFogFactor = smoothstep(0.0, 0.3, abs(worldDir.y));
sceneColor = mix(dynamicFogColor, sceneColor, skyFogFactor);
float fogScatter = pow(sunDot, 24.0)*(1.0 - skyFogFactor);
sceneColor += celestialColor * fogScatter * 1.5;
}
else{
sceneColor = pow(sceneColor, vec3(2.2));
vec2 lightmap = texture(colortex1, texcoord).xy;
vec3 encodedNormal = texture(colortex2, texcoord).rgb;
vec3 rawNormal = (encodedNormal - 0.5) * 2.0;
vec3 normal = vec3(0.0, 1.0, 0.0);
if(length(encodedNormal) > 0.01){
normal = normalize(rawNormal);
}
vec3 ndcPos = vec3(texcoord.xy, depth)*2.0 - 1.0;
vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
vec3 shadowViewPos = (shadowModelView*vec4(feetPlayerPos, 1.0)).xyz;
vec4 shadowClipPos = shadowProjection*vec4(shadowViewPos, 1.0);
shadowClipPos.z -= 0.001;
shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
vec3 shadowScreenPos = shadowNdcPos*0.5 + 0.5;
vec3 shadow = getShadow(shadowScreenPos);
vec3 blocklight = lightmap.x*blocklightColor;
vec3 skylight = lightmap.y*currentSkylight;
vec3 ambient = currentAmbient;
vec3 sunlight = currentSunlight*clamp(dot(sunDir, normal), 0.0, 1.0) * shadow;
sceneColor *= blocklight + skylight + ambient + sunlight;
sceneColor *= DAYLIGHT_DARKNESS_FACTOR;
vec3 terrainWorldDir = normalize((gbufferModelViewInverse * vec4(viewPos, 0.0)).xyz);
float dist = length(viewPos);
float fogFactor = exp(-pow(dist*FOG_DENSITY, 2.0));
fogFactor = clamp(fogFactor, 0.0, 1.0);
float terrainSunDot = max(dot(terrainWorldDir, sunDir), 0.0);
float terrainFogScatter = pow(terrainSunDot, 24.0)*(1.0 - fogFactor);
vec3 finalFogColor = dynamicFogColor + celestialColor * terrainFogScatter * 1.5;
sceneColor = mix(finalFogColor, sceneColor, fogFactor);
  }
color.rgb = clamp(sceneColor, 0.0, 1.0);
color.a = 1.0;
 }