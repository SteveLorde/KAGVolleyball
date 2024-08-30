// Bushy tree Logic

#include "TreeSync.as"

void onInit(CBlob@ this)
{
	this.set_f32("bend amount", XORRandom(10));
	this.set_u8("direction", XORRandom(2));

	InitVars(this);
	this.server_setTeamNum(-1);
	TreeVars vars;
	vars.seed = XORRandom(30000);
	vars.growth_time = 250 + XORRandom(30);
	vars.height = 0;
	vars.max_height = 5 + XORRandom(4);
	vars.grown_times = 0;
	vars.max_grow_times = 50;
	vars.last_grew_time = getGameTime() - 1; //pretend we started a frame ago ;)
	InitTree(this, vars);
	this.set("TreeVars", vars);

}

void GrowSprite(CSprite@ this, TreeVars@ vars)
{
	CBlob@ blob = this.getBlob();
	if (vars is null)
		return;

	if (vars.height == 0)
	{
		this.animation.frame = 0;
	}
	//else //vanish
	//{
	//	this.animation.frame = 1;
	//}

	const f32 bend = blob.get_f32("bend amount");
	const u8 direction = blob.get_u8("direction");

	TreeSegment[]@ segments;
	blob.get("TreeSegments", @segments);
	if (segments is null)
		return;
	for (uint i = 0; i < segments.length; i++)
	{
		TreeSegment@ segment = segments[i];

		if (segment !is null && !segment.gotsprites)
		{
			segment.gotsprites = true;

			if (segment.grown_times == 1)
			{
				CSpriteLayer@ newsegment = this.addSpriteLayer("segment " + i, "PalmTree.png" , 16, 16, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);					

					if (XORRandom(2) == 0)
					{
						animGrow.AddFrame(1);
					}
					else
					{
						animGrow.AddFrame(2);
					}

					newsegment.SetAnimation(animGrow);
					newsegment.ResetTransform();
					newsegment.SetRelativeZ(-130.0f - vars.height);

					if (direction == 0)
					{
						newsegment.RotateBy(segment.angle+(i*bend), -(segment.start_pos/2) );
					}
					else
					{
						newsegment.RotateBy(segment.angle+(i*bend)*-1, (segment.start_pos/2)*-1 );
					}

					//newsegment.SetFacingLeft(segment.flip);

					Vec2f offset = segment.start_pos;
					newsegment.SetOffset(offset);
				}
			}
			else if (i == 0 && segment.grown_times == 4) //add roots
			{
				f32 flipsign = 1.0f;
				CSpriteLayer@ newsegment = this.addSpriteLayer("roots", "PalmTree.png" , 16, 16, 0, 0);

				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					animGrow.AddFrame(12);

					newsegment.ResetTransform();
					newsegment.SetRelativeZ(-120.0f);
					newsegment.RotateBy(segment.angle, Vec2f(0, 0));
					newsegment.SetOffset(segment.start_pos + Vec2f(0, 8.0f));

					newsegment.SetFacingLeft(segment.flip);
				}
			}
			else if (segment.grown_times == 5 && i == vars.max_height - 1) //top of the tree
			{
				CSpriteLayer@ newsegment = this.addSpriteLayer("leavesback", "PalmTree.png" , 64, 48, 0, 0);
				if (newsegment !is null)
				{
					Animation@ animGrow = newsegment.addAnimation("grow", 0, false);
					animGrow.AddFrame(2);
					newsegment.SetAnimation(animGrow);
					newsegment.ResetTransform();
					newsegment.SetRelativeZ(-550.0f- vars.height);
					if (direction == 0)
					{
						newsegment.RotateBy(segment.angle+(i*bend), -(segment.start_pos/2) );
					}
					else
					{
						newsegment.RotateBy(segment.angle+(i*bend)*-1, (segment.start_pos/2)*-1 );
					}

					Vec2f offset = segment.start_pos;
					newsegment.SetOffset(offset);
				}

				CSpriteLayer@ newsegment2 = this.addSpriteLayer("leavesfront", "PalmTree.png" , 64, 48, 0, 0);
				if (newsegment2 !is null)
				{
					Animation@ animGrow = newsegment2.addAnimation("grow", 0, false);
					animGrow.AddFrame(3);
					newsegment2.SetAnimation(animGrow);
					newsegment2.ResetTransform();
					newsegment2.SetRelativeZ(550.0f- vars.height);

					if (direction == 0)
					{
						newsegment2.RotateBy(segment.angle+(i*bend), -(segment.start_pos/2) );
					}
					else
					{
						newsegment2.RotateBy(segment.angle+(i*bend)*-1, (segment.start_pos/2)*-1 );
					}

					Vec2f offset = segment.start_pos;
					newsegment2.SetOffset(offset);
				}				
			}

		//	if (segment.grown_times < 5)
		//	{
		//		CSpriteLayer@ segmentlayer = this.getSpriteLayer("segment " + i);
//
		//		if (segmentlayer !is null)
		//		{
		//			segmentlayer.animation.frame++;
//
		//			if (i == vars.max_height - 1 && segment.grown_times == 3)
		//			{
		//				segmentlayer.SetOffset(segmentlayer.getOffset());
		//			}
		//		}
		//	}
		}
	}
}

void UpdateMinimapIcon(CBlob@ this, TreeVars@ vars)
{
	if (vars.grown_times < 5)
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 9, Vec2f(8, 32));
	}
	else if (vars.grown_times < 10)
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 11, Vec2f(8, 32));
	}
	else
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 13, Vec2f(8, 32));
	}
}