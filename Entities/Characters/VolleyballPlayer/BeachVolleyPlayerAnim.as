
#include "BeachVolleyPlayerCommon.as"
//#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "Knocked.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"

void onInit(CSprite@ this)
{
	addRunnerTextures(this, "beachvolleyplayer", "BeachVolleyPlayer");

	LoadSprites(this);
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{
	ensureCorrectRunnerTexture(this, "beachvolleyplayer", "BeachVolleyPlayer");
}

void setAimValues(CSpriteLayer@ arm, f32 angle, Vec2f around)
{
	if (arm !is null)
	{
		arm.ResetTransform();
		arm.RotateBy(angle, around);
	}
}


void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f aimpos;

	BallPlayerInfo@ BallPlayer;
	if (!blob.get("BallPlayerInfo", @BallPlayer))
	{
		return;
	}

	const u8 knocked = getKnocked(blob);

	//bool Attacking = inMiddleOfAttack(BallPlayer.state);
	bool isJab = (BallPlayer.chargeAmount <= 15);

	bool pressed_a1 = blob.isKeyPressed(key_action1);
	bool pressed_a2 = blob.isKeyPressed(key_action2);

	bool walking = (blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right));

	aimpos = blob.getAimPos();
	bool inair = (!blob.isOnGround() && !blob.isOnLadder());

	Vec2f vel = blob.getVelocity();

	u16 taunttimer = blob.get_u16("taunt timer");
	if (getGameTime() % 6 == 0 && taunttimer > 0)
		{taunttimer--; blob.set_u16("taunt timer", taunttimer);}

	if (blob.hasTag("dead"))
	{
		if (this.animation.name != "dead")
		{
			this.SetAnimation("dead");
		}
		Vec2f oldvel = blob.getOldVelocity();

		//TODO: trigger frame one the first time we server_Die()()
		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(1);
		}
		else if (vel.y > 1.0f)
		{
			this.SetFrameIndex(1);
		}
		else
		{
			this.SetFrameIndex(0);
		}

		return;
	}

	// get the angle of aiming with mouse
	Vec2f vec;
	int direction = blob.getAimDirection(vec);
	// set facing
	bool facingLeft = this.isFacingLeft();
	// animations
	bool ended = this.isAnimationEnded();

	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	const bool up = blob.isKeyPressed(key_up);
	const bool down = blob.isKeyPressed(key_down);
	//bool shinydot = false;
	Vec2f aimvec = BallPlayer.smack_direction;
	f32 angle = -aimvec.Angle();
	Vec2f headaimvec = (aimpos - pos);
	f32 headangle = -headaimvec.Angle(); 
	
	if 	(facingLeft) 		 		{ angle = 180.0f + angle; 	headangle = 180.0f + headangle; }
	while (headangle > 180.0f)   	{ angle -= 360.0f; 			headangle -= 360.0f;}
	while (headangle < -180.0f)  	{ angle += 360.0f; 			headangle += 360.0f;}

	headangle = Maths::Min(30,Maths::Max(-30,headangle));

	//Head angle
	setAimValues(this.getSpriteLayer("head"), headangle, Vec2f(0, 4) );

	if (knocked > 0)
	{
		this.SetAnimation("knocked");		
	}
	else if (blob.hasTag("seated"))
	{
		this.SetAnimation("crouch");
	}
	else if (BallPlayer.state == BallPlayerStates::smack_drawn)
	{
		if (BallPlayer.smackTimer > BallPlayerVars::smack_charge)
		{
			this.SetAnimation("power_readying");
			if (BallPlayer.smackTimer < BallPlayerVars::smack_charge_level2-4)
			{
				if 		(aimvec.y < -0.97) 	{ this.animation.SetFrameIndex(0); }
				else if (aimvec.y < -0.25)	{ this.animation.SetFrameIndex(1); }
				else if (aimvec.y < 0.25) 	{ this.animation.SetFrameIndex(2); }	
				else if (aimvec.y < 0.75) 	{ this.animation.SetFrameIndex(3); }
				else 						{ this.animation.SetFrameIndex(4); }		
			}			
			else if (BallPlayer.smackTimer >= BallPlayerVars::smack_charge_level2-4)
			{
				if 		(aimvec.y < -0.97) 	{ this.animation.SetFrameIndex(5); }
				else if (aimvec.y < -0.25) 	{ this.animation.SetFrameIndex(6); }
				else if (aimvec.y < 0.25) 	{ this.animation.SetFrameIndex(7); }	
				else if (aimvec.y < 0.75) 	{ this.animation.SetFrameIndex(8); }
				else 						{ this.animation.SetFrameIndex(9); }		
			}
		}
		else
		{ this.SetAnimation("readying"); }
	}
	else if (BallPlayer.state == BallPlayerStates::smack_ing || BallPlayer.state == BallPlayerStates::smack_coolingdown) 		
	{ 
		string type = isJab ? "jab" : "strike" ;

		if 		(aimvec.y < -0.97) 	{ this.SetAnimation(type+"_up"); 		}
		else if (aimvec.y < -0.25)	{ this.SetAnimation(type+"_mid_up"); 	}
		else if (aimvec.y < 0.25) 	{ this.SetAnimation(type+"_mid"); 		}	
		else if (aimvec.y < 0.75) 	{ this.SetAnimation(type+"_mid_down"); 	}
		else 						{ this.SetAnimation(type+"_down"); 		}
	}	
	else if (BallPlayer.state == BallPlayerStates::dive_ing || BallPlayer.state == BallPlayerStates::dive_coolingdown) 		
	{ 
		this.SetAnimation("dive");
	}

	else if (inair)
	{
		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars))
		{
			return;
		}
		f32 vy = vel.y;
		if (vy < -0.0f && moveVars.walljumped)
		{
			this.SetAnimation("run");
		}
		else
		{
			this.SetAnimation("fall");
			this.animation.timer = 0;

			if (vy < -1.5)
			{
				this.animation.frame = 0;
			}
			else if (vy > 1.5)
			{
				this.animation.frame = 2;
			}
			else
			{
				this.animation.frame = 1;
			}
		}
	}
	else if (walking ||
	         (blob.isOnLadder() && (blob.isKeyPressed(key_up) || blob.isKeyPressed(key_down))))
	{
		this.SetAnimation("run");
	}
	else
	{
		if (blob.isKeyPressed(key_down))
		{
			this.SetAnimation("crouch");
		}
		else if (blob.isKeyJustPressed(key_taunts)) //#include "EmotesCommon.as";
		{			
			if (taunttimer == 0)
			{
				this.SetAnimation("taunt1");
				int facedir = (facingLeft ? -1 : 1);

				if (blob.getSexNum() == 0) //male
				{
					switch (XORRandom(2))
					{
						//case 0: this.PlaySound("EvilNotice.ogg"); break;
						case 0: this.PlaySound("MigrantSayHello.ogg"); break;
						case 1: this.PlaySound("MigrantHmm.ogg"); break;
					}				
				}
				else // female
				{
					this.PlaySound("Kiss.ogg");
				}

				blob.set_u16("taunt timer", 30);
			}
			
			
		}
		else if (this.isAnimationEnded())
		{
			this.SetAnimation("default");
		}
	}

	//set the head anim
	if (knocked > 0)
	{
		blob.Tag("dead head");
	}
	else if (blob.isKeyPressed(key_action1))
	{
		blob.Tag("attack head");
		blob.Untag("dead head");
	}
	else
	{
		blob.Untag("attack head");
		blob.Untag("dead head");
	}

}

void onGib(CSprite@ this)
{
	if (g_kidssafe)
	{
		return;
	}

	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0;
	const u8 team = blob.getTeamNum();
	CParticle@ Body     = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm1     = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm2     = makeGibParticle("Entities/Characters/Builder/BuilderGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
}