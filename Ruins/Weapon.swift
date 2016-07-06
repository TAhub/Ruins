//
//  Weapon.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation

class Weapon
{
	let type:String
	let subtype:Int
	let material:String
	
	init(type:String, material:String, level:Int)
	{
		self.type = type
		self.material = material
		
		if false
		{
			//TODO: if its a weapon with no discrete subtypes, pick the subtype with the level closest to the desired level
			subtype = 0
		}
		else
		{
			//otherwise, set the subtype to the level
			subtype = level
		}
	}
	
	//MARK: derived variables
	var damage:Int
	{
		//TODO: take into account:
		//	type
		//	subtype (if it's a weapon with no discrete subtypes, auto-scale damage to 100 * (50 / 13 * subtype)
		//	material
		return 100
	}
	var weight:Int
	{
		//TODO: take into account:
		//	type
		//	subtype (but only if it's a weapon with discrete subtypes
		//	material
		return 100
	}
	var hitDamageMultiplier:Int
	{
		return 100
	}
	var accuracy:Int
	{
		return 100
	}
	var range:Int
	{
		return 1
	}
}