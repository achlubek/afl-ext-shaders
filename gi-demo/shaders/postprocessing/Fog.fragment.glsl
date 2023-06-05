#version 430 core

in vec2 UV;
#include Lighting.glsl
#include LogDepth.glsl

layout(binding = 0) uniform sampler2D texColor;
layout(binding = 1) uniform sampler2D texDepth;
layout(binding = 30) uniform sampler2D worldPosTex;
//layout(binding = 31) uniform sampler2D normalsTex;

out vec4 outColor;

const int MAX_FOG_SPACES = 256;
uniform int FogSpheresCount;
uniform vec3 FogSettings[MAX_FOG_SPACES]; //x: FogDensity, y: FogNoise, z: FogVelocity
uniform vec4 FogPositionsAndSizes[MAX_FOG_SPACES]; //w: Size
uniform vec4 FogVelocitiesAndBlur[MAX_FOG_SPACES]; //w: Blur
uniform vec4 FogColors[MAX_FOG_SPACES];

#include noise4D.glsl

#define ENABLE_FOG_NOISE

void main()
{
	vec3 color1 = vec3(0);

	vec3 fragmentPosWorld3d = texture(worldPosTex, UV).xyz;	
	
	for(int i=0;i<LightsCount;i++){
	
		mat4 lightPV = (LightsPs[i] * LightsVs[i]);
		
		
		float fogDensity = 0.0;
		float fogMultiplier = 0.5;
		
		for(float m = 0.0; m< 1.0;m+= 0.022){
			vec3 pos = mix(CameraPosition, fragmentPosWorld3d, m);
			vec4 lightClipSpace = lightPV * vec4(pos, 1.0);
			#ifdef ENABLE_FOG_NOISE
			//float fogNoise = (snoise(pos / 4.0 + vec3(0, -Time*0.2, 0)) + 1.0) / 2.0;
			float fogNoise = (snoise(vec4(pos * 4, Time)) + 1.0) / 2.0;
			#else
			float fogNoise = 1.0;
			#endif
			//float idle = 1.0 / 250.0 * fogNoise * fogMultiplier;
			float idle = 0.0;
			if(lightClipSpace.z < 0.0){ 
				fogDensity += idle;
				continue;
			}
			vec2 lightScreenSpace = ((lightClipSpace.xyz / lightClipSpace.w).xy + 1.0) / 2.0;
			if(lightScreenSpace.x < 0.0 || lightScreenSpace.x > 1.0 || lightScreenSpace.y < 0.0 || lightScreenSpace.y > 1.0){ 
				fogDensity += idle;
				continue;
			}
			if(toLogDepth(distance(pos, LightsPos[i])) < lookupDepthFromLight(i,lightScreenSpace)) {
				float culler = clamp(1.0 - distance(lightScreenSpace, vec2(0.5)) * 2.0, 0.0, 1.0);
				//float fogNoise = 1.0;
				fogDensity += idle + 1.0 / 200.0 * culler * fogNoise * fogMultiplier;
			} else {
				fogDensity += idle;
			}
		}
		color1 += LightsColors[i].xyz * LightsColors[i].a * fogDensity;
		
	}
	
    outColor = vec4(color1, 1);
}