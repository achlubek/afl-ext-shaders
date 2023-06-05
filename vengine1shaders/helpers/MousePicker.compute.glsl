#version 430 core

layout(binding = 29) uniform usampler2D tex;
uniform vec2 Mouse;
uniform vec2 Resolution;

layout (std430, binding = 0) buffer R1
{
  uint Result; 
}; 

layout( local_size_x = 1, local_size_y = 1, local_size_z = 1 ) in;

void main(){
    vec2 ratio = vec2(Mouse) / Resolution;
    Result = textureLod(tex,  ratio, 0).r;
}