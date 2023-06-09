#define iSteps 7
#define jSteps 6

#include ProceduralValueNoise.glsl

uniform float Time;
float fbmHI(vec3 p){
   // p *= 0.1;
    p *= 0.0000169;
    p.x *= 0.489;
	p += Time * 0.02;
	//p += getWind(p * 0.2) * 6.0;
	float a = 0.0;
    float w = 1.0;
    float wc = 0.0;
	for(int i=0;i<4;i++){
        //p += noise(vec3(a));
		a += clamp(2.0 * abs(0.5 - (supernoise3dX(p))) * w, 0.0, 1.0);
		wc += w;
        w *= 0.5;
		p = p * 3.0;
	}
	return a / wc;// + noise(p * 100.0) * 11;
}
vec3 wind(vec3 p){
    return vec3(
        supernoise3d(p),
        supernoise3d(p.yzx),
        supernoise3d(-p.xzy)
        ) * 2.0 - 1.0;
}
vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g) {
    pSun = normalize(pSun);
    r = normalize(r);
	float rs = rsi2(Ray(r0, r), Sphere(vec3(0), rAtmos));
	vec3 px = r0 + r * rs;
	shMie *= smoothstep(1.2e3 * 1.0, 1.2e3 * 2.0, shMie) * pow(fbmHI(px  + wind(px * 0.00000669) * 40000.0) * (supernoise3dX(px* 0.00000669 + Time * 0.001)*0.5 + 0.5) * 1.3, 3.0) * 0.8 + 0.2;
    float iStepSize = rs / float(iSteps);
    float iTime = 0.0;
    vec3 totalRlh = vec3(0,0,0);
    vec3 totalMie = vec3(0,0,0);
    float iOdRlh = 0.0;
    float iOdMie = 0.0;
    float mu = dot(r, pSun);
    float mumu = mu * mu;
    float gg = g * g;
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
    float pMie = 3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));
    for (int i = 0; i < iSteps; i++) {
        vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);
        float iHeight = length(iPos) - rPlanet;
        float odStepRlh = exp(-iHeight / shRlh) * iStepSize;
        float odStepMie = exp(-iHeight / shMie) * iStepSize;
        iOdRlh += odStepRlh;
        iOdMie += odStepMie;
        float jStepSize = rsi2(Ray(iPos, pSun), Sphere(vec3(0),rAtmos)) / float(jSteps);
        float jTime = 0.0;
        float jOdRlh = 0.0;
        float jOdMie = 0.0;
        float invshRlh = 1.0 / shRlh;
        float invshMie = 1.0 / shMie;
        for (int j = 0; j < jSteps; j++) {
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);
            float jHeight = length(jPos) - rPlanet;
            jOdRlh += exp(-jHeight * invshRlh) * jStepSize;
            jOdMie += exp(-jHeight * invshMie) * jStepSize;
            jTime += jStepSize;
        }
        vec3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));
        totalRlh += odStepRlh * attn;
        totalMie += odStepMie * attn;
        iTime += iStepSize;
    }
    return max(vec3(0.0), iSun * (pRlh * kRlh * totalRlh + pMie * kMie * totalMie));
}
vec3 mydumbassscatteringfunction(vec3 dir, vec3 sun){
    float daynight = max(0.0, (sun.y + 0.1)) / 1.1;
    float daynight2 = max(0.0, (sun.y));
    //dir.y *= sun.y;
    float upsky = max(0.0, dot(dir, vec3(0.0, 1.0, 0.0)));
    float wholeskysun = dot(dir, sun) * 0.5 + 0.5;
    float halfskysun = max(0.0, dot(dir, sun));

    vec3 blue = vec3(0) * 2.0;
    vec3 orange = vec3(0.9, 0.18, 0.03) * 3.0;
    vec3 dust = vec3(3.2) + blue * 3.0;
    vec3 farScatter = mix(orange, dust, 1.0 - pow(1.0 - daynight2, 4.0));


    vec3 suncolor = mix(orange, vec3(1.0), daynight2) * 10.0;
    farScatter = mix(farScatter, suncolor, pow(wholeskysun, 14.0) / (0.5 + dir.y) / (0.5 + sun.y));
    vec3 skycolor =
    //  mix(farScatter, blue, 1.0 - (pow(1.0 - max(0.0, dir.y), 1.0) * wholeskysun)) * daynight * 0.2
    mix(farScatter, blue, 1.0 - (pow(1.0 - max(0.0, dir.y), 4.0) * wholeskysun)) * daynight * 0.2
    + mix(farScatter, blue, 1.0 - (pow(1.0 - max(0.0, dir.y), 8.0) * wholeskysun)) * daynight * 0.2
    + mix(farScatter, blue, 1.0 - (pow(1.0 - max(0.0, dir.y), 16.0) * wholeskysun)) * daynight * 0.2;

    return skycolor * ( pow(1.0 - daynight, 4.0)) * 3.0;
}
vec3 getAtmosphereForDirectionReal(vec3 origin, vec3 dir, vec3 sunpos){
	float mult = max(0.0, dot(VECTOR_UP, sunpos) * 0.9 + 0.1);

    //if(dir.y < -0.01) return vec3(0.0);

    dir.y = abs(dir.y);
    return// mult * 3.3 * mydumbassscatteringfunction(dir, sunpos) +
     12.0 * mult * atmosphere(
        dir,           // normalized ray direction
        vec3(0,planetradius  ,0) + origin,               // ray origin
        sunpos,                        // position of the sun
        22.0,                           // intensity of the sun
        planetradius,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
       // vec3(0.05e-5, 0.10e-5, 0.25e-5) * 2.0, // Rayleigh scattering coefficient
      //  vec3(4.5e-6, 10.0e-6, 2.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3  * MieScattCoeff ,                          // Mie scale height
        0.758                         // Mie preferred scattering direction
    ) +
     2 * atmosphere(
        dir,           // normalized ray direction
        vec3(0,planetradius  ,0) + origin,               // ray origin
        dayData.moonDir,                        // position of the sun
        22.0 / 300.0,                           // intensity of the sun
        planetradius,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
       // vec3(0.05e-5, 0.10e-5, 0.25e-5) * 2.0, // Rayleigh scattering coefficient
      //  vec3(4.5e-6, 10.0e-6, 2.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        2e3,                            // Rayleigh scale height
        11.2e3  * MieScattCoeff ,                          // Mie scale height
        0.758                         // Mie preferred scattering direction
    );
}
