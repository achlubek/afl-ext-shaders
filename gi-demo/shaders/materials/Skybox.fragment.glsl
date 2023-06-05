#version 430 core

out vec4 outColor;

uniform vec3 CameraDirection;
in vec2 UV;
const vec2 resolution = vec2(1600, 900);

void main( void ) {

	float ratio = resolution.x / resolution.y;
	vec2 p = ( gl_FragCoord.xy / resolution.xy);
	
	vec3 bottom = vec3(0.5, 0.5, 0.5) * 2.0;
	vec3 top = vec3(0.2, 0.6, 0.9);
	
	vec3 sky = mix(top, bottom, 1.0 - p.y);
	
	outColor = vec4(sky, 1.0);
	//outColor = vec4(0, 0, 0, 1);
	gl_FragDepth = 1.0;
}