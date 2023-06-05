#version 430 core

in vec2 UV;

layout(binding = 0) uniform sampler2DMS texColor;
layout(binding = 1) uniform sampler2DMS texDepth;
layout(binding = 2) uniform sampler2D worldPosTex;
layout(binding = 3) uniform sampler2D worldPosDepth;

const int samples = 4;
float samplesInverted = 1.0 / samples;

out vec4 outColor;

ivec2 ctexSize = textureSize(texColor);
ivec2 dtexSize = textureSize(texDepth);

vec4 fetchColor()
{
	vec4 c = vec4(0.0);
	ivec2 tx = ivec2(ctexSize * UV); 
	for (int i = 0; i < samples; i++) c += texelFetch(texColor, tx, i);  
	return c * samplesInverted;
}

float fetchDepth()
{
	return texture(worldPosDepth, UV).r;
}

void main()
{
	outColor = fetchColor();
	gl_FragDepth = fetchDepth();
}