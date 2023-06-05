#version 430 core
layout(location = 0) out float outDistance;
#include LogDepth.glsl

void main()
{
    outDistance = distance(CameraPosition, Input.WorldPos);
}