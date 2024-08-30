//bot controller, has control over all the bots

#define SERVER_ONLY
//#include "/EmotesCommon.as"

class BotTeamController
{
	int Team;
	int Side;
	u16[] teamPlayers;
	int AttackingNum;
	f32 CourtHalfSize = 300;

	BotTeamController(int _team) 
	{
		Team = _team;	
		Side = _team == 0 ? -1 : 1;
		AttackingNum = -1;
	}

	u8 getTeamPlayerCount(int teamnum)
	{
		int count;
		for (int i = 0; i < getPlayersCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			s32 team = p.getTeamNum();
			if (team == teamnum)
			{
				count++;
			}
		}
		return count;
	}

	void UpdateTeamPlayers()
	{
		teamPlayers.clear();
		CBlob@[] potentials;
		for (int i = 0; i < getPlayersCount(); i++)
		{
			CPlayer@ player = getPlayer(i);
			if ( player is null || player.getTeamNum() != Team)
			continue;

			CBlob@ pBlob = player.getBlob();

			if (pBlob !is null) //&& player.isBot())
			{
				potentials.push_back(pBlob);				
			}
		}

		CMap@ map = getMap();
		const f32 mapWidth = map.tilemapwidth * map.tilesize;
		const f32 mapMiddleX = mapWidth * 0.5f;

		if (potentials.length > 0)
		{			
			while (potentials.size() > 0)
			{
				f32 closestDist = 999999.9f;
				uint closestIndex = 999;
				CBlob@ closestBlob = null;

				for (uint i = 0; i < potentials.length; i++)
				{
					CBlob@ b = potentials[i];
					f32 bposX = b.getPosition().x;
					f32 distToNet = Maths::Abs(bposX - mapMiddleX);	
					if (distToNet < closestDist)
					{
						closestDist = distToNet;
						closestIndex = i;
						@closestBlob = b;

					}
				} 
				if (closestIndex >= 999) {
					break;
				}  
				teamPlayers.push_back(closestBlob.getNetworkID());
				potentials.erase(closestIndex);
			}
		}
	}

	void UpdatePositions()
	{
		if (teamPlayers.length() == 0) return;

		f32 coverage_dist = CourtHalfSize/teamPlayers.length();	
		CMap@ map = getMap();
		const f32 mapWidth = map.tilemapwidth * map.tilesize;
		const f32 mapMiddleX = mapWidth * 0.5f;

		for (int i = 0; i < teamPlayers.length(); i++)
		{
			CBlob@ b = getBlobByNetworkID(teamPlayers[i]);
			if (b !is null)
			{
				b.set_f32("Coverage_Distance", coverage_dist);

				// sorted placement from net distance
				b.set_f32("Coverage_PosX", mapMiddleX +  (40 + i*coverage_dist)*Side );
			}
		}
	}

	void SetAttacker(Vec2f LandingPos)
	{
		if (teamPlayers.length() == 0) return;

		f32 closestDist = 999999.9f;
		uint closestIndex = 999;

		for (int i = 0; i < teamPlayers.length(); i++)
		{
			CBlob@ b = getBlobByNetworkID(teamPlayers[i]);
			if (b is null) continue;

			f32 cposX = b.get_f32("Coverage_PosX");
			f32 distToBallLanding = Maths::Abs(cposX - LandingPos.x);
			if (distToBallLanding < closestDist)
			{
				closestDist = distToBallLanding;
				closestIndex = i;
			}
		}
		AttackingNum = closestIndex;
		CBlob@ b = getBlobByNetworkID(teamPlayers[closestIndex]);
		if (b !is null)
		{
			b.Tag("My Ball");
			//set_emote( b, Emotes::mine );
		}
	}
	void UnSetAttacker()
	{
		CBlob@ b = getBlobByNetworkID(teamPlayers[AttackingNum]);
		if (b !is null)
		{
			b.Untag("My Ball");
		}
	}
};

BotTeamController@ bc0 = BotTeamController(0);
BotTeamController@ bc1 = BotTeamController(1);

void onTick(CRules@ this)
{		
	if (getGameTime() % 15 == 0)
	{
		bc0.UpdateTeamPlayers();
		bc1.UpdateTeamPlayers();
		bc0.UpdatePositions();
		bc1.UpdatePositions();


		CBlob@ ball = getBlobByName("beachball");
		if (ball !is null)
		{

			if (ball.isAttached())
			{
				bc1.UnSetAttacker();
				bc0.UnSetAttacker();
 				return;
			}

			CMap@ map = getMap();
			const f32 mapWidth = map.tilemapwidth * map.tilesize;
			const f32 mapMiddleX = mapWidth * 0.5f;

			Vec2f LandingPos = ball.get_Vec2f("landing pos");
			bool LandingLeftSide = LandingPos.x < mapMiddleX;

			if ( LandingLeftSide ) //incoming
			{
				bc1.UnSetAttacker();
				bc0.UnSetAttacker();
				bc0.SetAttacker(LandingPos);
			}
			else
			{
				bc1.UnSetAttacker();
				bc0.UnSetAttacker();
				bc1.SetAttacker(LandingPos);
			}
		}		
	}	
}