#version 430 core

in vec2 UV;
#include LogDepth.glsl
#include Lighting.glsl
#include UsefulIncludes.glsl
#include Shade.glsl

out vec4 outColor;

uniform int DisablePostEffects;

float globalDim = 1.0;

vec2 transformFishEye(vec2 inuv){
	float aperture = 180.0;
	float apertureHalf = 0.5 * aperture * (3.1415 / 180.0);
	float maxFactor = sin(apertureHalf);
	vec2 zoomer = inuv * 2.0 - 1.0;
	zoomer /= 1.0;
	zoomer = zoomer * 0.5 + 0.5;
	vec2 uv;
	vec2 xy = 2.0 * zoomer - 1.0;
	float d = length(xy);
	if (d < (2.0-maxFactor)) 
	{
		d = length(xy * maxFactor);
		float z = sqrt(1.0 - d * d);
		float r = atan(d, z) / 3.1415;
		float phi = atan(xy.y, xy.x);

		uv.x = r * cos(phi) + 0.5;
		uv.y = r * sin(phi) + 0.5;
	}
	else
	{
		uv = inuv;
		globalDim = 0.0;
	}
	return uv;
}

void main()
{
    vec3 color = texture(lastStageResultTex, transformFishEye(UV)).rgb;
    outColor = vec4(color * globalDim, 1);
}