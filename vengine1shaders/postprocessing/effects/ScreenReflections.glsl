
vec2 project(vec3 pos){
    vec4 tmp = (VPMatrix * vec4(pos, 1.0));
    return (tmp.xy / tmp.w) * 0.5 + 0.5;
}


vec4 ScreenReflections(FragmentData data){
	//if(data.roughness > 0.5) return vec4(0);
    vec2 closuv = vec2(0);
	float closest = 0;
	float closestdst = 0;
	
	#define SSREFSSTEPS_CLOSE 12
	
	#define SSREFSSTEPS 48
	
	#define SSREFSSTEPS_REFINE 8
	
	vec2 start = UV;
	vec2 reconstructNorm = project(data.worldPos + data.normal * 0.05);
	float invs = 0.1 / SSREFSSTEPS;
	vec2 dir = normalize(reconstructNorm - start) / SSREFSSTEPS;
	vec2 dir_refine = dir / SSREFSSTEPS_REFINE;
	
	vec3 reflected = normalize(reflect(data.cameraPos, data.normal));
		
	float tolerance = 0.9998;
		
	float iteri = 1.12342;
    for(int i=0;i<SSREFSSTEPS;i++){
		iteri += 1.012343;
		start += dir + (rand2s(UV + iteri) * 2 - 1) * invs;;
		if(start.x > 1.0 || start.y > 1.0 || start.x < 0.0 || start.y < 0.0) break;
		vec3 rec = reconstructCameraSpace(start);
		vec3 dd = normalize(rec - data.cameraPos);
		float dt = max(0, dot(dd, reflected));
		if(dt > closest && dt > tolerance){
			closest = dt;
			closestdst = distance(rec, data.cameraPos);
			closuv = start;
		}
    }
	start = closuv;
    for(int i=0;i<SSREFSSTEPS_REFINE;i++){
		start += dir_refine;
		//if(start.x > 1.0 || start.y > 1.0 || start.x < 0.0 || start.y < 0.0) break;
		vec3 rec = reconstructCameraSpace(start);
		vec3 dd = normalize(rec - data.cameraPos);
		float dt = max(0, dot(dd, reflected));
		if(dt > closest && dt > tolerance){
			closest = dt;
			closestdst = distance(rec, data.cameraPos);
			closuv = start;
		}
    }
	start = closuv;
    for(int i=0;i<SSREFSSTEPS_REFINE;i++){
		start -= dir_refine;
		//if(start.x > 1.0 || start.y > 1.0 || start.x < 0.0 || start.y < 0.0) break;
		vec3 rec = reconstructCameraSpace(start);
		vec3 dd = normalize(rec - data.cameraPos);
		float dt = max(0, dot(dd, reflected));
		if(dt > closest && dt > tolerance){
			closest = dt;
			closestdst = distance(rec, data.cameraPos);
			closuv = start;
		}
    }
	
	vec3 res = vec3(0);
	float blurfactor = 0;
	if(closest > 0){
		closuv = clamp(closuv, 0.0, 1.0);
		float dim = 1.0 - distance(closuv, vec2(0.5));
		
		float tolerancedim = smoothstep(tolerance, 1.0, closest);
	
		vec3 deferred = texture(lastStageResultTex, closuv).rgb;
		
		vec4 normalsDistanceData = textureMSAAFull(normalsDistancetex, closuv);
		vec3 normal = normalsDistanceData.rgb;
		
		blurfactor = closestdst * 0.1;
	
		res = deferred * tolerancedim;
	}
	float roughMaxed = 1.0 - (data.roughness * 2.0);
	
    return vec4(res, blurfactor * data.roughness);
}