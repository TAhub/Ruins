//
//  Tile.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation

class Tile
{
	var trap:Trap?
	var creature:Creature?
	let solid:Bool
	let entryCost:Int = 1
	var visible:Bool
	
	init(solid:Bool)
	{
		self.solid = solid
		visible = false
	}
	
	var walkable:Bool
	{
		return !solid && creature == nil
	}
}