// Tent logic

#include "StandardRespawnCommand.as"

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-50.0f);

	this.CreateRespawnPoint("tent", Vec2f(0.0f, -4.0f));

	this.Tag("respawn");

	// minimap
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 1, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);

	// defaultnobuild
	this.set_Vec2f("nobuild extend", Vec2f(0.0f, 8.0f));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onRespawnCommand(this, cmd, params);
}
