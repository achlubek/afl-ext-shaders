#version 430 core
layout(invocations = 1) in;
layout(triangles) in;
layout(triangle_strip, max_vertices = 96) out;

#include Mesh3dUniforms.glsl
mat4 PV = (VPMatrix);

in Data {
#include InOutStageLayout.glsl
} gs_in[];

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
#define MaterialTypeFlag 8

#define MaterialTypePlastic 9
#define MaterialTypeMetal 10

#define MaterialTypeParallax 11

#include noise4D.glsl

// input 3 vertices
// output 3 to 32 vertices
vec2 interpolate2D(vec3 interpolator, vec2 v0, vec2 v1, vec2 v2)
{
       return vec2(interpolator.x) * v0 + vec2(interpolator.y) * v1 + vec2(interpolator.z) * v2;
}

vec3 interpolate3D(vec3 interpolator, vec3 v0, vec3 v1, vec3 v2)
{
       return vec3(interpolator.x) * v0 + vec3(interpolator.y )* v1 + vec3(interpolator.z) * v2;
}
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
uniform int UseBumpMap;
layout(binding = 29) uniform sampler2D bumpMap;


void FixNormals(){
    if(gl_InvocationID > 1) return;
    vec3 n = normalize(cross(gs_in[1].WorldPos - gs_in[0].WorldPos, gs_in[2].WorldPos - gs_in[0].WorldPos));
    for(int i=0;i<3;i++){
        Output.instanceId = gs_in[0].instanceId;
        Output.WorldPos = gs_in[i].WorldPos;
        Output.TexCoord = gs_in[i].TexCoord;
        Output.Normal = n;
        Output.Tangent = gs_in[i].Tangent;
        gl_Position = PV * vec4(gs_in[i].WorldPos, 1);
        EmitVertex();
    }
    EndPrimitive(); 
}


void main(){
    if(MaterialType == MaterialTypeTessellatedTerrain) FixNormals();

}