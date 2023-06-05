#version 430 core

in vec2 UV;
#include Lighting.glsl

layout(binding = 0) uniform sampler2D texColor;

uniform float Brightness;

out vec4 outColor;

void main()
{

	vec3 color1 = texture(texColor, UV).rgb;
	
	vec3 gamma = vec3(1.0/2.2, 1.0/2.2, 1.0/2.2) / Brightness;
	color1 = vec3(pow(color1.r, gamma.r),
                  pow(color1.g, gamma.g),
                  pow(color1.b, gamma.b));
				  
    outColor = vec4(color1, 1.0);
	
}