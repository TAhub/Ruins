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
	var creature:Creature?
	let solid:Bool
	let entryCost:Int = 1
	
	init(solid:Bool)
	{
		self.solid = solid
	}
	
	var walkable:Bool
	{
		return !solid && creature == nil
	}
}