#version 430 core

layout (binding = 0, r32f) uniform image2D GrassTex;
#define MAX_COLLIDERS 96
uniform vec3 Barrels[MAX_COLLIDERS];
uniform int BarrelsCount;
uniform vec3 GrassSurfaceMin;
uniform vec3 GrassSurfaceMax;

layout( local_size_x = 1, local_size_y = 1, local_size_z = 1 ) in;

void main(){
    
    float absdt1 = float(gl_GlobalInvocationID.x);
    float absdt2 = float(gl_GlobalInvocationID.y);
    vec2 uv = vec2(absdt1, absdt2) / vec2(1024);
    float OldValue = imageLoad(GrassTex, ivec2(gl_GlobalInvocationID.xy)).r;
    ivec2 isize = imageSize(GrassTex);
    for(int i=0;i<BarrelsCount;i++){
        vec3 pos = Barrels[i].xyz;
        pos.y = 0;
        vec2 coord = uv * 24 - 12;
        OldValue -= 1.0 - smoothstep(0.0, 0.9, distance(pos, vec3(coord.x, 0, coord.y)));
        //if(distance(pos, vec3(coord.x, 0, coord.y)) < 2.0) OldValue = 0;
    }
    OldValue = max(0, OldValue);
    OldValue = min(2, OldValue);
    imageStore(GrassTex, ivec2(gl_GlobalInvocationID.xy), vec4(OldValue + 0.004));
}