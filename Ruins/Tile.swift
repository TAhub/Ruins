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
	
	init(solid:Bool)
	{
		self.solid = solid
	}
}