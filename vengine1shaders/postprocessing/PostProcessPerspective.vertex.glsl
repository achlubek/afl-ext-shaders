#version 430 core
#include AttributeLayout.glsl
#include Mesh3dUniforms.glsl

uniform mat4 ModelMatrix;

void main(){

    vec4 v = vec4(in_position,1);
	vec4 outpoint = (VPMatrix) * vec4((ModelMatrix * v).xyz, 1);
    gl_Position = outpoint;
}