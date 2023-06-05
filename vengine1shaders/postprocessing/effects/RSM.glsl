/*vec3 ColorCurrent = vec3(0);
vec3 NormalCurrent = vec3(1);
float DistCurrent = 0;
vec3 reconstructLightPos(vec2 uv, int i){    
    vec3 uv2 = vec3(uv, float(i));  
    vec4 data = texture(shadowMapsColorsArray, uv2).rgba;   
    NormalCurrent = texture(shadowMapsNormalsArray, uv2).rgb;   
    vec3 dir = normalize((LightsConeLB[i].xyz + LightsConeLB2BR[i].xyz * uv.x + LightsConeLB2TL[i].xyz * uv.y));
    ColorCurrent = LightsColors[i].xyz * data.rgb;
    DistCurrent = data.a;
    return LightsPos[i].xyz + dir * data.a;
}

float checkVisibility(vec2 p1, vec2 p2){
    float percent = 1.0;
    float iter = 0.1;
    float d1 = textureMSAA(normalsDistancetex, p1, 0).a;
    float d2 = textureMSAA(normalsDistancetex, p2, 0).a;
    for(int i=0;i<9;i++){
        vec2 mx = mix(p1, p2, iter);
        float d = textureMSAA(normalsDistancetex, mx, 0).a;
        percent -= smoothstep(0.0, 0.9, max(0, mix(d1, d2, iter) - d));
        iter += 0.1;
    }
    return max(0, percent);
}

vec2 project(vec3 pos){
    vec4 tmp = (VPMatrix * vec4(pos, 1.0));
    return (tmp.xy / tmp.w) * 0.5 + 0.5;
}

vec2 rsmsamplesSpeed[] = vec2[](
vec2(0.5, 0.5),

vec2(0.25, 0.5),
vec2(0.75, 0.5),

vec2(0.5, 0.25),
vec2(0.5, 0.75),

vec2(0.25, 0.25),
vec2(0.75, 0.75),

vec2(0.75, 0.25),
vec2(0.75, 0.25),


vec2(0.33, 0.5),
vec2(0.66, 0.5),

vec2(0.5, 0.33),
vec2(0.5, 0.66),

vec2(0.33, 0.33),
vec2(0.66, 0.66),

vec2(0.66, 0.33),
vec2(0.66, 0.33),


vec2(0.0, 0.0),
vec2(0.0, 0.25),
vec2(0.0, 0.33),
vec2(0.0, 0.5),
vec2(0.0, 0.66),
vec2(0.0, 0.75),
vec2(0.0, 1.0),

vec2(1.0, 0.0),
vec2(1.0, 0.25),
vec2(1.0, 0.33),
vec2(1.0, 0.5),
vec2(1.0, 0.66),
vec2(1.0, 0.75),
vec2(1.0, 1.0),

vec2(0.0, 0.0),
vec2(0.25, 0.0),
vec2(0.33, 0.0),
vec2(0.5, 0.0),
vec2(0.66, 0.0),
vec2(0.75, 0.0),
vec2(1.0, 0.0),

vec2(0.0, 1.0),
vec2(0.25, 1.0),
vec2(0.33, 1.0),
vec2(0.5, 1.0),
vec2(0.66, 1.0),
vec2(0.75, 1.0),
vec2(1.0, 1.0)
);


vec2 rsmsamplesQuality[] = vec2[](
vec2(0, 0),
vec2(0, 0.1),
vec2(0, 0.2),
vec2(0, 0.3),
vec2(0, 0.4),
vec2(0, 0.5),
vec2(0, 0.6),
vec2(0, 0.7),
vec2(0, 0.8),
vec2(0, 0.9),
vec2(0, 1),
vec2(0.1, 0),
vec2(0.1, 0.1),
vec2(0.1, 0.2),
vec2(0.1, 0.3),
vec2(0.1, 0.4),
vec2(0.1, 0.5),
vec2(0.1, 0.6),
vec2(0.1, 0.7),
vec2(0.1, 0.8),
vec2(0.1, 0.9),
vec2(0.1, 1),
vec2(0.2, 0),
vec2(0.2, 0.1),
vec2(0.2, 0.2),
vec2(0.2, 0.3),
vec2(0.2, 0.4),
vec2(0.2, 0.5),
vec2(0.2, 0.6),
vec2(0.2, 0.7),
vec2(0.2, 0.8),
vec2(0.2, 0.9),
vec2(0.2, 1),
vec2(0.3, 0),
vec2(0.3, 0.1),
vec2(0.3, 0.2),
vec2(0.3, 0.3),
vec2(0.3, 0.4),
vec2(0.3, 0.5),
vec2(0.3, 0.6),
vec2(0.3, 0.7),
vec2(0.3, 0.8),
vec2(0.3, 0.9),
vec2(0.3, 1),
vec2(0.4, 0),
vec2(0.4, 0.1),
vec2(0.4, 0.2),
vec2(0.4, 0.3),
vec2(0.4, 0.4),
vec2(0.4, 0.5),
vec2(0.4, 0.6),
vec2(0.4, 0.7),
vec2(0.4, 0.8),
vec2(0.4, 0.9),
vec2(0.4, 1),
vec2(0.5, 0),
vec2(0.5, 0.1),
vec2(0.5, 0.2),
vec2(0.5, 0.3),
vec2(0.5, 0.4),
vec2(0.5, 0.5),
vec2(0.5, 0.6),
vec2(0.5, 0.7),
vec2(0.5, 0.8),
vec2(0.5, 0.9),
vec2(0.5, 1),
vec2(0.6, 0),
vec2(0.6, 0.1),
vec2(0.6, 0.2),
vec2(0.6, 0.3),
vec2(0.6, 0.4),
vec2(0.6, 0.5),
vec2(0.6, 0.6),
vec2(0.6, 0.7),
vec2(0.6, 0.8),
vec2(0.6, 0.9),
vec2(0.6, 1),
vec2(0.7, 0),
vec2(0.7, 0.1),
vec2(0.7, 0.2),
vec2(0.7, 0.3),
vec2(0.7, 0.4),
vec2(0.7, 0.5),
vec2(0.7, 0.6),
vec2(0.7, 0.7),
vec2(0.7, 0.8),
vec2(0.7, 0.9),
vec2(0.7, 1),
vec2(0.8, 0),
vec2(0.8, 0.1),
vec2(0.8, 0.2),
vec2(0.8, 0.3),
vec2(0.8, 0.4),
vec2(0.8, 0.5),
vec2(0.8, 0.6),
vec2(0.8, 0.7),
vec2(0.8, 0.8),
vec2(0.8, 0.9),
vec2(0.8, 1),
vec2(0.9, 0),
vec2(0.9, 0.1),
vec2(0.9, 0.2),
vec2(0.9, 0.3),
vec2(0.9, 0.4),
vec2(0.9, 0.5),
vec2(0.9, 0.6),
vec2(0.9, 0.7),
vec2(0.9, 0.8),
vec2(0.9, 0.9),
vec2(0.9, 1),
vec2(1, 0),
vec2(1, 0.1),
vec2(1, 0.2),
vec2(1, 0.3),
vec2(1, 0.4),
vec2(1, 0.5),
vec2(1, 0.6),
vec2(1, 0.7),
vec2(1, 0.8),
vec2(1, 0.9),
vec2(1, 1)

);

#define rsmsamples rsmsamplesSpeed

vec3 RSM(FragmentData data){
    vec3 color1 = vec3(0);
    float invs = 1.0 / float(rsmsamples.length());
    //for(int i=0;i<LightsCount;i++){
    vec3 lastPoint = vec3(0);
    float distanceProbe = 0;
    for(int i=0;i<1;i++){
        for(int g = 0; g < rsmsamples.length(); g++){
            vec3 pos = reconstructLightPos(rsmsamples[g], i);
            
            if(g == 0) lastPoint = pos;
            else {
                distanceProbe += distance(pos, lastPoint) * 10;
                lastPoint = pos;
            }
            
            vec3 dir2f = normalize(data.worldPos - pos);
            vec3 dir2l = -normalize(LightsPos[i].xyz - pos);
            vec3 ldir = normalize(reflect(dir2l, NormalCurrent));
            
            //float percent = checkVisibility(UV, project(pos));
        
            vec3 radiance = shade(CameraPosition, data.specularColor, data.normal, data.worldPos, pos, ColorCurrent, max(0.23, data.roughness), true) * (1.0 - data.roughness);
            vec3 difradiance = shade(CameraPosition, data.diffuseColor, data.normal, data.worldPos, pos, ColorCurrent, 1.0, true) * (data.roughness + 1.0);
            color1 += (radiance + difradiance) * invs * CalculateFallof(DistCurrent + distance(pos, data.worldPos)) * max(0, dot(dir2f, ldir));
        }
    }
    return color1 * distanceProbe;
}*/