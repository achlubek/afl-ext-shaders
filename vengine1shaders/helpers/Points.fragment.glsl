#version 450 core
layout(location = 0) out vec4 outAlbedoRoughness;
layout(location = 1) out vec4 outNormalsDistance;
layout(location = 2) out vec4 outSpecularBump;

void main(){
	if(length(gl_PointCoord - 0.5) > 0.5) discard;
	outAlbedoRoughness = vec4(1);
	outNormalsDistance =  vec4(9);
	outSpecularBump = vec4(0);
}