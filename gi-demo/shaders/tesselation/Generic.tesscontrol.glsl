#version 410 core
#include Mesh3dUniforms.glsl

// define the number of CPs in the output patch
layout (vertices = 3) out;

uniform vec3 gEyeWorldPos;

// attributes of the input CPs
in vec3 ModelPos_CS_in[];
in vec3 WorldPos_CS_in[];
in vec2 TexCoord_CS_in[];
in vec3 Normal_CS_in[];
in vec3 Barycentric_CS_in[];

// attributes of the output CPs
out vec3 ModelPos_ES_in[];
out vec3 WorldPos_ES_in[];
out vec2 TexCoord_ES_in[];
out vec3 Normal_ES_in[];
out vec3 Barycentric_ES_in[];

float GetTessLevel(float Distance0, float Distance1)
{
	float rd = round((Distance0 +Distance1)/2);
	if(rd < 10.0) return 164.0;
	else if(rd < 20.0) return 86.0;
	else if(rd < 30.0) return 36.0;
	else if(rd < 40.0) return 29.0;
	else if(rd < 60.0) return 24.0;
	else if(rd < 90.0) return 19.0;
	else if(rd < 170.0) return 12.0;
	else if(rd < 277.0) return 8.0;
	else if(rd < 800.0) return 6.0;
	else return 4.0;
}
void main()
{
    // Set the control points of the output patch
    TexCoord_ES_in[gl_InvocationID] = TexCoord_CS_in[gl_InvocationID];
    Normal_ES_in[gl_InvocationID] = Normal_CS_in[gl_InvocationID];
    WorldPos_ES_in[gl_InvocationID] = WorldPos_CS_in[gl_InvocationID];
    ModelPos_ES_in[gl_InvocationID] = ModelPos_CS_in[gl_InvocationID];
    //Barycentric_ES_in[gl_InvocationID] = Barycentric_CS_in[gl_InvocationID];
   	//Barycentric_ES_in = Barycentric_ES_in[0];
	int vid = int(floor(mod(gl_InvocationID, 3)));
	if(vid == 0)Barycentric_ES_in[gl_InvocationID] = vec3(1, 0, 0);
	if(vid == 1)Barycentric_ES_in[gl_InvocationID] = vec3(0, 1, 0);
	if(vid == 2)Barycentric_ES_in[gl_InvocationID] = vec3(0, 0, 1);
	
	// Calculate the distance from the camera to the three control points
    float EyeToVertexDistance0 = distance(CameraPosition, WorldPos_ES_in[0]);
    float EyeToVertexDistance1 = distance(CameraPosition, WorldPos_ES_in[1]);
    float EyeToVertexDistance2 = distance(CameraPosition, WorldPos_ES_in[2]);

    // Calculate the tessellation levels
	float tessmult = 4.0f;
    gl_TessLevelOuter[0] = GetTessLevel(EyeToVertexDistance1, EyeToVertexDistance2) * tessmult;
    gl_TessLevelOuter[1] = GetTessLevel(EyeToVertexDistance2, EyeToVertexDistance0) * tessmult;
    gl_TessLevelOuter[2] = GetTessLevel(EyeToVertexDistance0, EyeToVertexDistance1) * tessmult;
    gl_TessLevelInner[0] = gl_TessLevelOuter[2];
}