#version 430 core

layout(location = 0) out vec4 outDiffuseColorDistance;
layout(location = 1) out vec4 outNormals;
in Data {
#include InOutStageLayout.glsl
} Input;
#include Mesh3dUniforms.glsl
#include LightingSamplers.glsl
#include UsefulIncludes.glsl
#include Shade.glsl
#include LogDepth2.glsl

uniform vec3 LightColor;

vec3 getSimpleLighting(){
	vec3 diffuse = DiffuseColor;
	if(UseDiffuseTex) diffuse = texture(diffuseTex, Input.TexCoord).rgb;
	
	vec3 specular = SpecularColor;
	if(UseSpecularTex) specular = texture(specularTex, Input.TexCoord).rgb; 
	
	float roughness = Roughness;
	if(UseRoughnessTex) roughness = texture(roughnessTex, Input.TexCoord).r; 
	
	vec3 radiance = shade(CameraPosition, specular, Input.Normal, Input.WorldPos, CameraPosition, LightColor, roughness, false) * (roughness);
	
	vec3 difradiance = shade(CameraPosition, diffuse, Input.Normal, Input.WorldPos, CameraPosition, LightColor, 1.0, false) * (roughness + 1.0);
	
	return (radiance + difradiance) * 0.5;
}

void main()
{
	float alph = Alpha;
	if(UseAlphaTex) alph = texture(alphaTex, Input.TexCoord).r; 
	
	if(UseDiffuseTex && !UseAlphaTex)alph = texture(diffuseTex, Input.TexCoord).a; 
	if(alph < 0.99) discard;
	float dist = distance(CameraPosition, Input.WorldPos);
	outDiffuseColorDistance = vec4(getSimpleLighting(), dist);
	
	gl_FragDepth = toLogDepth2(dist, 10000);
	
	outNormals = vec4(quat_mul_vec(ModelInfos[Input.instanceId].Rotation, normalize(Input.Normal)), dist);
	
}