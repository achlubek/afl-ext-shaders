#version 430 core

in vec2 UV;
#include LogDepth.glsl
#include Lighting.glsl
#include UsefulIncludes.glsl
#include Shade.glsl
#include FXAA.glsl

uniform int Numbers[12];
uniform int NumbersCount;


//uniform float Brightness;

out vec4 outColor;




uniform float LensBlurAmount;
uniform float CameraCurrentDepth;

uniform int DisablePostEffects;
float centerDepth;
#define mPI (3.14159265)

float ngonsides = 5;
float sideLength = sqrt(1+1-2*cos(mPI2 / ngonsides));

float PIOverSides = mPI2/ngonsides;
float PIOverSidesOver2 = PIOverSides/2;
float triangleHeight = 0.85;
uniform int ShowSelected;
uniform int UnbiasedIntegrateRenderMode;


float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}


vec2 dofsamplesSpeed[] = vec2[](
vec2(0.5, 0.5),

vec2(0.25, 0.5),
vec2(0.75, 0.5),

vec2(0.5, 0.25),
vec2(0.5, 0.75),

vec2(0.25, 0.25),
vec2(0.75, 0.75),

vec2(0.75, 0.25),
vec2(0.75, 0.25),


vec2(0.33, 0.5),
vec2(0.66, 0.5),

vec2(0.5, 0.33),
vec2(0.5, 0.66),

vec2(0.33, 0.33),
vec2(0.66, 0.66),

vec2(0.66, 0.33),
vec2(0.66, 0.33)
);

uniform float InputFocalLength;
float getAmountForDistance(float focus, float dist){

	float f = InputFocalLength;
	float d = focus*1000.0; //focal plane in mm
	float o = dist*1000.0; //depth in mm
	
	float fstop = 64.0 / LensBlurAmount;
	float CoC = 1.0;
	float a = (o*f)/(o-f); 
	float b = (d*f)/(d-f); 
	float c = (d-f)/(d*fstop*CoC); 
	
	float blur = abs(a-b)*c;
	return blur;
}

vec3 lensblur(float amount, float depthfocus, float max_radius, float samples){
    vec3 finalColor = vec3(0);  
    float weight = 0.0;//vec4(0.,0.,0.,0.);  
    if(amount < 0.05) amount = 0.05;
    amount -= 0.05;
	amount = min(amount, 1.1);
    //amount = max(0, amount - 0.1);
    //return textureLod(currentTex, UV, amount*2).rgb;
    float radius = max_radius;  
    float centerDepthDistance = abs((centerDepth) - (depthfocus));
    //float centerDepth = texture(texDepth, UV).r;
    float focus = length(reconstructCameraSpace(vec2(0.5)));
    float cc = textureMSAA(normalsDistancetex, UV, 0).a;
	
	float iter = 1.0;
	for(int ix=0;ix<4;ix++){
		float rot = rand2d(UV + iter) * 3.1415 * 2;
		iter += 1.0;
		mat2 RM = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
		for(int i=0;i<dofsamplesSpeed.length();i++){ 
				
			
			vec2 crd = RM * (dofsamplesSpeed[i] * 2 - 1) * vec2(ratio, 1.0);
			//float alpha = texture(alphaMaskTex, crd*1.41421).r;
			//if(length(crd) > 1.0) continue;
			vec2 coord = UV+crd * 0.02 * amount;  
			coord = clamp(coord, 0.0, 1.0);
			//coord.x = clamp(abs(coord.x), 0.0, 1.0);
			//coord.y = clamp(abs(coord.y), 0.0, 1.0);
			float depth = textureMSAA(normalsDistancetex, coord, 0).a;
			
			float amountForIt = min(2, getAmountForDistance(focus, depth));
			
			vec3 texel = texture(lastStageResultTex, coord).rgb;
			//texel += texture(ssRefTex, coord).rgb;
			if(depth < 0.001) texel = vec3(1);
			float w = length(texel) + 0.1;
			
			// if 
			//w *= 
			float blurdif = abs(amount - amountForIt);
			
			float fact2 = 1.0 - blurdif * 0.1;
			
			w *= clamp(fact2, 0.001, 1.0);
			
			finalColor += texel * w;
			weight += w;
		}
    }
    return weight == 0.0 ? vec3(0.0) : finalColor/weight;
}


vec3 vec3pow(vec3 inputx, float po){
    return vec3(
    pow(inputx.x, po),
    pow(inputx.y, po),
    pow(inputx.z, po)
    );
}

#include noise3D.glsl

float avgdepth(vec2 buv){
    float outc = float(0);
    float counter = 0;
    float fDepth = length(reconstructCameraSpace(vec2(0.5, 0.5)).rgb);
    //
            //vec2 gauss = buv + vec2(sin(g + g2)*ratio, cos(g + g2)) * (g2 * 0.05);
            //gauss = clamp(gauss, 0.0, 0.90);
            float adepth = textureMSAA(normalsDistancetex, buv, 0).a;
            //if(adepth < fDepth) adepth = fDepth + (fDepth - adepth);
            //float avdepth = clamp(pow(abs(depth - focus), 0.9) * 53.0 * LensBlurAmount, 0.0, 4.5 * LensBlurAmount);        
            float f = InputFocalLength;
            //float f = 715.0; //focal length in mm
            float d = fDepth*1000.0; //focal plane in mm
            float o = adepth*1000.0; //depth in mm
            
            float fstop = 64.0 / LensBlurAmount;
            float CoC = 1.0;
            float a = (o*f)/(o-f); 
            float b = (d*f)/(d-f); 
            float c = (d-f)/(d*fstop*CoC); 
            
            float blur = abs(a-b)*c;
            outc += blur;
            counter++;
     //   }
   // }
    return min(abs(outc / counter), 2.0);
}



vec3 ExecutePostProcessing(vec3 color, vec2 uv){
	float vignette = distance(vec2(0), vec2(0.5)) - distance(uv, vec2(0.5));
	vignette = 0.1 + 0.9*smoothstep(0.0, 0.3, vignette);
    return vec3pow(color.rgb, 1.0) * vignette;
}

// THATS FROM PANDA 3d! Thanks tobspr
const float SRGB_ALPHA = 0.055;
float linear_to_srgb(float channel) {
    if(channel <= 0.0031308)
        return 12.92 * channel;
    else
        return (1.0 + SRGB_ALPHA) * pow(channel, 1.0/2.4) - SRGB_ALPHA;
}
vec3 rgb_to_srgb(vec3 rgb) {
    return vec3(
        linear_to_srgb(rgb.r),
        linear_to_srgb(rgb.g),
        linear_to_srgb(rgb.b)
    );
}
vec3 czm_saturation(vec3 rgb, float adjustment)
{
    // Algorithm from Chapter 16 of OpenGL Shading Language
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}
void main()
{
    vec3 color = fxaa(lastStageResultTex, UV).rgb;
    
    if(LensBlurAmount > 0.001 && DisablePostEffects == 0){
        float focus = CameraCurrentDepth;
        float adepth = textureMSAA(normalsDistancetex, vec2(0.5), 0).a;

        color = lensblur(avgdepth(UV), adepth, 0.99, 7.0);
    }

	if(DisablePostEffects == 0){
		if(UseBloom == 1) color += texture(bloomPassSource, UV).rgb * 0.2;
        color = ExecutePostProcessing(color, UV);
		//color = color / (1 + color);
		float gamma = 1.0/2.2;
        //color = czm_saturation(color, 2);
		color = rgb_to_srgb(color);
	}
    color += textureMSAAFull(albedoRoughnessTex, UV).rgb;
    outColor = clamp(vec4(color, toLogDepth(textureMSAAFull(normalsDistancetex, UV).a, 1000)), 0.0, 10000.0);
}