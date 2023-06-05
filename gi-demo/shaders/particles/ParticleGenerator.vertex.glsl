/*vertex*/
#version 430 core
#include AttributeLayout.glsl

//smooth out vec3 normal;
smooth out vec3 positionWorldSpace;
//smooth out vec3 positionModelSpace;

uniform mat4 ModelMatrix;
uniform mat4 ViewMatrix;
uniform mat4 RotationMatrix;
uniform mat4 ProjectionMatrix;
uniform mat4 Orientation;
uniform mat4 OrientationOriginal;

uniform float AlphaDecrease;
uniform float TimeToLife;
uniform float TimeRate;
uniform float TimeElapsed;
uniform int MaxInstances;
uniform vec3 Gravity;
uniform vec3 InitialVelocity;
uniform vec3 CameraPosition;

smooth out vec2 UV;

uniform int GeneratorMode;
uniform vec3 BoxSize;
uniform vec3 PlaneSize;
out float alphaDelta;

float rand(float x){
	return (fract(sin(x*12.9898) * 43758.5453) - 0.5) * 2.0;
}

void main(){

	float step = mod((gl_InstanceID * TimeRate) + TimeElapsed, TimeToLife) / TimeToLife;
	vec3 transformed = (ModelMatrix * Orientation * vec4(in_position, 1.0)).xyz;
	if(GeneratorMode == 0){// BOX
		transformed += (OrientationOriginal * vec4(BoxSize.x * rand(gl_InstanceID/11642.0), BoxSize.y * rand(gl_InstanceID/12233.534), BoxSize.z * rand(gl_InstanceID/85437.0), 1.0)).xyz;
		vec3 start = vec3(0);
		vec3 stop = Gravity * TimeToLife;
		stop.x += rand(gl_InstanceID/1235.652);
		stop.z += rand(gl_InstanceID/4432.123);
		transformed += mix(start, stop, step);
	}// else if(GeneratorMode == 1){// PLANE
		//transformed += (OrientationOriginal * vec4(PlaneSize.x * rand(gl_InstanceID/2321.0), 0, PlaneSize.z * rand(gl_InstanceID/1882.0), 1.0)).xyz;
	//} else { // point
		/*vec3 start = vec3(0);
		vec3 stop = Gravity * TimeToLife;
		stop.x += rand(gl_InstanceID * 2) * step * 34.0;
		stop.z += rand(1.0/gl_InstanceID) * step * 34.0;
		transformed += mix(start, stop, step);*/
	//}
	//vec4 temp = ProjectionMatrix  * ViewMatrix * ModelMatrix * vec4(in_position, 1.0);
	alphaDelta = AlphaDecrease * step;
	
	//depth = temp.z / temp.w;// + (gl_InstanceID / MaxInstances / 10.0);
	
	//positionModelSpace = in_position;
	//normal = (OrientationOriginal * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	
	positionWorldSpace = transformed;
    vec4 v = vec4(transformed,1);
    
	gl_Position = (ProjectionMatrix  * ViewMatrix) * v;	
	
	
	UV = vec2(in_uv.x, -in_uv.y);
	
}