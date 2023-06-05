#version 430 core

layout(location = 0) out vec4 outColor;



uniform int DisablePostEffects;
uniform float VDAOGlobalMultiplier;

#include LogDepth.glsl

vec2 UV = gl_FragCoord.xy / resolution.xy;


FragmentData currentFragment;

#include Lighting.glsl
#include UsefulIncludes.glsl
#include Shade.glsl
#include Direct.glsl
#include AmbientOcclusion.glsl
#include RSM.glsl
#include EnvironmentLight.glsl

#include ParallaxOcclusion.glsl

uniform float NormalMapScale;

uniform int InvertNormalMap;

vec2 getTexel(sampler2D t){
	return 1.0 / vec2(textureSize(t, 0));
}
vec3 examineBumpMap(){
	vec2 iuv = Input.TexCoord;
	float bc = texture(bumpTex, iuv, 0).r;
	vec2 dsp = getTexel(bumpTex);
	float bdx = texture(bumpTex, iuv).r - texture(bumpTex, iuv+vec2(dsp.x, 0)).r;
	float bdy = texture(bumpTex, iuv).r - texture(bumpTex, iuv+vec2(0, dsp.y)).r;

	vec3 tang = normalize(Input.Tangent.xyz)*6;
	vec3 bitan = normalize(cross(Input.Tangent.xyz, Input.Normal))*6 * Input.Tangent.w;;

	return normalize(vec3(0,0,1) + bdx * tang + bdy * bitan);
}

uniform int IsTessellatedTerrain;

vec3 lookupFog(vec2 fuv, float radius, int samp){
    vec3 outc =  textureLod(fogTex, fuv, 0).rgb;
    float counter = 1;
    for(float g = 0; g < mPI2; g+=0.8)
    {
        for(float g2 = 0.05; g2 < 1.0; g2+=0.14)
        {
            vec2 gauss = vec2(sin(g + g2*6)*ratio, cos(g + g2*6)) * (g2 * 0.012 * radius);
            vec3 color = textureLod(fogTex, fuv + gauss, 0).rgb;
			float w = 1.0 - smoothstep(0.0, 1.0, g2);
			outc += color * w;
			counter+=w;
            
        }
    }
    return outc / counter;
}


vec3 ApplyLighting(FragmentData data){
	vec3 result = vec3(0);
	 //result += DirectLight(data);
	result += EnvironmentLightSkybox(data);
	//if(UseRSM == 1) result += RSM(data);
	//if(UseFog == 1) result += lookupFog(UV, 1.0, 0);
	if(UseDepth == 1) result = mix(result, vec3(1), 1.0 - CalculateFallof(data.cameraDistance*0.1));
	//if(UseVDAO == 0 && UseRSM == 0 && UseHBAO == 1) result = vec3(AOValue * 0.5);
	return result;
}


#define PASS_ADDITIVE
#define PASS_ALPHA
uniform int ForwardPass;

void main(){
	vec3 norm = normalize(Input.Normal);
	norm = faceforward(norm, norm, normalize(ToCameraSpace(Input.WorldPos)));
	currentFragment = FragmentData(
		DiffuseColor,
		SpecularColor,
		norm,
		normalize(Input.Tangent.xyz),
		Input.WorldPos,
		ToCameraSpace(Input.WorldPos),
		distance(CameraPosition, Input.WorldPos),
		1.0,
		Roughness,
		0.0
	);	
	
	vec2 UVx = Input.TexCoord;
	if(UseBumpTex && IsTessellatedTerrain == 0) {
        UVx = adjustParallaxUV();
    }
	
	mat3 TBN = mat3(
		normalize(Input.Tangent.xyz),
		normalize(cross(Input.Normal, (Input.Tangent.xyz))) * Input.Tangent.w,
		normalize(Input.Normal)
	);   
	
	if(UseNormalsTex){  
		vec3 map = texture(normalsTex, UVx ).rgb;
		map = map * 2 - 1;

		map.r = - map.r;
		map.g = - map.g;
		
		currentFragment.normal = TBN * map;
	} 
	if(!UseNormalsTex && UseBumpTex){
		currentFragment.normal = TBN * examineBumpMap();
	}
	if(UseRoughnessTex) currentFragment.roughness = max(0.07, texture(roughnessTex, UVx).r);
	if(UseDiffuseTex) currentFragment.diffuseColor = texture(diffuseTex, UVx).rgb; 
	
	if(UseDiffuseTex && !UseAlphaTex)currentFragment.alpha = texture(diffuseTex, UVx).a; 
	
	if(UseSpecularTex) currentFragment.specularColor = texture(specularTex, UVx).rgb; 
	if(UseBumpTex) currentFragment.bump = texture(bumpTex, UVx).r; 
	if(UseAlphaTex) currentFragment.alpha = texture(alphaTex, UVx).r;
	
	float texdst = textureMSAAFull(normalsDistancetex, UV).a;
	if(texdst > 0.001 && texdst < currentFragment.cameraDistance) discard;
	//if(ForwardPass == 0 && currentFragment.alpha < 0.99) discard;
	//if(ForwardPass == 1 && currentFragment.alpha > 0.99) discard;
	
	//gl_FragDepth = toLogDepth2(distance(CameraPosition, Input.WorldPos), 10000);
	
	currentFragment.normal = quat_mul_vec(ModelInfos[Input.instanceId].Rotation, currentFragment.normal);

	//outColor = vec4(ApplyLighting(currentFragment), currentFragment.alpha);
	outColor = vec4(currentFragment.diffuseColor, 0.2);
}