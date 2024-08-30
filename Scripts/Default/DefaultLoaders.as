
void LoadDefaultMapLoaders()
{
	printf("### Loaded GameMode: VolleyBall ###");
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadPNGMap.as", "png");
	//RegisterFileExtensionScript("Scripts/MapLoaders/GenerateFromKAGGen.as", "kaggen.cfg");
}
