#version 330 compatibility
attribute vec2 mc_Entity;
out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 worldPos;
out float isWater;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
void main(){
texcoord = (gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;
lmcoord  = (gl_TextureMatrix[1]*gl_MultiTexCoord1).xy;
glcolor  = gl_Color;
vec4 vertexPos = gl_Vertex;
int blockId = int(max(mc_Entity.x, 0.0));
vec4 viewPos = gl_ModelViewMatrix*vertexPos;
worldPos =(gbufferModelViewInverse*viewPos).xyz + cameraPosition;
isWater = 0.0;
if(blockId==8){
float wave = sin(frameTimeCounter * 3.0 + worldPos.x * 2.5 + worldPos.z * 2.5)*0.12;
wave += sin(frameTimeCounter * 2.0 + worldPos.x * -1.5 + worldPos.z * 1.0)*0.08;
vertexPos.y += wave;
isWater = 1.0;
  }
gl_Position = gl_ModelViewProjectionMatrix*vertexPos;
 }