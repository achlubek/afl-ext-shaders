#version 430 core
uniform int Pass;

in vec2 UV;// let get it done well this time
out vec4 outColor;
#include LightingSamplers.glsl

float kern[] = float[](
	0.02547,
	0.02447,
	0.02351,
	0.02101,
	0.01850,
	0.01550,
	0.01240,
	0.00940,
	0.00708,
	0.00508,
	0.00345,
	0.00205,
	0.00143,
	0.00103,
	0.00051,
	0.00028,
	0.00015,
	0.00009,
	0.00004
);

float cosmix(float a, float b, float factor){
    return mix(a, b, 1.0 - (cos(factor*3.1415)*0.5+0.5));
}
float ncos(float a){
    return cosmix(0, 1, clamp(a, 0.0, 1.0));
}
vec3 sampletex(vec2 uv)
{
	vec3 r = clamp(texture(bloomPassSource, uv).rgb, 0.0, 3.0);
	return r * (Pass == 0 ? smoothstep(0.5, length(vec3(1.0)), length(clamp(r, 0.0, 1.0))) * length(r) : 1.0);
}

float getpix()
{
	return Pass == 0 ? (1.0 / textureSize(bloomPassSource, 0).x) : (1.0 / textureSize(bloomPassSource, 0).y);
}
float getpixpass(int pass)
{
	return pass == 0 ? (1.0 / textureSize(bloomPassSource, 0).x) : (1.0 / textureSize(bloomPassSource, 0).y);
}
//#define samples 16
float getkern(float factor){
	return (cos(factor*3.1415)*0.5+0.5);
}
vec3 gauss(vec2 uv, int samples, float power){
	vec2 lookup = Pass == 0 ? vec2(1, 0) : vec2(0, 1);
	vec3 accum = vec3(0);
	float pix = getpix();
	float pixx = 0;
	for(int i=0;i<samples;++i) {
		accum += power * sampletex(uv + pixx * lookup) * getkern(float(i)/samples);
		pixx += pix;
	}
	pixx = pix;
	for(int i=1;i<samples;++i) {
		accum += power * sampletex(uv - pixx * lookup) * getkern(float(i)/samples);
		pixx += pix;
	}
	return accum / (samples * 2 - 1);
}

vec3 makeGlare(vec2 uv, int samples, float power){
	vec3 accum = vec3(0);
	vec2 pix = 0.5 / textureSize(bloomPassSource, 0);
	vec2 pixx = vec2(0);
	
	vec2 lookup = vec2(1, 1);
	for(int i=0;i<samples;++i) {
		accum += power * sampletex(uv + pixx * lookup) * getkern(float(i)/samples);
		pixx += pix;
	}
	
	pixx = pix;
	for(int i=1;i<samples;++i) {
		accum += power * sampletex(uv - pixx * lookup) * getkern(float(i)/samples);
		pixx += pix;
	}	
	
	pixx = vec2(0);
	lookup = vec2(-1, 1);
	for(int i=0;i<samples;++i) {
		accum += power * sampletex(uv + pixx * lookup) * getkern(float(i)/samples);
		pixx += pix;
	}
	
	pixx = pix;
	for(int i=1;i<samples;++i) {
		accum += power * sampletex(uv - pixx * lookup) * getkern(float(i)/samples);
		pixx += pix;
	}
	
	pixx = vec2(0);
	lookup = vec2(1, 0);
	for(int i=0;i<samples;++i) {
		accum += power * sampletex(uv + pixx * lookup) * getkern(float(i)/samples);
		pixx += pix;
	}
	
	pixx = pix;
	for(int i=1;i<samples;++i) {
		accum += power * sampletex(uv - pixx * lookup) * getkern(float(i)/samples);
		pixx += pix;
	}
	
	pixx = vec2(0);
	lookup = vec2(0, 1);
	for(int i=0;i<samples;++i) {
		accum += power * sampletex(uv + pixx * lookup) * getkern(float(i)/samples);
		pixx += pix;
	}
	
	pixx = pix;
	for(int i=1;i<samples;++i) {
		accum += power * sampletex(uv - pixx * lookup) * getkern(float(i)/samples);
		pixx += pix;
	}
	
	return accum / (samples * 4 - 1);
}

void main()
{
	vec3 res = gauss(UV, 32, 3);
	res += gauss(UV, 48, 3) * vec3(0.7, 0.8, 1);
	res += gauss(UV, 64, 3) * vec3(0.5, 0.6, 1);
	res *= 0.25;
	// res += gauss((1.0 - UV), 16, 1) * vec3(0.5, 0.6, 1);
	// res += makeGlare(UV, 32, 2) * 0.1;
    outColor = vec4(res, 1.0);
}