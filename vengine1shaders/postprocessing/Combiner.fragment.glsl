#version 430 core

in vec2 UV;
#include LogDepth.glsl
#include Lighting.glsl
#include UsefulIncludes.glsl
#include Shade.glsl
#include FXAA.glsl

out vec4 outColor;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float lookupAO(vec2 fuv, float radius, int samp){
     float outc = 0;
     float counter = 0;
     float depthCenter = textureMSAA(originalNormalsTex, fuv, samp).a;
 	vec3 normalcenter = textureMSAA(originalNormalsTex, fuv, samp).rgb;
     for(float g = 0; g < mPI2; g+=0.8)
     {
         for(float g2 = 0; g2 < 1.0; g2+=0.33)
         {
             vec2 gauss = vec2(sin(g + g2*6)*ratio, cos(g + g2*6)) * (g2 * 0.012 * radius);
             float color = textureLod(aoTex, fuv + gauss, 0).r;
             float depthThere = textureMSAA(originalNormalsTex, fuv + gauss, samp).a;
 			vec3 normalthere = textureMSAA(originalNormalsTex, fuv + gauss, samp).rgb;
 			float weight = pow(max(0, dot(normalthere, normalcenter)), 32);
 			outc += color * weight;
 			counter+=weight;
             
         }
     }
     return counter == 0 ? textureLod(aoTex, fuv, 0).r : outc / counter;
 }
 
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
 
void main()
{
    float AOValue = 1.0;
    if(UseHBAO == 1) AOValue = lookupAO(UV, 1.0, 0);
    vec3 color = vec3(0);
    if(UseDeferred == 1) color += texture(deferredTex, UV).rgb;
    if(UseVDAO == 1) color += AOValue * textureLod(envLightTex, UV, 0.0).rgb * 0.05;
    //if(UseVDAO == 0 && UseRSM == 0 && UseHBAO == 1) color = vec3(AOValue * 0.5);


	if(textureMSAAFull(normalsDistancetex, UV).a == 0.0){
        //color = texture(cube, reconstructCameraSpaceDistance(UV, 1.0)).rgb;
        color = vec3(0);
    }
    
    
    outColor = clamp(vec4(color, 1.0), 0.0, 10000.0);
}