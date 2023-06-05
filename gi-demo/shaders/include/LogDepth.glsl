
void updateDepth(){
	float depth = distance(positionWorldSpace, CameraPosition);
	float badass_depth = log(LogEnchacer*depth + 1.0f) / log(LogEnchacer*FarPlane + 1.0f);
	gl_FragDepth = badass_depth;
}
float getDepth(){
	float depth = distance(positionWorldSpace, CameraPosition);
	float badass_depth = log(LogEnchacer*depth + 1.0f) / log(LogEnchacer*FarPlane + 1.0f);
	return badass_depth;
}
float toLogDepth(float depth){
	float badass_depth = log(LogEnchacer*depth + 1.0f) / log(LogEnchacer*FarPlane + 1.0f);
	return badass_depth;
}