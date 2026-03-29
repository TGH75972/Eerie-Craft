#version 330 compatibility
uniform sampler2D colortex0;
in vec2 texcoord;
layout(location = 0) out vec4 color;
void main(){
vec3 sceneColor = texture(colortex0, texcoord).rgb;
sceneColor = max(sceneColor, vec3(0.0));
color.rgb = pow(sceneColor, vec3(1.0 / 2.2));
color.a = 1.0;
}