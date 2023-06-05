#version 430 core
#include Fragment.glsl
layout(binding = 2) uniform sampler2D AlphaMask;
uniform int UseAlphaMask;

void discardIfAlphaMasked(){
	if(UseAlphaMask == 1){
		if(texture(AlphaMask, UV).r < 0.5) discard;
	}
}
void main()
{
	discardIfAlphaMasked();
	finishFragment(input_Color);
}