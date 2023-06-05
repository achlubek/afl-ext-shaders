#version 430 core

in vec2 UV;
out float outColor;
uniform int DisablePostEffects;
uniform float VDAOGlobalMultiplier;

#include LogDepth.glsl

FragmentData currentFragment;

#include Lighting.glsl
#include UsefulIncludes.glsl
#include Shade.glsl
#include AmbientOcclusion.glsl


void main()
{	
	vec4 albedoRoughnessData = textureMSAA(albedoRoughnessTex, UV, 0);
	vec4 normalsDistanceData = textureMSAA(normalsDistancetex, UV, 0);
	vec4 specularBumpData = textureMSAA(specularBumpTex, UV, 0);
	vec3 camSpacePos = reconstructCameraSpaceDistance(UV, normalsDistanceData.a);
	vec3 worldPos = FromCameraSpace(camSpacePos);
	
	currentFragment = FragmentData(
		albedoRoughnessData.rgb,
		specularBumpData.rgb,
		normalsDistanceData.rgb,
		vec3(1,0,0),
		worldPos,
		camSpacePos,	
		normalsDistanceData.a,
		1.0,
		albedoRoughnessData.a,
		specularBumpData.a
	);	
	
	float color = AmbientOcclusion(currentFragment);
    outColor = clamp(color, 0.0, 1.0);
}