//
//  Map.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation

class Map
{
	var width:Int
	var height:Int
	private var tiles:[Tile]
	
	init(width:Int, height:Int)
	{
		self.width = width
		self.height = height
		
		//make just a simple walled arena in the size
		tiles = [Tile]()
		for y in 0..<height
		{
			for x in 0..<width
			{
				tiles.append(Tile(solid: x == 0 || y == 0 || x == width - 1 || y == height - 1))
			}
		}
	}
	
	func tileAt(x x:Int, y:Int) -> Tile
	{
		return tiles[x + y * width];
	}
}