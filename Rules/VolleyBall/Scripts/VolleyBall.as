
//BVB gamemode logic script

#define SERVER_ONLY

#include "BVB_Structs.as";
#include "RulesCore.as";
#include "RespawnSystem.as";

#include "CTF_PopulateSpawnList.as"

//edit the variables in the config file below to change the basics
// no scripting required! 
string bvb_config_file = "../Mods/Volleyball/volleyball_vars.cfg";

void Config(BVBCore@ this)
{
	if (getRules().exists("bvb_config"))
		bvb_config_file = getRules().get_string("bvb_config");

	ConfigFile cfg = ConfigFile();
	cfg.loadFile(bvb_config_file);

	if (cfg.read_bool("teamsmanaged", false) == false)
	{
		getRules().AddScript("TeamQueues.as");
	}	

	//how long to wait for everyone to spawn in?
	s32 warmUpTimeSeconds = cfg.read_s32("warmup_time", 10);
	this.warmUpTime = (getTicksASecond() * warmUpTimeSeconds);

	//how many Goals needed to win the match.
	this.goals_to_win = cfg.read_u16("goals_to_win", 7);

	//how long for the game to play out?
	s32 gameDurationMinutes = cfg.read_s32("game_time", -1);
	if (gameDurationMinutes <= 0)
	{
		this.gameDuration = 0;
		getRules().set_bool("no timer", true);
	}
	else
	{
		this.gameDuration = (getTicksASecond() * 60 * gameDurationMinutes);
	}

	this.gameDuration = (getTicksASecond() * 60 * gameDurationMinutes) + this.warmUpTime;

	this.spawnTime = (getTicksASecond() * 2);
	//how many players have to be in for the game to start
	this.minimum_players_in_team = cfg.read_s32("minimum_players_in_team", 1);

	//whether to scramble each game or not
	this.scramble_teams = cfg.read_bool("scrambleTeams", false);

	s32 scramble_maps = cfg.read_s32("scramble_maps", -1);
	if(scramble_maps != -1) {
		sv_mapcycle_shuffle = (scramble_maps != 0);
	}

	// modifies if the fall damage velocity is higher or lower - BVB has lower velocity
	this.rules.set_f32("fall vel modifier", cfg.read_f32("fall_dmg_nerf", 1.3f));
}

shared string base_name() { return "beachtent"; }
const s32 spawnspam_limit_time = 3;

shared class BVBSpawns : RespawnSystem
{
	BVBCore@ BVB_core;

	bool force;	
	s32 limit;

	void SetCore(RulesCore@ _core)
	{
		RespawnSystem::SetCore(_core);
		@BVB_core = cast < BVBCore@ > (core);

		limit = spawnspam_limit_time;
	}
	void Update()
	{
		for (uint team_num = 0; team_num < BVB_core.teams.length; ++team_num)
		{
			BVBTeamInfo@ team = cast < BVBTeamInfo@ > (BVB_core.teams[team_num]);

			for (uint i = 0; i < team.spawns.length; i++)
			{
				BVBPlayerInfo@ info = cast < BVBPlayerInfo@ > (team.spawns[i]);

				UpdateSpawnTime(info, i);

				DoSpawnPlayer(info);
			}
		}
	}
	void UpdateSpawnTime(BVBPlayerInfo@ info, int i)
	{
		if (info !is null)
		{
			u8 spawn_property = 255;

			if (info.can_spawn_time > 0)
			{
				info.can_spawn_time--;
				spawn_property = u8(Maths::Min(250, (info.can_spawn_time / 30)));
			}

			string propname = "bvb spawn time " + info.username;

			BVB_core.rules.set_u8(propname, spawn_property);
			BVB_core.rules.SyncToPlayer(propname, getPlayerByUsername(info.username));
		}
	}

	void DoSpawnPlayer(PlayerInfo@ p_info)
	{
		if (canSpawnPlayer(p_info))
		{
			//limit how many spawn per second
			if (limit > 0)
			{
				limit--;
				return;
			}
			else
			{
				limit = spawnspam_limit_time;
			}

			// tutorials hack
			if (getRules().exists("singleplayer"))
			{
				p_info.team = 0;
			}

			CPlayer@ player = getPlayerByUsername(p_info.username); // is still connected?

			if (player is null)
			{
				RemovePlayerFromSpawn(p_info);
				return;
			}
			if (player.getTeamNum() != int(p_info.team))
			{
				player.server_setTeamNum(p_info.team);
			}

			// remove previous players blob
			if (player.getBlob() !is null)
			{
				CBlob @blob = player.getBlob();
				blob.server_SetPlayer(null);
				blob.server_Die();
			}

			CBlob@ playerBlob = SpawnPlayerIntoWorld(getSpawnLocation(p_info), p_info);

			if (playerBlob !is null)
			{
				// spawn resources
				p_info.spawnsCount++;
				RemovePlayerFromSpawn(player);
			}
		}
	}

	bool canSpawnPlayer(PlayerInfo@ p_info)
	{
		BVBPlayerInfo@ info = cast < BVBPlayerInfo@ > (p_info);

		if (info is null) { warn("BVB LOGIC: Couldn't get player info ( in bool canSpawnPlayer(PlayerInfo@ p_info) ) "); return false; }

		if (force) { return true; }

		return true; //info.can_spawn_time == 0;
	}

	Vec2f getSpawnLocation(PlayerInfo@ p_info)
	{
		BVBPlayerInfo@ c_info = cast < BVBPlayerInfo@ > (p_info);
		if (c_info !is null)
		{			
			{
				CBlob@[] spawns;
				PopulateSpawnList(spawns, p_info.team);

				for (uint step = 0; step < spawns.length; ++step)
				{
					if (spawns[step].getTeamNum() == s32(p_info.team))
					{
						return spawns[step].getPosition();
					}
				}
			}
		}

		return Vec2f(0, 0);
	}

	Vec2f getBlueSpawnLocation(PlayerInfo@ p_info)
	{
		Vec2f[] spawns;
		CMap@ map = getMap();
		if (map !is null)
		{				
			Vec2f respawnPos = Vec2f(150.0f, map.getLandYAtX(150.0f / map.tilesize) * map.tilesize - 32.0f);
			respawnPos.y -= 16.0f;
			return respawnPos;
		}

		return Vec2f(0, 0);
	}

	Vec2f getRedSpawnLocation(PlayerInfo@ p_info)
	{
		Vec2f[] spawns;
		CMap@ map = getMap();
		if (map !is null)
		{
			Vec2f respawnPos = Vec2f(map.tilemapwidth * map.tilesize - 150.0f, map.getLandYAtX(map.tilemapwidth - (150.0f / map.tilesize)) * map.tilesize - 32.0f);
			respawnPos.y -= 16.0f;
			return respawnPos;
		}

		return Vec2f(0, 0);
	}

	void RemovePlayerFromSpawn(CPlayer@ player)
	{
		RemovePlayerFromSpawn(core.getInfoFromPlayer(player));
	}

	void RemovePlayerFromSpawn(PlayerInfo@ p_info)
	{
		BVBPlayerInfo@ info = cast < BVBPlayerInfo@ > (p_info);

		if (info is null) { warn("BVB LOGIC: Couldn't get player info ( in void RemovePlayerFromSpawn(PlayerInfo@ p_info) )"); return; }

		string propname = "bvb spawn time " + info.username;

		for (uint i = 0; i < BVB_core.teams.length; i++)
		{
			BVBTeamInfo@ team = cast < BVBTeamInfo@ > (BVB_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1)
			{
				team.spawns.erase(pos);
				break;
			}
		}

		BVB_core.rules.set_u8(propname, 255);   //not respawning
		BVB_core.rules.SyncToPlayer(propname, getPlayerByUsername(info.username));
		//info.can_spawn_time = 0;
	}

	void AddPlayerToSpawn(CPlayer@ player)
	{
		s32 tickspawndelay = s32(BVB_core.spawnTime);

		BVBPlayerInfo@ info = cast < BVBPlayerInfo@ > (core.getInfoFromPlayer(player));

		if (info is null) { warn("BVB LOGIC: Couldn't get player info  ( in void AddPlayerToSpawn(CPlayer@ player) )"); return; }

		//clamp it so old bad values don't get propagated
		s32 old_spawn_time = Maths::Max(0, Maths::Min(info.can_spawn_time, tickspawndelay));

		RemovePlayerFromSpawn(player);
		if (player.getTeamNum() == core.rules.getSpectatorTeamNum())
			return;

		if (info.team < BVB_core.teams.length)
		{
			BVBTeamInfo@ team = cast < BVBTeamInfo@ > (BVB_core.teams[info.team]);

			info.can_spawn_time = ((old_spawn_time > 30) ? old_spawn_time : tickspawndelay);

			info.spawn_point = player.getSpawnPoint();
			team.spawns.push_back(info);
		}
		else
		{
			error("PLAYER TEAM NOT SET CORRECTLY! " + info.team + " / " + BVB_core.teams.length);
		}
	}

	bool isSpawning(CPlayer@ player)
	{
		BVBPlayerInfo@ info = cast < BVBPlayerInfo@ > (core.getInfoFromPlayer(player));
		for (uint i = 0; i < BVB_core.teams.length; i++)
		{
			BVBTeamInfo@ team = cast < BVBTeamInfo@ > (BVB_core.teams[i]);
			int pos = team.spawns.find(info);

			if (pos != -1)
			{
				return true;
			}
		}
		return false;
	}

};

shared class BVBCore : RulesCore
{
	s32 warmUpTime;
	s32 gameDuration;
	s32 spawnTime;
	u16 goals;
	u16 goals_to_win;
	s32 minimum_players_in_team;

	bool scramble_teams;

	BVBSpawns@ bvb_spawns;

	BVBCore() {}

	BVBCore(CRules@ _rules, RespawnSystem@ _respawns)
	{
		spawnTime=0;
		super(_rules, _respawns);
	}

	int gamestart;
	void Setup(CRules@ _rules = null, RespawnSystem@ _respawns = null)
	{
		RulesCore::Setup(_rules, _respawns);
		gamestart = getGameTime();
		@bvb_spawns = cast < BVBSpawns@ > (_respawns);		
		_rules.set_string("music - base name", base_name());
		server_CreateBlob("../Mods/Volleyball/Rules/VolleyBall/Scripts/BVBMusic.cfg");

		sv_mapautocycle = true;
	}

	void Update()
	{
		if (getGameTime() % 6 == 0) 
		{ updateHUD(); }
		
		if (rules.isGameOver()) { return; }

		s32 ticksToStart = gamestart + warmUpTime - getGameTime();
		bvb_spawns.force = false;

		if (ticksToStart <= 0 && (rules.isWarmup()))
		{				
			getRules().set_u8("servingTeam", XORRandom(2));
			rules.set_bool("Wants New Serve", true);
			rules.set_u8("serve delay", 2*30);
			rules.SetCurrentState(GAME);	
		}

		if (ticksToStart > 0 && rules.isWarmup()) //is the start of the game, spawn everyone + give mats
		{
			rules.SetGlobalMessage("Match starts in {SEC}");
			rules.AddGlobalMessageReplacement("SEC", "" + ((ticksToStart / 30) + 1));
		}

		if (rules.isIntermission())  //Handling this in Team Queues
		{			
			gamestart = getGameTime();
		//	rules.set_u32("game_end_time", gamestart + gameDuration);
		//	if (!rules.get_bool("enough_in_queue"))
		//	{
		//		rules.SetGlobalMessage("Not enough players in queues.\nPlease wait for someone to join...");
		//	}
		//	else
			//{
			//	rules.SetGlobalMessage(""); // removes the win team msg
			//}
		}	
		else if (rules.isMatchRunning())
		{
			if (rules.get_bool("Wants New Serve"))
			{						
				u8 delay = rules.get_u8("serve delay");
				u8 st = rules.get_u8("servingTeam");

				CBlob@ p = getBallServer(st);		
				if (p !is null)
				{
					rules.SetGlobalMessage("{TEAMNAME} Is Serving in " + delay/30 + " secs");
					rules.AddGlobalMessageReplacement("TEAMNAME", "" + rules.getTeam(st).getName());
					
					if (delay > 1)
					{
						delay--;
						rules.set_u8("serve delay", delay);
						rules.Sync("serve delay", true);
					}
					else if (delay == 1)
					{
						if (getNet().isServer())
						{	
							CBlob@ ball = server_CreateBlob("beachball");
							if (ball !is null)
							{						
								ball.setPosition(p.getPosition());
								ball.set_u8("last_hit_team", -1);						
								p.server_AttachTo(ball, "PICKUP");
							}
						}

						rules.set_u8("serve delay", 0);
					}
					else if (delay == 0)
					{
						rules.set_bool("Wants New Serve",false);
					}
				}				
			}
			else
			{
				rules.SetGlobalMessage("");
			}
		}

		//  SpawnPowerups();
		RulesCore::Update(); //update respawns
		CheckTeamWon();
	}

	void AddTeam(CTeam@ team)
	{
		BVBTeamInfo t(teams.length, team.getName());
		teams.push_back(t);
	}

	void AddPlayer(CPlayer@ player, u8 team = 0, string default_config = "")
	{
		BVBPlayerInfo p(player.getUsername(), player.getTeamNum(), "beachvolleyplayer");
		players.push_back(p);
		ChangeTeamPlayerCount(p.team, 1);
	}

	void SetupBase(CBlob@ base)
	{
		if (base is null)
		{return;} //nothing to do
	}

	void SetupBases()
	{
		// destroy all previous spawns if present
		CBlob@[] oldBases;
		getBlobsByName(base_name(), @oldBases);

		for (uint i = 0; i < oldBases.length; i++)
		{
			oldBases[i].server_Die();
		}

		CMap@ map = getMap();

		if (map !is null && map.tilemapwidth != 0)
		{
			//spawn the spawns :D
			Vec2f respawnPos;

			f32 auto_distance_from_edge_tents = Maths::Min(map.tilemapwidth * 0.05f * 8.0f, 100.0f);

			if (!getMap().getMarker("blue main spawn", respawnPos))
			{
				respawnPos = Vec2f(auto_distance_from_edge_tents, map.getLandYAtX(auto_distance_from_edge_tents / map.tilesize) * map.tilesize - 32.0f);
			}

			respawnPos.y -= 8.0f;
			SetupBase(server_CreateBlob(base_name(), 0, respawnPos));

			if (!getMap().getMarker("red main spawn", respawnPos))
			{
				respawnPos = Vec2f(map.tilemapwidth * map.tilesize - auto_distance_from_edge_tents, map.getLandYAtX(map.tilemapwidth - (auto_distance_from_edge_tents / map.tilesize)) * map.tilesize - 32.0f);
			}

			respawnPos.y -= 8.0f;
			SetupBase(server_CreateBlob(base_name(), 1, respawnPos));
		}
		else
		{
			warn("CTF: map loading failure");
			for(int i = 0; i < 2; i++)
			{
				SetupBase(server_CreateBlob(base_name(), i, Vec2f(0,0)));
			}
		}

		rules.SetCurrentState(0); // intermission
	}

	void CheckTeamWon() // and scores
	{
		if (!rules.isMatchRunning()) { return; }

		CBlob@ gb = getGameBall();
		if (gb !is null && !rules.get_bool("Wants New Serve"))
		{
			if (!gb.isAttached() && !gb.hasTag("HasHit") && gb.isOnMap())
			{ 
				CMap@ map = getMap();
				f32 ballXpos = gb.getPosition().x;
				f32 mapMid = (map.tilemapwidth * map.tilesize)/2;

				if (ballXpos > mapMid)
				{
					if (ballXpos < mapMid+296.0f)
					{
						rules.set_u8("servingTeam", 0);
						addGoal(0);
					}
					else // out of bounds
					{
						if (gb.get_u8("last_hit_team") == 0)
						{
							rules.set_u8("servingTeam", 1);
							addGoal(1);
						}
						else if (gb.get_u8("last_hit_team") == 1)
						{
							rules.set_u8("servingTeam", 0);
							addGoal(0);
						}
					}					
				}
				else if (ballXpos < mapMid)
				{
					if (ballXpos > mapMid-296.0f)
					{
						rules.set_u8("servingTeam", 1);
						addGoal(1);
					}
					else // out of bounds
					{
						if (gb.get_u8("last_hit_team") == 0)
						{
							rules.set_u8("servingTeam", 1);
							addGoal(1);
						}
						else if (gb.get_u8("last_hit_team") == 1)
						{
							rules.set_u8("servingTeam", 0);
							addGoal(0);
						}
					}										
				}
				gb.Tag("HasHit");
				gb.server_SetTimeToDie(0.5);

				//Sound::Play("Whistle1.ogg");
				rules.set_bool("Wants New Serve", true);
				rules.set_u8("serve delay", 2*30);
			}
		}

		int winteamIndex = -1;
		BVBTeamInfo@ winteam = null;
		s8 team_wins_on_end = -1;

		//set up an array of which teams are alive
		array<bool> teams_alive;
		s32 teams_alive_count = 0;
		for (int i = 0; i < teams.length; i++)
			teams_alive.push_back(false);

		//check with each player
		for (int i = 0; i < getPlayersCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			CBlob@ b = p.getBlob();
			s32 team = p.getTeamNum();
			if (b !is null && //blob alive
			        team >= 0 && team < teams.length) //team sensible
			{
				if (!teams_alive[team])
				{
					teams_alive[team] = true;
					teams_alive_count++;
				}
			}
		}

		//only one team remains!
		if (teams_alive_count == 1)
		{
			for (int i = 0; i < teams.length; i++)
			{
				if (teams_alive[i])
				{
					@winteam = cast < BVBTeamInfo@ > (teams[i]);
					winteamIndex = i;
					team_wins_on_end = i;
				}
			}
		}

		for (uint team_num = 0; team_num < teams.length; ++team_num)
		{
			BVBTeamInfo@ team = cast < BVBTeamInfo@ > (teams[team_num]);

			bool win = false;

			if (team.goals >= goals_to_win)
			{
				winteamIndex = team_num;
				win = true;
			}

			if (win)
			{				
				@winteam = team;
			}
		}

		//rules.set_s8("team_wins_on_end", team_wins_on_end);

		if (winteamIndex >= 0)
		{
			rules.SetTeamWon(winteamIndex);   //game over!
			rules.SetCurrentState(GAME_OVER);
			rules.SetGlobalMessage("{WINNING_TEAM} wins the game!");
			rules.AddGlobalMessageReplacement("WINNING_TEAM", winteam.name);

			if (getNet().isServer())
			{	
				rules.AddScript("EndGameEvents.as");
			}
		}
	}

	void addGoal(int team)
	{
		if (team >= 0 && team < int(teams.length))
		{
			BVBTeamInfo@ team_info = cast < BVBTeamInfo@ > (teams[team]);
			team_info.goals++;
		}
	}

	void updateHUD()
	{
		CBitStream serialised_team_hud;
		serialised_team_hud.write_u16(0x5afe); //check bits
		BVB_HUD hud;

		for (uint team_num = 0; team_num < teams.length; ++team_num)
		{
			BVBTeamInfo@ team = cast < BVBTeamInfo@ > (teams[team_num]);
			
			if(team_num == 0)
			{ hud.bluegoals = team.goals; }
			else if (team_num == 1)
			{ hud.redgoals = team.goals; }

		}
		
		hud.Serialise(serialised_team_hud);

		rules.set_CBitStream("bvb_serialised_team_hud", serialised_team_hud);
		rules.Sync("bvb_serialised_team_hud", true);
	}
};

//pass stuff to the core from each of the hooks

void Reset(CRules@ this)
{	
	CBitStream stream;
	stream.write_u16(0xDEAD); //check bits rewritten when theres something useful
	this.set_CBitStream("bvb_serialised_team_hud", stream);
    this.Sync("bvb_serialized_team_hud", true);

	printf("Restarting rules script: " + getCurrentScriptName());
	BVBSpawns spawns();
	BVBCore core(this, spawns);
	Config(core);
	core.SetupBases();
	this.set("core", @core);
	this.set("start_gametime", getGameTime() + core.warmUpTime);
	this.set_u32("game_end_time", getGameTime() + core.gameDuration); //for TimeToEnd.as

	this.RemoveScript("EndGameEvents.as"); //remove it so we can initalize again
	
}

void onRestart(CRules@ this)
{	
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
	this.set_s32("restart_rules_after_game_time", 25 * 30); // endgame nextmap timer	
}