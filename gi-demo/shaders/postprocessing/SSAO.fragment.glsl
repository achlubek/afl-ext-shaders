#version 430 core

in vec2 UV;
#include Lighting.glsl
#include LogDepth.glsl

out vec4 outColor;

layout(binding = 0) uniform sampler2D texColor;
layout(binding = 1) uniform sampler2D texDepth;
layout(binding = 30) uniform sampler2D worldPosTex;
layout(binding = 31) uniform sampler2D normalsTex;

	
float getSSAOAmount(){
	vec3 normalCenter = texture(normalsTex, UV).rgb;	
	vec3 positionCenter = texture(worldPosTex, UV).rgb;	
	float distanceToCamera = distance(CameraPosition, positionCenter);
	float ssao = 0.0;
	int counter = 0;
	// pass 1 - normals
	for(float size = 6.0; size < 20.0; size += 4.5){
		for(float x = 0; x < mPI2 * 2; x+=GOLDEN_RATIO){ 
			for(float y=0;y<4;y+= 1.0){  
				vec2 crd = vec2(sin(x), cos(x)) * (y * 0.0176 * size / (distanceToCamera + 1.0));
				vec3 normalThere = texture(normalsTex, UV + crd).rgb;
				vec3 positionThere = texture(worldPosTex, UV + crd).rgb;
				if(distance(positionThere, positionCenter) > 1.00) continue;
				float dotProduct1 = clamp(1.0 - dot(normalCenter, normalThere), 0.0, 1.0);
				ssao += dotProduct1 / (size / 10);
				counter++;
			}
		}
	}/*
	//pass 2 - distance
	for(float x = 0; x < mPI2 * 2; x+=GOLDEN_RATIO){ 
        for(float y=0;y<12;y+= 1.0){  
			vec2 crd = vec2(sin(x), cos(x)) * (y * 0.026 / (distanceToCamera + 1.0));
			vec3 normalThere = texture(normalsTex, UV + crd).rgb;
			vec3 positionThere = texture(worldPosTex, UV + crd).rgb;
			if(distance(positionThere, positionCenter) > 1.00) continue;
			float dotProduct2 = clamp(distance(positionCenter, positionThere) / 8.0, 0.0, 1.0);
			ssao += dotProduct2;
			counter++;
		}
	}*/
	
	
	return ssao / counter * 1.0;
}

void main()
{
	vec3 color1 = texture(texColor, UV).rgb;
	float depth = texture(texDepth, UV).r;
	gl_FragDepth = depth;
	//float ssao = getSSAOAmount();
	float ssao = 0.0;
    outColor = vec4(clamp(color1 - ssao, 0.0, 1.0), 1);
	//outColor = vec4(clamp(vec3(1) - ssao, 0.0, 1.0), 1);
}