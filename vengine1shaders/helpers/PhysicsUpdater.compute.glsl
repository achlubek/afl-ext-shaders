#version 450 core

layout( local_size_x = 1024, local_size_y = 1, local_size_z = 1 ) in;

struct Particle{
	vec4 Position;
	vec4 Velocity;
};

layout (std430, binding = 9) coherent buffer R1
{
  Particle[] Particles; 
}; 

uniform int ParticlesCount;

void Solve(int index){
	Particle mainParticle = Particles[index];
	vec3 pressureStatic;
	vec3 pressureDynamic;
	float divider = float(ParticlesCount) - 1.0;;
	
	for(int i=0;i<index;i++){
		Particle part = Particles[i];
		vec3 diffpress = mainParticle.Position.xyz - part.Position.xyz;
		pressureStatic += normalize(diffpress) * (1.0 / (length(diffpress)*100 + 0.1));
		//pressureDynamic += normalize(part.Velocity.xyz) * (1.0 / (length(diffpress)*100 + 1));
	}
	
	for(int i=index + 1;i<ParticlesCount;i++){
		Particle part = Particles[i];
		vec3 diffpress = mainParticle.Position.xyz - part.Position.xyz;
		pressureStatic += normalize(diffpress) * (1.0 / (length(diffpress)*100 + 0.1));
		//pressureDynamic += normalize(part.Velocity.xyz) * (1.0 / (length(diffpress)*100 + 1));
	}
		
	memoryBarrier();
	barrier();
	
	vec3 newPosition = mainParticle.Position.xyz + mainParticle.Velocity.xyz * 0.01 + vec3(0, -0.001, 0);
	vec3 newVelocity = mix(mainParticle.Velocity.xyz, pressureStatic + pressureDynamic, 0.5) * 0.9;
	
	vec3 bboxmin = vec3(-20, 0, -10);
	vec3 bboxmax = vec3(20, 30, 10);
	
	newPosition = clamp(newPosition, bboxmin, bboxmax);
	
	Particles[index] = Particle(vec4(newPosition, 1), vec4(newVelocity, 1));
}

void main(){
	Solve(int(gl_GlobalInvocationID.x));
}