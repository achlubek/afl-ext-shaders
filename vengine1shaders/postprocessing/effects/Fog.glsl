/*vec3 raymarchFog(vec3 start, vec3 end){
    vec3 color1 = vec3(0);

    //vec3 fragmentPosWorld3d = texture(worldPosTex, UV).xyz;    
    float distbetween = distance(start, end);
    bool foundSun = false;
    for(int i=0;i<LightsCount;i++){
    
        mat4 lightPV = (LightsPs[i] * LightsVs[i]);
        vec4 lightClipSpace = lightPV * vec4(end, 1.0);
        
        
        float fogDensity = 0.0;
        float fogMultiplier = 111.0;
        vec2 fuv = ((lightClipSpace.xyz / lightClipSpace.w).xy + 1.0) / 2.0;
        vec3 lastPos = start - mix(start, end, 0.01);
        float stepr = mix(0.009, 0.001, distbetween / 100);
        float samples = 1.0 / stepr;
        float stepsize = distance(start, end) / samples;
		float rd = rand2s(UV);
        for(float m = 0.0; m< 1.0;m+= stepr){
			rd += 1.432135647;
            vec3 pos = mix(start, end, m );
            float distanceMult = stepsize;
            //float distanceMult = 5;
            lastPos = pos;
            float att = CalculateFallof(distance(pos, LightsPos[i]));
            //att = 1;
            lightClipSpace = lightPV * vec4(pos, 1.0);
            
            float fogNoise = 1.0;
    
            vec2 frfuv = ((lightClipSpace.xyz / lightClipSpace.w).xy + 1.0) / 2.0;
            float frfuvz = (lightClipSpace.z / lightClipSpace.w) * 0.5 + 0.5;
            //float idle = 1.0 / 1000.0 * fogNoise * fogMultiplier * distanceMult;
            float idle = 0.0;
            if(lightClipSpace.z < 0.0 || frfuv.x < 0.0 || frfuv.x > 1.0 || frfuv.y < 0.0 || frfuv.y > 1.0){ 
                fogDensity += idle;
                continue;
            }
            float diff =(lookupDepthFromLight(i, frfuv, toLogDepth(frfuvz, 10000)));
		
			float culler = 1;//clamp(1.0 - distance(frfuv, vec2(0.5)) * 2.0, 0.0, 1.0);
			//float fogNoise = 1.0;
			fogDensity += diff * (idle + 1.0 / 20.0 * culler * fogNoise * fogMultiplier * att * distanceMult) * smoothstep(0.0, 1.0, distance(pos, LightsPos[i].rgb));
            
        }
        color1 += LightsColors[i].xyz * fogDensity;
        
    }
    return color1;
}

vec3 Fog(FragmentData data){
    vec3 cspaceEnd = data.cameraPos;
    if(length(cspaceEnd) > 100) cspaceEnd = normalize(cspaceEnd) * 100;
	float dst1 = textureMSAA(normalsDistancetex, UV, 0).a;
	if(dst1 < 0.0001) cspaceEnd = reconstructCameraSpaceDistance(UV, 100);
    return vec3(raymarchFog(CameraPosition, CameraPosition + cspaceEnd));
}
*/