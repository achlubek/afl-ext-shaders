#version 430 core

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec2 in_uv;
layout(location = 2) in vec3 in_normal;


uniform vec3 LightPosition;

uniform mat4 ViewMatrix;
uniform mat4 ProjectionMatrix;
const int MAX_INSTANCES = 2000;
uniform int Instances;
uniform mat4 ModelMatrixes[MAX_INSTANCES];
smooth out vec2 UV;

//out vec3 normal;
smooth out vec3 vertexWorldSpace;

void main(){
	vec4 v = vec4(in_position,1);

	mat4 mvp = ProjectionMatrix * ViewMatrix * ModelMatrixes[gl_InstanceID];
	vertexWorldSpace = (ModelMatrixes[gl_InstanceID] * v).xyz;
	gl_Position = mvp * v;
	UV = vec2(in_uv.x, -in_uv.y);

}