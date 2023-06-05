#version 430 core

in vec2 UV;
#include Lighting.glsl
#include LogDepth.glsl
#define mPI (3.14159265)
#define mPI2 (2*3.14159265)
#define GOLDEN_RATIO (1.6180339)
out vec4 outColor;

layout(binding = 0) uniform sampler2D color;
layout(binding = 1) uniform sampler2D depth;
layout(binding = 2) uniform sampler2D fog;
layout(binding = 3) uniform sampler2D lightpoints;
layout(binding = 4) uniform sampler2D bloom;
layout(binding = 5) uniform sampler2D globalIllumination;
layout(binding = 6) uniform sampler2D diffuseColor;

vec3 lookupFog(){
	vec3 outc = vec3(0);
	int counter = 0;
	for(float g = 0; g < mPI2 * 2; g+=GOLDEN_RATIO)
	{ 
		for(float g2 = 0; g2 < 6.0; g2+=1.0)
		{ 
			vec2 gauss = vec2(sin(g + g2)*ratio, cos(g + g2)) * (g2 * 0.001);
			vec3 color = texture(fog, UV + gauss).rgb;
			outc += color;
			counter++;
		}
	}
	return outc / counter;
}

vec3 lookupGIBlurred(float radius){
	vec3 outc = vec3(0);
	float last = 0;
	int counter = 0;
	for(float g = 0; g < mPI2 * 2; g+=GOLDEN_RATIO)
	{ 
		for(float g2 = 1; g2 < 6.0; g2+=1.0)
		{ 
			vec2 gauss = vec2(sin(g + g2)*ratio, cos(g + g2)) * (g2 * radius);
			vec3 color = texture(globalIllumination, UV + gauss).rgb;
			if(length(color) >= last){
				outc += color;
				counter++;
				last = length(color);
			}
		}
	}
	return outc / counter / 3 * texture(diffuseColor, UV).rgb ;
}

vec3 lookupFogSimple(){
	return texture(fog, UV).rgb;
}

float centerDepth;

vec3 lookupGIBilinearDepthNearest(vec2 giuv){
    //ivec2 texSize = textureSize(globalIllumination,0);
	//float lookupLengthX = 1.7 / texSize.x;
	//float lookupLengthY = 1.7 / texSize.y;
	//lookupLengthX = clamp(lookupLengthX, 0, 1);
	//lookupLengthY = clamp(lookupLengthY, 0, 1);
	vec3 gi =  (texture(globalIllumination, giuv ).rgb);
	return (texture(diffuseColor, giuv).rgb) * gi	* 1.1 + (texture(color, giuv).rgb) * gi	* 1.1;
}

vec3 lookupGI(){
	return lookupGIBilinearDepthNearest(UV);
}
vec3 lookupGISimple(vec2 giuv){
	return texture(globalIllumination, giuv ).rgb;
}
/*
vec3 subsurfaceScatteringExperiment(){
	float frontDistance = reverseLog(texture(depth, UV).r);
	float backDistance = reverseLog(texture(backDepth, UV).r);
	float deepness =  backDistance - frontDistance;
	return vec3(
		1.0 - deepness * 15
	);
}*/

uniform int UseSimpleGI;
uniform int UseFog;
uniform int UseLightPoints;
uniform int UseDepth;
uniform int UseBloom;
uniform int UseDeferred;
uniform int UseBilinearGI;

void main()
{
	vec3 color1 = vec3(0);
	if(UseDeferred == 1) color1 += texture(color, UV).rgb;
	if(UseFog == 1) color1 += lookupFog();
	if(UseLightPoints == 1) color1 += texture(lightpoints, UV).rgb;
	if(UseBloom == 1) color1 += texture(bloom, UV).rgb;
	if(UseDepth == 1) color1 += texture(depth, UV).rrr;
	if(UseBilinearGI == 1) color1 += lookupGIBilinearDepthNearest(UV);
	if(UseSimpleGI == 1) color1 += lookupGIBlurred(0.0005);
	centerDepth = texture(depth, UV).r;
	
	gl_FragDepth = centerDepth;
	
    outColor = vec4(color1, 1);
}