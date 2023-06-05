#version 450 core
layout( local_size_x = 16, local_size_y = 8, local_size_z = 8 ) in;


layout(binding = 0) uniform usampler3D VoxelsTextureRed;
layout(binding = 1) uniform usampler3D VoxelsTextureGreen;
layout(binding = 2) uniform usampler3D VoxelsTextureBlue;
layout(binding = 3) uniform usampler3D VoxelsTextureCount;
layout (binding = 4, rgba16f) uniform image3D VoxelsTextureResult;


void main(){
    ivec3 ba = ivec3(gl_GlobalInvocationID.xyz);
    uint r = texelFetch(VoxelsTextureRed, ba, 0).r;
    uint g = texelFetch(VoxelsTextureGreen, ba, 0).r;
    uint b = texelFetch(VoxelsTextureBlue, ba, 0).r;
    uint c = texelFetch(VoxelsTextureCount, ba, 0).r;
    vec3 rgb = c == 0 ? vec3(0) : vec3(r, g, b) / 256.0 / float(c);
    //imageStore(VoxelsTextureResult, ivec3(gl_GlobalInvocationID.xyz), vec4(rgb, float(c)));
    imageStore(VoxelsTextureResult, ba, vec4(rgb, float(c)));

}