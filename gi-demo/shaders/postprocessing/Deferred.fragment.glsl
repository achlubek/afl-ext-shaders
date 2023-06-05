#version 430 core

in vec2 UV;
#include Lighting.glsl
#include LogDepth.glsl

layout(binding = 0) uniform sampler2D texColor;
layout(binding = 1) uniform sampler2D texDepth;
layout(binding = 30) uniform sampler2D worldPosTex;
layout(binding = 31) uniform sampler2D normalsTex;

const int MAX_SIMPLE_LIGHTS = 2000;
uniform int SimpleLightsCount;
uniform vec3 SimpleLightsPos[MAX_SIMPLE_LIGHTS];
uniform vec4 SimpleLightsColors[MAX_SIMPLE_LIGHTS];

out vec4 outColor;

void main()
{
	vec3 colorOriginal = texture(texColor, UV).rgb;
	vec3 color1 = colorOriginal * 0.012;
	gl_FragDepth = texture(texDepth, UV).r;
	vec4 fragmentPosWorld3d = texture(worldPosTex, UV);
	vec4 normal = texture(normalsTex, UV);
	if(normal.a == 0.0){
		color1 = colorOriginal;
	} else {
			
		vec3 cameraRelativeToVPos = CameraPosition - fragmentPosWorld3d.xyz;
		for(int i=0;i<LightsCount;i++){
			float distanceToLight = distance(fragmentPosWorld3d.xyz, LightsPos[i]);
            //if(worldDistance < 0.0002) continue;
			float att = 1.0 / pow(((distanceToLight/1.0) + 1.0), 2.0) * 390.0;
			mat4 lightPV = (LightsPs[i] * LightsVs[i]);
			
			
			vec3 lightRelativeToVPos = LightsPos[i] - fragmentPosWorld3d.xyz;
			vec3 R = reflect(lightRelativeToVPos, normal.xyz);
			float cosAlpha = -dot(normalize(cameraRelativeToVPos), normalize(R));
			float specularComponent = clamp(pow(cosAlpha, 80.0 / normal.a), 0.0, 1.0) * fragmentPosWorld3d.a;


			lightRelativeToVPos = LightsPos[i] - fragmentPosWorld3d.xyz;
			float dotdiffuse = dot(normalize(lightRelativeToVPos), normalize (normal.xyz));
			float diffuseComponent = clamp(dotdiffuse, 0.0, 1.0);
			
			//int counter = 0;

			// do shadows
			vec4 lightClipSpace = lightPV * vec4(fragmentPosWorld3d.xyz, 1.0);
			if(lightClipSpace.z >= 0.0){ 
				vec2 lightScreenSpace = ((lightClipSpace.xyz / lightClipSpace.w).xy + 1.0) / 2.0;	
				if(lightScreenSpace.x > 0.0 && lightScreenSpace.x < 1.0 && lightScreenSpace.y > 0.0 && lightScreenSpace.y < 1.0){ 
					float percent = clamp(getShadowPercent(lightScreenSpace, fragmentPosWorld3d.xyz, i), 0.0, 1.0);

					float culler = clamp((1.0 - distance(lightScreenSpace, vec2(0.5)) * 2.0), 0.0, 1.0);

					color1 += ((colorOriginal * (diffuseComponent * LightsColors[i].rgb)) 
					+ (LightsColors[i].rgb * specularComponent)) * LightsColors[i].a 
					* culler * att * percent;
					
				}
			}
			
		}
		

		for(int i=0;i<SimpleLightsCount;i++){
		
			float dist = distance(CameraPosition, SimpleLightsPos[i]);
			float att = 1.0 / pow(((dist/1.0) + 1.0), 2.0) * 40.0;
			float revlog = reverseLog(texture(texDepth, UV).r);
			
			vec3 lightRelativeToVPos = SimpleLightsPos[i] - fragmentPosWorld3d.xyz;
			vec3 R = reflect(lightRelativeToVPos, normal.xyz);
			float cosAlpha = -dot(normalize(cameraRelativeToVPos), normalize(R));
			float specularComponent = clamp(pow(cosAlpha, 80.0 / normal.a), 0.0, 1.0) * fragmentPosWorld3d.a;
			
			lightRelativeToVPos = SimpleLightsPos[i] - fragmentPosWorld3d.xyz;
			float dotdiffuse = dot(normalize(lightRelativeToVPos), normalize (normal.xyz));
			float diffuseComponent = clamp(dotdiffuse, 0.0, 1.0);
			color1 += ((colorOriginal * (diffuseComponent * SimpleLightsColors[i].rgb)) 
					+ (SimpleLightsColors[i].rgb * specularComponent))
					*att;
		}	
	}
    outColor = vec4(color1, 1);
}