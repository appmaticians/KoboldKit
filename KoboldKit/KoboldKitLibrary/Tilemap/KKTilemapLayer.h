//
// KTTilemapLayer.h
// KoboldTouch-Libraries
//
// Created by Steffen Itterheim on 20.12.12.
//
//

#import "KKTypes.h"

@class KKTilemap;
@class KKTilemapTileset;
@class KKTilemapLayerTiles;
@class KKTilemapProperties;
@class KKTilemapObject;

/** TMX Layer data. Can be either a tile or object layer. Depending on which it is not all properties are used, this is noted in the property descriptions. */
@interface KKTilemapLayer : NSObject
{
	@private
	KKTilemapProperties* _properties;
	KKTilemapLayerTiles* _tiles;
	NSMutableArray* _objects;
}

/** @name Common Layer Properties */

/** The name of the layer. TILED-EDITABLE
 @returns The name of the layer. */
@property (nonatomic, copy) NSString* name;
/** @returns The layer's properties. */
@property (nonatomic, readonly) KKTilemapProperties* properties;
/** Reference to the tilemap to allow KTTileLayerViewController and KTObjectLayerViewController quick access to the KTTilemap object. 
 @returns The tilemap the layer is part of. */
@property (nonatomic, weak) KKTilemap* tilemap;
/** Is set if this layer is an Object Layer. If NO it is a Tile Layer.
 @returns YES if this is an object layer. */
@property (nonatomic) BOOL isObjectLayer;
/** Is set if this layer is a Tile Layer. If NO it is a Object Layer.
 @returns YES if this is a tile layer. */
@property (nonatomic) BOOL isTileLayer;
/** Whether the tiles on this layer are visible or not. If a tile layer is hidden, it will still create the tiles and therefore
 use the same memory as if the tiles were visible. Default: NO. TILED-EDITABLE
 @returns YES if the layer is hidden (not visible). */
@property (nonatomic) BOOL hidden;

/** @name Tile Layer Properties */

/** (Tile Layers Only) The layer's size (in tiles). The layer size is usually identical to the mapSize property of KTTilemap.
 @returns The size of the tile layer, in tiles. */
@property (nonatomic) CGSize size;
@property (nonatomic) unsigned int tileCount;
/** How opaque the layer is. Value ranges from 0 (fully transparent) to 1 (fully opaque).
   The alpha of a layer can be set in Tiled by moving the Opacity slider just above the Layers list. Default: 1.0. TILED-EDITABLE
 @returns The alpha (opacity) of the layer. */
@property (nonatomic) unsigned char alpha;

/** If YES, this layer will scroll endlessly in all directions, repeating itself (wrap around) at map borders. If changed will set both
 endlessScrollingHorizontal and endlessScrollingVertical. Returns YES only if both endlessScrollingHorizontal and endlessScrollingVertical are YES.
 Default: NO. TILED-EDITABLE
 @returns YES if the map wraps around and repeats in all directions. */
@property (nonatomic) BOOL endlessScrolling;
/** If YES, this layer will scroll endlessly along the X axis, repeating itself (wrap around) at map borders. Default: NO. TILED-EDITABLE
 @returns YES if the map wraps around and repeats along the horizontal axis. */
@property (nonatomic) BOOL endlessScrollingHorizontal;
/** If YES, this layer will scroll endlessly along the Y axis, repeating itself (wrap around) at map borders. Default: NO. TILED-EDITABLE
 @returns YES if the map wraps around and repeats along the vertical axis. */
@property (nonatomic) BOOL endlessScrollingVertical;

/** Determines how fast this layer moves in both directions when scrolling the tilemap. Value between -1.0f and 1.0f, usually you only use the range from 0.0f to 1.0f.
   Negative values simply scroll in the other direction. Defaults to: (1.0f, 1.0f).

   The parallaxFactor determines how much slower than the default (1.0f) the layer scrolls. At 0.0f the layer won't move at all. Design your layers so that the fastest
   moving layer has a parallaxFactor of 1.0f. To create a parallax scroller where your game layer has slower background layers and faster foreground layers, give
   the front-most foreground layer a parallaxFactor of 1.0f, your game's main layer perhaps 0.5f and the remaining layers values greater or smaller than 0.5f.

   Note: Yes, it makes it a little bit more difficult to tweak the speed based on the game's main layer in such a situation. It does however make things a lot simpler
   internally. In this case I decided the tradeoff in usability is acceptable, the tradeoff in additional code (special case handling) isn't. TILED-EDITABLE
 @returns The layer's parallaxFactor. */
@property (nonatomic) CGPoint parallaxFactor;

/** @name Working with Tile Layer GIDs */

/** (Tile Layers Only) Reference to the KTTilemapLayerTiles object which contains the memory buffer for the tile GIDs of this tile layer. Always nil
 for object layers.
 @returns A tile layer's tiles. */
@property (nonatomic, readonly) KKTilemapLayerTiles* tiles;

/** Returns the tile GID at a specific tile coordinate, without the flip flags normally encoded in the GID. Returns 0 if there is no tile set at this coordinate
   (empty tile) or if the tile coordinate is outside the boundaries of the layer.
 @param tileCoord Coordinate in tiles. 
 @returns The tile GID (without flags) at the given tile coordinate, or 0 for illegal coordinates. */
-(gid_t) tileGidAt:(CGPoint)tileCoord;
/** Like tileAt but returns the GID including the KTTilemapTileFlags. To get just the GID from the returned value use tileAt or mask out
   the flip flags: gid = (gidWithFlags & KTTilemapTileFlipMask) - you don't normally need the flip flags unless they have some meaning in your game,
   for example if certain tile GIDs can only be operated from one side (ie a button tile that the player must approach from the correct side to operate it).
 @param tileCoord Coordinate in tiles.
 @returns The tile GID (with flags) at the given tile coordinate, or 0 for illegal coordinates. */
-(gid_t) tileGidWithFlagsAt:(CGPoint)tileCoord;
/** Sets a tile gid at the given tile coordinate, leaves the tile's flags (flipping etc) untouched. A tile gid of 0 will "clear" the tile (empty tile).
 @param gid The tile GID to set. Must be a valid GID. GID flags will be ignored.
 @param tileCoord The tile coordinate of the tile to set the gid at. */
-(void) setTileGid:(gid_t)gid tileCoord:(CGPoint)tileCoord;
/** Sets a tile gid at the given tile coordinate, including tile flags. Tile flags must already be OR'ed into the gid. A tile gid of 0 will "clear" the tile (empty tile).
 @param gidWithFlags The tile GID including flags to set. Must be a valid GID.
 @param tileCoord The tile coordinate of the tile to set the gid at. */
-(void) setTileGidWithFlags:(gid_t)gidWithFlags tileCoord:(CGPoint)tileCoord;
/** Clears a tile at the given tile coordinate (sets gid to 0, clears all flags). Same as calling setTileGidWithFlags:0.
 @param tileCoord The tile coordinate of the tile to clear (remove). */
-(void) clearTileAt:(CGPoint)tileCoord;

/** @name Working with Layer Objects */

/** (Object Layers Only) A list of "objects" on this layer. These "objects" are Tiled's rectangles, polylines and polygons. They can be used to position
 tilemap objects not editable in Tiled by (normally) using the first point of such an "object" as the origin for the actual game object.
 Always nil for tile layers.
 @returns An array of an object layer's KTTilemapObject objects. */
@property (nonatomic, readonly) NSArray* objects;

/** Adds a tilemap object if the layer is an object layer. Ignored if the layer is a tile layer.
 @param object The tilemap object to add to the layer. */
-(void) addObject:(KKTilemapObject*)object;
/** Removes a tilemap object if the layer is an object layer. Ignored if the layer is a tile layer, or layer does not contain object. 
 @param object The tilemap object to remove from the layer. */
-(void) removeObject:(KKTilemapObject*)object;
/**  @param index The object at the given index.
 @returns The object at the given index. Returns nil if object does not exist or the index is out of bounds (contrary to NSArray which would raise an exception).*/
-(KKTilemapObject*) objectAtIndex:(NSUInteger)index;
/** @param name The name identifying an object.
 @returns the first object with the given name, or nil if there's no object with this name on this layer. Object names are case-sensitive! */
-(KKTilemapObject*) objectByName:(NSString*)name;

@end

