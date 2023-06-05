#version 410 core

layout(triangles, equal_spacing, ccw) in;

#include Mesh3dUniforms.glsl

in vec3 ModelPos_ES_in[];
in vec3 WorldPos_ES_in[];
in vec2 TexCoord_ES_in[];
in vec3 Normal_ES_in[];
in vec3 Barycentric_ES_in[];

smooth out vec3 normal;
smooth out vec3 positionWorldSpace;
smooth out vec3 positionModelSpace;
smooth out vec2 UV;
smooth out vec3 barycentric;

vec2 interpolate2D(vec2 v0, vec2 v1, vec2 v2)
{
   	return vec2(gl_TessCoord.x) * v0 + vec2(gl_TessCoord.y) * v1 + vec2(gl_TessCoord.z) * v2;
}

vec3 interpolate3D(vec3 v0, vec3 v1, vec3 v2)
{
   	return vec3(gl_TessCoord.x) * v0 + vec3(gl_TessCoord.y )* v1 + vec3(gl_TessCoord.z) * v2;
}

float hash2(vec2 co) {
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))));
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

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

void main()
{
   	// Interpolate the attributes of the output vertex using the barycentric coordinates
   	UV = interpolate2D(TexCoord_ES_in[0], TexCoord_ES_in[1], TexCoord_ES_in[2]);
   	barycentric = interpolate3D(Barycentric_ES_in[0], Barycentric_ES_in[1], Barycentric_ES_in[2]);
   	normal = interpolate3D(Normal_ES_in[0], Normal_ES_in[1], Normal_ES_in[2]);
   	positionWorldSpace = interpolate3D(WorldPos_ES_in[0], WorldPos_ES_in[1], WorldPos_ES_in[2]);
   	positionModelSpace = interpolate3D(ModelPos_ES_in[0], ModelPos_ES_in[1], ModelPos_ES_in[2]);
	   	// Displace the vertex along the normal
	float hash = hash2(vec2(positionWorldSpace.x + Time, positionWorldSpace.z + Time/4.0f));
	vec3 displacer = vec3(
		0,
		//sin(Time*12.0 + positionWorldSpace.x * 0.34)+ cos(Time*80.0 + positionWorldSpace.y * 0.1),
		distance(gl_TessCoord, vec3(0.5)) * 25.0f + hash*4.0f + hash2(gl_TessCoord.xy),
		0
	);
	
	positionWorldSpace -= displacer;
	/*
	float mindist = 99999999.0;
	if(distance(positionWorldSpace, WorldPos_ES_in[0]) < mindist){
		normal = cross(positionWorldSpace, WorldPos_ES_in[0]);
		if(dot(positionWorldSpace, WorldPos_ES_in[0]) > 0.0) normal = -normal;
		mindist = distance(positionWorldSpace, WorldPos_ES_in[0]);
	}
	
	if(distance(positionWorldSpace, WorldPos_ES_in[1]) < mindist){
		normal = cross(positionWorldSpace, WorldPos_ES_in[1]);
		if(dot(positionWorldSpace, WorldPos_ES_in[1]) > 0.0) normal = -normal;
		mindist = distance(positionWorldSpace, WorldPos_ES_in[1]);
	}
	
	if(distance(positionWorldSpace, WorldPos_ES_in[2]) < mindist){
		normal = cross(positionWorldSpace, WorldPos_ES_in[2]);
		if(dot(positionWorldSpace, WorldPos_ES_in[2]) > 0.0) normal = -normal;
		mindist = distance(positionWorldSpace, WorldPos_ES_in[2]);
	}*/
	
	normal = normalize(normal);
   	gl_Position = ProjectionMatrix * ViewMatrix * vec4(positionWorldSpace, 1.0);
}
/**/