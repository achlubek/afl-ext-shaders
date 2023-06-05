#version 450 core
uniform mat4 VPMatrix;
uniform float Time;

struct Particle{
	vec4 Position;
	vec4 Velocity;
};

layout (std430, binding = 9) coherent buffer R1
{
  Particle[] Particles; 
}; 

void main(){

	vec4 outpoint = (VPMatrix) * vec4(vec3(sin(Time), 0, 0), 1);
    gl_Position = outpoint;
}