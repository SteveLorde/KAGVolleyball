
// all players join spec on join and restart/next map

#include "PlayerInfo.as";
#include "BaseTeamInfo.as";
#include "RulesCore.as";

#define SERVER_ONLY

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{    
	RulesCore@ core;
	this.get("core", @core);
	if (core is null) return;
	
	for (int player_step = 0; player_step < getPlayersCount(); ++player_step)
	{
		CPlayer@ player = (getPlayer(player_step));
		if (player !is null)
		{
		//	if (player.isBot())
		//	{
		//		if (getNet().isServer()) { getSecurity().ban(player, 0, "BotKick"); } // kick all bots
		//	}
		//	else if (player.getTeamNum() != this.getSpectatorTeamNum())
			{
				core.ChangePlayerTeam(player, this.getSpectatorTeamNum()); // move all players to spec
			}
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	RulesCore@ core;
    this.get("core", @core);

	if (core is null) { warn("onNewPlayerJoin: CORE NOT FOUND "); return; }	

	core.ChangePlayerTeam(player, this.getSpectatorTeamNum());
}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newTeam)
{
	RulesCore@ core;
	this.get("core", @core);
	if (core is null) return;

	core.ChangePlayerTeam(player, newTeam);
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	RulesCore@ core;
    this.get("core", @core);

	if (core is null) return;
	
	core.ChangePlayerTeam(player, player.getTeamNum() );
}
