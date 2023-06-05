/*fragment*/
#version 430 core
in vec2 UV;
uniform vec3 CameraPosition;
uniform float LogEnchacer;
uniform float FarPlane;
in vec3 positionWorldSpace;

#include LogDepth.glsl

out vec4 outColor;
in float alphaDelta;
layout(binding = 0) uniform sampler2D tex;

void main()
{
	vec4 color = texture(tex, UV);
	//outColor = vec4(processLighting(color.xyz), color.a - alphaDelta);
	outColor = vec4(color.rgb, clamp(color.a - alphaDelta, 0.0, 1.0));
	updateDepth();
	//outColor = vec4(color.xyz, color.a - alphaDelta);
}