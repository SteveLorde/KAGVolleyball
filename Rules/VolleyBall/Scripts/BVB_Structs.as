// management structs

#include "Rules/CommonScripts/BaseTeamInfo.as";
#include "Rules/CommonScripts/PlayerInfo.as";

shared class BVBPlayerInfo : PlayerInfo
{
	u32 can_spawn_time;
	u32 spawn_point;

	BVBPlayerInfo() { Setup("", 0, ""); }
	BVBPlayerInfo(string _name, u8 _team, string _default_config) { Setup(_name, _team, _default_config); }

	void Setup(string _name, u8 _team, string _default_config)
	{
		PlayerInfo::Setup(_name, _team, _default_config);
		can_spawn_time = 0;		
		spawn_point = 0;
	}
};

//teams
shared class BVBTeamInfo : BaseTeamInfo
{
	PlayerInfo@[] spawns;	
	u16 goals;

	u8 teamnumber;

	BVBTeamInfo() { super(); }

	BVBTeamInfo(u8 _index, string _name)
	{
		super(_index, _name);
	}

	void Reset()
	{
		BaseTeamInfo::Reset();
		goals = 0;
	}
};

shared class BVB_HUD
{
	u8 team_num;
	u8 spawn_time;
	u16 bluegoals;
	u16 redgoals;
	u16 goals_limit;

	BVB_HUD() { }
	BVB_HUD(CBitStream@ bt) { Unserialise(bt); }	

	void Serialise(CBitStream@ bt)
	{
		bt.write_u8(team_num);
		bt.write_u8(spawn_time);
		bt.write_u16(goals_limit);
		bt.write_u16(bluegoals);
		bt.write_u16(redgoals);
	}
	void Unserialise(CBitStream@ bt)
	{
		team_num = bt.read_u8();
		spawn_time = bt.read_u8();
		goals_limit = bt.read_u16();
		bluegoals = bt.read_u16();
		redgoals =  bt.read_u16();
	}
};

shared CBlob@ getGameBall()
{
	CBlob@ ball = getBlobByName("beachball");
	if (ball !is null)
	{
		return ball;
	}
	return null;
}

shared CBlob@ getBallServer(int servingTeam)
{
	CBlob@[] players;
	CBlob@[] potentials;

	getBlobsByTag("player", @players);
	for (uint i = 0; i < players.size(); i++)
	{		
		if (players[i].getTeamNum() == servingTeam)
		{
			CBlob@ potential = players[i];
			if (potential !is null)
			{ 
				potentials.push_back(potential);				
			}	
			else
			{				
				getRules().set_u8("serve delay", 2*30);
				CBlob@ b = getGameBall();
				if (b !is null)
				{b.server_Die();}				
			}				
		}
	}
	
	Random _r(Time());
	int randPotential = _r.NextRanged(potentials.size());
	return potentials[randPotential];
}
