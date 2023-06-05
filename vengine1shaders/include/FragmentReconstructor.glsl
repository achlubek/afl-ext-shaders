

struct Material{
	vec4 diffuseColor;
	vec4 specularColor;
	vec4 roughnessAndParallaxHeight;
	
	uvec2 diffuseAddr;
	uvec2 specularAddr;
	uvec2 alphaAddr;
	uvec2 roughnessAddr;
	uvec2 bumpAddr;
	uvec2 normalAddr;
};

layout (std430, binding = 7) buffer MatBuffer
{
  Material Materials[]; 
};
uniform int MaterialIndex;

Material getCurrentMaterial(){
	//return Materials[MaterialIndex];
	Material mat = Material(
		Materials[MaterialIndex].diffuseColor,
		Materials[MaterialIndex].specularColor,
		Materials[MaterialIndex].roughnessAndParallaxHeight,
		
		Materials[MaterialIndex].diffuseAddr,
		Materials[MaterialIndex].specularAddr,
		Materials[MaterialIndex].alphaAddr,
		Materials[MaterialIndex].roughnessAddr,
		Materials[MaterialIndex].bumpAddr,
		Materials[MaterialIndex].normalAddr
	);
	return mat;
}


Material currentMaterial = getCurrentMaterial();


#define SpecularColor currentMaterial.specularColor.xyz
#define DiffuseColor currentMaterial.diffuseColor.xyz


#define UseNormalsTex (currentMaterial.normalAddr.x > 0)
#define UseBumpTex (currentMaterial.bumpAddr.x > 0)
#define UseAlphaTex (currentMaterial.alphaAddr.x > 0)
#define UseRoughnessTex (currentMaterial.roughnessAddr.x > 0)
#define UseDiffuseTex (currentMaterial.diffuseAddr.x > 0)
#define UseSpecularTex (currentMaterial.specularAddr.x > 0)


#extension GL_ARB_bindless_texture : require
#define bumpTex sampler2D(currentMaterial.bumpAddr)
#define alphaTex sampler2D(currentMaterial.alphaAddr)
#define diffuseTex sampler2D(currentMaterial.diffuseAddr)
#define normalsTex sampler2D(currentMaterial.normalAddr)
#define specularTex sampler2D(currentMaterial.specularAddr)
#define roughnessTex sampler2D(currentMaterial.roughnessAddr)

#define Roughness currentMaterial.roughnessAndParallaxHeight.x
#define ParallaxHeightMultiplier currentMaterial.roughnessAndParallaxHeight.y

/*
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
}*/

FragmentData ReconstructFragment(vec2 uv, int sampleid){	
	vec3 normal = textureMSAA(normalTex, uv, sampleid).rgb;
	vec4 tangent = textureMSAA(tangentTex, uv, sampleid).rgba;
	vec4 UVMaterialDistanceData = textureMSAA(uvMaterialDistanceTex, uv, sampleid).rgba;
	
	vec2 texcoord = UVMaterialDistanceData.xy;
	//currentMaterial = Materials[0]; 
	vec3 camSpacePos = reconstructCameraSpaceDistance(uv, UVMaterialDistanceData.a);
	vec3 worldPos = FromCameraSpace(camSpacePos);
		
	FragmentData cf = FragmentData(
		DiffuseColor,
		SpecularColor,
		normalize(normal),
		normalize(tangent.xyz),
		worldPos,
		camSpacePos,
		length(camSpacePos),
		1.0,
		Roughness,
		0.0
	);	
	
	//if(UseBumpTex && IsTessellatedTerrain == 0) {
    //    UV = adjustParallaxUV();
    //}
	/*
	mat3 TBN = mat3(
		normalize(tangent.xyz),
		normalize(cross(normal, (tangent.xyz))) * tangent.w,
		normalize(normal)
	);   
	
	if(UseNormalsTex){  
		vec3 map = texture(normalsTex, texcoord ).rgb;
		map = map * 2 - 1;

		map.r = - map.r;
		map.g = - map.g;
		
		cf.normal = TBN * map;
	} */
	//if(!UseNormalsTex && UseBumpTex){
	//	cf.normal = TBN * examineBumpMap();
	//}
	
	if(UseRoughnessTex) cf.roughness = max(0.07, texture(roughnessTex, texcoord).r);
	if(UseDiffuseTex) cf.diffuseColor = texture(diffuseTex, texcoord).rgb; 
	//if(UseDiffuseTex && !UseAlphaTex)cf.alpha = texture(diffuseTex, UV).r; 
	if(UseSpecularTex) cf.specularColor = texture(specularTex, texcoord).rgb; 
	if(UseBumpTex) cf.bump = texture(bumpTex, texcoord).r; 
	if(UseAlphaTex) cf.alpha = texture(alphaTex, texcoord).r; 
	
	return cf;
}