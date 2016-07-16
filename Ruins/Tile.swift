//
//  Tile.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class Tile
{
	var trap:Trap?
	var creature:Creature?
	var visible:Bool
	var discovered:Bool
	let type:String
	
	init(type:String)
	{
		self.type = type
		visible = false
		discovered = false
	}
	
	var entryCost:Int
	{
		return DataStore.getBool("Tiles", type, "difficult") ? 2 : 1
	}
	
	var solid:Bool
	{
		return DataStore.getBool("Tiles", type, "solid")
	}
	
	var opaque:Bool
	{
		return DataStore.getBool("Tiles", type, "opaque")
	}
	
	var walkable:Bool
	{
		return !solid && creature == nil
	}
	
	var lowerSprite:String?
	{
		return DataStore.getString("Tiles", type, "lower sprite")
	}
	
	var middleSprite:String?
	{
		return DataStore.getString("Tiles", type, "middle sprite")
	}
	
	var upperSprite:String?
	{
		return DataStore.getString("Tiles", type, "upper sprite")
	}
	
	var color:UIColor
	{
		return DataStore.getColor("Tiles", type, "color") ?? UIColor.whiteColor()
	}
}