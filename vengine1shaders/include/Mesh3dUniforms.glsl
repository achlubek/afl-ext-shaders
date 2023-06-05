//uniform mat4 ViewMatrix;
//uniform mat4 ProjectionMatrix;
uniform mat4 VPMatrix;

const int MAX_LIGHTS = 6;
uniform int LightsCount;
uniform mat4 LightsPs[MAX_LIGHTS];
uniform mat4 LightsVs[MAX_LIGHTS];
uniform int LightsShadowMapsLayer[MAX_LIGHTS];
uniform vec3 LightsPos[MAX_LIGHTS];
uniform float LightsFarPlane[MAX_LIGHTS];
uniform vec4 LightsColors[MAX_LIGHTS];
uniform float LightsBlurFactors[MAX_LIGHTS];
uniform int LightsExclusionGroups[MAX_LIGHTS];

uniform vec4 LightsConeLB[MAX_LIGHTS];
uniform vec4 LightsConeLB2BR[MAX_LIGHTS];
uniform vec4 LightsConeLB2TL[MAX_LIGHTS];


const int MAX_SUN_CASCADES = 10;
uniform vec3 SunColor;
uniform vec3 SunDirection;
uniform int SunCascadeCount;
uniform mat4 SunMatricesP[MAX_SUN_CASCADES];
uniform mat4 SunMatricesV[MAX_SUN_CASCADES];


uniform int Instances;

struct ModelInfo{
	vec4 Rotation;
	vec3 Translation;
	uint Id;
	vec4 Scale;
};

layout (std430, binding = 0) buffer MMBuffer
{
  ModelInfo ModelInfos[]; 
}; 

#include Quaternions.glsl

vec3 transform_vertex(int info, vec3 vertex){
	vec3 result = vertex;
	result *= ModelInfos[info].Scale.xyz;
	result = quat_mul_vec(ModelInfos[info].Rotation, result);
	result += ModelInfos[info].Translation.xyz;
	return result;
}

uniform vec3 CameraPosition;
//uniform vec3 CameraDirection;
uniform float Time;
uniform float Brightness;
/*
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

#define Roughness currentMaterial.roughnessAndParallaxHeightAndAlpha.x
#define ParallaxHeightMultiplier currentMaterial.roughnessAndParallaxHeightAndAlpha.y
#define Alpha currentMaterial.roughnessAndParallaxHeightAndAlpha.z*/
//uniform float Metalness;

uniform vec3 SpecularColor;
uniform vec3 DiffuseColor;

uniform float Roughness;
uniform float ParallaxHeightMultiplier;
uniform float Alpha;

uniform int NormalTexEnabled;
uniform int BumpTexEnabled;
uniform int AlphaTexEnabled;
uniform int RoughnessTexEnabled;
uniform int DiffuseTexEnabled;
uniform int SpecularTexEnabled;

#define UseNormalsTex (NormalTexEnabled > 0)
#define UseBumpTex (BumpTexEnabled > 0)
#define UseAlphaTex (AlphaTexEnabled > 0)
#define UseRoughnessTex (RoughnessTexEnabled > 0)
#define UseDiffuseTex (DiffuseTexEnabled > 0)
#define UseSpecularTex (SpecularTexEnabled > 0)

uniform vec2 resolution;
float ratio = resolution.y/resolution.x;

uniform int UseVDAO;
uniform int UseHBAO;
uniform int UseFog;
uniform int UseBloom;
uniform int UseDeferred;
uniform int UseDepth;
uniform int UseCubeMapGI;
uniform int UseRSM;
uniform int UseVXGI;
