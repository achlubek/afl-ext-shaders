#version 430 core
layout(location = 0) in vec3 in_position;
layout(location = 1) in vec2 in_uv;
layout(location = 2) in vec3 in_normal;

out vec2 UV;

void main(){
	vec4 v = vec4(in_position, 1.0);
	UV = in_position.xy;
    gl_Position = v;
}