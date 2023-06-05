#version 430 core

in vec2 UV;
#include LogDepth.glsl
#include Lighting.glsl
#include UsefulIncludes.glsl
#include Shade.glsl
#include FXAA.glsl

out vec4 outColor;

FragmentData currentFragment;

#include VXGITracing.glsl

float lookupAO(vec2 fuv, float radius, int samp){
     float outc = 0;
     float counter = 0;
     float depthCenter = textureMSAA(originalNormalsTex, fuv, samp).a;
 	vec3 normalcenter = textureMSAA(originalNormalsTex, fuv, samp).rgb;
     for(float g = 0; g < mPI2; g+=0.8)
     {
         for(float g2 = 0; g2 < 1.0; g2+=0.33)
         {
             vec2 gauss = vec2(sin(g + g2*6)*ratio, cos(g + g2*6)) * (g2 * 0.012 * radius);
             float color = textureLod(aoTex, fuv + gauss, 0).r;
             float depthThere = textureMSAA(originalNormalsTex, fuv + gauss, samp).a;
 			vec3 normalthere = textureMSAA(originalNormalsTex, fuv + gauss, samp).rgb;
 			float weight = pow(max(0, dot(normalthere, normalcenter)), 32);
 			outc += color * weight;
 			counter+=weight;
             
         }
     }
     return counter == 0 ? textureLod(aoTex, fuv, 0).r : outc / counter;
 }
 
void main()
{
    vec3 color = vec3(0);
    
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
    float AOValue = 1.0;
    if(UseHBAO == 1) AOValue = lookupAO(UV, 1.0, 0);
   // vec3 ao = traceConeAOx(currentFragment);
    color +=  traceConeDiffuse(currentFragment) * 8;
    //color +=  traceConeSpecular(currentFragment) * specularBumpData.rgb * mix(1, AOValue, currentFragment.roughness);
   // color += debugVoxel();
    /*
    color = traceVisDir(vec3(-2, 1, 0)) 
    + traceVisDir(vec3(-1, 1, 0)) 
    + traceVisDir(vec3(0, 1, 0)) 
    + traceVisDir(vec3(1, 1, 0)) 
    + traceVisDir(vec3(2, 1, 0));
    color *= 0.2;*/
    //color += max(vec3(0.0), albedoRoughnessData.rgb - 1.0);
    
    vec3 last = texture(forwardPassBuffer, UV).rgb;
    color = mix(last, color, 0.1);
    
    outColor = clamp(vec4(color, 0), 0.0, 10000.0);
}