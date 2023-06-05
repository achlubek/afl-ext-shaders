vec3 vec3pow(vec3 inputx, float po){
    return vec3(
    pow(inputx.x, po),
    pow(inputx.y, po),
    pow(inputx.z, po)
    );
}

#define MMAL_LOD_REGULATOR 512
float precentage = 0;
float falloff = 0;


vec3 MMALNoPrcDiffuse(vec3 visdis, float dist, vec3 normal, float roughness){
	
    float levels = float(textureQueryLevels(cube)) - 1;
    float mx = log2(roughness*MMAL_LOD_REGULATOR+1)/log2(MMAL_LOD_REGULATOR);
	vec3 result = vec3(0);
	result += textureLod(cube, vec3(1, 0, 0), levels).rgb;
	result += textureLod(cube, vec3(0, 1, 0), levels).rgb;
	result += textureLod(cube, vec3(0, 0, 1), levels).rgb;
	result += textureLod(cube, vec3(-1, 0, 0), levels).rgb;
	result += textureLod(cube, vec3(0, -1, 0), levels).rgb;
	result += textureLod(cube, vec3(0, 0, -1), levels).rgb;	
	result /= 6;
    //return vec3pow(result * 2.0, 1.7)*0.5;
    return precentage * result;
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

vec3 getTangent(vec3 v){
	return normalize(v) == vec3(0,1,0) ? vec3(1,0,0) : normalize(cross(vec3(0,1,0), v));
}
vec3 getBiTangent(vec3 v){
	return normalize(v) == vec3(1,0,0) ? vec3(0,0,1) : normalize(cross(vec3(1,0,0), v));
}

#define rlg(a) reverseLog(a,1000)
#define tld(a) toLogDepth(a,1000)
float MMALGetShadowforFuckSake(float dists, vec3 wpos, vec3 dir){
	float dist = toLogDepth(dists, 1000);
	float aaprc = 0.0;
	float count = 0.0;
	float rdiz = 1.654221;
	vec3 tang = getTangent(dir);
	vec3 bitang = getBiTangent(dir);
	for(int x = 0; x < 11; x++){
		//rd=rd.wxyz;
		vec2 rd = vec2(
			rand2s(x + currentFragment.worldPos.xy),
			rand2s(x + currentFragment.worldPos.yz)
		) *2-1;
		vec3 displace = tang * rd.x + bitang * rd.y;
		float dst = texture(cube, normalize(dir + displace * 0.04)).a;
		float prc = max(0.0, 1.0 - step(0.001, dist - dst)); 
		aaprc += prc;
	}
	return aaprc / 11;
}

vec3 MMAL(vec3 visdis, float dist, vec3 normal, vec3 reflected, float roughness){
	
    float levels = float(textureQueryLevels(cube))*0.5;
    float mx = log2(roughness*MMAL_LOD_REGULATOR+1)/log2(MMAL_LOD_REGULATOR);
	vec3 result = vec3(0);
	float counter = 0.01;
	float aaprc = 0;
	float aafw = 0;
	
	float fw = 1;//CubeMapsFalloffs[i].x * CalculateFallof(length((currentFragment.worldPos - CubeMapsPositions[i].xyz)));
	//precentage = MMALGetShadowforFuckSake(dist, currentFragment.worldPos, visdis);

	result += precentage * ( textureLod(cube, mix(reflected, normal, roughness), mx * levels).rgb);

	
	aafw += fw;
	
    //return vec3pow(result * 2.0, 1.7)*0.5;
	falloff = fw;
    return (result) * (1.0 - ncos(roughness));
}

float hash( float n )
{
    return fract(sin(n)*758.5453);
}

vec3 stupidBRDF(vec3 dir, float level, float roughness){
	vec3 aaprc = vec3(0.0);
	vec3 tang = getTangent(dir);
	vec3 bitang = getBiTangent(dir);
    float xx=2;
    float xx2=1;
	for(int x = 0; x < 22; x++){
		vec3 rd = vec3(
			rand2s(vec2(xx, xx2)),
			rand2s(vec2(-xx2, xx)),
			rand2s(vec2(xx2, xx))
		) *2-1;
		vec3 displace = rd;
        vec3 prc = textureLod(cube, dir + (displace * 0.6 * roughness), level).rgb;
		aaprc += prc;
        xx += 0.01;
        xx2 -= 0.02123;
	}
	return aaprc / 22;
}


vec3 MMALSkybox(vec3 normal, vec3 reflected, float roughness){
	//roughness = roughness * roughness;
    float levels = max(0, float(textureQueryLevels(cube)) - 1);
    float mx = log2(roughness*MMAL_LOD_REGULATOR+1)/log2(MMAL_LOD_REGULATOR);
    vec3 result = stupidBRDF(mix(reflected, normal, roughness), mx * levels, roughness);
	
	return result;
}


uniform int CurrentlyRenderedCubeMap;
uniform vec3 MapPosition;
uniform float CubeCutOff;
vec3 EnvironmentLight(FragmentData data)
{       
    vec3 dir = normalize(reflect(data.cameraPos, data.normal));
    vec3 vdir = normalize(data.cameraPos);
	vec3 reflected = vec3(0);
	vec3 diffused = vec3(0);
	if(distance(data.worldPos, MapPosition) < CubeCutOff || CubeCutOff > 4000.0) {
		float fv = CubeCutOff > 4000.0 ? 1.0 : 1.0 - smoothstep(0.0, CubeCutOff, distance(data.worldPos, MapPosition));
		vec3 dirvis = normalize(data.worldPos - MapPosition);

		precentage = MMALGetShadowforFuckSake(distance(data.worldPos, MapPosition), currentFragment.worldPos, dirvis);
		reflected += fv * MMAL(dirvis, distance(data.worldPos, MapPosition), data.normal, dir, data.roughness) * data.specularColor;
		//reflected = vec3(0);
		diffused += fv * MMALNoPrcDiffuse(dirvis, distance(data.worldPos, MapPosition), normalize(data.normal), 1.0) * data.diffuseColor;
	}

	//if(DisablePostEffects == 1){reflected *= 0.6;diffused *= 0.6;}
	vec3 radiance = shade(CameraPosition, data.specularColor, data.normal, data.worldPos, MapPosition, reflected, data.roughness, true) * (data.roughness);
	vec3 difradiance = shade(CameraPosition, data.diffuseColor, data.normal, data.worldPos, MapPosition, diffused, 1.0, true) * (data.roughness + 1.0);
	//return vec3(vdir);
    //return (radiance + difradiance) * 0.5;
    return (reflected + diffused) * 0.5;
}
vec3 EnvironmentLightSkybox(FragmentData data)
{       
    vec3 dir = normalize(reflect(data.cameraPos, data.normal));
    
	vec3 reflected = vec3(0);
	vec3 diffused = vec3(0);
	
    float fresnel = 1.0 - fresnel_again(data.normal, data.cameraPos, data.roughness);
    
	reflected += MMALSkybox(data.normal, dir, fresnel) * data.specularColor;// * (1.0 - data.roughness); 
	
	diffused += MMALSkybox(data.normal, dir, 1.0) * data.diffuseColor * (data.roughness + 1.0);

    fresnel = fresnel_again(data.normal, data.cameraPos, data.roughness);
    
    //return fresnel * vec3(0.2);
    return fresnel * reflected + diffused;
}
vec3 EnvironmentLightShadowsOnly(FragmentData data)
{       
	vec3 reflected = vec3(0);
	if(distance(data.worldPos, MapPosition) < CubeCutOff) {
		float fv = 1.0 - smoothstep(0.0, CubeCutOff, distance(data.worldPos, MapPosition));
		vec3 dirvis = normalize(data.worldPos - MapPosition);

		precentage = MMALGetShadowforFuckSake(distance(data.worldPos, MapPosition), currentFragment.worldPos, dirvis);
		reflected += fv * vec3(precentage);
	}
    return reflected * 0.1;
}

