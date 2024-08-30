
#include "RulesCore.as";
#include "BVB_Structs.as";

void onInit(CRules@ this)
{
	CBitStream stream;
	stream.write_u16(0xDEAD); //check bits rewritten when theres something useful
	this.set_CBitStream("bvb_serialised_team_queues", stream);
    this.Sync("bvb_serialized_team_queues", true);

    if (!GUI::isFontLoaded("AveriaSerif-Bold_20"))
	{		
		string AveriaSerif = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
		GUI::LoadFont("AveriaSerif-Bold_20", AveriaSerif, 20, true);
	}
}

void onRender(CRules@ this)
{	
	DrawGamePoints(this);
}

void DrawGamePoints(CRules@ this)
{
	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) { return; }	

	CMap@ map = getMap();
	f32 SMid = (getScreenWidth()/2)-8.0f;

	CBitStream serialised_team_hud;
	this.get_CBitStream("bvb_serialised_team_hud", serialised_team_hud);

	if (serialised_team_hud.getBytesUsed() > 0)
	{
		serialised_team_hud.Reset();
		u16 check;

		if (serialised_team_hud.saferead_u16(check) && check == 0x5afe)
		{
			while (!serialised_team_hud.isBufferEnd())
			{
				BVB_HUD hud(serialised_team_hud);

				GUI::DrawIcon( "BVB_Gui.png", 1, Vec2f(32,16), Vec2f(SMid-48-(hud.bluegoals > 99 ? 6: 0),2)); 	//blue outer, draw these first			
				GUI::DrawIcon( "BVB_Gui.png", 2, Vec2f(32,16), Vec2f(SMid-16+(hud.redgoals  > 99 ? 6: 0),2)); 	//red outer

				GUI::DrawIcon( "BVB_Gui.png", 0, Vec2f(16,16), Vec2f(SMid-32,2)); 	//blue inner, draw these over the top of those
				GUI::DrawIcon( "BVB_Gui.png", 1, Vec2f(16,16), Vec2f(SMid,2));		//red inner

				//scores
				string bluegoals = hud.bluegoals;
				string redgoals =  hud.redgoals;

				GUI::SetFont("AveriaSerif-Bold_20");
				GUI::DrawTextCentered(""+bluegoals, Vec2f(SMid-20,15), color_white);
				GUI::DrawTextCentered(""+redgoals, Vec2f(SMid+18,15), color_white);
			}
		}
		serialised_team_hud.Reset();
	}
}
