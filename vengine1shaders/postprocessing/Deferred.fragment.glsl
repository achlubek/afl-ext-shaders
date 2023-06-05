#version 430 core

layout(location = 0) out vec4 outColor;

uniform int DisablePostEffects;
uniform float VDAOGlobalMultiplier;

#include LogDepth.glsl

FragmentData currentFragment;

#include Lighting.glsl
vec2 UV = gl_FragCoord.xy / resolution;
#include UsefulIncludes.glsl
#include Shade.glsl
#include Direct.glsl
#include AmbientOcclusion.glsl
#include RSM.glsl

uniform vec3 LightColor;
uniform vec3 LightPosition;
uniform vec4 LightOrientation;
uniform float LightAngle;
uniform int LightUseShadowMap;
uniform int LightShadowMapType;
uniform mat4 LightVPMatrix;
uniform float LightCutOffDistance;


layout(binding = 20) uniform sampler2DShadow shadowMapSingle;

layout(binding = 21) uniform samplerCubeShadow shadowMapCube;

#define KERNEL 6
#define PCFEDGE 1
float PCFDeferred(vec2 uvi, float comparison){

    float shadow = 0.0;
    float pixSize = 1.0 / textureSize(shadowMapSingle,0).x;
    float bound = KERNEL * 0.5 - 0.5;
    bound *= PCFEDGE;
    for (float y = -bound; y <= bound; y += PCFEDGE){
        for (float x = -bound; x <= bound; x += PCFEDGE){
			vec2 uv = vec2(uvi+ vec2(x,y)* pixSize);
            shadow += texture(shadowMapSingle, vec3(uv, comparison));
        }
    }
	return shadow / (KERNEL * KERNEL);
}

vec3 getTangent(vec3 v){
	return normalize(v) == vec3(0,1,0) ? vec3(1,0,0) : normalize(cross(vec3(0,1,0), v));
}
vec3 getBiTangent(vec3 v){
	return normalize(v) == vec3(1,0,0) ? vec3(0,0,1) : normalize(cross(vec3(1,0,0), v));
}

float CubeMapShadows(vec3 dir, float comparison){
	float aaprc = 0.0;
	vec3 tang = getTangent(dir);
	vec3 bitang = getBiTangent(dir);
	for(int x = 0; x < 11; x++){
		//rd=rd.wxyz;
		vec2 rd = vec2(
			rand2s(x + currentFragment.worldPos.xy),
			rand2s(x + currentFragment.worldPos.yz)
		) *2-1;
		vec3 displace = tang * rd.x + bitang * rd.y;
        float prc = texture(shadowMapCube, vec4(normalize(dir + displace * 0.04), comparison));
		aaprc += prc;
	}
	return aaprc / 11;
}


vec3 shadingMetalic(PostProceessingData data){
    float fresnel = fresnel_again(data.normal, data.cameraPos, data.roughness);
    
    return fresnel * shade(CameraPosition, data.diffuseColor, data.normal, data.worldPos, LightPosition, LightColor, max(0.02, data.roughness), false);
}

vec3 shadingNonMetalic(PostProceessingData data){
    float fresnel = fresnel_again(data.normal, data.cameraPos, 1.0 - data.roughness);
    float fresnel2 = fresnel_again(data.normal, data.cameraPos, 0.0);
    
    vec3 radiance =  shade(CameraPosition, vec3(0.08), data.normal, data.worldPos, LightPosition, LightColor, fresnel, false);    
    
    vec3 difradiance = shade(CameraPosition, data.diffuseColor, data.normal, data.worldPos, LightPosition, LightColor, 1, false);
    return radiance + difradiance;
}

vec3 MakeShading(PostProceessingData data){
    return mix(shadingNonMetalic(data), shadingMetalic(data), data.metalness);
}
vec3 ApplyLighting(FragmentData data, int samp)
{
	vec3 result = vec3(0);
    float fresnel = fresnel_again(data.normal, data.cameraPos, data.roughness);
    
    vec3 radiance = MakeShading(data);
    
	if(LightUseShadowMap == 1){
		if(LightShadowMapType == 0){
			vec4 lightClipSpace = LightVPMatrix * vec4(data.worldPos, 1.0);
			if(lightClipSpace.z > 0.0){
				vec3 lightScreenSpace = (lightClipSpace.xyz / lightClipSpace.w) * 0.5 + 0.5;   

				float percent = 0;
				if(lightScreenSpace.x >= 0.0 && lightScreenSpace.x <= 1.0 && lightScreenSpace.y >= 0.0 && lightScreenSpace.y <= 1.0) {
					percent = PCFDeferred(lightScreenSpace.xy, toLogDepth2(distance(data.worldPos, LightPosition), 10000) - 0.001);
				}
				result += radiance * percent ;
                
                //subsurf
               /* float subsurfv = PCFDeferredValueSubSurf(lightScreenSpace.xy, distance(data.worldPos, LightPosition));
                
                result += subsurfv * data.diffuseColor;*/
                
			}
		} else if(LightShadowMapType == 1){
			
			vec3 checkdir = normalize(data.worldPos - LightPosition);
			float percent = CubeMapShadows(checkdir, toLogDepth2(distance(data.worldPos, LightPosition), 10000) - 0.001);
		
			result += radiance * percent;
		
		} 
	} else if(LightUseShadowMap == 0){
		result += radiance;
	}
	return result * (1.0 - smoothstep(0.0, LightCutOffDistance, distance(LightPosition, data.worldPos)));
}

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
        
        float stepsky = step(0.001, currentFragment.cameraDistance);
        color += stepsky * ApplyLighting(currentFragment, i);
    }
    color /= samples;
    outColor = clamp(vec4(color, 1.0), 0.0, 10000.0);
}