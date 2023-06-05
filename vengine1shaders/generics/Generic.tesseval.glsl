#version 430 core

layout(triangles, fractional_odd_spacing, ccw) in;

#include Mesh3dUniforms.glsl
#include LightingSamplers.glsl

in Data {
#include InOutStageLayout.glsl
} Input[];
out Data {
#include InOutStageLayout.glsl
} Output;

uniform int MaterialType;

#define MaterialTypeSolid 0
#define MaterialTypeRandomlyDisplaced 1
#define MaterialTypeWater 2
#define MaterialTypeSky 3
#define MaterialTypeWetDrops 4
#define MaterialTypeGrass 5
#define MaterialTypePlanetSurface 6
#define MaterialTypeTessellatedTerrain 7

uniform int UseBumpMap;
layout(binding = 29) uniform sampler2D bumpMap;


#include noise3D.glsl

vec2 interpolate2D(vec2 v0, vec2 v1, vec2 v2)
{
	return vec2(gl_TessCoord.x) * v0 + vec2(gl_TessCoord.y) * v1 + vec2(gl_TessCoord.z) * v2;
}

vec3 interpolate3D(vec3 v0, vec3 v1, vec3 v2)
{
	return vec3(gl_TessCoord.x) * v0 + vec3(gl_TessCoord.y )* v1 + vec3(gl_TessCoord.z) * v2;
}
vec4 interpolate4D(vec4 v0, vec4 v1, vec4 v2)
{
	return vec4(gl_TessCoord.x) * v0 + vec4(gl_TessCoord.y )* v1 + vec4(gl_TessCoord.z) * v2;
}

float sns(vec2 p, float scale, float tscale){
	return snoise(vec3(p.x*scale, p.y*scale, Time * tscale * 0.5));
}
float getwater( vec2 position ) {

	float color = 0.0;
	color += sns(position + vec2(Time/3, Time/13), 0.03, 1.2) * 40;
	color += sns(position, 0.1, 1.2) * 10;
	color += sns(position, 0.25, 2.)*6;
	color += sns(position, 0.38, 3.)*3;
	//color += sns(position, 4., 2.)*0.9;
	// color += sns(position, 7., 6.)*0.3;
	//color += sns(position, 15., 2.)*0.7;
	//color += sns(position, 2., 2.) * 1.2;
	return color / 7.0;

}

float getPlanetSurface(){
	vec3 wpos = Output.WorldPos * 0.00111;
	float factor = snoise(wpos) * 12;
	factor += snoise(wpos * 0.1) * 20;
	factor += snoise(wpos * 0.06) * 50;
	factor += snoise(wpos * 0.01) * 80;
	return factor * 1;
}

uniform int IsTessellatedTerrain;
uniform float TessellationMultiplier;

float GetTerrainHeight(vec2 uv){
	return texture(bumpTex, uv).r * ParallaxHeightMultiplier; 
}

void main()
{
	// Interpolate the attributes of the output vertex using the barycentric coordinates
	vec2 UV = interpolate2D(Input[0].TexCoord, Input[1].TexCoord, Input[2].TexCoord);
	Output.TexCoord = UV;
	//barycentric = interpolate3D(Input[0].Barycentric, Input[1].Barycentric, Input[2].Barycentric);
	vec3 normal = interpolate3D(Input[0].Normal, Input[1].Normal, Input[2].Normal);
	Output.Tangent = interpolate4D(Input[0].Tangent, Input[1].Tangent, Input[2].Tangent);
	Output.WorldPos = interpolate3D(Input[0].WorldPos, Input[1].WorldPos, Input[2].WorldPos);
	// Displace the vertex along the normal
	Output.instanceId = Input[0].instanceId;
	Output.Data = Input[0].Data;
	
	Output.Normal = normalize(normal);
	
	//Output.WorldPos += getwater(UV);
	//Output.WorldPos += normalize(normal) * 11*sns(UV, 0.1, 1.0);
	//Output.WorldPos += normalize(normal) * sns(UV, 2.1, 0.1);
	Output.WorldPos += normalize(normal) * GetTerrainHeight(UV);
	
	gl_Position = VPMatrix * vec4(Output.WorldPos, 1.0);
}
/**/