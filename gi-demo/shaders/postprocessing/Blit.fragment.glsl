#version 430 core

in vec2 UV;
#include Lighting.glsl
#include LogDepth.glsl

out vec4 outColor;

layout(binding = 0) uniform sampler2D texColor;
layout(binding = 1) uniform sampler2D texDepth;


void main()
{
	vec3 color1 = texture(texColor, UV).rgb;
	gl_FragDepth = texture(texDepth, UV).r;
    outColor = vec4(color1, 1);
}