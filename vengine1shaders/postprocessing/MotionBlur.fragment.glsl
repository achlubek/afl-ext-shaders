#version 430 core

in vec2 UV;
#include LogDepth.glsl
#include Lighting.glsl
#include UsefulIncludes.glsl
#include Shade.glsl
#include FXAA.glsl

out vec4 outColor;

uniform mat4 CurrentViewMatrix;
uniform mat4 LastViewMatrix;
uniform mat4 ProjectionMatrix;

vec2 projectMotion(vec3 pos){
    vec4 tmp = (ProjectionMatrix * vec4(pos, 1.0));
    return (tmp.xy / tmp.w) * 0.5 + 0.5;
}

vec3 makeMotion(vec2 uv){
	vec4 normalsDistanceData = textureMSAA(normalsDistancetex, uv, 0);
	normalsDistanceData.a += (1.0 - step(0.001, normalsDistanceData.a)) * 10000.0;
	vec3 camSpacePos = reconstructCameraSpaceDistance(uv, normalsDistanceData.a);
	vec3 worldPos = FromCameraSpace(camSpacePos);
	
	vec3 pos1 = (CurrentViewMatrix * vec4(worldPos, 1.0)).xyz;
	vec3 pos2 = (LastViewMatrix * vec4(worldPos, 1.0)).xyz;
	vec2 direction = (projectMotion(pos2) - projectMotion(pos1));
	if(length(direction) < (1.0/resolution.x)) return texture(lastStageResultTex, uv).rgb;
	
	vec2 lookup = uv + direction * 0.05;
	
	vec3 color = vec3(0);
	for(int i=0;i<20;i++){
		color += texture(lastStageResultTex, lookup).rgb;
		lookup += direction * 0.05;
	}
	
	return color / 20.0;
}

void main()
{
    vec3 color = makeMotion(UV);
    outColor = clamp(vec4(color, toLogDepth(textureMSAAFull(normalsDistancetex, UV).a, 1000)), 0.0, 10000.0);
}