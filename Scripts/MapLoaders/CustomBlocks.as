#include "LoaderUtilities.as";

namespace CMap
{
	enum CustomTiles
	{
		tile_sand 	= 400,
	};
};

Random@ c_map_random = Random();

const SColor color_sandbackground(0xffebbe65);
const SColor color_sand(0xffebb065);
const SColor color_sandwet(0xffdc9f65);

const SColor color_palm(0xff3c6722);

void HandleCustomTile(CMap@ map, int offset, SColor pixel)
{
	if(color_palm == pixel)
	{
		
		CBlob@ palmtree = server_CreateBlobNoInit("tree_palm");
		if (palmtree !is null)
		{
			palmtree.Tag("startbig");
			palmtree.setPosition( map.getTileWorldPosition(offset) );
			palmtree.Init();
			//if (map.getTile(offset).type == CMap::tile_empty)
			//{
			//	map.SetTile(offset, CMap::tile_grass + c_map_random.NextRanged(3) );
			//}
		}

	}
	if(color_sandbackground == pixel)
	{
		map.SetTile(offset, 384 + XORRandom(12) );

		map.AddTileFlag( offset,  Tile::BACKGROUND | Tile::LIGHT_SOURCE | Tile::LIGHT_PASSES | Tile::WATER_PASSES);
		//map.AddTileFlag( offset, Tile::SOLID | Tile::COLLISION );
	}
	if(color_sand == pixel)
	{
		map.SetTile(offset, 400 + XORRandom(12) );

		map.AddTileFlag( offset,  Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::SOLID | Tile::COLLISION );
	}
	if(color_sandwet == pixel)
	{
		map.SetTile(offset, 416 + XORRandom(6) );
		map.AddTileFlag( offset,  Tile::LIGHT_PASSES | Tile::LIGHT_SOURCE | Tile::SOLID | Tile::COLLISION );
	}
}

//Vec2f getCustomSpawnPosition(CMap@ map, int offset)
//{
//	Vec2f pos = map.getTileWorldPosition(offset);
//	f32 tile_offset = map.tilesize * 0.5f;
//	pos.x += tile_offset;
//	pos.y += tile_offset;
//	return pos;
//}
