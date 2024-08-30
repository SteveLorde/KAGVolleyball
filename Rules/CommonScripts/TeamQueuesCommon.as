#include "RulesCore.as";

const string join_blue_id = "join: blue";
const string join_red_id = "join: red";
const string exit_queues_id = "exit: queues";
const string queue_lock_id = "lock: queues";
string bvb_config_file = "../Mods/VolleyballDark/volleyball_vars.cfg";

class QueueObject
{
	u16[] players;	
	string[] BlueQueuePlayers;
	string[] RedQueuePlayers;

	u16 timeremaining;
	u8 min_players;
	u8 max_players;
	u8 current_red;
	u8 current_blue;
	u8 current_spawned;
	bool equalteams;

	bool enough_in_queue;
	

	QueueObject() { current_blue = current_red = current_spawned = 0; }	
	QueueObject(CBitStream@ bt) { Unserialise(bt); }

	void Serialise(CBitStream@ bt)
	{		
		bt.write_u16(timeremaining);
		bt.write_u8(min_players);
		bt.write_u8(max_players);
		bt.write_u8(current_red);
		bt.write_u8(current_blue);
		bt.write_u8(current_spawned);
		bt.write_bool(enough_in_queue);	
		bt.write_bool(equalteams);		

		u8 blength = BlueQueuePlayers.length;
		bt.write_u8(blength);
		for(int i = 0; i < blength; i++) 
		{
		 	bt.write_string(BlueQueuePlayers[i]);
		}

		u8 rlength = RedQueuePlayers.length;
		bt.write_u8(rlength);
		for(int i = 0; i < rlength; i++) 
		{
		 	bt.write_string(RedQueuePlayers[i]);
		}
	}

	void Unserialise(CBitStream@ bt)
	{	
		timeremaining = bt.read_u16();
		min_players = bt.read_u8();
		max_players = bt.read_u8();
		current_red = bt.read_u8();
		current_blue = bt.read_u8();
		current_spawned = bt.read_u8();
		enough_in_queue = bt.read_bool();
		equalteams = bt.read_bool();

		BlueQueuePlayers.clear();
		RedQueuePlayers.clear();		

		u8 blength = 0;
		if(!bt.saferead_u8(blength)) return;
		for(int i = 0; i < blength; i++) 
		{
		 	string blueplayer;
		 	if(!bt.saferead_string(blueplayer)) return;
		 	BlueQueuePlayers.push_back(blueplayer);
		}

		u8 rlength = 0;
		if(!bt.saferead_u8(rlength)) return;
		for(int i = 0; i < rlength; i++) 
		{
		 	string redplayer;
		 	if(!bt.saferead_string(redplayer)) return;
		 	RedQueuePlayers.push_back(redplayer);
		}
	}
};

void Rules_ResetQueuesTimer(CRules@ this, QueueObject@ queues)
{				
	if (getRules().exists("bvb_config"))
		bvb_config_file = getRules().get_string("bvb_config");

	ConfigFile cfg = ConfigFile();
	cfg.loadFile(bvb_config_file);

	u16 cfg_queuelocktime = cfg.read_u16("queue_lock_time", 20);
	queues.timeremaining = cfg_queuelocktime*30;
	queues.equalteams = cfg.read_bool("equalteams", true);
	//this.set("team_queues", @queues);
}

void Rules_SetJoinQueues(CRules@ this)
{	
	QueueObject queues;
	
	if (getRules().exists("bvb_config"))
		bvb_config_file = getRules().get_string("bvb_config");

	ConfigFile cfg = ConfigFile();
	cfg.loadFile(bvb_config_file);

	u8 cfg_min_players = cfg.read_u8("minimum_players_in_team", 1);
	u8 cfg_max_players = cfg.read_u8("maximum_players_in_team", 3);
	u8 cfg_queuelocktime = cfg.read_u16("queue_lock_time", 20);

	queues.timeremaining = cfg_queuelocktime*30;
	queues.min_players = cfg_min_players;
	queues.max_players = cfg_max_players;	

	this.set("team_queues", @queues);	
}

void onInit(CRules@ this)
{
	CBitStream stream;
	stream.write_u16(0xDEAD);
	this.set_CBitStream("queues_serialised", stream);

	this.addCommandID(join_blue_id);
	this.addCommandID(join_red_id);
	this.addCommandID(exit_queues_id);
	this.addCommandID(queue_lock_id);

	Rules_SetJoinQueues(this);
	onRestart(this);
	
	if (!GUI::isFontLoaded("slightly bigger text"))
	{
		string font = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
		GUI::LoadFont("slightly bigger text", font, 36, true);
	}

	if (!GUI::isFontLoaded("big text")) 
	{
		string font = CFileMatcher("AveriaSerif-Regular.ttf").getFirst();
		GUI::LoadFont("big text", font, 60, true);
	}

	RulesCore@ core;
	this.get("core", @core);
	if (core !is null)
	{
		this.set_s32("core.teams.length", core.teams.length);
		this.Sync("core.teams.length", true);
	}
}

void onRestart(CRules@ this)
{
	QueueObject@ queues;
	this.get("team_queues", @queues);

	queues.enough_in_queue = false;
	queues.current_spawned = 0;
	Rules_ResetQueuesTimer(this, queues);
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
	this.SyncToPlayer("queues_serialised", player);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	u16 id = player.getNetworkID();
  	CBitStream params;
	params.write_u16(id);
	this.SendCommand(this.getCommandID(exit_queues_id), params);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (getGameTime() < 60) return; //Bad Delta fix

	QueueObject@ queues;
	if (!this.get("team_queues", @queues)) return;
	
	if (getNet().isServer() && cmd == this.getCommandID(queue_lock_id)) {
		SpawnPlayers(queues);
	}

	u16 id;
	if (!params.saferead_u16(id)) {return;}

	CPlayer@ player = getPlayerByNetworkId(id);
	if (player is null) {return;}

	if (cmd == this.getCommandID(join_blue_id))
	{
		{ JoinQueue(queues, player, 0); }
	}
	else if (cmd == this.getCommandID(join_red_id))
	{
		{ JoinQueue(queues, player, 1); }
	}
	else if (cmd == this.getCommandID(exit_queues_id))
	{
		{ ExitQueues(queues, player); }
	}
}

void SpawnPlayers(QueueObject@ queues)
{
	if (queues is null || queues.timeremaining < 0) return;
	queues.timeremaining = -1;

	RulesCore@ core;
    getRules().get("core", @core);
	if (core is null) return;

	for (uint i = 0; i < queues.current_blue; i++)
	{
		if ( i < queues.current_red+(queues.equalteams?0:1) && i < queues.max_players)
		{
			CPlayer@ player = getPlayerByUsername(queues.BlueQueuePlayers[i]);
			if(player !is null)
			{
				core.ChangePlayerTeam(player, 0 );
				queues.current_spawned++;
			}
		}
	}
	for (uint i = 0; i < queues.current_red; i++)
	{
		if ( i < queues.current_blue+(queues.equalteams?0:1) && i < queues.max_players)
		{
			CPlayer@ player = getPlayerByUsername(queues.RedQueuePlayers[i]);
			if(player !is null)
			{
				queues.current_spawned++;
				core.ChangePlayerTeam(player, 1 );
			}
		}
	}

	{
		int lowestCount;
		if (queues.current_red <= queues.current_blue && queues.current_red < queues.max_players)
		{
			lowestCount = queues.current_red;
		}
		else if (queues.current_blue < queues.max_players)
		{
			lowestCount = queues.current_blue;
		}
		else
		{
			lowestCount = queues.max_players;
		}
		//print("cb "+queues.current_blue);
		//print("cr "+queues.current_red);
		//print("cs "+queues.current_spawned);
		//print("lc "+lowestCount);	

		if (queues.current_spawned == (lowestCount*2)+(!queues.equalteams && (queues.BlueQueuePlayers.size() > queues.RedQueuePlayers.size() || queues.RedQueuePlayers.size() > queues.BlueQueuePlayers.size())?1:0))
		{
			for (uint i = 0; i < lowestCount; i++)
			{	
				CPlayer@ btp = getPlayerByUsername(queues.BlueQueuePlayers[0]);
				if (btp !is null)
				{
					u16 id = btp.getNetworkID();
				  	CBitStream params;
					params.write_u16(id);
					getRules().SendCommand(getRules().getCommandID(exit_queues_id), params);
				}
				CPlayer@ rtp = getPlayerByUsername(queues.RedQueuePlayers[0]);
				if (rtp !is null)
				{
					u16 id2 = rtp.getNetworkID();
				  	CBitStream params2;
					params2.write_u16(id2);
					getRules().SendCommand(getRules().getCommandID(exit_queues_id), params2);
				}
			}

			if (!queues.equalteams)
			{
				if (queues.BlueQueuePlayers.size() > 0)
				{
					CPlayer@ btp = getPlayerByUsername(queues.BlueQueuePlayers[0]);
					if (btp !is null)
					{
						u16 id = btp.getNetworkID();
					  	CBitStream params;
						params.write_u16(id);
						getRules().SendCommand(getRules().getCommandID(exit_queues_id), params);
					}
				}
				else if ( queues.RedQueuePlayers.size() > 0)
				{				
					CPlayer@ rtp = getPlayerByUsername(queues.RedQueuePlayers[0]);
					if (rtp !is null)
					{
						u16 id2 = rtp.getNetworkID();
					  	CBitStream params2;
						params2.write_u16(id2);
						getRules().SendCommand(getRules().getCommandID(exit_queues_id), params2);
					}
				}
			}
	
			getRules().SetCurrentState(WARMUP);
		}
	}
}

void JoinQueue(QueueObject@ queues, CPlayer@ p, int team)
{
	if (queues is null) return; // || queues.timeremaining < 0) return;

	bool joined = false;

	u16 p_id = p.getNetworkID();
	for (uint i = 0; i < queues.players.length; ++i)
	{
		if (queues.players[i] == p_id)
		{
			joined = true;
			break;
		}
	}

	if (joined)
	{
		//warning("double-join from " + p.getUsername()); //warning about exploits
	}
	else
	{
		queues.players.push_back(p_id);
		if (team == 0)
		{
			u16 pos = queues.BlueQueuePlayers.size();
			queues.BlueQueuePlayers.set_length(queues.BlueQueuePlayers.size());
			for (uint i = 0; i < queues.BlueQueuePlayers.size(); i++)
			{
				string pname = queues.BlueQueuePlayers[i];
				string[] tokens = pname.split('~');
				if (tokens[0] == "Henry")
				{
					pos--;
				}
			}
			queues.BlueQueuePlayers.insertAt(pos, p.getUsername());
			queues.current_blue++;
		}
		else if (team == 1)
		{
			u16 pos = queues.RedQueuePlayers.size();
			queues.RedQueuePlayers.set_length(queues.RedQueuePlayers.size());
			for (uint i = 0; i < queues.RedQueuePlayers.size(); i++)
			{
				string pname = queues.RedQueuePlayers[i];
				string[] tokens = pname.split('~');
				if (tokens[0] == "Henry")
				{
					pos--;
				}
			}
			queues.RedQueuePlayers.insertAt(pos, p.getUsername());
			queues.current_red++;
		}
	}
}

void ExitQueues(QueueObject@ queues, CPlayer@ p)
{
	if (queues is null) return; // || queues.timeremaining < 0) return;

	u16 p_id = p.getNetworkID();
	for (uint i = 0; i < queues.players.length; ++i)
	{
		if (queues.players[i] == p_id)
		{
			queues.players.removeAt(i);
			break;
		}
	}
				
	int blueQueueNumber = queues.BlueQueuePlayers.find(p.getUsername());
	int redQueueNumber = queues.RedQueuePlayers.find(p.getUsername());

	if (blueQueueNumber >= 0)
	{
		queues.BlueQueuePlayers.removeAt(blueQueueNumber);
		queues.current_blue--;
	}
	else if (redQueueNumber >= 0)
	{ 
		queues.RedQueuePlayers.removeAt(redQueueNumber);
		queues.current_red--;		
	}

}
