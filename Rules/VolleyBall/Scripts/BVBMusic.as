// Game Music

#define CLIENT_ONLY

enum GameMusicTags
{
	world_music,
	world_waves,
};

void onInit(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	this.set_bool("initialized game", false);
}

void onTick(CBlob@ this)
{
	CMixer@ mixer = getMixer();
	if (mixer is null)
		return;

	if (s_gamemusic && s_musicvolume > 0.0f)
	{
		if (!this.get_bool("initialized game"))
		{
			AddGameMusic(this, mixer);
		}

		GameMusicLogic(this, mixer);
	}
	else
	{
		mixer.FadeOutAll(0.0f, 2.0f);
	}
}

//sound references with tag
void AddGameMusic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	this.set_bool("initialized game", true);
	mixer.ResetMixer();

	mixer.AddTrack("../Mods/Volleyball/Music/WavesAmbientLoop.ogg", world_waves);

	mixer.AddTrack("../Mods/Volleyball/Music/Tropical_Holiday.ogg", world_music);
	mixer.AddTrack("../Mods/Volleyball/Music/DaysGoBy.ogg", 		world_music);
	mixer.AddTrack("../Mods/Volleyball/Music/HyperParadise.ogg", 	world_music);
	mixer.AddTrack("../Mods/Volleyball/Music/InTheAirTonight.ogg", 	world_music);
}

void GameMusicLogic(CBlob@ this, CMixer@ mixer)
{
	if (mixer is null)
		return;

	//warmup
	CRules @rules = getRules();

	if (rules.isIntermission() || rules.isWarmup())
	{
	 	// initial fade in
	 	if (mixer.getPlayingCount() == 0)
		{	
			mixer.FadeInRandom(world_music , 3.0f);
			mixer.FadeInRandom(world_waves , 3.0f);
		}
		
		// else if 
		if (!mixer.isPlaying(world_music))
		{
			mixer.FadeInRandom(world_music , 3.0f);
		}

		if (!mixer.isPlaying(world_waves))
		{
		 	mixer.FadeInRandom(world_waves , 0.0f);
		}
	}
	else
	{
		if (!mixer.isPlaying(world_waves))
		{
		 	mixer.FadeInRandom(world_waves , 0.0f);
		}

		if (rules.isGameOver())
		{
			mixer.FadeInRandom(world_music , 0.5f);
		}
		else if (rules.isMatchRunning())
		{
			mixer.FadeOut(world_music, 5.0f);		
		}
	}
}
