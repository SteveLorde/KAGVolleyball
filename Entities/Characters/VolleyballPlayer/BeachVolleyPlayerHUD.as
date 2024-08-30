//archer HUD

#include "BeachVolleyPlayerCommon.as";
#include "ActorHUDStartPos.as";

//const string iconsFilename = "Entities/Characters/Archer/ArcherIcons.png";
//const int slotsSize = 6;

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	//this.getBlob().set_u8("gui_HUD_slots_width", slotsSize);
}

void ManageCursors(CBlob@ this)
{
	// set cursor
	if (getHUD().hasButtons())
	{
		getHUD().SetDefaultCursor();
	}
	else
	{
		// set cursor
		getHUD().SetCursorImage("Entities/Characters/Archer/BeachVolleyCursor.png", Vec2f(32, 32));
		getHUD().SetCursorOffset(Vec2f(-32, -24));
		// frame set in logic
	}
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	ManageCursors(blob);
	
	if (g_videorecording)
		return;	

	CBlob@ carried = blob.getCarriedBlob();
	if (carried !is null)
	{
		if (carried.getName() == "beachball")
		{
			GUI::SetFont("menu");

			CMap@ map = getMap();
			if (map is null) return;
			f32 mapmid = (map.tilemapwidth * map.tilesize)/2;
			f32 bposx = blob.getPosition().x;
			if (bposx >= mapmid-296 && bposx <= mapmid+296)
			GUI::DrawShadowedText("YOU MUST BE BEHIND THE LINE TO SERVE!", blob.getInterpolatedScreenPos()+Vec2f(-140.0f,-80.0f), SColor(1000,255,0,0));
			else
			GUI::DrawShadowedText("PRESS 'C' KEY TO THROW IT UP!", blob.getInterpolatedScreenPos()+Vec2f(-96.0f,120.0f), SColor(1000,0,500,0));
		}
	}

	//Vec2f mouse = getControls().getMouseScreenPos();
	//Vec2f aimPos2D = getDriver().getScreenPosFromWorldPos(blob.getAimPos()+Vec2f(8.0f,8.0f));

	//u16 hitcount = blob.get_u16("playerhitcount");
//
	//if (hitcount > 0 && hitcount < blob.get_u16("maxhits"))
	//{
	//	GUI::DrawShadowedText(""+blob.get_u16("playerhitcount"), blob.getInterpolatedScreenPos()+Vec2f(8.0f,8.0f), color_white);		
	//}
	//else if (hitcount >= blob.get_u16("maxhits"))
	//{
	//	GUI::DrawShadowedText("MAX", blob.getInterpolatedScreenPos()+Vec2f(8.0f,8.0f), color_white);
	//}

	// draw inventory
//	Vec2f tl = getActorHUDStartPosition(blob, slotsSize);
//	DrawInventoryOnHUD(blob, tl);
//
//	const u8 type = getArrowType(blob);
//	u8 arrow_frame = 0;
//
//	if (type != ArrowType::normal)
//	{
//		arrow_frame = type;
//	}
//
//	// draw coins
//	const int coins = player !is null ? player.getCoins() : 0;
//	DrawCoinsOnHUD(blob, coins, tl, slotsSize - 2);
//
//	// class weapon icon
//	GUI::DrawIcon(iconsFilename, arrow_frame, Vec2f(16, 32), tl + Vec2f(8 + (slotsSize - 1) * 40, -16), 1.0f);
}
