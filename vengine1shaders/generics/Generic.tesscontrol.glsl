#version 430 core
#include Mesh3dUniforms.glsl

// define the number of CPs in the output patch
layout (vertices = 3) out;

uniform vec3 gEyeWorldPos;
in Data {
#include InOutStageLayout.glsl
} Input[];
out Data {
#include InOutStageLayout.glsl
} Output[];

uniform float TessellationMultiplier;

vec2 ss(vec3 pos){
    vec4 tmp = (VPMatrix * vec4(pos, 1.0));
    return tmp.xy / tmp.w;
}

float liness(vec3 p1, vec3 p2){
    return distance(ss(p1), ss(p2));
}

void main()
{
    Output[gl_InvocationID].TexCoord = Input[gl_InvocationID].TexCoord;
    Output[gl_InvocationID].Normal = Input[gl_InvocationID].Normal;
    Output[gl_InvocationID].WorldPos = Input[gl_InvocationID].WorldPos;
    Output[gl_InvocationID].Tangent = Input[gl_InvocationID].Tangent;
    Output[gl_InvocationID].Data = Input[gl_InvocationID].Data;
    Output[gl_InvocationID].instanceId = Input[gl_InvocationID].instanceId;


    gl_TessLevelOuter[2] = clamp(liness(Input[0].WorldPos, Input[1].WorldPos) * 128 * TessellationMultiplier, 1, 32);
    gl_TessLevelOuter[0] = clamp(liness(Input[1].WorldPos, Input[2].WorldPos) * 128 * TessellationMultiplier, 1, 32);
    gl_TessLevelOuter[1] = clamp(liness(Input[2].WorldPos, Input[0].WorldPos) * 128 * TessellationMultiplier, 1, 32);
    gl_TessLevelInner[0] = gl_TessLevelOuter[0];
    gl_TessLevelInner[1] = gl_TessLevelOuter[1];

}