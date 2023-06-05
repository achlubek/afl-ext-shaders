#version 430 core
uniform vec2 Position;
uniform vec2 Size;
uniform vec4 Color;
in vec2 UV;
out vec4 outColor;
void main()
{
	if(UV.x >= Position.x && UV.y >= Position.y && UV.x <= Position.x + Size.x && UV.y <= Position.y + Size.y){
		outColor = Color;
	} else {
		outColor = vec4(1,1,1,0);
	}
}