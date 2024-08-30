
const string texture_name = "WavesTexture.png";
int direction = -1;	
Random _r(Time());

void onInit(CRules@ this)
{	
	if (getNet().isClient())
	{
		Setup();
		int cb_id = Render::addScript(Render::layer_postworld, "VolleyBall_Setup.as", "RenderFunction", 500.0f);
	}
	onRestart(this);
}

void Setup()
{
	//ensure texture for our use exists
	if(!Texture::exists(texture_name))
	{
		if(!Texture::createBySize(texture_name, 48, 48))
		{
			warn("texture creation failed");
		}
		else
		{
			ImageData@ edit = Texture::data(texture_name);

			for(int i = 0; i < edit.size(); i++)
			{
				edit[i] = SColor((((i + i / 8) % 2) == 0) ? 0xff707070 : 0xff909090);
			}

			if(!Texture::update(texture_name, edit))
			{
				warn("texture update failed");
			}
		}
	}
}

void onRestart(CRules@ this)
{
	if (_r.NextRanged(2) == 0) 
	{ direction = -1; }
	else 
	{ direction = 1; }	

	SetupArena(this);
}

void SetupArena(CRules@ this)
{
	if (getNet().isServer())
	{
		CMap@ map = getMap();
		if(map !is null)
		{	
			f32 mapmid = (map.tilemapwidth * map.tilesize)/2;
			Vec2f GroundMid = Vec2f(mapmid, map.getLandYAtX(mapmid / map.tilesize) * map.tilesize -40.0f);

			CBlob@ nl = server_CreateBlob("net", -1, GroundMid+Vec2f(0,-4));

			CBlob@ cbl = server_CreateBlob("courtboundaryend", -1, GroundMid+Vec2f(-296,17));
			if (cbl !is null)
			{
				cbl.getSprite().SetZ(500.0f);
				cbl.getShape().SetStatic( true );
			}		
			CBlob@ cbr = server_CreateBlob("courtboundaryend", -1, GroundMid+Vec2f(296,17));
			if (cbr !is null)
			{
				cbr.getSprite().SetZ(500.0f);
				cbr.getSprite().SetFacingLeft( true );
				cbr.getShape().SetStatic( true );
			}

			CBlob@ bfl1 = server_CreateBlob("beachflag1", _r.NextRanged(7), GroundMid+Vec2f(-312,-24));
			if (bfl1 !is null)
			{
				//bf.getSprite().SetFacingLeft(true);
				bfl1.getShape().SetStatic( true );
			}

			CBlob@ bfl2 = server_CreateBlob("beachflag1", _r.NextRanged(7), GroundMid+Vec2f(-394,-24));
			if (bfl2 !is null)
			{
				//bf.getSprite().SetFacingLeft(true);
				bfl2.getShape().SetStatic( true );
			}

			CBlob@ bfr1 = server_CreateBlob("beachflag1", _r.NextRanged(7), GroundMid+Vec2f(312,-24));
			if (bfr1 !is null)
			{
				bfr1.getSprite().SetFacingLeft(true);
				bfr1.getShape().SetStatic( true );
			}

			CBlob@ bfr2 = server_CreateBlob("beachflag1", _r.NextRanged(7), GroundMid+Vec2f(394,-24));
			if (bfr2 !is null)
			{
				bfr2.getSprite().SetFacingLeft(true);
				bfr2.getShape().SetStatic( true );
			}

			for (int i = 0; i < 12; i++)
			{	
				CBlob@ eb = server_CreateBlob("courtboundaryedge", -1, GroundMid+Vec2f(-268+(49*i),12));
				if (eb !is null)
				{
					eb.getSprite().SetFacingLeft(true);
					eb.getShape().SetStatic( true );
				}				
			}

			f32 mapwidth = (map.tilemapwidth * map.tilesize);				
			for (int i = 0; i < 5; i++)
			{
				CBlob@ topcloud = server_CreateBlob("cloud"+(1+_r.NextRanged(3)), -1, Vec2f(mapwidth/10+(i*mapwidth/5)+_r.NextRanged(64)-32,-300));
				if (topcloud !is null)
				{						
					topcloud.getSprite().ScaleBy(Vec2f(4,4));
				}
			}			
			for (int i = 0; i < 5; i++)
			{
				CBlob@ midcloud = server_CreateBlob("cloud"+(1+_r.NextRanged(3)), -1, Vec2f(mapwidth/10+(i*mapwidth/5)+_r.NextRanged(128)-64,-150+_r.NextRanged(48)));
				if (midcloud !is null)
				{						
					midcloud.getSprite().ScaleBy(Vec2f(2,2)); //not working on server
				}
			}

			for (int i = 0; i < 10; i++)
			{
				CBlob@ lowcloud = server_CreateBlob("cloud"+(1+_r.NextRanged(3)), -1, Vec2f(mapwidth/20+(i*mapwidth/10)+_r.NextRanged(128)-64,-64+_r.NextRanged(48)));
				if (lowcloud !is null)
				{						
					lowcloud.getSprite().ScaleBy(Vec2f(1,1));
				}
			}		

			//CBlob@ b = server_CreateBlob("balllauncher", -1, Vec2f(GroundMid.x+60.0f,GroundMid.y));
			//if (b !is null)
			//{
			//}
		}
	}
}


Vertex[] v_raw;
void RenderFunction(int id)
{
	CMap@ map = getMap();
	string render_texture_name = texture_name;	
	const f32 z = 500.0;	
	const float x_size = 48.0;
	const float y_size = 32.0;	

	const int wavelength = 16;
	const f32 amplitude = 3.5;
	const f32 pi = 3.14159;

	const int wavecount = (map.tilemapwidth * map.tilesize)/x_size;
	const u16 mapheight =	map.tilemapheight * map.tilesize;
	const u16 mapwidth =	map.tilemapwidth * map.tilesize;

	Vec2f p = Vec2f(0,(map.tilemapheight * map.tilesize)-20);
	float time = (getGameTime()*direction / 5.0f);

	v_raw.clear();

	for (int i = 0; i < wavecount; i++)
	{
		f32 y1 =  -amplitude * Maths::Sin(Maths::Pi*2.0f*((time)+i)/wavelength);
		f32 y2 =  -amplitude * Maths::Sin(Maths::Pi*2.0f*((time)+i+1)/wavelength);

		v_raw.push_back(Vertex(p.x + x_size*i, 		p.y +		y1, 	z ,0,0, SColor(100,255,255,255)));
		v_raw.push_back(Vertex(p.x + x_size*(i+1),  p.y +		y2, 	z ,1,0, SColor(100,255,255,255)));
		v_raw.push_back(Vertex(p.x + x_size*(i+1),  p.y +	y_size, 	z ,1,1, SColor(255,0,0,0)));
		v_raw.push_back(Vertex(p.x + x_size*i, 		p.y + 	y_size, 	z ,0,1, SColor(255,0,0,0)));
	}

	Render::SetAlphaBlend(true);
	Render::RawQuads(render_texture_name, v_raw);
}

//Vec2f[] v_pos;
//Vec2f[] v_uv;
//SColor[] v_col;

//void RenderClouds()
//{
//	CMap@ map = getMap();
//	if (map is null) return;
//
//	string render_texture_name = texture_cloud_name;
//
//	v_pos.clear();
//	v_uv.clear();
//	v_col.clear();
//
//	const int cloudcount = (map.tilemapwidth * map.tilesize)/74.5f;
//
//	for (int i = 0; i < cloudcount; i++)
//	{
//		Vec2f cpos = Vec2f((74.5f*i),50);
//		v_pos.push_back(cpos+ Vec2f(-74.5f,-36.5)); v_uv.push_back(Vec2f(0,0));
//		v_pos.push_back(cpos+ Vec2f( 74.5f,-36.5)); v_uv.push_back(Vec2f(1,0));
//		v_pos.push_back(cpos+ Vec2f( 74.5f, 36.5)); v_uv.push_back(Vec2f(1,1));
//		v_pos.push_back(cpos+ Vec2f(-74.5f, 36.5)); v_uv.push_back(Vec2f(0,1));
//
//	}
//	for(int i = 0; i < v_pos.length; i++)
//	{
//		SColor lightcol = map.getColorLight(v_pos[i]);
//		v_col.push_back(SColor(50, lightcol.getRed(), lightcol.getGreen(), lightcol.getBlue()));
//	}
//	Render::SetAlphaBlend(true);
//	Render::QuadsColored(render_texture_name, 500, v_pos, v_uv, v_col);
//}
