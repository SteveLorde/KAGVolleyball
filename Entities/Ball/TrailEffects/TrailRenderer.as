// TrailRenderer.as
// Created by Chrispin  // edited version by Monkey_Feats - add this script to blobs instead of rules
#include "TrailCommon.as";

void onInit(CBlob@ this)
{	
	Setup(this);
    int cb_id = Render::addBlobScript(Render::layer_postworld, this, "TrailRenderer.as", "RenderTrails");
}

void Setup(CBlob@ this)
{
    TrailEffect trailEffect = TrailEffect();

	trailEffect.startWidth = 14.0f;
	trailEffect.endWidth = 0.0f;
	trailEffect.timePerNewSeg = 0.02f;
	trailEffect.decayTime = 0.6f; 
	trailEffect.minSegDist = 4.0f;
	trailEffect.fadeInDist = 0.0f;
	trailEffect.fadeOutDist = 1024.0f;
	trailEffect.smoothingFactor = 0.0f;
	trailEffect.Z = -1.0f;
	trailEffect.setTexture("trail_basicsoft.png");
	trailEffect.setBaseAlpha(15);
	trailEffect.leaveTexBehind = false;
	trailEffect.emitterBlobID = this.getNetworkID();
    trailEffect.emitOffset = Vec2f_zero;

    this.set("trail", trailEffect);
}

void RenderTrails(CBlob@ this, int id)
{
	TrailEffect@ Trail;
	if (!this.get("trail", @Trail))
	{
		Setup(this);
		return;
	}
	Vertex[] v_raw;

	Render::SetAlphaBlend(true);
	Trail.Update(v_raw);	// update trail and add verticies to v_raw
		
    if(v_raw.length() > 0)
    {
        Render::RawQuads(Trail.texName, v_raw);
    }
	Render::SetAlphaBlend(false);
}