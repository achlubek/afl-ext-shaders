#version 430 core
layout(binding = 0) uniform sampler2D tex;
uniform vec2 Position;
uniform vec2 Size;
uniform float Alpha;
in vec2 UV;
out vec4 outColor;
void main()
{
	if(UV.x >= Position.x && UV.y >= Position.y && UV.x <= Position.x + Size.x && UV.y <= Position.y + Size.y){
		outColor = texture(tex, (UV - Position) / Size);
		outColor.a *= Alpha; 
	} else {
		outColor = vec4(1,1,1,0);
	}
}