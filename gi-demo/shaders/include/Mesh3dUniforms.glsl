uniform mat4 ViewMatrix;
uniform mat4 ProjectionMatrix;
uniform float LogEnchacer;
uniform float FarPlane;

const int MAX_LIGHTS = 27;
uniform int LightsCount;
uniform mat4 LightsPs[MAX_LIGHTS];
uniform mat4 LightsVs[MAX_LIGHTS];
uniform vec3 LightsPos[MAX_LIGHTS];
uniform float LightsFarPlane[MAX_LIGHTS];
uniform vec4 LightsColors[MAX_LIGHTS];


const int MAX_INSTANCES = 2000;
uniform int Instances;
uniform mat4 ModelMatrixes[MAX_INSTANCES];
uniform mat4 RotationMatrixes[MAX_INSTANCES];

uniform float RandomSeed1;
uniform float RandomSeed2;
uniform float RandomSeed3;
uniform float RandomSeed4;
uniform vec3 CameraPosition;
uniform vec3 CameraDirection;
uniform vec3 CameraTangentUp;
uniform vec3 CameraTangentLeft;
uniform float Time;

uniform vec3 ColoredID;

uniform float DiffuseComponent;
uniform float SpecularComponent;
uniform float SpecularSize;
uniform vec2 resolution;
float ratio = resolution.y/resolution.x;

uniform int IgnoreLighting;
