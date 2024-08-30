// Simple chat processing example.
// If the player sends a command, the server does what the command says.
// You can also modify the chat message before it is sent to clients by modifying text_out
// By the way, in case you couldn't tell, "mat" stands for "material(s)"

#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as";

#include "RulesCore.as";
#include "BVB_Structs.as";

const bool ChatCommandCoolDown = false; // enable if you want cooldown on your server
const uint ChatCommandDelay = 3 * 30; // Cooldown in seconds

void onInit(CRules@ this)
{
	this.addCommandID("SendChatMessage");
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	//--------MAKING CUSTOM COMMANDS-------//
	// Making commands is easy - Here's a template:
	//
	// if (text_in == "!YourCommand")
	// {
	//	// what the command actually does here
	// }
	//
	// Switch out the "!YourCommand" with
	// your command's name (i.e., !cool)
	//
	// Then decide what you want to have
	// the command do
	//
	// Here are a few bits of code you can put in there
	// to make your command do something:
	//
	// blob.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), 10.0f, 0);
	// Deals 10 damage to the player that used that command (20 hearts)
	//
	// CBlob@ b = server_CreateBlob('mat_wood', -1, pos);
	// insert your blob/the thing you want to spawn at 'mat_wood'
	//
	// player.server_setCoins(player.getCoins() + 100);
	// Adds 100 coins to the player's coins
	//-----------------END-----------------//

	// cannot do commands while dead

	if (player is null)
		return true;

	if (text_in.substr(0, 1) != "!") // dont continue if its not a command
	{
		return true;
	}

	string[]@ tokens = text_in.split(" ");

	const bool isMod = player.isMod();

	if (text_in == "!bot" && isMod)
	{
		AddBot("Henry");
		return true;
	}
	else if (text_in == "!debug" && isMod)
	{
		CBlob@[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob@ blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");
		}
	}
	else if (text_in == "!endgame" && isMod)
	{
		this.SetCurrentState(GAME_OVER); //go to map vote
		return true;
	}
	else if (text_in == "!startgame" && isMod)
	{
		this.SetCurrentState(1);
		return true;
	}	
	else if (tokens.length > 1 && isMod)
	{	
		RulesCore@ core;
		this.get("core", @core);


		if (core is null)
		{
			warn("chatCommands: CORE NOT FOUND ");
			return false;
		}

		//@BVB_core = cast < BVBCore@ > (core);

		if (tokens[0] == "!addpoint" && tokens[1] == "blue" && isMod)
		{
			BVBTeamInfo@ team_info = cast < BVBTeamInfo@ > (core.teams[0]);
			team_info.goals++;
			return false;
		}
		else if (tokens[0] == "!addpoint" && tokens[1] == "red" && isMod)
		{
			BVBTeamInfo@ team_info = cast < BVBTeamInfo@ > (core.teams[1]);
			team_info.goals++;
			return false;
		}
		else if (tokens[0] == "!takepoint" && tokens[1] == "blue" && isMod)
		{
			BVBTeamInfo@ team_info = cast < BVBTeamInfo@ > (core.teams[0]);
			team_info.goals--;
			return false;
		}
		else if (tokens[0] == "!takepoint" && tokens[1] == "red" && isMod)
		{
			BVBTeamInfo@ team_info = cast < BVBTeamInfo@ > (core.teams[1]);
			team_info.goals--;
			return false;
		}

		string user = tokens[1];
		CPlayer@ target_player = null;

		for(int i = 0; i < getPlayerCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			if( // partial match on
				// char name
				p.getCharacterName().toLower().findFirst(user.toLower(), 0) >= 0
				// or username
				|| p.getUsername().toLower().findFirst(user.toLower(), 0) >= 0
			) {
				@target_player = p;
				break;
			}
		}

		if (target_player !is null)
		{
			if (tokens[0] == "!addblue" && isMod)
			{
				core.ChangePlayerTeam(target_player, 0);
			}
			else if (tokens[0] == "!addred" && isMod)
			{
				core.ChangePlayerTeam(target_player, 1);
			}
			else if (tokens[0] == "!addspec" && isMod)
			{
				core.ChangePlayerTeam(target_player, this.getSpectatorTeamNum());
			}
		}
		else
		{
			client_AddToChat("player is null", SColor(255, 255, 0, 0));
		}
		return false;
	}

	CBlob@ blob = player.getBlob(); // now, when the code references "blob," it means the player who called the command

	if (blob is null) // dont continue if its not a command
	{
		return true;
	}

	const Vec2f pos = blob.getPosition(); // grab player position (x, y)
	const int team = blob.getTeamNum(); // grab player team number (for i.e. making all flags you spawn be your team's flags)	
	const string gamemode = this.gamemode_name;
	bool wasCommandSuccessful = true; // assume command is successful 
	string errorMessage = ""; // so errors can be printed out of wasCommandSuccessful is false
	SColor errorColor = SColor(255,255,0,0); // ^

	if (!isMod && gamemode == "Sandbox" || ChatCommandCoolDown) // chat command cooldown timer
	{
		uint lastChatTime = 0;
		uint gameTime = getGameTime();
		if (blob.exists("chat_last_sent"))
		{
			lastChatTime = blob.get_u16("chat_last_sent");
			if (gameTime < lastChatTime)
			{
				return true;
			}
		}
	}

	// spawning things

	// these all require sv_test - no spawning without it
	// some also require the player to have mod status (!spawnwater)

	if (sv_test)
	{
		if (text_in == "!tree") // pine tree (seed)
		{
			server_MakeSeed(pos, "tree_pine", 600, 1, 16);
		}
		else if (tokens[0] == "!admin" && isMod)
				{
					if (blob.getName()!="grandpa")
					{
						player.server_setTeamNum(-1);
						CBlob@ newBlob = server_CreateBlob("grandpa",-1,blob.getPosition());
						newBlob.server_SetPlayer(player);
						blob.server_Die();
					}
					else blob.server_Die();
					return false;
				}
				else if (tokens[0] == "!build" && isMod)
				{
					if (blob.getName()!="builder")
					{
						player.server_setTeamNum(-1);
						CBlob@ newBlob = server_CreateBlob("builder",-1,blob.getPosition());
						newBlob.server_SetPlayer(player);
						blob.server_Die();
					}
					else blob.server_Die();
					return false;
				}
				else if (tokens[0] == "!beach" && isMod)
				{
					if (blob.getName()!="beachvolleyplayer")
					{
						player.server_setTeamNum(-1);
						CBlob@ newBlob = server_CreateBlob("beachvolleyplayer",-1,blob.getPosition());
						newBlob.server_SetPlayer(player);
						blob.server_Die();
					}
					else blob.server_Die();
					return false;
				}
				else if (tokens[0] == "!m" && isMod)
				{
					if (blob.getName()!="princess")
					{
						player.server_setTeamNum(-1);
						CBlob@ newBlob = server_CreateBlob("princess",-1,blob.getPosition());
						newBlob.server_SetPlayer(player);
						blob.server_Die();
					}
					else blob.server_Die();
					return false;
				}
				else if (tokens[0]=="!team")
				{
					if (tokens.length<2) return false;
					int team=parseInt(tokens[1]);
					blob.server_setTeamNum(team);

					player.server_setTeamNum(team); // Finally
				}
		else if (text_in == "!btree") // bushy tree (seed)
		{
			server_MakeSeed(pos, "tree_bushy", 400, 2, 16);
		}
		else if (text_in == "!allarrows") // 30 normal arrows, 2 water arrows, 2 fire arrows, 1 bomb arrow (full inventory for archer)
		{
			server_CreateBlob('mat_arrows', -1, pos);
			server_CreateBlob('mat_waterarrows', -1, pos);
			server_CreateBlob('mat_firearrows', -1, pos);
			server_CreateBlob('mat_bombarrows', -1, pos);
		}
		else if (text_in == "!arrows") // 3 mats of 30 arrows (90 arrows)
		{
			for (int i = 0; i < 3; i++)
			{
				server_CreateBlob('mat_arrows', -1, pos);
			}
		}
		else if (text_in == "!allbombs") // 2 normal bombs, 1 water bomb
		{
			for (int i = 0; i < 2; i++)
			{
				server_CreateBlob('mat_bombs', -1, pos);
			}
			server_CreateBlob('mat_waterbombs', -1, pos);
		}
		else if (text_in == "!bombs") // 3 (unlit) bomb mats
		{
			for (int i = 0; i < 3; i++)
			{
				server_CreateBlob('mat_bombs', -1, pos);
			}
		}
		else if (text_in == "!spawnwater" && player.isMod())
		{
			getMap().server_setFloodWaterWorldspace(pos, true);
		}
		/*else if (text_in == "!drink") // removes 1 water tile roughly at the player's x, y, coordinates (I notice that it favors the bottom left of the player's sprite)
		{
			getMap().server_setFloodWaterWorldspace(pos, false);
		}*/
		else if (text_in == "!seed")
		{
			// crash prevention?
		}
		else if (text_in == "!crate")
		{
			client_AddToChat("usage: !crate BLOBNAME [DESCRIPTION]", SColor(255, 255, 0, 0)); //e.g., !crate shark Your Little Darling
			server_MakeCrate("", "", 0, team, Vec2f(pos.x, pos.y - 30.0f));
		}
		else if (text_in == "!coins") // adds 100 coins to the player's coins
		{
			player.server_setCoins(player.getCoins() + 100);
		}
		else if (text_in == "!coinoverload") // + 10000 coins
		{
			player.server_setCoins(player.getCoins() + 10000);
		}
		else if (text_in == "!fishyschool") // spawns 12 fishies
		{
			for (int i = 0; i < 12; i++)
			{
				server_CreateBlob('fishy', -1, pos);
			}
		}
		else if (text_in == "!chickenflock") // spawns 12 chickens
		{
			for (int i = 0; i < 12; i++)
			{
				server_CreateBlob('chicken', -1, pos);
			}
		}
		else if (text_in == "!allmats") // 500 wood, 500 stone, 100 gold
		{
			//wood
			CBlob@ wood = server_CreateBlob('mat_wood', -1, pos);
			wood.server_SetQuantity(500); // so I don't have to repeat the server_CreateBlob line again
			//stone
			CBlob@ stone = server_CreateBlob('mat_stone', -1, pos);
			stone.server_SetQuantity(500);
			//gold
			CBlob@ gold = server_CreateBlob('mat_gold', -1, pos);
			gold.server_SetQuantity(100);
		}
		else if (text_in == "!woodstone") // 250 wood, 500 stone
		{
			server_CreateBlob('mat_wood', -1, pos);

			for (int i = 0; i < 2; i++)
			{
				server_CreateBlob('mat_stone', -1, pos);
			}
		}
		else if (text_in == "!stonewood") // 500 wood, 250 stone
		{
			server_CreateBlob('mat_stone', -1, pos);

			for (int i = 0; i < 2; i++)
			{
				server_CreateBlob('mat_wood', -1, pos);
			}
		}
		else if (text_in == "!wood") // 250 wood
		{
			server_CreateBlob('mat_wood', -1, pos);
		}
		else if (text_in == "!stones" || text_in == "!stone") // 250 stone
		{
			server_CreateBlob('mat_stone', -1, pos);
		}
		else if (text_in == "!gold") // 200 gold
		{
			for (int i = 0; i < 4; i++)
			{
				server_CreateBlob('mat_gold', -1, pos);
			}
		}
		// removed/commented out since this can easily be abused...
		/*else if (text_in == "!sharkpit") // spawns 5 sharks, perfect for making shark pits
		{
			for (int i = 0; i < 5; i++)
			{
				CBlob@ b = server_CreateBlob('shark', -1, pos);
			}
		}
		else if (text_in == "!bisonherd") // spawns 5 bisons
		{
			for (int i = 0; i < 5; i++)
			{
				CBlob@ b = server_CreateBlob('bison', -1, pos);
			}
		}*/
		else
		{
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				//(see above for crate parsing example)
				if (tokens[0] == "!crate")
				{
					int frame = tokens[1] == "catapult" ? 1 : 0;
					string description = tokens.length > 2 ? tokens[2] : tokens[1];
					server_MakeCrate(tokens[1], description, frame, -1, Vec2f(pos.x, pos.y));
				}
				// eg. !team 2
				else if (tokens[0] == "!team")
				{
					// Picks team color from the TeamPalette.png (0 is blue, 1 is red, and so forth - if it runs out of colors, it uses the grey "neutral" color)
					int team = parseInt(tokens[1]);
					blob.server_setTeamNum(team);
					// We should consider if this should change the player team as well, or not.
				}
				else if (tokens[0] == "!scroll")
				{
					string s = tokens[1];
					for (uint i = 2; i < tokens.length; i++)
					{
						s += " " + tokens[i];
					}
					server_MakePredefinedScroll(pos, s);
				}
				else if(tokens[0] == "!coins")
				{
					int money = parseInt(tokens[1]);
					player.server_setCoins(money);
				}
			}
			else
			{
				string name = text_in.substr(1, text_in.size());
				if (!isMod && IsBlacklisted(name))
				{
					wasCommandSuccessful = false;
					errorMessage = "blob is currently blacklisted";
				}
				else
				{
					CBlob@ newBlob = server_CreateBlob(name, team, pos); // currently any blob made will come back with a valid pointer

					if (newBlob !is null)
					{
						if (newBlob.getName() != name)  // invalid blobs will have 'broken' names
						{
							wasCommandSuccessful = false;
							errorMessage = "blob " + text_in + " not found";
						}
					}
				}
			}
		}
	}

	if (wasCommandSuccessful)
	{
		blob.set_u16("chat_last_sent", getGameTime() + ChatCommandDelay);
	}
	else if(errorMessage != "") // send error message to client
	{
		CBitStream params;
		params.write_string(errorMessage);

		// List is reverse so we can read it correctly into SColor when reading
		params.write_u8(errorColor.getBlue());
		params.write_u8(errorColor.getGreen());
		params.write_u8(errorColor.getRed());
		params.write_u8(errorColor.getAlpha());

		this.SendCommand(this.getCommandID("SendChatMessage"), params, player);
	}

	return true;
}

bool onClientProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (text_in == "!debug" && !getNet().isServer())
	{
		// print all blobs
		CBlob@[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob@ blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");

			if (blob.getShape() !is null)
			{
				CBlob@[] overlapping;
				if (blob.getOverlapping(@overlapping))
				{
					for (uint i = 0; i < overlapping.length; i++)
					{
						CBlob@ overlap = overlapping[i];
						print("       " + overlap.getName() + " " + overlap.isLadder());
					}
				}
			}
		}
	}

	return true;
}


void onCommand(CRules@ this, u8 cmd, CBitStream @para)
{
	if (cmd == this.getCommandID("SendChatMessage"))
	{
		string errorMessage = para.read_string();
		SColor col = SColor(para.read_u8(), para.read_u8(), para.read_u8(), para.read_u8());
		client_AddToChat(errorMessage, col);
	}
}

bool IsBlacklisted(string name)
{
	return  name=="hall" || // used to dig hole to bottom of the map, spawns lots of migrants
			name=="shark" || // greif
			name=="bison" ||
			name=="necromancer" || // annoying / grief
			name=="greg" || // annoying / grief
			name=="ctf_flag" || // sound spam
			name=="flag_base";// sound spam / grief
}