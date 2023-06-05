
float toLogDepth(float depth, float far){
	//float badass_depth = log(LogEnchacer*depth + 1.0f) / log(LogEnchacer*far + 1.0f);
    float badass_depth = log2(max(1e-6, 1.0 + depth*far)) / (log2(far));
    //float badass_depth = log2(1.0 + depth) / log2(far+1.0);
	return badass_depth;
}
float toLogDepth2(float depth, float far){
	//float badass_depth = log(LogEnchacer*depth + 1.0f) / log(LogEnchacer*far + 1.0f);
    float badass_depth = log2(max(1e-6, 1.0 + depth)) / (log2(far));
    //float badass_depth = log2(1.0 + depth) / log2(far+1.0);
	return badass_depth;
}
float reverseLog(float dd, float far){
	//return pow(2, dd * log2(far+1.0) ) - 1;
	return pow(2, dd * log2(far)) - 1.0;
}