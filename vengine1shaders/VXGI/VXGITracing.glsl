
uniform int Voxelize_GridSizeX;
uniform int Voxelize_GridSizeY;
uniform int Voxelize_GridSizeZ;
uniform vec3 Voxelize_BoxSize;
uniform vec3 Voxelize_MapPosition;

vec3 getMapCoord(vec2 UV){
    vec3 cpos =  (FromCameraSpace(reconstructCameraSpaceDistance(UV, textureMSAAFull(normalsDistancetex, UV).a)) - Voxelize_MapPosition) / Voxelize_BoxSize;
    return clamp(cpos * 0.5 + 0.5,0.0, 1.0);
}
vec3 getMapCoordWPos(vec3 wpos){
    vec3 cpos = (wpos - Voxelize_MapPosition) / Voxelize_BoxSize;
    return clamp(cpos * 0.5 + 0.5,0.0, 1.0);
}

vec3 getNormalV(vec3 coord){
    return normalize(textureLod(voxelsNormalsTex, coord, 0).rgb);
}

float smoothgradient(float edge1, float edge2, float mx){
    return smoothstep(0.0, edge1, mx) * (1.0 - smoothstep(edge2, 1.0, mx));
}

vec4 sampleCone(vec3 coord, float blurness){
    vec4 i1 = textureLod(voxelsTex1, coord, 0).rgba;
    vec4 i2 = textureLod(voxelsTex2, coord, 0).rgba;
    vec4 i3 = textureLod(voxelsTex3, coord, 0).rgba;
    vec4 i4 = textureLod(voxelsTex4, coord, 0).rgba;

    vec4 a = vec4(0);
    a += i1 * ( smoothgradient(0.0, 0.25, blurness));
    a += i2 * ( smoothgradient(0.25, 0.50, blurness));
    a += i3 * ( smoothgradient(0.50, 0.75, blurness));
    a += i4 * ( smoothgradient(0.75, 1.0, blurness));
    
    return a;
}

// Y up in this case, tangent space
// needs normalization
vec3 coneDirections[] = vec3[](

    vec3(0, 1, 0)
    
);

#define MMAL_LOD_REGULATOR 512
vec3 MMALGI(vec3 dir, float roughness){
	//roughness = roughness * roughness;
    float levels = max(0, float(textureQueryLevels(cube)) - 2);
    float mx = log2(roughness*MMAL_LOD_REGULATOR+1)/log2(MMAL_LOD_REGULATOR);
    vec3 result = textureLod(cube, dir, mx * levels).rgb;
	
	return result;
	//return vec3pow(result*1.5, 6.0);
}
vec3 getTangent(vec3 v){
	return normalize(v) == vec3(0,1,0) ? vec3(1,0,0) : normalize(cross(vec3(0,1,0), v));
}


vec3 normalSeekLut[] = vec3[](
    vec3(-1, 0, 0),
    vec3(1, 0, 0),
    vec3(0, 1, 0),
    vec3(0, -1, 0),
    vec3(0, 0, 1),
    vec3(0, 0, -1)
);
vec3 VoxelSize = 1.0 / vec3(Voxelize_GridSizeX, Voxelize_GridSizeY, Voxelize_GridSizeZ);
float VoxelCut = length(VoxelSize);
vec3 approxNormal(vec3 voxspace, vec3 opposite){
    vec3 v = vec3(0);
    for(int i=0;i<normalSeekLut.length();i++) 
        v += textureLod(voxelsTex1, voxspace + normalSeekLut[i] * VoxelSize, 0).a * normalSeekLut[i];
    return length(v) == 0.0 ? opposite : normalize(v);
}

mat3 rotationMatrix(vec3 axis, float angle)
{
	axis = normalize(axis);
	float s = sin(angle);
	float c = cos(angle);
	float oc = 1.0 - c;
	
	return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 
	oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s, 
	oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}
vec3 traceConeSingle(vec3 wposOrigin, vec3 direction){ 
    vec3 csp = getMapCoordWPos(wposOrigin);

    vec3 res = vec3(0);
    float st = 0.04;
    float w = 1.0;
    float blurness = 0.7;
    
    st = 0.0;
    for(int g=0;g<12;g++){
        vec3 c = csp + direction * (st * st + 0.02) * 0.9;
        vec4 rc = textureLod(voxelsTex3, clamp(c, 0.0, 1.0), 0) ;
        //float aa = textureLod(voxelsTex1, clamp(c, 0.0, 1.0), 0).a ;
        st += 0.050;
        res += rc.rgb / (1.0 + st * Voxelize_BoxSize.x);
    } 
    return res * 5;
}
float traceConeSingleAO(vec3 wposOrigin, vec3 direction){ 
    vec3 csp = getMapCoordWPos(wposOrigin);

    float res = 0;
    float st = 0.04;
    float w = 1.0;
    float blurness = 0.7;
    
    st = 0.0;
    for(int g=0;g<3;g++){
        vec3 c = csp + direction * (st * st + 0.01) * 0.6;
        vec4 rc = textureLod(voxelsTex1, clamp(c, 0.0, 1.0), 0) ;
        //float aa = textureLod(voxelsTex1, clamp(c, 0.0, 1.0), 0).a ;
        res += rc.a;
        st += 0.06;
    } 
    st = 0.04;
    for(int g=0;g<3;g++){
        vec3 c = csp + direction * (st * st + 0.03) * 0.6;
        vec4 rc = textureLod(voxelsTex2, clamp(c, 0.0, 1.0), 0) ;
        //float aa = textureLod(voxelsTex1, clamp(c, 0.0, 1.0), 0).a ;
        res += rc.a ;
        st += 0.06;
    } 
    return res * 1;
}

vec3 raytrace(vec3 voxelorigin, vec3 dir){
    vec3 c = voxelorigin + dir * 0.015;
    vec3 res = vec3(0);
    for(int i=0;i<128;i++){
        c += dir * 0.002;
        if(clamp(c, 0.0, 1.0) != c) break;
        vec4 rc = textureLod(voxelsTex1, c, 0);
        if(rc.a > 0.0) { 
            res = rc.rgb; 
            break;
        }
    }
    return res;
}

vec3 traceConeDiffuse(FragmentData data){
    float iter1 = 0.0 + Time;
    float iter2 = 1.1112+ Time;
    float iter3 = 0.4565+ Time;
    vec3 buf = vec3(0);
    vec2 uvx = vec2(0,1);
    vec3 dir = normalize(mix(normalize(reflect(reconstructCameraSpace(UV), textureMSAA(normalsDistancetex, UV, 0).rgb)), normalize(textureMSAA(normalsDistancetex, UV, 0).rgb), data.roughness * data.roughness));
    
    vec3 voxelspace = getMapCoordWPos(data.worldPos);
    
    float w = 0.0;
    
    for(int i=0;i<2;i++){
        vec3 rd = vec3(
            rand2s(UV + iter1),
            rand2s(UV + iter2),
            rand2s(UV + iter3)
        ) * 2.0 - 1.0;
        rd = faceforward(rd, -rd, data.normal);
        rd = mix(dir, rd, data.roughness);
        
        buf += raytrace(voxelspace, normalize(rd))
        * max(0, dot(rd, data.normal));
        
        iter1 += 0.0031231;
        iter2 += 0.0021232;
        iter3 += 0.0041246;
        w += 1.0;
    }
    return (buf / w) * data.diffuseColor;
}

vec3 traceConeDiffusePrecise(FragmentData data){
    float iter1 = 0.0;
    float iter2 = 1.1112;
    float iter3 = 0.4565;
    vec3 buf = vec3(0);
    vec2 uvx = vec2(0,1);
    vec3 dir = normalize(mix(normalize(reflect(reconstructCameraSpace(UV), textureMSAA(normalsDistancetex, UV, 0).rgb)), normalize(textureMSAA(normalsDistancetex, UV, 0).rgb), data.roughness * data.roughness));
    
    vec3 voxelspace = getMapCoordWPos(data.worldPos);
    
    float w = 0.0;
    
    for(int i=0;i<20;i++){
        vec3 rd = vec3(
            rand2s(UV + iter1),
            rand2s(UV + iter2),
            rand2s(UV + iter3)
        ) * 2.0 - 1.0;
        rd = faceforward(rd, -rd, data.normal);
        rd = mix(dir, rd, data.roughness * 0.9 + 0.1);
        
       // buf += traceConeSingle(data.worldPos, normalize(rd));
        vec4 res = vec4(0);
        vec3 c = vec3(0);
        float st = 0.02;
        float wx = 1.0;
        float blurness = 0.7;

        st = 0.0;
        for(int g=0;g<20;g++){
            c = voxelspace + rd * (st * st + 0.02) * 0.7;
            res = textureLod(voxelsTex3, clamp(c, 0.0, 1.0), 0) ;
            buf += res.rgb * 11;
            wx -= res.a * 0.05;
            st += 0.05;
        } 
       // buf += res.rgb * 100 ;//* max(0, dot(approxNormal(c, data.normal), data.normal));
        
        iter1 += 0.0031231;
        iter2 += 0.0021232;
        iter3 += 0.0041246;
        w += 1.0;
    }
    return (buf / w) * data.diffuseColor;
}

vec3 traceDiffuseVoxelInvariant(vec3 csp){

    float w = 1.0;
    vec3 res = vec3(0);
    float st = 0.04;
    float blurness = 0.9;
    
    st = 0.0;
    
    for(int g=0;g<5;g++){
        vec4 rc = sampleCone(csp, 1.0 - blurness);
        res += rc.rgb ;
        blurness = blurness * 0.5;
        st += 0.1;
    }
    return res * 0.9;
}

vec3 traceConeSpecular(FragmentData data){ 
    //vec3 csp = reconstructCameraSpaceDistance(UV, textureMSAAFull(normalsDistancetex, UV).a) / Voxelize_BoxSize;///Voxelize_BoxSize;
    vec3 csp = getMapCoord(UV);
    vec3 center = csp;
    
    vec3 norm = normalize(textureMSAA(normalsDistancetex, UV, 0).rgb);
	float roughness = max(0.01, textureMSAA(albedoRoughnessTex, UV, 0).a);
    vec3 dir = normalize(mix(normalize(reflect(reconstructCameraSpace(UV), textureMSAA(normalsDistancetex, UV, 0).rgb)), normalize(textureMSAA(normalsDistancetex, UV, 0).rgb), roughness * roughness));
    float w = 1.0;
    vec3 res = vec3(0);
    float st = 0.001;
    float blurness = 1.0;
    float rg2 =  sqrt( roughness);
    rg2 = ((1.0 - smoothstep(0.5, 1.0, rg2)) * 0.6 + 0.4);
    
    float shift = mix(VoxelCut * 9.0, VoxelCut * 2.0, max(0, dot(normalize(-data.cameraPos), data.normal)));
    
    for(int i=0;i < 140;i++){
        vec3 c = center + dir * (st * st + shift ) * 1.0; 
        
        if(c.x > 1.0 || c.y > 1.0 || c.z > 1.0 || c.x < 0.0 || c.y < 0.0 || c.z < 0.0) { break; }
        
        vec4 rc = sampleCone(clamp(c, 0.0, 1.0), roughness * (1.0 - blurness));
        res += w * rc.rgb * rg2 * smoothstep(0.0, 0.7, st);
       // w -= min(rc.a, 1.0)  ;
       // w = max(0, w);
      //  if(w == 0.0) { break; }
        blurness = blurness * 0.9;
        st += 0.007;
    }
    float fresnel = fresnel_again(norm, data.cameraPos, data.roughness);
   // res += w * MMALGI(dir, roughness);
    return res * fresnel;
    //return approxNormal(center, vec3(0));
}

vec3 traceConeAOx(FragmentData data){ 
    float iter1 = 0.0;
    float iter2 = 1.1112;
    float iter3 = 0.4565;
    float buf = 0;
    vec2 uvx = vec2(0,1);
    
    
    vec3 voxelspace = getMapCoordWPos(data.worldPos);
    //float c = textureLod(voxelsTex2, voxelspace, 0).a;
    
    float w = 0.0;
    
    for(int i=0;i<28;i++){
        vec3 rd = vec3(
            rand2s(UV + iter1),
            rand2s(UV + iter2),
            rand2s(UV + iter3)
        ) * 2.0 - 1.0;
        rd = faceforward(rd, -rd, data.normal);
        
        buf += traceConeSingleAO(data.worldPos, normalize(rd)) * 0.3;
        
        iter1 += 0.0031231;
        iter2 += 0.0021232;
        iter3 += 0.0041246;
        w += 1.0;
    }
    return vec3(1.0 - buf / w);
}
vec3 traceConeAO(){ 
    //vec3 csp = reconstructCameraSpaceDistance(UV, textureMSAAFull(normalsDistancetex, UV).a) / Voxelize_BoxSize;///Voxelize_BoxSize;
    vec3 csp = getMapCoord(UV);
    vec3 center = csp;

    float ao = max(0, 1.0 - (textureLod(voxelsTex2, center, 0).a * 0.1));
    ao += max(0, 1.0 - (textureLod(voxelsTex4, center, 0).a * 0.2));
    ao += max(0, 1.0 - (textureLod(voxelsTex5, center, 0).a * 0.4));
    
    return vec3(1) * ao * 0.3;
}

vec3 getFragWPos(){
    return FromCameraSpace(reconstructCameraSpaceDistance(UV, textureMSAAFull(normalsDistancetex, UV).a));
}


vec3 traceVisDir(vec3 pos){ 
    vec3 cr1 = getMapCoordWPos(getFragWPos());
    vec3 cr2 = getMapCoordWPos(pos);
    float vis = 0.0;
    
    float stepper = 0.0;
    
    vec3 VoxelSize = Voxelize_BoxSize / vec3(Voxelize_GridSizeX, Voxelize_GridSizeY, Voxelize_GridSizeZ);
    
    float fx = 1.0/256.0;
    
    for(int i=0;i < 30;i++){
        vec3 crd = mix(cr1, cr2, stepper);
        if(distance(crd, cr1) > fx ){
            vis += sampleCone(crd, stepper * 0.1).a;
        }
        stepper += 1.0 / 30.0;
    }
    //vis = 1.0 - vis;
    vis = 1.0 - smoothstep(8.0, 16.0, vis);
    return vec3(1) * vis;
}

vec3 debugVoxel(){
    vec3 cr1 = getMapCoordWPos(getFragWPos());
    return textureLod(voxelsTex1, cr1, 0).rgb;
}
