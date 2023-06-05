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
    f -= 0.00125*noise( p );
    return f/0.884375;
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

vec4 internalmarchshadow(float scale, vec3 p1, vec3 p2, float coverageinv){
    float iter = 0.1;
    const float stepcount = 6.0;
    float stepsize = 1.0 / stepcount;
    float rd = rand2s(UV + vec2(0, 2)) * stepsize;
    for(int i=0;i<stepcount;i++){
        vec3 pos = mix(p1, p2, iter + rd);
        float clouds = cloudsDensity3D(pos * 0.01 * scale);
      //  clouds *= smoothstep(0.5, 0.9, iter + rd);
        coverageinv *= 1.0 - clamp(clouds * stepsize *  10 * (1.0 - abs(iter * 2.0 - 1.0)), 0.0, 1.0);
      //  if(coverageinv < 0.6)break;
        iter += stepsize;
    }
    
    return vec4(vec3(1.0), coverageinv);
}
float marchatmosphere(float scale, vec3 p1, vec3 p2){
    float iter = 0.0;
    const float stepcount = 10.0;
    float stepsize = 1.0 / stepcount;
    float rd = rand2s(UV + vec2(1, 1)) * stepsize;
    float color = 1.0;
    float mult = distance(p1, mix(p1, p2, stepsize));
    for(int i=0;i<stepcount;i++){
        vec3 pos = mix(p1, p2, iter + rd);
        Ray r = Ray(vec3(0,planetradius ,0) + pos, sundir);
        float hitceil = rsi2(r, sphere2);
        float shadow = pow(internalmarchshadow(scale, pos, pos + r.d * hitceil, 1.0).a, 20.0);
        color += shadow * 0.02 * mult;// * (1.0 - iter);
        iter += stepsize;
    }
    return (color * stepsize) * clamp((distance(p1, p2) * 0.0001), 0.0, 10.0);
}

#define intersects(a) (a >= 0.0)
float atmos(float scale, float floord, float ceiling){
    vec3 campos = CameraPosition * AtmosphereScale;
    vec3 viewdir = normalize(reconstructCameraSpaceDistance(UV, 10.0));
    viewdirglob = viewdir;
    vec3 atmorg = vec3(0,planetradius ,0) + campos;  
    float height = length(atmorg);
    float cloudslow = planetradius + floord;
    float cloudshigh = planetradius + ceiling;
    
    sphere1 = Sphere(vec3(0), cloudslow);
    sphere2 = Sphere(vec3(0), cloudshigh);
    Ray r = Ray(atmorg, viewdir);
         
    float planethit = rsi2(r, planet);
    float hitfloor = rsi2(r, sphere1);
    float floorminhit = minhit;
    float floormaxhit = maxhit;
    float hitceil = rsi2(r, sphere2);
    float ceilminhit = minhit;
    float ceilmaxhit = maxhit;
    float atmcoverage = 0.0;
    if(height > cloudshigh){
        if(intersects(planethit)){
            atmcoverage = marchatmosphere(scale, campos + viewdir * max(0.0, min(hitceil, hitfloor)), campos + viewdir * planethit);
        } else if(intersects(hitceil)){
            atmcoverage = marchatmosphere(scale, campos + viewdir * ceilminhit, campos + viewdir * ceilmaxhit);
        }
    } else {
        if(intersects(planethit)){
            atmcoverage = marchatmosphere(scale, campos, campos + viewdir * planethit);
        } else {
            atmcoverage = marchatmosphere(scale, campos, campos + viewdir * hitceil);
        }
    }
    return atmcoverage;
}
vec4 shade(){    
    wtim = wind * Time * CloudsWindSpeed;
    float val = atmos(1, CloudsFloor, CloudsCeil);
    return vec4(val * CloudsAtmosphereShaftsMultiplier, 0, 0, 0);
}