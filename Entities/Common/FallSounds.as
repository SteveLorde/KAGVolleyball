#define CLIENT_ONLY

void Sound(CBlob@ this, Vec2f normal)
{
	const f32 velx = this.getVelocity().x;

	if (Maths::Abs(velx) > 3.0f)
	{
		this.getSprite().PlaySound("sand_fall2");
		MakeSandParticle(this.getPosition(), (velx < 0 ? "SandDustLeft.png" : "SandDustRight.png"), velx*0.6f, (this.isFacingLeft() ? -1 : 1));		
	}
	else if (Maths::Abs(velx) > 2.25f)
	{
		this.getSprite().PlayRandomSound("/EarthStep");
	}
}

void MakeSandParticle(Vec2f pos, string file, f32 velx, int sign)
{
	CParticle@ temp = ParticleAnimated(file, pos - Vec2f(sign*-8, 8), Vec2f(velx*1.25, 0), 0.0f, 1.0f, 2, 0.0f, true);

	if (temp !is null)
	{
		temp.width = 8;
		temp.height = 8;
		temp.Z = 500;
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (blob is null && solid && this.getOldVelocity() * normal < 0.0f)   // only if approaching
	{
		Sound(this, normal);
	}
}
