
#include_once Mesh3dUniforms.glsl

struct FragmentData
{
	vec3 diffuseColor;
	vec3 specularColor;
	vec3 normal;
	vec3 tangent;
	vec3 worldPos;
	vec3 cameraPos;
	float cameraDistance;
	float alpha;
	float roughness;
	float bump;
};


in Data {
#include InOutStageLayout.glsl
} Input; 
#define FarPlane (10000.0f)
