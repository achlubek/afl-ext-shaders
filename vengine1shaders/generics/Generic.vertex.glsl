#version 430 core
#include AttributeLayout.glsl
#include Mesh3dUniforms.glsl

out Data {
#include InOutStageLayout.glsl
} Output;

uniform int InvertUVy;
uniform int IsBillboard;

		
mat4 lookAtDirection(vec3 dir, vec3 up){
	vec3 z = normalize(-dir);
	vec3 x = -normalize(cross(up, z));
	vec3 y = normalize(cross(z, x));

	return mat4(x.x, y.x, z.x, 0.0,
				x.y, y.y, z.y, 0.0,
				x.z, y.z, z.z, 0.0,
				0.0, 0.0, 0.0, 1.0);
}
mat3 calcLookAtMatrix(vec3 origin, vec3 target, float roll) {
  vec3 rr = vec3(sin(roll), cos(roll), 0.0);
  vec3 ww = normalize(target - origin);
  vec3 uu = normalize(cross(ww, rr));
  vec3 vv = normalize(cross(uu, ww));

  return mat3(uu, vv, ww);
}

void main(){

    vec4 v = vec4(in_position,1);
	if(IsBillboard == 1){
		v.xyz = calcLookAtMatrix(CameraPosition, ModelInfos[int(gl_InstanceID)].Translation.xyz, 0) * v.xyz;
	}
    Output.instanceId = int(gl_InstanceID);
    Output.TexCoord = vec2(in_uv.x, InvertUVy == 1 ? in_uv.y : (1.0 - in_uv.y));
    Output.WorldPos = transform_vertex(int(gl_InstanceID), v.xyz);
    Output.Normal = in_normal;
    Output.Tangent = in_tangent;
	vec4 outpoint = (VPMatrix) * vec4(Output.WorldPos, 1);
//	outpoint.w = 0.5 + 0.5 * outpoint.w;
	//outpoint.w = - outpoint.w;
	Output.Data.y = (outpoint.z / outpoint.w) * 0.5 + 0.5; 
    gl_Position = outpoint;// + vec4(0, 0.9, 0, 0);
}