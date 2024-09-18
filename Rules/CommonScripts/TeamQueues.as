
#include "TeamQueuesCommon.as"

const Vec2f dim(384, 272);
const Vec2f buttondim(192, 32);
const Vec2f openclosebuttondim(24, 24);

Vec2f getTopLeft() { return Vec2f( 60, 56); }

Vec2f getOpenCloseButtonTopLeft( )
{
	Vec2f tl = getTopLeft();

	return tl + Vec2f(0, -32);
}

Vec2f getBlueButtonTopLeft()
{
	Vec2f tl = getTopLeft();
	Vec2f br = tl + dim;
	return br + Vec2f(-dim.x, 10);
}

Vec2f getRedButtonTopLeft()
{
	Vec2f tl = getTopLeft();
	Vec2f br = tl + dim;
	return br + Vec2f(-dim.x+(dim.x/2), 10);
}

bool mouse_over_menuopen;
bool g_queues_menuopen = false;

bool mouse_over_blue;
bool mouse_over_red;

const SColor grey_colour(SColor(0xcee8e8e8));
const SColor blue_colour(SColor(0xff00ccff));
const SColor red_colour(SColor(0xffff0000));

void onTick(CRules@ this)
{

	QueueObject@ queues;
	if (!this.get("team_queues", @queues)) return;
	
	if (getNet().isServer())
	{
		CBitStream stream;
		stream.write_u16(0x54f3);
		queues.Serialise(stream);
		this.set_CBitStream("queues_serialised", stream);
		this.Sync("queues_serialised", true);

		if (this.isIntermission())
		{
			if (queues.timeremaining != -1 )
			{
				//bots add themselves
				for (u32 i = 0; i < getPlayersCount(); i++)
				{
					CPlayer@ p = getPlayer(i);
					if (p !is null && p.isBot() && p.getTeamNum() == this.getSpectatorTeamNum())
					{
						u16 id = p.getNetworkID();
				        CBitStream params;
						params.write_u16(id);

						if(i % 2 == 0)
						{
							//if (queues.BlueQueuePlayers.size() > queues.max_players)
							//this.SendCommand(this.getCommandID(exit_queues_id), params);
							//else 
							if (queues.BlueQueuePlayers.size() < queues.max_players)
							this.SendCommand(this.getCommandID(join_blue_id), params);
						}
						else
						{
							//if (queues.RedQueuePlayers.size() > queues.max_players)
							//this.SendCommand(this.getCommandID(exit_queues_id), params);
							//else 
							if (queues.RedQueuePlayers.size() < queues.max_players)
							this.SendCommand(this.getCommandID(join_red_id), params);
						}
					}
				}

				string timeRemainingString = formatInt(queues.timeremaining, "d");
				print("variable timeremaining = " + timeRemainingString);

				if (queues.current_blue >= queues.min_players && queues.current_red >= queues.min_players)
				{
					if (queues.timeremaining > 0) {
						queues.enough_in_queue = true;
						queues.timeremaining--;
					}
					else {
						 queues.timeremaining = 0;
					}
				}
				else
				{
					print("CALLING RESETTING TIMER");
					queues.enough_in_queue = false;
					Rules_ResetQueuesTimer(this, queues);
				}

				if (queues.timeremaining == 0)	//time up
				{
					print("TIME IS 0, SENDING COMMADN TO LOCK QUEUE");
					SpawnPlayers(queues);
					// this.SendCommand(this.getCommandID(queue_lock_id), CBitStream());
				}
			}	

			if (!queues.enough_in_queue)
			{
				this.SetGlobalMessage("Not enough players in queues.\n\nPlease wait for someone to join...");				
			}
			else if (queues.current_blue >= queues.min_players && queues.current_red >= queues.min_players)
			{
				this.SetGlobalMessage(("Locking Queues In {TIMELEFT} Seconds").replace("{TIMELEFT}", "" + Maths::Ceil(queues.timeremaining / 30.0f)));
			}
		}
	}

	//--------------------------------- CLIENT ---------------------------------
	CPlayer@ me = getLocalPlayer();
	if (me is null) return;
	
	if (me.getTeamNum() != this.getSpectatorTeamNum()) return;

	if (!getNet().isClient()) return;
	
	CControls@ controls = getControls();
	if (controls is null) return;	
	
	bool joined = false; 

	Vec2f tl = getTopLeft();
	Vec2f br = tl + dim+Vec2f(-4,12);
	Vec2f mousepos = controls.getMouseScreenPos();

	Vec2f BluebuttonUL, BluebuttonLR, RedbuttonUL, RedbuttonLR, MenubuttonUL, MenubuttonLR;

	BluebuttonUL = getBlueButtonTopLeft();
	BluebuttonLR = BluebuttonUL + buttondim;
	RedbuttonUL =  getRedButtonTopLeft();
	RedbuttonLR =  RedbuttonUL + buttondim;

	MenubuttonUL =  getOpenCloseButtonTopLeft();
	MenubuttonLR =  MenubuttonUL + openclosebuttondim;

	mouse_over_menuopen = (mousepos.x > MenubuttonUL.x && mousepos.x < MenubuttonLR.x && mousepos.y > MenubuttonUL.y && mousepos.y < MenubuttonLR.y);

	mouse_over_blue = (mousepos.x > BluebuttonUL.x && mousepos.x < BluebuttonLR.x && mousepos.y > BluebuttonUL.y && mousepos.y < BluebuttonLR.y);
	mouse_over_red = (mousepos.x > RedbuttonUL.x && mousepos.x < RedbuttonLR.x && mousepos.y > RedbuttonUL.y && mousepos.y < RedbuttonLR.y);
	const bool keyAction1 = (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ACTION1)));
	const bool keyAction2 = (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ACTION2)));

	int blueQueueNumber = queues.BlueQueuePlayers.find(me.getUsername());
	int redQueueNumber = queues.RedQueuePlayers.find(me.getUsername());

	if (mouse_over_blue && queues.current_blue < 10)
	{		
		if (keyAction1)
		{				
			if (redQueueNumber >= 0)
			{
				u16 id = me.getNetworkID();
	          	CBitStream params;
				params.write_u16(id);
				this.SendCommand(this.getCommandID(exit_queues_id), params);
			}
			if (blueQueueNumber == -1)
			{
	          	u16 id = me.getNetworkID();
	          	CBitStream params;
				params.write_u16(id);
				this.SendCommand(this.getCommandID(join_blue_id), params);
			}
			else if (blueQueueNumber >= 0)
			{
				u16 id = me.getNetworkID();
	          	CBitStream params;
				params.write_u16(id);
				this.SendCommand(this.getCommandID(exit_queues_id), params);
			}	          
		}	
		//if (sv_test && keyAction2)
		//{	        			
		//	//CPlayer@ bot = AddBot("Henry");
		//	//u16 id = bot.getNetworkID();
        //  	//CBitStream params;
		//	//params.write_u16(id);
		//	//this.SendCommand(this.getCommandID(join_blue_id), params);  

		//	for (int i = 0; i < 2; i++)
		//	{
		//	    CBitStream params;
		//		CPlayer@ bot = AddBot("Henry");
		//		u16 id = bot.getNetworkID();
		//		params.write_u16(id);
		//		this.SendCommand(this.getCommandID(join_blue_id), params);
		//	}
		//	for (int i = 0; i < 2; i++)
		//	{
		//	    CBitStream params;
		//		CPlayer@ bot = AddBot("joe");
		//		u16 id = bot.getNetworkID();
		//		params.write_u16(id);
		//		this.SendCommand(this.getCommandID(join_red_id), params); 
		//	}  
		//}	
	}
	if (mouse_over_red && queues.current_red < 10)
	{
		if (keyAction1)
		{	
			if (blueQueueNumber >= 0)
			{
				u16 id = me.getNetworkID();
	          	CBitStream params;
				params.write_u16(id);
				this.SendCommand(this.getCommandID(exit_queues_id), params);
			}
			if (redQueueNumber == -1)
			{
	          	u16 id = me.getNetworkID();
	          	CBitStream params;
				params.write_u16(id);
				this.SendCommand(this.getCommandID(join_red_id), params);
			}
			else if (redQueueNumber >= 0)
			{
				u16 id = me.getNetworkID();
	          	CBitStream params;
				params.write_u16(id);
				this.SendCommand(this.getCommandID(exit_queues_id), params);
			}	          
		}	
		//if (sv_test && keyAction2)
		//{	  
		//	CPlayer@ bot = AddBot("Joe");			
		//	u16 id = bot.getNetworkID();
        //  	CBitStream params;
		//	params.write_u16(id);
		//	this.SendCommand(this.getCommandID(join_red_id), params);  
		//}		
	}

	if (mouse_over_menuopen && keyAction1)
	{	
		g_queues_menuopen = !g_queues_menuopen;
	}
	
}

void onRender(CRules@ this)
{
	//hud from rules bitstream
	CBitStream stream;
	this.get_CBitStream("queues_serialised", stream);

	u16 checkbits;
	if (stream.getBitsUsed() > 0 && stream.saferead_u16(checkbits) && checkbits == 0x54f3)
	{
		QueueObject queues(stream);

		if (!getNet().isClient()) return;
		CPlayer@ me = getLocalPlayer();
		if (me is null) return;		
		if (me.getTeamNum() != this.getSpectatorTeamNum()) return;

		if (getRules().exists("bvb_config"))
		bvb_config_file = getRules().get_string("bvb_config");

		ConfigFile cfg = ConfigFile();
		cfg.loadFile(bvb_config_file);

		GUI::DrawPane( getOpenCloseButtonTopLeft() , getOpenCloseButtonTopLeft() + openclosebuttondim, (mouse_over_menuopen) ? SColor(0xCCCCffff) : grey_colour );
		
		string menustate = (g_queues_menuopen ? "Close" : "Open");
		GUI::DrawText(getTranslatedString("{STATE} Queues").replace("{STATE}", menustate), getOpenCloseButtonTopLeft() + Vec2f(openclosebuttondim.x+6, 4), color_white);		

		Vec2f tl = getTopLeft();
		Vec2f br = tl + dim;
		Vec2f text_dim;
		GUI::GetTextDimensions("Team Queues", text_dim);

		br += Vec2f(0, text_dim.y);

		GUI::SetFont("menu");

		// blue header
		GUI::DrawPane( tl, tl + Vec2f(dim.x/2+1, 34), grey_colour );
		GUI::DrawTextCentered(getTranslatedString("BLUE QUEUE"), tl + Vec2f((dim.x/4), 16), blue_colour);

		// red header
		GUI::DrawPane( tl + Vec2f(dim.x/2-1, 0)	, tl + Vec2f((dim.x/2)*2, 34), grey_colour );
		GUI::DrawTextCentered(getTranslatedString("RED QUEUE"), tl + Vec2f((dim.x/4)+(dim.x/2), 16), red_colour);

		// blue and red lists
		GUI::DrawPane( tl + Vec2f(0, 32),Vec2f(tl.x+dim.x/2+1,br.y), grey_colour );
		GUI::DrawPane( tl + Vec2f(dim.x/2-1, 32), br, grey_colour );	

		// blue and red button postions
		Vec2f BluebuttonUL = getBlueButtonTopLeft();
		Vec2f RedbuttonUL =  getRedButtonTopLeft();

		for (uint i = 0; i < queues.BlueQueuePlayers.length; i++)
		{
			if (i >= queues.max_players || i >= queues.RedQueuePlayers.length+(queues.equalteams?0:1)) // draw gray
			{
				GUI::DrawTextCentered(queues.BlueQueuePlayers[i], tl+Vec2f((dim.x/4), 48+(24*i)), grey_colour);
			}
			else // draw blue
			{
				GUI::DrawTextCentered(queues.BlueQueuePlayers[i], tl+Vec2f((dim.x/4), 48+(24*i)), blue_colour);
		
			}		
		}
		for (uint i = 0; i < queues.RedQueuePlayers.length; i++)
		{
			if (i >= queues.max_players || i >= queues.BlueQueuePlayers.length+(queues.equalteams?0:1)) // draw gray
			{
				GUI::DrawTextCentered(queues.RedQueuePlayers[i], tl+Vec2f((dim.x/4)+(dim.x/2), 48+(24*i)), grey_colour);
			}
			else //draw red
			{
				GUI::DrawTextCentered(queues.RedQueuePlayers[i], tl+Vec2f((dim.x/4)+(dim.x/2), 48+(24*i)), red_colour);
			}
		}

		if (queues.timeremaining == -1 )
		{
			GUI::DrawTextCentered(getTranslatedString("Match is Live"), br + Vec2f(-dim.x/2, 28 + text_dim.y), SColor(0xccff00ff));
		}

		//red blue join buttons
		(mouse_over_blue) ? GUI::DrawPane( BluebuttonUL, BluebuttonUL+buttondim+Vec2f(1,0), SColor(0xCCCCffff)) : GUI::DrawPane( BluebuttonUL, BluebuttonUL+buttondim+Vec2f(1,0), grey_colour);
		(mouse_over_red)  ? GUI::DrawPane( RedbuttonUL+Vec2f(-1,0),  RedbuttonUL +buttondim, SColor(0xCCffCCCC)) : GUI::DrawPane( RedbuttonUL+Vec2f(-1,0),  RedbuttonUL +buttondim, grey_colour);

		int blueQueueNumber = queues.BlueQueuePlayers.find(me.getUsername());
		int redQueueNumber = queues.RedQueuePlayers.find(me.getUsername());

		if (blueQueueNumber >= 0)
		{GUI::DrawTextCentered(getTranslatedString("Exit Blue Queue"), BluebuttonUL + Vec2f((buttondim.x/2),(buttondim.y/2)), blue_colour);}
		else 
		{GUI::DrawTextCentered(getTranslatedString("Join Blue Queue"), BluebuttonUL + Vec2f((buttondim.x/2),(buttondim.y/2)), blue_colour);}
		
		if (redQueueNumber >= 0)
		{GUI::DrawTextCentered(getTranslatedString("Exit Red Queue"), RedbuttonUL + Vec2f((buttondim.x/2),(buttondim.y/2)), red_colour);}
		else 
		{GUI::DrawTextCentered(getTranslatedString("Join Red Queue"), RedbuttonUL + Vec2f((buttondim.x/2),(buttondim.y/2)), red_colour);}

		//drawing cfg/queue info
		Vec2f info_tl = tl + Vec2f(0, dim.y+buttondim.y+16);
		GUI::DrawPane( info_tl , info_tl + Vec2f(dim.x, 128), grey_colour );


		GUI::DrawText(getTranslatedString("Max Players Per Team")+" = "+ cfg.read_u16("maximum_players_in_team", 1), info_tl+Vec2f(8, 16), color_white);
		GUI::DrawText(getTranslatedString("Min Players Per Team")+" = "+ cfg.read_u16("minimum_players_in_team", 1), info_tl+Vec2f(8, 32), color_white);

		GUI::DrawText(getTranslatedString("Goals To Win")+" = "+ cfg.read_u16("goals_to_win", 7), info_tl+Vec2f(8, 48), color_white);
		GUI::DrawText(getTranslatedString("Match Length")+" = "+ (cfg.read_u16("game_time", -1) > 6000 ? "∞": ""+cfg.read_u16("game_time", -1)+" Mins"), info_tl+Vec2f(8, 64), color_white);
		GUI::DrawText(getTranslatedString("Equal Teams")+" = "+ queues.equalteams, info_tl+Vec2f(8, 80), color_white);
		//GUI::DrawText(getTranslatedString("Max Hits Per Player")+" = "+ (cfg.read_u16("max_hits_per_player", 3) > 6000 ? "∞": ""+cfg.read_u16("max_hits_per_player", 3)), info_tl+Vec2f(8, 48), color_white);

		//GUI::DrawText(getTranslatedString("Team Sides Barrier ")+" = true", info_tl+Vec2f(8, 96), color_white);

	}
};
