#version 430 core

in vec2 UV;
#include LogDepth.glsl
#include Lighting.glsl
#include UsefulIncludes.glsl
#include Shade.glsl
#include FXAA.glsl

out vec4 outColor;


 
void main()
{

    vec3 color = texture(lastStageResultTex, UV).rgb;
    
    //float AOValue = 1.0;
    //if(UseHBAO == 1) AOValue = lookupAO(UV, 1.0, 0);
    
    if(UseVXGI == 1) color += texture(vxgiTex, UV).rgb;
    color *= Brightness;
    
    outColor = clamp(vec4(color, 1.0), 0.0, 10000.0);
}