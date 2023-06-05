layout(location = 0) out vec4 outAlbedoRoughness;
layout(location = 1) out vec4 outNormalsDistance;
layout(location = 2) out vec4 outSpecularBump;
layout(location = 3) out vec4 outOriginalNormal;
layout(location = 4) out uint outId;



uniform int DisablePostEffects;
uniform float VDAOGlobalMultiplier;

#include LogDepth.glsl
#include Lighting.glsl
#include UsefulIncludes.glsl

#include ParallaxOcclusion.glsl

uniform float NormalMapScale;

uniform int InvertNormalMap;
//vec2 UVx = gl_FragCoord.xy / resolution.xy;

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

vec3 linearize(vec3 c){
    return pow(c, vec3(2.4));
}

void main(){
	//outColor = vec4(1.0);
	//return;
    
	vec3 norm = normalize(Input.Normal);
	FragmentData currentFragment = FragmentData(
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
	
	vec2 UV = Input.TexCoord;
	if(UseBumpTex && IsTessellatedTerrain == 0) {
        UV = adjustParallaxUV();
    }
	
	mat3 TBN = mat3(
		normalize(Input.Tangent.xyz),
		normalize(cross(Input.Normal, (Input.Tangent.xyz))) * Input.Tangent.w,
		normalize(Input.Normal)
	);   
	
	if(UseNormalsTex){  
		vec3 map = texture(normalsTex, UV ).rgb;
		map = map * 2 - 1;

		map.r = - map.r;
		map.g = - map.g;
		
		currentFragment.normal = TBN * map;
	} 
	if(!UseNormalsTex && UseBumpTex){
		currentFragment.normal = TBN * examineBumpMap();
	}
	if(UseRoughnessTex) currentFragment.roughness = max(0.07, texture(roughnessTex, UV).r);
	if(UseDiffuseTex) currentFragment.diffuseColor = linearize(texture(diffuseTex, UV).rgb); 
	if(UseDiffuseTex && !UseAlphaTex)currentFragment.alpha = texture(diffuseTex, UV).a; 
	if(UseSpecularTex) currentFragment.specularColor = linearize(texture(specularTex, UV).rgb); 
	if(UseBumpTex) currentFragment.bump = texture(bumpTex, UV).r; 
	if(UseAlphaTex) currentFragment.alpha = texture(alphaTex, UV).r; 
	if(currentFragment.alpha < 0.44) discard;
	
	currentFragment.normal = quat_mul_vec(ModelInfos[Input.instanceId].Rotation, currentFragment.normal);

	outAlbedoRoughness = vec4(currentFragment.diffuseColor, currentFragment.roughness);
	outNormalsDistance = vec4(currentFragment.normal, currentFragment.cameraDistance);
	outSpecularBump = vec4(currentFragment.specularColor, currentFragment.bump);
	norm = quat_mul_vec(ModelInfos[Input.instanceId].Rotation, Input.Normal);
	norm = faceforward(norm, norm, normalize(ToCameraSpace(Input.WorldPos)));
	outOriginalNormal = vec4(norm, currentFragment.cameraDistance);
	outId = ModelInfos[Input.instanceId].Id;
}