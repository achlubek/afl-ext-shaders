#version 430 core

out vec4 outColor;
uniform int DisablePostEffects;
uniform float VDAOGlobalMultiplier;

#include LogDepth.glsl

FragmentData currentFragment;

#include Lighting.glsl
vec2 UV = gl_FragCoord.xy / resolution;
#include UsefulIncludes.glsl
#include Shade.glsl
#include EnvironmentLight.glsl


void main()
{	
    
    float MSAASampleFrequency = MSAADifference(albedoRoughnessTex, UV);
    int samples = min(int(mix(1, 8, MSAASampleFrequency)), 8);
    vec3 color  = vec3(0);
    
    for(int i=0;i<samples;i++){
        vec4 albedoRoughnessData = textureMSAA(albedoRoughnessTex, UV, i);
        vec4 normalsDistanceData = textureMSAA(normalsDistancetex, UV, i);
        vec4 specularBumpData = textureMSAA(specularBumpTex, UV, i);
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
        
	    color += EnvironmentLightSkybox(currentFragment).rgb;
        
    }
    color /= samples;
    outColor = clamp(color.rgbb, 0.0, 10000.0);
}