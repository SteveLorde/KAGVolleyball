
void onInit(CBlob@ this)
{	
	this.Tag("invincible");
	this.Tag("volleyball");
	this.getShape().SetRotationsAllowed(true);
    this.getShape().SetGravityScale(0.65f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}