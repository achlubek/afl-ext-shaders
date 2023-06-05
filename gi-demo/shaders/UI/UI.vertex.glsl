#version 430 core

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec2 in_uv;
layout(location = 2) in vec3 in_normal;

out vec2 UV;

void main(){

    gl_Position =  vec4(in_position,1);
    UV = vec2(
		(in_position.xy + 1.0) / 2.0
	);
	UV.y = 1.0 - UV.y;
}