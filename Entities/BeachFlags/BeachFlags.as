
//#include "TrailCommon.as";

void onInit(CSprite@ this)
{	
	//this.Tag("invincible");
	this.SetZ(-450.0f);
	this.SetFrameIndex(XORRandom(15));
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0; //no block, damage goes through
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{	
	return false;	
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}