#version 430 core
#include Fragment.glsl

layout(binding = 16) uniform sampler2D bumpMap;

layout(binding = 2) uniform sampler2D AlphaMask;
uniform int UseAlphaMask;

void discardIfAlphaMasked(){
	if(UseAlphaMask == 1){
		if(texture(AlphaMask, UV).r < 0.5) discard;
	}
}

vec3 rotate_vector_by_quat( vec4 quat, vec3 vec )
{
	return vec + 2.0 * cross( cross( vec, quat.xyz ) + quat.w * vec, quat.xyz );
}

vec3 rotate_vector_by_vector( vec3 vec_first, vec3 vec_sec )
{
	vec3 zeros = vec3(0.0, 1.0, 0.0);
	vec3 cr = cross(zeros, vec_sec);
	float angle = dot(normalize(cr), normalize(vec_sec));
	return rotate_vector_by_quat(vec4(cr, angle), vec_first);
}

mat3 cotangent_frame(vec3 N, vec3 p, vec2 uv)
{
    // get edge vectors of the pixel triangle
    vec3 dp1 = dFdx( p );
    vec3 dp2 = dFdy( p );
    vec2 duv1 = dFdx( uv );
    vec2 duv2 = dFdy( uv );
 
    // solve the linear system
    vec3 dp2perp = cross( dp2, N );
    vec3 dp1perp = cross( N, dp1 );
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;
 
    // construct a scale-invariant frame 
    float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );
    return mat3( T * invmax, B * invmax, N );
}

vec3 perturb_normal( vec3 N, vec3 V, vec2 texcoord )
{
    // assume N, the interpolated vertex normal and 
    // V, the view vector (vertex to eye)
   vec3 map = texture(normalMap, texcoord ).xyz;
   map = map * 255./127. - 128./127.;
    mat3 TBN = cotangent_frame(N, -V, texcoord);
    return normalize(TBN * map);
}
vec3 perturb_normalRaw( vec3 N, vec3 V, vec3 map )
{
    // assume N, the interpolated vertex normal and 
    // V, the view vector (vertex to eye)
   map = map * 255./127. - 128./127.;
    mat3 TBN = cotangent_frame(N, -V, UV);
    return normalize(TBN * map);
}
vec3 perturb_bump( float B, vec3 N, vec3 V)
{

   vec3 map = vec3(0.5, 0.5, 1);
   map = map * 255./127. - 128./127.;
    mat3 TBN = cotangent_frame(N, -V - (N*B), UV);
    return normalize(TBN * map);
}

uniform float NormalMapScale;
#include noise3D.glsl
void main()
{	
	discardIfAlphaMasked();
	if(IgnoreLighting == 0){
		vec3 normalNew  = normal;
		if(UseNormalMap == 1){
			normalNew = perturb_normal(normal, positionWorldSpace, UV * NormalMapScale);
			
		}
		if(UseBumpMap == 1){
			//float bmap = texture(bumpMap, UV).r;
			//normalNew = normalize(rotate_vector_by_vector(normal, nmap));
			//normalNew = perturb_bump(bmap, normal, positionWorldSpace);
		//		
			vec3 nmap = vec3(0.5, 0.5, 1.0) * 9.0;
			nmap.x += snoise(vec3(UV.x / 3, UV.y / 3, Time * 2));
			nmap.y -= snoise(vec3(UV.x / 3, UV.y / 3, Time * 3));
			nmap.z += snoise(vec3(UV.x / 3, UV.y / 3, Time * 1.3));
			
			nmap.x += snoise(vec3(UV.x, UV.y, Time * 2));
			nmap.y -= snoise(vec3(UV.x, UV.y, Time * 1.23));
			nmap.z += snoise(vec3(UV.x, UV.y, Time* 3.1));
			
			nmap.x += snoise(vec3(UV.x * 10.0, UV.y * 10.0, Time));
			nmap.y -= snoise(vec3(UV.x * 10.0, UV.y * 10.0, Time));
			nmap.z += snoise(vec3(UV.x * 10.0, UV.y * 10.0, Time));
			nmap = normalize(nmap/10);
			normalNew = perturb_normalRaw(normalNew, positionWorldSpace, nmap * NormalMapScale);
			
		}
		
		outColor = vec4((RotationMatrixes[instanceId] * vec4(normalNew, 0)).xyz, SpecularSize);
	} else {
		outColor = vec4(0, 0, 0, 0);
	}
	updateDepth();
}