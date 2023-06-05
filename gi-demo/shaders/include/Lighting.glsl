#include LightingSamplers.glsl
#include Mesh3dUniforms.glsl
/*
Insane lighting
Part of: https://github.com/achlubek/vengine
@author Adrian Chlubek
*/

vec2 LightScreenSpaceFromGeo[MAX_LIGHTS];
smooth in vec3 positionModelSpace;
smooth in vec3 positionWorldSpace;
smooth in vec3 normal;
smooth in vec3 barycentric;
flat in int instanceId;
uniform int UseNormalMap;
uniform int UseBumpMap;


float specular(vec3 normalin, uint index){
	vec3 lightRelativeToVPos = LightsPos[index] - positionWorldSpace.xyz;
	vec3 cameraRelativeToVPos = CameraPosition - positionWorldSpace.xyz;
	vec3 R = reflect(lightRelativeToVPos, normalin);
	float cosAlpha = -dot(normalize(cameraRelativeToVPos), normalize(R));
	return clamp(pow(cosAlpha, 80.0 / SpecularSize), 0.0, 1.0);
}

float diffuse(vec3 normalin, uint index){
	vec3 lightRelativeToVPos = LightsPos[index] - positionWorldSpace.xyz;
	float dotdiffuse = dot(normalize(lightRelativeToVPos), normalize (normalin));
	float angle = clamp(dotdiffuse, 0.0, 1.0);
	return (angle);
}

const float gaussKernel[14] = float[14](-0.028, -0.024,-0.020,-0.016,-0.012,-0.008,-0.004,.004,.008,.012,0.016,0.020,0.024,0.028); 
float getGaussianKernel(int i){
	return gaussKernel[i];
}

float lookupDepthFromLight(uint i, vec2 uv){
	mediump float distance1 = 0.0;
	if(i==0)distance1 = texture(lightDepth0, uv).r;
	else if(i==1)distance1 = texture(lightDepth1, uv).r;
	else if(i==2)distance1 = texture(lightDepth2, uv).r;
	else if(i==3)distance1 = texture(lightDepth3, uv).r;
	else if(i==4)distance1 = texture(lightDepth4, uv).r;
	else if(i==5)distance1 = texture(lightDepth5, uv).r;
	else if(i==6)distance1 = texture(lightDepth6, uv).r;
	else if(i==7)distance1 = texture(lightDepth7, uv).r;
	else if(i==8)distance1 = texture(lightDepth8, uv).r;
	else if(i==9)distance1 = texture(lightDepth9, uv).r;
	else if(i==10)distance1 = texture(lightDepth10, uv).r;
	else if(i==11)distance1 = texture(lightDepth11, uv).r;
	else if(i==12)distance1 = texture(lightDepth12, uv).r;
	else if(i==13)distance1 = texture(lightDepth13, uv).r;
	else if(i==14)distance1 = texture(lightDepth14, uv).r;
	else if(i==15)distance1 = texture(lightDepth15, uv).r;
	else if(i==16)distance1 = texture(lightDepth16, uv).r;
	else if(i==17)distance1 = texture(lightDepth17, uv).r;
	else if(i==18)distance1 = texture(lightDepth18, uv).r;
	else if(i==19)distance1 = texture(lightDepth19, uv).r;
	else if(i==20)distance1 = texture(lightDepth20, uv).r;
	else if(i==21)distance1 = texture(lightDepth21, uv).r;
	else if(i==22)distance1 = texture(lightDepth22, uv).r;
	else if(i==23)distance1 = texture(lightDepth23, uv).r;
	else if(i==24)distance1 = texture(lightDepth24, uv).r;
	else if(i==25)distance1 = texture(lightDepth25, uv).r;
	else if(i==26)distance1 = texture(lightDepth26, uv).r;
	else if(i==27)distance1 = texture(lightDepth27, uv).r;
	return distance1;
}
#define MATH_E 2.7182818284
float reverseLog(float dd){
	return pow(MATH_E, dd - 1.0) / LogEnchacer;
}

#define mPI (3.14159265)
#define mPI2 (2*3.14159265)
#define GOLDEN_RATIO (1.6180339)

float getBlurAmount(vec2 uv, uint i){
	float distanceCenter = reverseLog(lookupDepthFromLight(i, uv));
	float average = 0.0;
	vec2 fakeUV;
	int counter = 0;
    for(float x = 0; x < mPI2 * 1.5; x+=GOLDEN_RATIO){ 
        for(float y=0;y<3;y+= 1.0){  
			vec2 crd = vec2(sin(x), cos(x)) * (y * 0.002);
			fakeUV = uv + crd;
			average += reverseLog(lookupDepthFromLight(i, fakeUV));
			counter++;
		}
	}
	return abs((average / counter) - distanceCenter) * 4;
}


float getShadowPercent(vec2 uv, vec3 pos, uint i){
	float accum = 1.0;
	float distance2 = distance(pos, LightsPos[i]);
	//float distanceCam = distance(positionWorldSpace.xyz, CameraPosition);
	float distance1 = 0.0;
	vec2 fakeUV = vec2(0.0);
	float badass_depth = log(LogEnchacer*distance2 + 1.0) / log(LogEnchacer*FarPlane + 1.0f);
	//float centerDiff = abs(badass_depth - lookupDepthFromLight(i, uv)) * 10000.0;
		
	int counter = 0;
	//distance1 = lookupDepthFromLight(i, uv);
	float pssblur = getBlurAmount(uv, i) + 0.1;
	//float pssblur = 0.2;
    for(float x = 0; x < mPI2 * 2.5; x+=GOLDEN_RATIO){ 
        for(float y=0;y<4;y+= 1.0){  
			vec2 crd = vec2(sin(x), cos(x)) * y * pssblur * 0.007;
			fakeUV = uv + crd;
			distance1 = lookupDepthFromLight(i, fakeUV);
			float diff = abs(distance1 -  badass_depth);
			if(diff > 0.0003) accum += 1.0;
			counter++;
		}
	}
	return 1.0 - (accum / counter);
}
