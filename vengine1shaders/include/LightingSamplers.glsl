// let get it done well this time

#pragma const deferredTexBinding 7

#ifdef USE_MSAA
layout(binding = 1) uniform sampler2DMS albedoRoughnessTex;
layout(binding = 2) uniform sampler2DMS normalsDistancetex;
layout(binding = 3) uniform sampler2DMS specularBumpTex;
layout(binding = 15) uniform sampler2DMS originalNormalsTex;
#else
layout(binding = 1) uniform sampler2D albedoRoughnessTex;
layout(binding = 2) uniform sampler2D normalsDistancetex;
layout(binding = 3) uniform sampler2D specularBumpTex;
layout(binding = 15) uniform sampler2D originalNormalsTex;
#endif

layout(binding = 4) uniform sampler2D lastStageResultTex;

layout(binding = deferredTexBinding) uniform sampler2D deferredTex;

layout(binding = 9) uniform sampler2D vxgiTex;
layout(binding = 8) uniform sampler2D envLightTex;

layout(binding = 11) uniform sampler2D bloomPassSource;

layout(binding = 12) uniform sampler2D glareTex;

layout(binding = 13) uniform sampler2D fogTex;

layout(binding = 14) uniform sampler2D aoTex;

layout(binding = 17) uniform sampler2D forwardPassBuffer;
layout(binding = 18) uniform sampler2D forwardPassBufferDepth;
layout(binding = 19) uniform sampler2D combinerTex;


layout(binding = 22) uniform sampler2DArrayShadow sunCascadesArray;


#pragma const normalsTexBind 5
#pragma const bumpTexBind 8
#pragma const alphaTexBind 0
#pragma const roughnessTexBind 7
#pragma const diffuseTexBind 16
#pragma const specularTexBind 6

layout(binding = normalsTexBind) uniform sampler2D normalsTex;
layout(binding = bumpTexBind) uniform sampler2D bumpTex;
layout(binding = alphaTexBind) uniform sampler2D alphaTex;
layout(binding = roughnessTexBind) uniform sampler2D roughnessTex;
layout(binding = diffuseTexBind) uniform sampler2D diffuseTex;
layout(binding = specularTexBind) uniform sampler2D specularTex;
//layout(binding = 8) uniform sampler2D free1Tex;
//layout(binding = 0) uniform sampler2D free1Tex;

layout(binding = 23) uniform samplerCube cube;

layout(binding = 24) uniform sampler3D voxelsNormalsTex;
layout(binding = 25) uniform sampler3D voxelsTex1;
layout(binding = 26) uniform sampler3D voxelsTex2;
layout(binding = 27) uniform sampler3D voxelsTex3;
layout(binding = 28) uniform sampler3D voxelsTex4;
layout(binding = 29) uniform sampler3D voxelsTex5;
layout(binding = 30) uniform sampler3D voxelsTex6;
//layout(binding = 26) uniform sampler2D voxelsTexTest;

//layout(binding = 8) uniform sampler2D distanceTex;

uniform int CubeMapsCount;
uniform vec4 CubeMapsPositions[233];
uniform vec4 CubeMapsFalloffs[233];
uniform uvec2 CubeMapsAddrs[233];


#ifdef USE_MSAA

#pragma regex replace loop\([ ]*([A-z0-9_-]+)[ ]*,[ ]*([A-z0-9_-]+)[ ]*\.\.[ ]*([A-z0-9_-]+).*\) with for(int $1 = $2; $1 < $3; $1++)

ivec2 txsize = textureSize(albedoRoughnessTex);
float MSAADifference(sampler2DMS tex, vec2 inUV){
    ivec2 texcoord = ivec2(vec2(txsize) * inUV); 
    vec4 color11 = texelFetch(tex, texcoord, 0);
    float diff = 0;
    for (int i=1;i<MSAA_SAMPLES;i++)
    //loop(i, i..MSAA_SAMPLES)
    {
        vec4 color2 = texelFetch(tex, texcoord, i);
        diff += distance(color11, color2);  
        color11 = color2;
    }
    return diff;
}

vec4 textureMSAAFull(sampler2DMS tex, vec2 inUV){
    vec4 color11 = vec4(0.0);
    ivec2 texcoord = ivec2(vec2(txsize) * inUV); 
    for (int i=0;i<MSAA_SAMPLES;i++)
    {
        color11 += texelFetch(tex, texcoord, i);  
    }

    color11/= MSAA_SAMPLES; 
    return color11;
}
vec4 textureMSAA(sampler2DMS tex, vec2 inUV, int samplee){
    ivec2 texcoord = ivec2(vec2(txsize) * inUV);
    return texelFetch(tex, texcoord, samplee);  
}

#else

float MSAADifference(sampler2D tex, vec2 inUV){
    return 0;
}

ivec2 txsize = textureSize(albedoRoughnessTex, 0);
vec4 textureMSAAFull(sampler2D tex, vec2 inUV){
    return texture(tex, inUV);
}
vec4 textureMSAA(sampler2D tex, vec2 inUV, int samplee){
    return texture(tex, inUV); 
}
#endif
