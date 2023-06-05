#version 430 core
#include AttributeLayout.glsl
#include Mesh3dUniforms.glsl

smooth out vec3 normal;
smooth out vec3 positionWorldSpace;
smooth out vec3 positionModelSpace;
smooth out vec2 UV;
out flat int instanceId;
smooth out vec3 barycentric;


void main(){

    vec4 v = vec4(in_position,1);
    //vec4 n = vec4(in_normal,0);
	int vid = int(floor(mod(gl_VertexID, 3)));
	if(vid == 0)barycentric = vec3(1, 0, 0);
	if(vid == 1)barycentric = vec3(0, 1, 0);
	if(vid == 2)barycentric = vec3(0, 0, 1);

	normal = in_normal;
	UV = vec2(in_uv.x, -in_uv.y);

	gl_Position = (ProjectionMatrix  * ViewMatrix * ModelMatrixes[gl_InstanceID]) * v;	
	positionWorldSpace = (ModelMatrixes[gl_InstanceID] * v).xyz;

	instanceId = gl_InstanceID;

	positionModelSpace = v.xyz;	
	
}