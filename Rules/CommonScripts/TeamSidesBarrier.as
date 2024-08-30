// red barrier before match starts

const f32 BARRIER_PERCENT = 0.01f;
bool barrier_set = false;

bool shouldBarrier(CRules@ this)
{
	return !this.isGameOver() || this.isBarrier();
}

void onTick(CRules@ this)
{
	if (shouldBarrier(this))
	{
		if (!barrier_set)
		{
			barrier_set = true;
			addBarrier();
		}

		f32 x1, x2, y1, y2;
		getBarrierPositions(x1, x2, y1, y2);
		const f32 middle = x1 + (x2 - x1) * 0.5f;

		CBlob@[] players;
		getBlobsByTag("player", @players);
		for (uint i = 0; i < players.length; i++)
		{	
			CBlob@ b = players[i];
			if (b !is null)
			{
				Vec2f pos = b.getPosition();
				f32 f = b.getMass() * 1.0f;

				if (b.getTeamNum() == 0 && pos.x > middle-15)
				{
					if (pos.x > middle+4)
					{
						b.AddForce(Vec2f(-f, -f * 0.4f)); //trying to get behind the net.
					}
					else
					{
						b.AddForce(Vec2f(-f, -f * 0.02f));
					}
				}
				else if (b.getTeamNum() == 1 && pos.x < middle+15)
				{
					if (pos.x < middle-4)
					{
						b.AddForce(Vec2f(f, -f * 0.4f)); //trying to get behind the net.
					}
					else
					{
						b.AddForce(Vec2f(f, -f * 0.02f));
					}
				}
			}
		}
		
	}
	else
	{
		if (barrier_set)
		{
			removeBarrier();
			barrier_set = false;
		}
	}
}

void Reset(CRules@ this)
{
	barrier_set = false;
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
}
/*
void onRender(CRules@ this)
{
	if (shouldBarrier(this))
	{
		f32 x1, x2, y1, y2;
		getBarrierPositions(x1, x2, y1, y2);
		GUI::DrawRectangle(getDriver().getScreenPosFromWorldPos(Vec2f(x1, y1)), getDriver().getScreenPosFromWorldPos(Vec2f(x2/2+10, y2)), SColor(100, 0, 0, 235));
		GUI::DrawRectangle(getDriver().getScreenPosFromWorldPos(Vec2f(x2/2-10, y1)), getDriver().getScreenPosFromWorldPos(Vec2f(x2, y2)), SColor(100, 235, 0, 0));
	}
}
*/

void getBarrierPositions(f32 &out x1, f32 &out x2, f32 &out y1, f32 &out y2)
{
	CMap@ map = getMap();
	const f32 mapWidth = map.tilemapwidth * map.tilesize;
	const f32 mapMiddle = mapWidth * 0.5f;
	x1 = 0;
	x2 = mapWidth;
	y2 = map.tilemapheight * map.tilesize;
	y1 = -y2;
	y2 *= 2.0f;
}

/**
 * Adding the barrier sector to the map
 */

void addBarrier()
{
	CMap@ map = getMap();

	f32 x1, x2, y1, y2;
	getBarrierPositions(x1, x2, y1, y2);

	Vec2f ul(x1, y1);
	Vec2f lr(x2, y2);

	if (map.getSectorAtPosition((ul + lr) * 0.5, "barrier") is null)
		map.server_AddSector(Vec2f(x1, y1), Vec2f(x2, y2), "barrier");
}

/**
 * Removing the barrier sector from the map
 */

void removeBarrier()
{
	CMap@ map = getMap();

	f32 x1, x2, y1, y2;
	getBarrierPositions(x1, x2, y1, y2);

	Vec2f ul(x1, y1);
	Vec2f lr(x2, y2);

	map.RemoveSectorsAtPosition((ul + lr) * 0.5 , "barrier");
}
