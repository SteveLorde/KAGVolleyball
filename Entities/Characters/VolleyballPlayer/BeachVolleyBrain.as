// big brain
#define SERVER_ONLY
#include "BeachVolleyPlayerCommon.as";

void onInit(CBrain@ this)
{
	CBlob @blob = this.getBlob();
	blob.set_u8("strategy", Strategy::idle);

	this.getCurrentScript().removeIfTag = "dead"; //won't be removed if not bot cause it isnt run

	if (!blob.exists("difficulty"))
	{
		blob.set_u8("difficulty", 5);
	}
}

namespace Strategy
{
	enum strategy_type
	{
		idle = 0,
		postioning,
		serving,
		attacking,
		taunting
	}
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f mypos = blob.getPosition();
	const u8 team = blob.getTeamNum();
	const int side = team == 0 ? -1 : 1;

	CMap@ map = getMap();
	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	const f32 netTopPosY = (map.tilemapheight * map.tilesize) - 48;
	const f32 mapMiddle = mapWidth * 0.5f;	

	f32 WantedPositionX = blob.get_f32("Coverage_PosX");
	const s32 difficulty = blob.get_u8("difficulty");
	u8 strategy = blob.get_u8("strategy");
	f32 Coverage_Distance = blob.get_f32("Coverage_Distance");	
	Vec2f LandingPos = Vec2f(mapMiddle, 0);

	CBlob@ ball = getBlobByName("beachball");
	Vec2f BallPos = Vec2f(mapMiddle, netTopPosY);
	f32 BallDist = 999999.0f;

	if (ball !is null)
	{
		BallPos = ball.getPosition();
		Vec2f BallVel = ball.getVelocity();
		Vec2f BallVector = (BallPos+Vec2f(0,BallVel.y)) - mypos;
		BallDist = BallVector.Length();

		LandingPos = ball.get_Vec2f("landing pos");

		bool LandingLeftSide = LandingPos.x < mapMiddle;
		
		if (ball.isAttachedTo(blob))
		{
			strategy = Strategy::serving;
		}
		else if (blob.hasTag("My Ball")) //incoming
		{
			//if (!isFriendAheadOfMe(blob, ball))
			strategy = Strategy::attacking; // charging
		}
		else
		{
			strategy = Strategy::postioning;
		}

		blob.set_u8("strategy", strategy);
	}	
	else
	{
		strategy = Strategy::postioning;
	}

	//if (strategy == Strategy::idle)
	//{
	//	blob.setAimPos( BallPos );
	//	blob.setKeyPressed(key_down, XORRandom(20) == 0);
	//	//WantedPositionX = LandingPos.x + (team == 0 ? -2-XORRandom(8) : 2+XORRandom(8));
	//}
	//else 
	if (strategy == Strategy::postioning || strategy == Strategy::idle)
	{
		//blob.set_f32("WantedXpos", checkPositions(blob, mypos, team, side, Coverage_Distance, Vec2f(mapMiddle, 0)));		
		WantedPositionX = blob.get_f32("Coverage_PosX");

		blob.setAimPos( BallPos );

		if (WantedPositionX > mypos.x+4 )
		{
			blob.setKeyPressed(key_right, true);
		}
		else if (WantedPositionX < mypos.x-4 )
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_left, false);
			blob.setKeyPressed(key_right, false);
		}
	}
	else if (strategy == Strategy::attacking) //take a swing
	{	
		if (ball is null) return;

		WantedPositionX = LandingPos.x + (side*4);

		if (getGameTime() % 10 == 0)
		blob.setAimPos( mypos + Vec2f(team == 0 ? 10+XORRandom(50) : -10-XORRandom(50) , -70) );

		blob.set_f32("WantedXpos", LandingPos.x);

		f32 ETA;
		DoCalculations(blob, ball, LandingPos, ETA);				

		if (ball.getVelocity().y > 0) //&& ETA < 5)
		{
			if (ETA < 2.5 && Maths::Abs(LandingPos.x-mypos.x) > 16)
			{
				blob.setAimPos( BallPos );
				blob.setKeyPressed(key_action2, true);
				blob.setKeyPressed(key_up, false);			
			}
			else if (ETA < 2.0)
			{
				blob.setAimPos( BallPos );
				blob.setKeyPressed(key_action2, false);
				blob.setKeyPressed(key_up, false);
				strategy = Strategy::idle;
			}	

			blob.setKeyPressed(key_action1, true);
		}
		
		if (WantedPositionX > mypos.x+4 )
		{
			blob.setKeyPressed(key_right, true);
		}
		else if (WantedPositionX < mypos.x-4 )
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_left, false);
			blob.setKeyPressed(key_right, false);
		}				

		if (BallDist < 28.0f) //release
		{	
			blob.setKeyPressed(key_action1, false);
			blob.setKeyPressed(key_up, false);
			strategy = Strategy::idle;
		}
		else if (BallDist < 64.0f && (LandingPos-mypos).Length() < 24 && (BallPos.y < mypos.y-12.0f) && Maths::Abs(BallPos.x - mypos.x) < 8.0f)
		{
			if (BallPos.x > mypos.x )
			{
				blob.setKeyPressed(key_right, true);
			}
			else if (BallPos.x < mypos.x )
			{
				blob.setKeyPressed(key_left, true);
			}
			else
			{
				blob.setKeyPressed(key_left, false);
				blob.setKeyPressed(key_right, false);
			}
			blob.setKeyPressed(key_up, true);
		}
	}
	else if (strategy == Strategy::serving)
	{
		int side = blob.getTeamNum() == 0 ? -1 : 1;
		f32 servePosX = mapMiddle + (308*side);
		Vec2f vel = blob.getVelocity();

		if (Maths::Abs(mypos.x-servePosX) < 6 )
		{
			//blob.setKeyPressed(key_left, false);
			//blob.setKeyPressed(key_right, false);

			blob.setAimPos( mypos + Vec2f(side * -10, -100) );

			if (blob.getTeamNum() == 0)
			blob.setKeyPressed(key_right, true);
			else
			blob.setKeyPressed(key_left, true);

			if (blob.getTeamNum() == 0 ? vel.x > 0.4 : vel.x < -0.4)
			{
				blob.setKeyPressed(key_up, true); //jump serve
				if (vel.y < -1.8)
				{
					bot_SendThrowCommand(blob);
					blob.setKeyPressed(key_up, false);
				}
			}

			
		}		
		else if (mypos.x < servePosX+8 )
		{
			blob.setAimPos( mypos + Vec2f(side * 10, 0) );
			blob.setKeyPressed(key_right, true);
		}
		else if (mypos.x > servePosX+8 )
		{
			blob.setAimPos( mypos + Vec2f(side * 10, 0) );
			blob.setKeyPressed(key_left, true);
		}
	}
}

void DoCalculations(CBlob@ blob, CBlob@ ball, Vec2f LandingPos, f32 &out ETA)
{
	Vec2f mypos = blob.getPosition();
	Vec2f BallPos = ball.getPosition();
	Vec2f BallVel = ball.getVelocity();
	Vec2f BallVector = BallPos - mypos;
	f32 ballDistance = BallVector.Length();
	const s32 difficulty = blob.get_u8("difficulty");

	BallPlayerInfo@ BallPlayer;
	if (!blob.get("BallPlayerInfo", @BallPlayer))
	{
		return;
	}

	Vec2f HitVec(1,0);

	HitVec = HitVec*BallPlayer.smackTimer;
	f32 angle = BallVector.Angle();
	HitVec.RotateBy(-angle);

	Vec2f thinghy(-1, 0);
	const f32 minHitAmount = 1.5f;

	Vec2f velocity = thinghy*(minHitAmount+(BallPlayer.chargeAmount*0.2f));

	Vec2f bvel = ball.getOldVelocity();
	bvel.y = (bvel.y/2);
				
	Vec2f hitVelocity = bvel/2+(velocity+blob.getVelocity()/2);

	blob.set_Vec2f("HitVec",HitVec);

	ETA = ((BallPos - LandingPos).Length()/1.0+BallVel.Length())/30;
	blob.set_f32("eta",ETA);

}

//void onRender(CSprite@ this)
//{
//	CBlob@ blob = this.getBlob();
//	Vec2f HitVec = blob.get_Vec2f("HitVec");	
//	f32 WantedPositionX = blob.get_f32("Coverage_PosX");
//
//	CMap@ map = getMap();
//	const f32 mapWidth = map.tilemapwidth * map.tilesize;
//	const f32 mapMiddle = mapWidth * 0.5f;
//
//	GUI::DrawLine(blob.getPosition(), blob.getAimPos(), SColor(255,0,255,255));	 
//
//	//if (blob.get_u8("strategy") == Strategy::attacking)
//	GUI::DrawLine(blob.getPosition(), Vec2f(WantedPositionX, blob.getPosition().y+(blob.getTeamNum()*3)), blob.getTeamNum() == 0 ? SColor(255,255,0,0) : SColor(255,0,0,255));	  
//}

void bot_SendThrowCommand(CBlob@ this)
{
	CBlob @carried = this.getCarriedBlob();
	if (carried !is null)
	{
		CBitStream params;
		params.write_Vec2f(this.getPosition());
		params.write_Vec2f(this.getAimPos() - this.getPosition());
		params.write_Vec2f(this.getVelocity());
		this.SendCommand(this.getCommandID("throw"), params);
	}
}