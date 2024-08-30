
//#include "TrailCommon.as";

u16[] player_hits;
void onInit(CBlob@ this)
{	
	//this.Tag("invincible");
	this.getSprite().SetZ(50.0f); // infront of heads
	this.Tag("volleyball");
	this.getShape().SetRotationsAllowed(false);
    this.getShape().SetGravityScale(0.65f);
    this.getShape().getConsts().net_threshold_multiplier = 2.0f;
    this.getShape().getConsts().bullet = true;
    //this.getShape().getConsts().collideWhenAttached = false;
	
}

void onDie(CBlob@ this)
{
	const Vec2f position = this.getPosition();
	for(u8 i = 0; i < 10; i++)
	{
		int timeout = 5+XORRandom(10);
		ParticlePixel(position, getRandomVelocity(90, 10, 360), color_white, true, timeout);
	}
}

void onTick(CBlob@ this)
{
	CShape@ shape = this.getShape();
	// too fast - slow down
	if (shape.vellen > 8.0f)
	{
		Vec2f vel = this.getVelocity();
		this.AddForce(Vec2f(-vel.x * 0.35f, -vel.y * 0.35f));
	}

	//trajectory for bot brains
	if (getGameTime() % 10 == 0)
	{
		this.Tag("update trajectory");
	}
	if (this.hasTag("update trajectory"))
	{		
		PredictLanding(this);
		this.Untag("update trajectory");
	}
}


Vec2f[] Trajectory;

void PredictLanding(CBlob@ this)
{ 
	Vec2f pos = this.getPosition();
	Vec2f vel = this.getVelocity();
	float speed = vel.Length();	

	float timestep = 3.0+(speed/3.0);

	const int PlotMaxSteps = 32;
	const float objectmass = this.getMass();
	const float objectgravityscale = 0.65f;
    const float dragX = 1.0 - (0.017) *timestep;
    const float dragY = 1.0 - (0.028) *timestep;
    Vec2f gravity = (Vec2f(0, sv_gravity) / objectmass) * objectgravityscale;

	Trajectory.set_length(PlotMaxSteps);
	Trajectory[0] = pos;

	Vec2f surfacepos;

    for ( int i = 1; i < PlotMaxSteps; ++i )
    {     	
        pos += (vel*timestep) + (gravity*timestep);
        vel.y += gravity.y*timestep;
        vel.y *= dragY;
        vel.x *= dragX;

        if (getMap().rayCastSolid(Trajectory[i-1], pos, surfacepos))
    	{
    		this.set_Vec2f("landing pos", surfacepos);
    		Trajectory[i] = surfacepos;
    		Trajectory.set_length(i);
    		break;
    	}

	    Trajectory[i] = pos;
    }	
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	for (int i = 1; i <= Trajectory.size(); ++i)
	{
	    GUI::DrawLine(Trajectory[i-1], Trajectory[i], SColor(255,0,255,0));	    
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	this.Tag("update trajectory");

	CRules@ rules = getRules();
	if (detached is null && !rules.isGameOver())
	{
		//if (!detached.isKeyJustReleased(key_pickup))
		{
			if (rules.get_u8("servingTeam") == 0)
			{
				rules.set_u8("servingTeam", 1);
			}
			else
			{
				rules.set_u8("servingTeam", 0);
			}
			rules.set_u8("serve delay", 60);
			this.server_Die();
		}
	}
	else
	{
		getRules().set_bool("Wants New Serve", false);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{	
	if (this.isAttached() || !solid || blob !is null || getRules().isGameOver())
	{
		return;
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	this.Tag("update trajectory");
	return 0; //no block, damage goes through
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{	
	return !blob.hasTag("player");	
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}