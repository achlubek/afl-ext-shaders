#version 430 core


uniform float CloudsFloor;
uniform float CloudsCeil;
uniform float CloudsThresholdLow;
uniform float CloudsThresholdHigh;
uniform float CloudsAtmosphereShaftsMultiplier;
uniform float CloudsWindSpeed;
uniform vec3 CloudsScale;
uniform vec3 SunDirection;
uniform float AtmosphereScale;
layout(binding = 18) uniform sampler2D cloudsCloudsTex;

#include PostProcessEffectBase.glsl

#define PI 3.141592

float hash( float n )
{
    return fract(sin(n)*758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x); 
    float n = p.x + p.y*57.0 + p.z*800.0;
    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x), mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
		    mix(mix( hash(n+800.0), hash(n+801.0),f.x), mix( hash(n+857.0), hash(n+858.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f = 0.0;
    f += 0.50000*noise( p ); p = p*2.02;
    f -= 0.25000*noise( p ); p = p*2.03;
    f += 0.12500*noise( p ); p = p*2.01;
    f += 0.06250*noise( p ); p = p*2.04;
    f += 0.03500*noise( p ); p = p*4.01;
    f += 0.01250*noise( p ); p = p*4.04;
    f -= 0.00125*noise( p );
    return f/0.984375;
}

float fbmx( vec3 p )
{
    float f = 0.0;
    f += 0.50000*noise( p ); p = p*2.02;
    f -= 0.25000*noise( p ); p = p*2.03;
    f += 0.12500*noise( p ); p = p*2.01;
    f += 0.06250*noise( p ); p = p*2.04;
    return f/0.984375 * 2.0;
}

float howcloudy = 0.83;
float howcloudyM = 0.84;
vec3 wtim =vec3(0);

#define wind vec3(-1.0, 0.0, 0.0)
float cloudsDensity3D(vec3 pos){
    vec3 ps = pos * CloudsScale + wtim;
    float density = fbm(ps * 0.05);
    
    float init = smoothstep(CloudsThresholdLow, CloudsThresholdHigh, 1.0 - density);
    return  init;
}
float cloudsDensity3DLOWRES(vec3 pos){
    vec3 ps = pos * CloudsScale + wtim;
    float density = fbmx(ps * 0.05);
    
    float init = smoothstep(CloudsThresholdLow, CloudsThresholdHigh, 1.0 - density);
    return  init;
}

struct Ray {
    vec3 o; //origin
    vec3 d; //direction (should always be normalized)
};

struct Sphere {
    vec3 pos;   //center of sphere position
    float rad;  //radius
};
float minhit = 0.0;
float maxhit = 0.0;
float rsi2(in Ray ray, in Sphere sphere)
{
    vec3 oc = ray.o - sphere.pos;
    float b = 2.0 * dot(ray.d, oc);
    float c = dot(oc, oc) - sphere.rad*sphere.rad;
    float disc = b * b - 4.0 * c;

    if (disc < 0.0)
        return -1.0;

    float q;
    if (b < 0.0)
        q = (-b - sqrt(disc))/2.0;
    else
        q = (-b + sqrt(disc))/2.0;

    float t0 = q;
    float t1 = c / q;

    if (t0 > t1) {
        float temp = t0;
        t0 = t1;
        t1 = temp;
    }
    minhit = min(t0, t1);
    maxhit = max(t0, t1);

    if (t1 < 0.0)
        return -1.0;

    if (t0 < 0.0) {
        return t1;
    } else {
        return t0; 
    }
}

uniform float Time;
float rand2s(vec2 co){
        return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}
    
float planetradius = 6372e3;
Sphere planet = Sphere(vec3(0), planetradius);

Sphere sphere1;
Sphere sphere2;

vec3 sundir = normalize(SunDirection);
vec3 viewdirglob = vec3(0,1,0);

uniform int UseShadows;
vec4 internalmarchshadow(float scale, vec3 p1, vec3 p2, float coverageinv){
    float iter = 0.0;
    const float stepcount = 27.0;
    float stepsize = 1.0 / stepcount;
    float rd = rand2s(UV + vec2(0, 2)) * stepsize;
    float f = 0.0;
    float mult = distance(p1, mix(p1, p2, stepsize));
    for(int i=0;i<stepcount;i++){
        vec3 pos = mix(p1, p2, iter + rd);
        float clouds = cloudsDensity3D(pos * 0.01 * scale);
       // clouds *= smoothstep(0.0, 0.1, iter + rd);
       // clouds *= smoothstep(0.2, 1.0, (iter + rd));
        //coverageinv *= 1.0 - clamp(clouds * stepsize *  10  * (1.0 - abs((iter+rd) * 2.0 - 1.0)), 0.0, 1.0);
        f += clamp( clouds * 0.005 * mult  , 0.0, 1.0);
        if(coverageinv < 0.01)break;
        iter += stepsize;
    }
    
    return vec4(vec3(1.0), 1.0 - f * stepsize);
}

float smartShadow(float scale){
    vec3 startpos = texture(cloudsCloudsTex, UV).yzw;
    Ray r = Ray(vec3(0,planetradius ,0) + startpos, sundir);
    float hitceil = rsi2(r, sphere2);
    return internalmarchshadow(scale, startpos, startpos + r.d * hitceil, 1.0).a;
}

vec2 aoSamplesSpeed[] = vec2[](
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
vec2(0.66, 0.33)
);
vec2 xsamples[] = vec2[](
vec2(0.009011431, 0.09457164),
vec2(0.03588319, 0.1865808),
vec2(0.08012987, 0.2735036),
vec2(0.1409498, 0.3528925),
vec2(0.2172358, 0.422414),
vec2(0.3075902, 0.4798836),
vec2(0.4103443, 0.5232996),
vec2(0.5235803, 0.5508754),
vec2(0.6451581, 0.5610668),
vec2(0.7727448, 0.5525989),
vec2(0.03761707, 0.08723506),
vec2(0.09144463, 0.1665469),
vec2(0.1602457, 0.2356826),
vec2(0.2425058, 0.2925593),
vec2(0.3364545, 0.3352959),
vec2(0.4400912, 0.3622426),
vec2(0.5512127, 0.3720074),
vec2(0.6674456, 0.3634782),
vec2(0.7862788, 0.3358431),
vec2(0.9051006, 0.2886051),
vec2(0.06258768, 0.07146875),
vec2(0.1381696, 0.1304192),
vec2(0.2248766, 0.1750872),
vec2(0.3206278, 0.2039553),
vec2(0.4231609, 0.2157773),
vec2(0.5300651, 0.2095973),
vec2(0.6388161, 0.1847671),
vec2(0.7468139, 0.1409573),
vec2(0.8514194, 0.07816622),
vec2(0.9499944, -0.00327723),
vec2(0.08151028, 0.04879625),
vec2(0.1715428, 0.08168877),
vec2(0.2677771, 0.09757254),
vec2(0.3677669, 0.09564264),
vec2(0.4689762, 0.07540761),
vec2(0.5688174, 0.03669818),
vec2(0.6646892, -0.0203276),
vec2(0.7540158, -0.09518456),
vec2(0.8342854, -0.1870641),
vec2(0.9030879, -0.2948429),
vec2(0.09255636, 0.02140844),
vec2(0.1883395, 0.02506454),
vec2(0.2848017, 0.01062928),
vec2(0.3793677, -0.02191219),
vec2(0.4694732, -0.07224894),
vec2(0.5526036, -0.1397472),
vec2(0.6263317, -0.2234581),
vec2(0.6883554, -0.3221287),
vec2(0.7365322, -0.4342181),
vec2(0.7689138, -0.5579172),
vec2(0.09465848, -0.008048125),
vec2(0.1869365, -0.03398174),
vec2(0.2743052, -0.07734115),
vec2(0.3543093, -0.1373496),
vec2(0.4246039, -0.2129238),
vec2(0.4829903, -0.3026886),
vec2(0.5274503, -0.4049953),
vec2(0.5561774, -0.5179446),
vec2(0.5676062, -0.6394124),
vec2(0.5604377, -0.7670786),
vec2(0.08761352, -0.03672697),
vec2(0.1674693, -0.08974428),
vec2(0.2373019, -0.1578379),
vec2(0.2950131, -0.2395146),
vec2(0.338704, -0.3330234),
vec2(0.3667045, -0.4363804),
vec2(0.3776, -0.5473967),
vec2(0.3702547, -0.6637104),
vec2(0.3438309, -0.7828189),
vec2(0.297805, -0.9021155),
vec2(0.07210226, -0.06185681),
vec2(0.1318191, -0.1368346),
vec2(0.1773675, -0.2230824),
vec2(0.207209, -0.3185348),
vec2(0.2200743, -0.4209421),
vec2(0.2149831, -0.5279036),
vec2(0.1912613, -0.6369019),
vec2(0.1485533, -0.7453401),
vec2(0.08683044, -0.8505795),
vec2(0.006394804, -0.9499785),
vec2(0.04962357, -0.08100927),
vec2(0.08343099, -0.1707023),
vec2(0.1002937, -0.2667699),
vec2(0.09938195, -0.3667741),
vec2(0.08017833, -0.4681842),
vec2(0.04248739, -0.5684143),
vec2(-0.01355944, -0.6648617),
vec2(-0.08750311, -0.7549458),
vec2(-0.1785607, -0.8361466),
vec2(-0.2856334, -0.9060429),
vec2(0.02234963, -0.0923336),
vec2(0.02698069, -0.1880746),
vec2(0.01352821, -0.2846787),
vec2(-0.01804882, -0.3795711),
vec2(-0.06746549, -0.4701844),
vec2(-0.134114, -0.5539976),
vec2(-0.2170699, -0.6285743),
vec2(-0.3151039, -0.6915992),
vec2(-0.426697, -0.7409148),
vec2(-0.5500601, -0.7745541),
vec2(-0.007084003, -0.0947355),
vec2(-0.03207681, -0.1872727),
vec2(-0.07454451, -0.2750784),
vec2(-0.1337353, -0.3556893),
vec2(-0.20859, -0.4267496),
vec2(-0.2977556, -0.4860469),
vec2(-0.3996044, -0.5315461),
vec2(-0.5122554, -0.5614217),
vec2(-0.6336006, -0.5740865),
vec2(-0.7613332, -0.5682181),
vec2(-0.03583309, -0.08798289),
vec2(-0.08803466, -0.1683743),
vec2(-0.1554138, -0.2388965),
vec2(-0.2364988, -0.2974362),
vec2(-0.3295579, -0.3420769),
vec2(-0.4326245, -0.3711281),
vec2(-0.5435241, -0.3831534),
vec2(-0.6599066, -0.3769925),
vec2(-0.7792777, -0.3517829),
vec2(-0.8990367, -0.3069741),
vec2(-0.06111954, -0.07272827),
vec2(-0.1354855, -0.1332054),
vec2(-0.2212651, -0.1796295),
vec2(-0.3164087, -0.2104413),
vec2(-0.4186798, -0.2243484),
vec2(-0.5256876, -0.2203465),
vec2(-0.6349217, -0.1977355),
vec2(-0.7437891, -0.1561338),
vec2(-0.8496514, -0.09548577),
vec2(-0.9498642, -0.01606606),
vec2(-0.08049984, -0.05044575),
vec2(-0.169844, -0.08516456),
vec2(-0.265735, -0.1030045),
vec2(-0.3657433, -0.1031108),
vec2(-0.4673436, -0.08494069),
vec2(-0.5679523, -0.04827199),
vec2(-0.6649653, 0.006789881),
vec2(-0.7557976, 0.0798124),
vec2(-0.8379211, 0.1700387),
vec2(-0.9089038, 0.2763945),
vec2(-0.09210127, -0.02328855),
vec2(-0.1877901, -0.0288941),
vec2(-0.2845263, -0.01642592),
vec2(-0.3797352, 0.01418343),
vec2(-0.4708469, 0.06267501),
vec2(-0.5553344, 0.1284669),
vec2(-0.6307517, 0.2106591),
vec2(-0.6947714, 0.3080465),
vec2(-0.7452206, 0.4191316),
vec2(-0.7801142, 0.5421457),
vec2(-0.09480272, 0.006119081),
vec2(-0.1875896, 0.03016846),
vec2(-0.2758231, 0.07173992),
vec2(-0.3570324, 0.1301071),
vec2(-0.4288512, 0.2042343),
vec2(-0.4890532, 0.2927917),
vec2(-0.5355871, 0.3941718),
vec2(-0.5666082, 0.5065128),
vec2(-0.5805076, 0.6277228),
vec2(-0.5759399, 0.7555087),
vec2(-0.08834317, 0.03493541),
vec2(-0.1692619, 0.08631578),
vec2(-0.2404665, 0.1529734),
vec2(-0.2998287, 0.2334582),
vec2(-0.3454146, 0.3260579),
vec2(-0.3755136, 0.4288234),
vec2(-0.3886675, 0.5395948),
vec2(-0.3836918, 0.656034),
vec2(-0.3596989, 0.7756557),
vec2(-0.3161118, 0.8958646),
vec2(-0.07334682, 0.06037585),
vec2(-0.134578, 0.1341222),
vec2(-0.1818731, 0.2194246),
vec2(-0.2136519, 0.3142497),
vec2(-0.2285998, 0.4163738),
vec2(-0.2256874, 0.5234168),
vec2(-0.20419, 0.6328755),
vec2(-0.163699, 0.7421607),
vec2(-0.1041316, 0.8486352),
vec2(-0.02573633, 0.9496514),
vec2(-0.05126279, 0.07998203),
vec2(-0.08688951, 0.1689681),
vec2(-0.1057049, 0.2646724),
vec2(-0.1068294, 0.3646744),
vec2(-0.0896948, 0.4664545),
vec2(-0.0540524, 0.5674313),
vec2(1.882498E-05, 0.665),
vec2(0.07211307, 0.756571),
vec2(0.1614982, 0.839609),
vec2(0.2671252, 0.9116711),
vec2(-0.02422512, 0.09185936),
vec2(-0.03080469, 0.1874862),
vec2(-0.01932213, 0.2843443),
vec2(0.01031622, 0.3798599),
vec2(0.05787758, 0.4714607),
vec2(0.1228058, 0.5566136),
vec2(0.2042258, 0.6328639),
vec2(0.300956, 0.6978721),
vec2(0.411522, 0.7494496),
vec2(0.5341747, 0.7855937),
vec2(0.005153478, 0.09486011),
vec2(0.02825686, 0.1878871),
vec2(0.06892776, 0.2765393),
vec2(0.126465, 0.3583387),
vec2(0.1998571, 0.4309085),
vec2(0.2877969, 0.492009),
vec2(0.388698, 0.5395728),
vec2(0.5007175, 0.5717359),
vec2(0.6217795, 0.5868691),
vec2(0.749605, 0.583603)
);
float hahassao(){
    float rot = rand2s(UV) * 3.1415 * 2;
    vec3 startpos = texture(cloudsCloudsTex, UV).yzw;
    float dstcenter = distance(CameraPosition, startpos);
    
    mat2 RM = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    float occl = 0.0;
    for(int g=0;g < xsamples.length();g+=1){
        vec2 sampl = UV + (RM * (xsamples[g])) * 0.01;
        vec3 startposa = texture(cloudsCloudsTex, sampl).yzw;
        float aadst = distance(CameraPosition, startposa);
		float fact =  1.0 - clamp(abs(dstcenter - aadst) - 1000.1, 0.0, 1.0);
        occl += smoothstep(0.0, 100.0,  dstcenter - aadst) * fact;
    }
    return 1.0 - (occl / xsamples.length());
;}

#define PI 3.141592
#define iSteps 16
#define jSteps 8

float rsi(vec3 r0, vec3 rd, float sr) {
    // Simplified ray-sphere intersection that assumes
    // the ray starts inside the sphere and that the
    // sphere is centered at the origin. Always intersects.
    float a = dot(rd, rd);
    float b = 2.0 * dot(rd, r0);
    float c = dot(r0, r0) - (sr * sr);
    return (-b + sqrt((b*b) - 4.0*a*c))/(2.0*a);
}

vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g) {
    // Normalize the sun and view directions.
    pSun = normalize(pSun);
    r = normalize(r);

    // Calculate the step size of the primary ray.
    float iStepSize = rsi(r0, r, rAtmos) / float(iSteps);

    // Initialize the primary ray time.
    float iTime = 0.0;

    // Initialize accumulators for Rayleigh and Mie scattering.
    vec3 totalRlh = vec3(0,0,0);
    vec3 totalMie = vec3(0,0,0);

    // Initialize optical depth accumulators for the primary ray.
    float iOdRlh = 0.0;
    float iOdMie = 0.0;

    // Calculate the Rayleigh and Mie phases.
    float mu = dot(r, pSun);
    float mumu = mu * mu;
    float gg = g * g;
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
    float pMie = 3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));

    // Sample the primary ray.
    for (int i = 0; i < iSteps; i++) {

        // Calculate the primary ray sample position.
        vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);

        // Calculate the height of the sample.
        float iHeight = length(iPos) - rPlanet;

        // Calculate the optical depth of the Rayleigh and Mie scattering for this step.
        float odStepRlh = exp(-iHeight / shRlh) * iStepSize;
        float odStepMie = exp(-iHeight / shMie) * iStepSize;

        // Accumulate optical depth.
        iOdRlh += odStepRlh;
        iOdMie += odStepMie;

        // Calculate the step size of the secondary ray.
        float jStepSize = rsi(iPos, pSun, rAtmos) / float(jSteps);

        // Initialize the secondary ray time.
        float jTime = 0.0;

        // Initialize optical depth accumulators for the secondary ray.
        float jOdRlh = 0.0;
        float jOdMie = 0.0;

        // Sample the secondary ray.
        for (int j = 0; j < jSteps; j++) {

            // Calculate the secondary ray sample position.
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

            // Calculate the height of the sample.
            float jHeight = length(jPos) - rPlanet;

            // Accumulate the optical depth.
            jOdRlh += exp(-jHeight / shRlh) * jStepSize;
            jOdMie += exp(-jHeight / shMie) * jStepSize;

            // Increment the secondary ray time.
            jTime += jStepSize;
        }

        // Calculate attenuation.
        vec3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));

        // Accumulate scattering.
        totalRlh += odStepRlh * attn;
        totalMie += odStepMie * attn;

        // Increment the primary ray time.
        iTime += iStepSize;

    }

    // Calculate and return the final color.
    return max(vec3(0.0), iSun * (pRlh * kRlh * totalRlh + pMie * kMie * totalMie));
}

vec3 sun(vec3 camdir, vec3 sundir){
    float dt = max(0, dot(camdir, sundir));
    //return pow(smoothstep(0.99574189, 0.99996189, dt), 60.0) * vec3(1);
    return pow(dt*dt*dt*dt*dt, 256.0) * vec3(10) + pow(dt, 128.0) * vec3(0.8);
}


vec3 atm(vec3 sunpos){
    vec3 scatter2 = atmosphere(
        sunpos,           // normalized ray direction
        vec3(0,6372e3  ,0),               // ray origin
        sunpos,                        // position of the sun
        22.0,                           // intensity of the sun
        6371e3,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(2.5e-6, 6.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3,                          // Mie scale height
        0.758                           // Mie preferred scattering direction
    );
    //return mix(vec3(1.0), 1.0 * scatter2,1.0 - texture(cloudsCloudsTex, UV).y);
    //return mix(vec3(3.0), scatter2 * 3.0, 1.0 - texture(cloudsCloudsTex, UV).y);
    vec3 cmix = mix(vec3(1.0), scatter2, 1.0 - max(0, dot(sunpos, vec3(0,1,0))));
    float shadowmult = 1000.0 / (CloudsCeil - CloudsFloor);
    return mix(vec3(cmix * shadowmult), vec3(cmix * 3.0), texture(cloudsCloudsTex, UV).y);
}

vec3 determineNormal(){
    ivec2 txs = textureSize(cloudsCloudsTex, 0);
    vec2 pix = 1.0 / vec2(txs);
    vec3 pcen = texture(cloudsCloudsTex, UV).yzw;
    vec3 pdx = texture(cloudsCloudsTex, UV + vec2(pix.x, 0)).yzw;
    vec3 pdy = texture(cloudsCloudsTex, UV + vec2(0, pix.y)).yzw;
    vec3 pmdx = texture(cloudsCloudsTex, UV - vec2(pix.x, 0)).yzw;
    vec3 pmdy = texture(cloudsCloudsTex, UV - vec2(0, pix.y)).yzw;
    pcen = (pcen + pdx + pdy + pmdx + pmdy) * 0.2;
    vec3 n1 = normalize(
        cross(
            pdx - pcen,
            pdy - pcen
        )
    );
    vec3 n2 = normalize(
        cross(
            pmdx - pcen,
            pdy - pcen
        )
    );
    vec3 n3 = normalize(
        cross(
            pdx - pcen,
            pmdy - pcen
        )
    );
    vec3 n4 = normalize(
        cross(
            pmdx - pcen,
            pmdy - pcen
        )
    );
    return normalize(n1);
}
    
vec4 shade(){    
    wtim = wind * Time * CloudsWindSpeed;
    //float val = raymarchClouds(1, CloudsFloor, CloudsCeil).r;
    sphere2 = Sphere(vec3(0), planetradius + CloudsCeil);
    float val = smartShadow(1);
   // float val = 1.0;
    vec3 color = atm(sundir);

    return vec4(color, 0);
}