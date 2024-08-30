
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
		if (!blob.isOnGround())
		{
			this.SetAnimation("fly");
		}
		else
		{
			this.SetAnimation("default");
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
    this.getCurrentScript().tickFrequency = 5;

    CSprite@ sprite = this.getSprite();
    if(sprite !is null)
    {
        sprite.SetRelativeZ(60.0f);
    }

	this.Tag("flesh");
	this.getShape().SetRotationsAllowed(false);
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return true;
}

int XDir = 1;
int YDir = 1;


void onTick(CBlob@ this)
{
	Vec2f vel = this.getVelocity();
    this.SetFacingLeft( vel.x < 0 );
    Vec2f moveForce;

    if (XORRandom(100) == 0)
    {
        XDir = XDir == 1 ? -1: 1;
    }
    
    if (XORRandom(10) == 0 && Maths::Abs(vel.x) < 30.0f)
    {        
        moveForce.x = 10.0f*XDir;
    }

    if (XORRandom(5) == 0 && vel.y > -30.0f)
    {
        if (getMap().rayCastSolid(this.getPosition(), this.getPosition()+Vec2f(0,333)))
        {
            moveForce.y = -40.6f;
        }
    }
    this.AddForce(moveForce);
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if (blob.hasTag("dead") || blob.hasTag("player") || blob.hasTag("volleyball"))
		return false;

	return true;
}