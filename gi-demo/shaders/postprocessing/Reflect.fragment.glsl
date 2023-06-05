#version 430 core

in vec2 UV;
#include Lighting.glsl
#include LogDepth.glsl
#define mPI (3.14159265)
#define mPI2 (2*3.14159265)
#define GOLDEN_RATIO (1.6180339)
out vec4 outColor;

layout(binding = 0) uniform sampler2D color;
layout(binding = 1) uniform sampler2D depth;
layout(binding = 3) uniform sampler2D worldPos;
layout(binding = 4) uniform sampler2D normals;
layout(binding = 5) uniform sampler2D screenSpaceNormals;


float visibilityValue(vec2 uv1, vec2 uv2){
	//vec3 wpos1 = texture(worldPos, uv1).rgb;
	//vec3 wpos2 = texture(worldPos, uv2).rgb;
	float d3d1 = texture(depth, uv1).r;
	float d3d2 = texture(depth, uv2).r;
	float visible = 1.0;
	// raymarch thru
	for(float i=0;i<1.0;i+= 0.1){ 
		vec2 ruv = mix(uv1, uv2, i);
		float rd3d = texture(depth, ruv).r;
		if(rd3d < mix(d3d1, d3d2, i)){
			visible -= 0.1; 
		}
	}
	return visible;
}

mediump float rand(vec2 co)
{
    mediump float a = 12.9898;
    mediump float b = 78.233;
    mediump float c = 43758.5453;
    mediump float dt= dot(co.xy ,vec2(a,b));
    mediump float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

vec3 getAverageCross(vec2 centerUV){
	float lsize = 0.01;
	vec3 centerPos = texture(worldPos,centerUV).rgb;
	vec3 result = normalize(cross(centerPos, texture(worldPos,centerUV + vec2(lsize, lsize)).rgb));
	for(float g = 0; g < mPI2 * 4; g+=GOLDEN_RATIO)
	{ 
		for(float g2 = lsize / 10; g2 < lsize; g2+=lsize/10.0)
		{ 
			vec2 coord = centerUV + vec2(sin(g + g2)*ratio, cos(g + g2))  *  (g2 * 0.116);
			vec3 pos = texture(worldPos, centerUV + coord).rgb;
			result = result * normalize(cross(centerPos, pos).rgb);
		}
	}
	return result;
}

bool testVisibility(vec2 uv1, vec2 uv2){
	float d3d1 = texture(depth, uv1).r;
	float d3d2 = texture(depth, uv2).r;
	bool visible = true;
	for(float i=0;i<1.0;i+= 0.1){ 
		vec2 ruv = mix(uv1, uv2, i);
		float rd3d = texture(depth, ruv).r;
		if(rd3d < mix(d3d1, d3d2, i)){
			visible = false; 
			break; 
		}
	}
	return visible;
}

vec3 getReflectionBT(vec2 centerUV){
	float originalDepth = texture(depth, centerUV).r;
	vec4 positionWorld = texture(worldPos, centerUV).rgba;
	vec4 normal = texture(normals, centerUV).rgba;
	vec3 outc = vec3(0);
	int counter = 0;
	for(float g = 0; g < 1; g += 0.0477)
	{ 
		for(float g2 = 0; g2 < 1; g2 += 0.0419)
		{ 
			counter++;
			vec2 coord = vec2(g, g2);
			//float d = abs(originalDepth - texture(depth, coord).r);
			if(testVisibility(coord, centerUV)){
				vec4 wpos = texture(worldPos, coord);	
				
				vec3 lightRelativeToVPos = wpos.xyz - positionWorld.xyz;
				vec3 R = reflect(lightRelativeToVPos, normal.xyz);
				float cosAlpha = abs(dot(normalize(CameraPosition - positionWorld.xyz), normalize(R)));
				float specularComponent = clamp(pow(cosAlpha, 10.0 / normal.a), 0.0, 1.0);

				vec3 c = (texture(color, coord).rgb) * specularComponent * 100;
				outc += c;
				
			}

				//outc += 1.0;
			
		}
	}
	if(counter == 0) return vec3(0);
	vec3 result = (outc);
	return result;
}

vec3 getReflection(){
	float lsize = 0.7;
	vec3 outc = vec3(0);
	vec3 direction = texture(normals, UV).rgb;
	vec4 uvtemp = texture(screenSpaceNormals, UV).rgba;
	vec2 uvdir = normalize(((uvtemp.xyz / uvtemp.w).xy));	
	vec3 centerPos = texture(worldPos,UV).rgb;	
	vec2 findUV = vec2(0);
	float lastDistance = 99.0;
	for(float g = 0.1; g < 1.0; g+=0.001)
	{ 
		vec3 p = texture(worldPos, UV + uvdir * g).rgb;
		float d = abs(dot(normalize(centerPos - p), normalize(centerPos - direction)));
		if(d > lastDistance){
			break;
		} else {
			lastDistance = d;
			findUV = UV + uvdir * g;
		}
	}
	
	outc = texture(color, findUV).rgb / (1.0 + distance(centerPos, texture(worldPos, findUV).rgb));

	return outc;
}

void main()
{

	vec3 color1 = getReflectionBT(UV);
	gl_FragDepth = texture(depth, UV).r;
	
    outColor = vec4(color1, 1);
}