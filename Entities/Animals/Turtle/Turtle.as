
//script for a birb

#include "AnimalConsts.as";

const u8 DEFAULT_PERSONALITY = SCARED_BIT;

//sprite


void onInit(CSprite@ this)
{
    this.ReloadSprites(0,0);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (!blob.hasTag("dead"))
	{
		f32 x = Maths::Abs(blob.getVelocity().x);
		if (blob.isAttached())
		{
			AttachmentPoint@ ap = blob.getAttachmentPoint(0);
			if (ap !is null && ap.getOccupied() !is null)
			{
				if (Maths::Abs(ap.getOccupied().getVelocity().y) > 0.2f)
				{
					this.SetAnimation("walk");
				}
				else
					this.SetAnimation("default");
			}
		}
		else if (!blob.isOnGround())
		{
			this.SetAnimation("retract");
		}
		else if (x > 0.1f)
		{
			this.SetAnimation("walk");
		}
		else
		{
			if (this.isAnimationEnded())
			{
				uint r = XORRandom(20);
				if (r == 0)
					this.SetAnimation("walk");
				else if (r < 5)
					this.SetAnimation("retract");
				else
					this.SetAnimation("default");
			}
		}
	}
	else
	{
		this.SetAnimation("dead");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

//blob

void onInit(CBlob@ this)
{
	//brain
	this.set_u8(personality_property, DEFAULT_PERSONALITY);
	this.getBrain().server_SetActive(true);
	this.set_f32(target_searchrad_property, 30.0f);
	this.set_f32(terr_rad_property, 75.0f);
	this.set_u8(target_lose_random, 14);

	//for shape
	this.getShape().SetRotationsAllowed(false);

	this.server_setTeamNum(2);

	//for flesh hit
	this.set_f32("gib health", -0.0f);
	this.Tag("flesh");

	//this.getShape().SetOffset(Vec2f(0, 6));

	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runProximityTag = "player";
	this.getCurrentScript().runProximityRadius = 320.0f;
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return true;
}

void onTick(CBlob@ this)
{
	f32 x = this.getVelocity().x;
	if (Maths::Abs(x) > 1.0f)
	{
		this.SetFacingLeft(x < 0);
	}
	else
	{
		if (this.isKeyPressed(key_left))
		{
			this.SetFacingLeft(true);
		}
		if (this.isKeyPressed(key_right))
		{
			this.SetFacingLeft(false);
		}
	}

	if (!this.isOnGround())
	{
		
		this.AddForce(Vec2f(0, 10));
		
	}
//	else if (XORRandom(128) == 0)
//	{
//		if (getNet().isServer())
//		{
//			//blow bubbles
//		}
//	}
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
   if (this.hasTag("dead"))
    this.AddScript( "Eatable.as" );
    return damage;
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if (blob.hasTag("dead") || blob.hasTag("player") || blob.hasTag("volleyball"))
		return false;
	return true;
}