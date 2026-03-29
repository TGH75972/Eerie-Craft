#version 330 compatibility
layout(location = 0) out vec4 color;
const vec3 DEAD_SKY_COLOR = vec3(0.45, 0.45, 0.5); 
void main(){
  color = vec4(DEAD_SKY_COLOR, 1.0);
 }