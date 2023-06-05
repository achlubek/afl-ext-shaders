#version 430 core
layout(binding = 0) uniform sampler2D tex;
#include Fragment.glsl
layout(binding = 2) uniform sampler2D AlphaMask;
uniform int UseAlphaMask;

void discardIfAlphaMasked(){
	if(UseAlphaMask == 1){
		if(texture(AlphaMask, UV).r < 0.5) discard;
	}
}
float blurMask(){
	float mask = 0.0;
	int c = 0;
	for(float a = -0.01; a < 0.01; a += 0.002){
		for(float b = -0.01; b < 0.01; b += 0.002){
			mask += texture(AlphaMask, UV + vec2(a + b)).r;
			c++;
		}
	}
	return pow(mask / c, 10.0);
}
void main()
{
	discardIfAlphaMasked();
	finishFragment(texture(tex, UV));
	if(UseAlphaMask == 1){
		outColor.a = blurMask();
	}
}