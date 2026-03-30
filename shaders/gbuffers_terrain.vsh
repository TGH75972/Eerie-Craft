#version 330 compatibility
attribute vec2 mc_Entity;
out vec2 texcoord;
out vec4 glcolor;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
void main(){
texcoord = (gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;
glcolor = gl_Color;
vec4 vertexPos = gl_Vertex;
int blockId = int(max(mc_Entity.x, 0.0));
vec4 viewPos = gl_ModelViewMatrix*vertexPos;
vec3 worldPos = (gbufferModelViewInverse * viewPos).xyz + cameraPosition;
if(blockId == 31 || blockId == 37 || blockId == 175){
float wave = sin(frameTimeCounter * 1.5 + worldPos.x * 2.0 + worldPos.z * 2.0)*0.05;
vertexPos.x += wave;
vertexPos.z += wave;
  } 
else if(blockId==18){
float wave = sin(frameTimeCounter * 1.0 + worldPos.x * 1.5 + worldPos.z * 1.5)*0.02;
vertexPos.x += wave;
vertexPos.z += wave;
 }
gl_Position = gl_ModelViewProjectionMatrix*vertexPos;
}