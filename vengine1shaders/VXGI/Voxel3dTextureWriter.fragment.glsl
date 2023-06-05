#version 430 core

#ifdef AMD
#define MMBuffer m1mbbf
#endif

layout(location = 0) out vec4 outColor;

layout (binding = 6, r32ui)  uniform uimage3D VoxelsTextureRed;
layout (binding = 1, r32ui)  uniform uimage3D VoxelsTextureGreen;
layout (binding = 2, r32ui)  uniform uimage3D VoxelsTextureBlue;

layout (binding = 3, r32ui)  uniform uimage3D VoxelsTextureCount;
uniform vec3 BoxSize;
uniform vec3 MapPosition;
uniform int GridSizeX;
uniform int GridSizeY;
uniform int GridSizeZ;

// xyz in range 0 -> 1
void WriteData3d(vec3 xyz, vec3 color, vec3 normal){
    uint r = uint(color.r * 256);
    uint g = uint(color.g * 256);
    uint b = uint(color.b * 256);
    
    //int nx = int(normal.x * 128);
    //int ny = int(normal.y * 128);
    //int nz = int(normal.z * 128);
    
    imageAtomicAdd(VoxelsTextureRed, ivec3(xyz * vec3(GridSizeX, GridSizeY, GridSizeZ)), r);
    imageAtomicAdd(VoxelsTextureGreen, ivec3(xyz * vec3(GridSizeX, GridSizeY, GridSizeZ)), g);
    imageAtomicAdd(VoxelsTextureBlue, ivec3(xyz * vec3(GridSizeX, GridSizeY, GridSizeZ)), b);
    
   // imageAtomicAdd(VoxelsTextureNormalX, ivec3(xyz * float(GridSize)), nx);
   // imageAtomicAdd(VoxelsTextureNormalY, ivec3(xyz * float(GridSize)), ny);
  //  imageAtomicAdd(VoxelsTextureNormalZ, ivec3(xyz * float(GridSize)), nz);
    
    imageAtomicAdd(VoxelsTextureCount, ivec3(xyz * vec3(GridSizeX, GridSizeY, GridSizeZ)), 1);
    //memoryBarrier();
}

uniform int DisablePostEffects;
uniform float VDAOGlobalMultiplier;

#include LogDepth.glsl

vec2 UV = gl_FragCoord.xy / resolution.xy;


FragmentData currentFragment;

#include Lighting.glsl
#include UsefulIncludes.glsl
#include Shade.glsl
#include Direct.glsl
#include AmbientOcclusion.glsl
#include RSM.glsl 

#include ParallaxOcclusion.glsl



uniform vec3 LightColor;
uniform vec3 LightPosition;
uniform vec4 LightOrientation;
uniform float LightAngle;
uniform int LightUseShadowMap;
uniform int LightShadowMapType;
uniform mat4 LightVPMatrix;
uniform float LightCutOffDistance;

layout(binding = 20) uniform sampler2DShadow shadowMapSingle;

layout(binding = 21) uniform samplerCubeShadow shadowMapCube;

#define KERNEL 6
#define PCFEDGE 1
float PCFDeferred(vec2 uvi, float comparison){

    float shadow = 0.0;
    float pixSize = 1.0 / textureSize(shadowMapSingle,0).x;
    float bound = KERNEL * 0.5 - 0.5;
    bound *= PCFEDGE;
    for (float y = -bound; y <= bound; y += PCFEDGE){
        for (float x = -bound; x <= bound; x += PCFEDGE){
			vec2 uv = vec2(uvi+ vec2(x,y)* pixSize);
            shadow += texture(shadowMapSingle, vec3(uv, comparison));
        }
    }
	return shadow / (KERNEL * KERNEL);
}
vec3 ApplyLighting(FragmentData data, int samp)
{
	vec3 result = vec3(0);
    float fresnel = fresnel_again(data.normal, data.cameraPos, data.roughness);
    
    vec3 radiance = shade(CameraPosition, data.specularColor, data.normal, data.worldPos, LightPosition, LightColor, max(0.02, data.roughness), false);
    
    vec3 difradiance = shadeDiffuse(CameraPosition, data.diffuseColor, data.normal, data.worldPos, LightPosition, LightColor, max(0.02, data.roughness), false);
    
	if(LightUseShadowMap == 1){
		if(LightShadowMapType == 0){
			vec4 lightClipSpace = LightVPMatrix * vec4(data.worldPos, 1.0);
			if(lightClipSpace.z > 0.0){
				vec3 lightScreenSpace = (lightClipSpace.xyz / lightClipSpace.w) * 0.5 + 0.5;   

				float percent = 0;
				if(lightScreenSpace.x >= 0.0 && lightScreenSpace.x <= 1.0 && lightScreenSpace.y >= 0.0 && lightScreenSpace.y <= 1.0) {
					percent = PCFDeferred(lightScreenSpace.xy, toLogDepth2(distance(data.worldPos, LightPosition), 10000) - 0.001);
				}
				result += (radiance + difradiance) * 0.5 * percent;
                
                //subsurf
               /* float subsurfv = PCFDeferredValueSubSurf(lightScreenSpace.xy, distance(data.worldPos, LightPosition));
                
                result += subsurfv * data.diffuseColor;*/
                
			}
		
		} 
	} else if(LightUseShadowMap == 0){
		result += (radiance + difradiance) * 0.5;
	}
    result = fresnel * result;
	return result;
}

vec3 getMapCoord(vec2 UV){
    vec3 cpos =  (FromCameraSpace(reconstructCameraSpaceDistance(UV, textureMSAAFull(normalsDistancetex, UV).a)) - CameraPosition) / BoxSize;
    return clamp(cpos * 0.5 + 0.5,0.0, 1.0);
}
vec3 getMapCoordWPos(vec3 wpos){
    vec3 cpos = (wpos - CameraPosition) / BoxSize;
    return clamp(cpos * 0.5 + 0.5,0.0, 1.0);
}
 

vec4 sampleCone(vec3 coord, float blurness){
    if(blurness < 0.2){
        float bl = blurness / 0.2;
        vec4 i1 = textureLod(voxelsTex1, coord, 0).rgba;
        vec4 i2 = textureLod(voxelsTex2, coord, 0).rgba;
        return mix(i1, i2, bl);
    } else if(blurness < 0.4){
        float bl = (blurness - 0.2) / 0.2;
        vec4 i1 = textureLod(voxelsTex2, coord, 0).rgba;
        vec4 i2 = textureLod(voxelsTex3, coord, 0).rgba * 2;
        return mix(i1, i2, bl);
    } else if(blurness < 0.6){
        float bl = (blurness - 0.4) / 0.2;
        vec4 i1 = textureLod(voxelsTex3, coord, 0).rgba* 3;
        vec4 i2 = textureLod(voxelsTex4, coord, 0).rgba* 5;
        return mix(i1, i2, bl) ;
    } else if(blurness < 0.8){
        float bl = (blurness - 0.6) / 0.2;
        vec4 i1 = textureLod(voxelsTex4, coord, 0).rgba;
        vec4 i2 = textureLod(voxelsTex4, coord, 0).rgba;
        return mix(i1, i2, bl) * 3;
    } else {
        float bl = (blurness - 0.8) / 0.2;
        vec4 i1 = textureLod(voxelsTex4, coord, 0).rgba;
        vec4 i2 = textureLod(voxelsTex4, coord, 0).rgba;
        return mix(i1, i2, bl) * 3;
    } 
}
vec3 traceConeSingle(vec3 wposOrigin, vec3 direction){ 
    vec3 csp = getMapCoordWPos(wposOrigin);

       vec3 res = vec3(0);
    float st = 0.04;
    float w = 1.0;
    float blurness = 0.7;
    
    st = 0.0;
    for(int g=0;g<12;g++){
        vec3 c = csp + direction * (st * st + 0.02) * 0.7;
        vec4 rc = textureLod(voxelsTex3, clamp(c, 0.0, 1.0), 0) ;
        //float aa = textureLod(voxelsTex1, clamp(c, 0.0, 1.0), 0).a ;
        st += 0.050;
        res += rc.rgb / (1.0 + st * BoxSize.x);
    } 
    return res * 11;
}

vec3 raytrace(vec3 voxelorigin, vec3 dir){
    vec3 c = voxelorigin + dir * 0.015;
    vec3 res = vec3(0);
    for(int i=0;i<32;i++){
        c += dir * 0.005;
        if(clamp(c, 0.0, 1.0) != c) break;
        vec4 rc = textureLod(voxelsTex1, c, 0);
        if(rc.a > 0.0) { 
            res = rc.rgb; 
            break;
        }
    }
    return res*4;
}

vec3 traceConeDiffuse(FragmentData data){
    float iter1 = 0.0;
    float iter2 = 1.1112;
    float iter3 = 0.4565;
    vec3 buf = vec3(0);
    vec2 uvx = vec2(0,1);
    

    vec3 voxelspace = getMapCoordWPos(data.worldPos);
    
    float w = 0.0;
    
    for(int i=0;i<3;i++){
        vec3 rd = vec3(
            rand2s(UV + iter1),
            rand2s(UV + iter2),
            rand2s(UV + iter3)
        ) * 2.0 - 1.0;
        rd = faceforward(rd, -rd, data.normal);
        //rd = mix(dir, rd, data.roughness * 0.9 + 0.1);
        
        buf += raytrace(voxelspace, normalize(rd))
        * max(0, dot(rd, data.normal));
        
        iter1 += 0.0031231;
        iter2 += 0.0021232;
        iter3 += 0.0041246;
        w += 1.0;
    }
    return (buf / w) * data.diffuseColor;
}

vec3 linearize(vec3 c){
    return pow(c, vec3(2.4));
}
void main(){
	vec3 norm = normalize(Input.Normal);
//	norm = faceforward(norm, norm, normalize(ToCameraSpace(Input.WorldPos)));
	currentFragment = FragmentData(
		DiffuseColor,
		SpecularColor,
		norm,
		normalize(Input.Tangent.xyz),
		Input.WorldPos,
		ToCameraSpace(Input.WorldPos),
		distance(CameraPosition, Input.WorldPos),
		1.0,
		Roughness,
		0.0
	);	
	
	vec2 UVx = Input.TexCoord;
	
	mat3 TBN = mat3(
		normalize(Input.Tangent.xyz),
		normalize(cross(Input.Normal, (Input.Tangent.xyz))) * Input.Tangent.w,
		normalize(Input.Normal)
	);   
	
	if(UseNormalsTex){  
		vec3 map = texture(normalsTex, UVx ).rgb;
		map = map * 2 - 1;

		map.r = - map.r;
		map.g = - map.g;
		
		currentFragment.normal = TBN * map;
	} 
	if(UseRoughnessTex) currentFragment.roughness = max(0.07, texture(roughnessTex, UVx).r);
	if(UseDiffuseTex) currentFragment.diffuseColor = linearize(texture(diffuseTex, UV).rgb); 
	if(UseDiffuseTex && !UseAlphaTex)currentFragment.alpha = texture(diffuseTex, UV).a; 
	if(UseSpecularTex) currentFragment.specularColor = linearize(texture(specularTex, UV).rgb); 
	if(UseBumpTex) currentFragment.bump = texture(bumpTex, UVx).r; 
	if(UseAlphaTex) currentFragment.alpha = texture(alphaTex, UVx).r;
	
	float texdst = textureMSAAFull(normalsDistancetex, UV).a;
	//if(texdst > 0.001 && texdst < currentFragment.cameraDistance) discard;
	//if(ForwardPass == 0 && currentFragment.alpha < 0.99) discard;
	//if(ForwardPass == 1 && currentFragment.alpha > 0.99) discard;
	
	//gl_FragDepth = toLogDepth2(distance(CameraPosition, Input.WorldPos), 10000);
	
	currentFragment.normal = quat_mul_vec(ModelInfos[Input.instanceId].Rotation, currentFragment.normal);
    
    vec3 hafbox = ToCameraSpace(Input.WorldPos) / BoxSize;
    hafbox = clamp(hafbox, -1.0, 1.0);
    
    WriteData3d(hafbox * 0.5 + 0.5, traceConeDiffuse(currentFragment) +   max(vec3(0.0), currentFragment.diffuseColor - 1.0) + ApplyLighting(currentFragment, 0) + currentFragment.diffuseColor * 0.0,  quat_mul_vec(ModelInfos[Input.instanceId].Rotation, Input.Normal));
	
	outColor = vec4(1,1,1, 0.2);
}