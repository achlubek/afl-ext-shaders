#version 430 core

#include Lighting.glsl

in vec2 UV;
out vec4 outColor;

layout(binding = 0) uniform sampler2D color;
layout(binding = 1) uniform sampler2D depth;
layout(binding = 2) uniform sampler2D diffuseColor;
layout(binding = 3) uniform sampler2D worldPos;
layout(binding = 4) uniform sampler2D normals;
layout(binding = 5) uniform sampler2D lastGi;
layout(binding = 6) uniform sampler2D lastGiDepth;
layout(binding = 7) uniform sampler2D ssnormals;
layout(binding = 8) uniform sampler2D backFacesColor;
layout(binding = 9) uniform sampler2D backFacesDepth;
//layout(binding = 9) uniform sampler2D backNormals;

bool testVisibilityHiRes(vec2 uv1, vec2 uv2) {
	float d3d1 = texture(depth, uv1).r;
	float d3d2 = texture(depth, uv2).r;
	float d = (distance(uv1, uv2) + 1.0) * 3 * 0.2;
	for(float i=0;i<1.0;i+= d) { 
		vec2 ruv = mix(uv1, uv2, i);
		float rd3d = texture(depth, ruv).r;
		float bd = texture(backFacesDepth, ruv).r;
		if(rd3d < mix(d3d1, d3d2, i) && rd3d + (rd3d - bd) < mix(d3d1, d3d2, i)) {
			return false;
		}
	}
	return true;
}
bool testVisibility(vec2 uv1, vec2 uv2) {
	float d3d1 = texture(depth, uv1).r;
	float d3d2 = texture(depth, uv2).r;
	for(float i=0;i<1.0;i+= 0.1) { 
		vec2 ruv = mix(uv1, uv2, i);
		float rd3d = texture(depth, ruv).r;
		if(rd3d < mix(d3d1, d3d2, i)) {
			return false;
		}
	}
	return true;
}
bool testVisibilityUnrolled(vec2 uv1, vec2 uv2) {
	float d3d1 = texture(depth, uv1).r;
	float d3d2 = texture(depth, uv2).r;
	
	vec2 ruv = mix(uv1, uv2, 0.1);
	float rd3d = texture(depth, ruv).r;
	if(rd3d < mix(d3d1, d3d2, 0.1)) return false;
	
	ruv = mix(uv1, uv2, 0.2);
	rd3d = texture(depth, ruv).r;
	if(rd3d < mix(d3d1, d3d2, 0.2)) return false;
	
	ruv = mix(uv1, uv2, 0.3);
	rd3d = texture(depth, ruv).r;
	if(rd3d < mix(d3d1, d3d2, 0.3)) return false;
	
	ruv = mix(uv1, uv2, 0.4);
	rd3d = texture(depth, ruv).r;
	if(rd3d < mix(d3d1, d3d2, 0.4)) return false;
	
	ruv = mix(uv1, uv2, 0.5);
	rd3d = texture(depth, ruv).r;
	if(rd3d < mix(d3d1, d3d2, 0.5)) return false;
	
	ruv = mix(uv1, uv2, 0.6);
	rd3d = texture(depth, ruv).r;
	if(rd3d < mix(d3d1, d3d2, 0.6)) return false;
	
	ruv = mix(uv1, uv2, 0.7);
	rd3d = texture(depth, ruv).r;
	if(rd3d < mix(d3d1, d3d2, 0.7)) return false;
	
	ruv = mix(uv1, uv2, 0.8);
	rd3d = texture(depth, ruv).r;
	if(rd3d < mix(d3d1, d3d2, 0.8)) return false;
	
	ruv = mix(uv1, uv2, 0.9);
	rd3d = texture(depth, ruv).r;
	if(rd3d < mix(d3d1, d3d2, 0.9)) return false;
	
	ruv = mix(uv1, uv2, 1.0);
	rd3d = texture(depth, ruv).r;
	if(rd3d < mix(d3d1, d3d2, 1.0)) return false;

	return true;
}

mediump float rand(vec2 co) {
	mediump float a = 12.9898; mediump float b = 78.233; mediump float c = 43758.5453; 
	mediump float dt= dot(co.xy ,vec2(a,b)); mediump float sn= mod(dt,3.14);
	return fract(sin(sn) * c);
}

#include noise2D.glsl
float centerDepth;

vec3 bruteForceGIBounce1(vec2 centerUV) {
	vec4 normalCenter4 = texture(normals, centerUV).rgba;
	vec3 original = (texture(color, centerUV).rgb * 3 + texture(diffuseColor, centerUV).rgb) * 0.7;
	vec3 normalCenter = normalCenter4.rgb;
	vec3 positionCenter = texture(worldPos, centerUV).rgb;  
	float distanceToCamera = distance(CameraPosition, positionCenter);
	vec3 outc = vec3(0);
	vec3 CRel = CameraPosition - positionCenter;
	#define samplesx 64
	float seed = RandomSeed4 * 2134.123665756 * rand(UV);
	for(int g = 1; g < samplesx; g += 1) { 			
		float rd = seed * g;
		vec2 coord = vec2(fract(rd), fract(rd*12.545));
		if(testVisibilityUnrolled(coord, centerUV)) {
			vec3 wpos = texture(worldPos, coord).rgb;
			float worldDistance = distance(positionCenter, wpos);
			if(worldDistance < 0.12) continue;
			if(worldDistance > 18) continue;
			float att = 1.0 / pow(((worldDistance/1.0) + 1.0), 2.0) * 190.0;
			vec3 ga = texture(lastGi, coord).rgb;
			vec3 c = ((texture(color, coord).rgb + texture(diffuseColor, coord).rgb)  * 7 + ga * 1.7) * att;
			vec3 normalThere = texture(normals, coord).rgb;
			outc += c * 1.0 - clamp(dot(normalCenter, normalThere), 0.0, 1.0);
			vec3 R = reflect(wpos - positionCenter, normalCenter);
			outc += c * 3 * smoothstep(0.88, 0.9999, clamp(-dot(normalize(CRel), normalize(R)), 0, 1));
		}
	}	
	return original * ((outc / samplesx / 2)) * (distanceToCamera / 16 * (texture(ssnormals, centerUV).a));
}
vec3 lowquality(vec2 centerUV) {
	vec4 normalCenter4 = texture(normals, centerUV).rgba;
	//if(normalCenter4.a == 0) return vec3(0); // lighting disabled for that object
	vec3 original = (texture(color, centerUV).rgb * 3 + texture(diffuseColor, centerUV).rgb) * 0.7;
	vec3 positionCenter = texture(worldPos, centerUV).rgb;  
	float distanceToCamera = distance(CameraPosition, positionCenter);
	vec3 normalCenter = normalCenter4.rgb;
	//if(distanceToCamera < 0.2) return vec3(0);
	vec3 outc = vec3(0);
	int counter = 0;
	vec3 CRel = CameraPosition - positionCenter;
	#define qualityx 0.0977 / (111.8)
	const float rseed = snoise(15.2345824 * centerUV);
	for(float g = 0; g < 1; g += qualityx) { 
		counter++;
		vec2 coord = vec2(fract(centerUV.x * RandomSeed3 * 1.654642 * g), fract(centerUV.y * RandomSeed1 * 1.36854642  * g));
		
		if(testVisibility(coord, centerUV)) {
			vec3 c = (texture(color, coord).rgb * 3 + texture(diffuseColor, coord).rgb) * 0.7;
			outc += (c);
			
		}
	}
	vec3 res = vec3(0);
	if(counter != 0) res = original * ((outc / counter)) * (distanceToCamera / 16 * (texture(ssnormals, centerUV).a));
	return res;

}


bool testVisibility3d(vec2 uv1, vec3 displaced) {
	vec3 wpos = texture(worldPos, uv1).xyz;
	vec3 dis = displaced;
	
	const mat4 vpmat = (ProjectionMatrix * ViewMatrix); 
	
	float d3d1 = distance(CameraPosition, wpos);
	float d3d2 = distance(CameraPosition, dis);
	float ou = 1;
	for(float i=0.1;i<1.0;i+= 0.1) { 
		vec3 ruv = mix(wpos, dis, i);
		vec4 clipspace = vpmat * vec4(ruv, 1.0);
		if(clipspace.z < 0.0) {ou -= 0.02; continue;}
		vec2 sspace = ((clipspace.xyz / clipspace.w).xy + 1.0) / 2.0;
		float rd3d = distance(CameraPosition, texture(worldPos, sspace).xyz);
		float m = mix(d3d1, d3d2, i);
		if(rd3d < m && m - rd3d < 0.5) {
			return false;
		}
	}
	return true;
}
vec3 ambientRadiosity(vec2 centerUV) {
	vec3 original = (texture(color, centerUV).rgb * 3 + texture(diffuseColor, centerUV).rgb) * 0.7;
	vec3 positionCenter = texture(worldPos, centerUV).rgb;  
	vec3 outc = vec3(0);
	float seed = RandomSeed4 * 2134.123665756 * rand(UV);
	#define samplesxa 27
	for(int g = 1; g < samplesxa; g += 1) { 			
		float rd = seed * g;
		vec3 coord = vec3(fract(rd * RandomSeed1), fract(rd * RandomSeed2), fract(rd * RandomSeed3));
		coord = ((coord * 2.0) - 1.0);
		if(!testVisibility3d(UV, positionCenter + coord)) {
			original -= 0.03;
		}
	}
	return  original;
}


vec3 visibilityOnly() {
	vec3 original = texture(color, UV).rgb + texture(diffuseColor, UV).rgb;
	#define samples3 22.54331
	for(float g = 0; g < samples3; g += 1.112313) { 			
		float rd = rand(vec2(RandomSeed3 * 0.063123 * g * UV.x, RandomSeed1 * g * UV.y));
		vec2 coord = vec2((rd), fract(rd*12.545));
		if(testVisibility(UV, coord)) {
			original -= 0.07;
		}
	}
	return (original);
}
/*
vec3 visibilityOnly() {
	vec3 original = texture(color, UV).rgb + texture(diffuseColor, UV).rgb;
	vec3 outc = vec3(0);
	#define samples 53.54331
	for(float g = 0; g < samples; g += 1.112313) { 			
		float rd = rand(vec2(RandomSeed3 * 0.063123 * g * UV.x, RandomSeed1 * g * UV.y));
		vec2 coord = vec2((rd), fract(rd*12.545));
		if(testVisibility(UV, coord)) {
			outc -= 0.01;
		}
	}
	return (outc);
}*/

vec3 directional() {
	vec3 original = texture(color, UV).rgb + texture(diffuseColor, UV).rgb;
	vec3 outc = vec3(0);
	vec3 worldLightDir = vec3(1, 1, 1) * 3;
	vec3 positionCenter = texture(worldPos, UV).rgb;  
	vec3 displaced = positionCenter + worldLightDir;  
	mat4 PV = (ProjectionMatrix * ViewMatrix);
	#define samples 53.54331
	for(float g = 0.2; g < samples; g += 1.112313) { 			
		float rd = (rand(vec2(RandomSeed3 * 0.063123 * g, RandomSeed1 * g)) - 0.5) * 2;
		vec3 coord = mix(positionCenter, displaced, g / samples) + (vec3(1) * rd * 0.2);

		coord = ((coord * 2.0) - 1.0);
		vec4 clipspace = PV * vec4(coord, 1.0);
		//if(clipspace.z < 0.0) continue;
		vec2 sspace = ((clipspace.xyz / clipspace.w).xy + 1.0) / 2.0;
		
		//outc += original * testVisibility3d(UV, coord);
		
	}
	return (outc/samples);
}
#ifndef SEED
#define SEED 0
#endif

// afl_ext (Adrian Chlubek) global illumination explained
vec3 GlobalIlluminationVersion1() 
{
	// Get some basic data for processed pixel, like normal, original color, position in world space
	// distance to camera, and precalculate some used data too.
	vec3 normalCenter = texture(normals, UV).rgb;
	float specSize = texture(normals, UV).a;
	// Good to mix direct light color with diffuse color
	vec3 originalColor = (texture(color, UV).rgb * 30 + texture(diffuseColor, UV).rgb * 0.1) * 0.7;
	vec3 positionCenter = texture(worldPos, UV).rgb;  
	float speccomp = texture(worldPos, UV).a;  
	float distanceToCamera = distance(CameraPosition, positionCenter);
	vec3 outBuffer = vec3(0);
	vec3 cameraSpace = CameraPosition - positionCenter;
	// We are going to sample the scene 256 times per frame.
	#define samplesCount 1024
	float seed = RandomSeed1 ;
	for(int g = 1; g < samplesCount; g += 1) 
	{ 			
		// Calculate 1D seed unique for every loop iteration
		float random = seed * g;
		// Performance trick to get unique vec2 :)
		// This vec2 is in range [0,1] so use it for random UV lookup
		vec2 coord = vec2(fract(random), fract(random*12.545));
		// Let's test visibility
		if(testVisibilityUnrolled(coord, UV)) 
		{
			// Pixels see each other.
			// Get pixel world position and calculate attentuation based on pixels' distance
			vec3 worldPosition = texture(worldPos, coord).rgb;
			float worldDistance = distance(positionCenter, worldPosition);
			if(worldDistance < 0.12) continue;
			//if(worldDistance > 6.2) continue;
			float attentuation = 1.0 / pow(((worldDistance/1.0) + 1.0), 2.0) * 80.0;
			// Get last GI result so we can bounce infinitely now! That color gets mixed with selected pixel
			vec3 giLastResult = texture(lastGi, coord).rgb;
			// Get pixel color
			vec3 c = ((texture(color, coord).rgb * 30 + texture(diffuseColor, coord).rgb * 0.1)  * 26 + giLastResult * 1.7) * attentuation;
			// Get normal of that random pixel
			vec3 normalThere = texture(normals, coord).rgb;
			// calculate diffuse component and add it
			outBuffer += c * 1.0 - clamp(dot(normalCenter, normalThere), 0.0, 1.0);
			// calculate specular component and add it
			vec3 lightRelativeToVPos = worldPosition - positionCenter;
			vec3 reflected = reflect(lightRelativeToVPos, normalCenter);
			float cosAlpha = -dot(normalize(lightRelativeToVPos), normalize(reflected));
			float specularComponent = clamp(pow(cosAlpha, 80.0 / specSize), 0.0, 1.0) * speccomp;
			outBuffer += c * 10 * specularComponent;
		}
	}	
	// Return calculated buffered value divided by samples count and by camera distance.
	// Check alpha mask there too.
	return originalColor * ((outBuffer / samplesCount)) * (distanceToCamera / 16 * (texture(ssnormals, UV).a));
}

#define BUFFER 3.0
#define BUFFER1 (3.88)
void main() {
	vec3 color1 = vec3(0);
	color1 = GlobalIlluminationVersion1();
	//color1 += directional();
	//color1 = bruteForceGIBounce1(UV);
	//color1 *= ambientRadiosity(UV) * 0.8;
	color1 = clamp(color1, 0, 1);
	centerDepth = texture(depth, UV).r;
	vec3 lgi = texture(lastGi, UV).rgb;
	
	if(length(lgi) > 0.001 && !(lgi.x == 1.0 && lgi.y == 1.0 && lgi.z == 1.0)){
		color1 = (lgi * BUFFER + color1) / BUFFER1;
	}
	gl_FragDepth = centerDepth;
	outColor = vec4(color1, 1);
}