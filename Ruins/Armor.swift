//
//  Armor.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation

class Armor
{
	let type:String
	let subtype:Int
	
	init(type:String, level:Int)
	{
		self.type = type
		
		let subtypes = Armor.subtypesFor(type)!
		
		//there is no such thing as no-subtype armors, so if you try to generate one a crash is appropriate
		
		var closestSub:Int = 0
		var closestSubLevelDistance:Int = 999999
		for i in 0..<subtypes.count
		{
			let sub = subtypes[i]
			let subLevel = Int((sub["level"] as! NSNumber).intValue)
			let levelDistance = abs(level - subLevel)
			if levelDistance < closestSubLevelDistance
			{
				closestSubLevelDistance = levelDistance
				closestSub = i
			}
		}
		subtype = closestSub
	}
	
	init(saveDict d:NSDictionary)
	{
		self.type = d["type"] as! String
		self.subtype = Int((d["subtype"] as! NSNumber).intValue)
	}
	
	var saveDict:NSDictionary
	{
		var d = [NSString : NSObject]()
		
		d["type"] = type
		d["subtype"] = subtype
		
		return d
	}
	
	private static func subtypesFor(type:String) -> [NSDictionary]?
	{
		return DataStore.getArray("Armors", type, "subtypes") as? [NSDictionary]
	}
	
	//MARK: accessors
	
	var weight:Int
	{
		return getStatisticInt("weight")!
	}
	var meleeResistance:Int
	{
		return getStatisticInt("melee resistance") ?? 0
	}
	var dodge:Int
	{
		return getStatisticInt("dodge") ?? 0
	}
	var maxHealthBonus:Int
	{
		return getStatisticInt("max health bonus") ?? 0
	}
	var trapResistance:Int
	{
		return getStatisticInt("trap resistance") ?? 0
	}
	var specialResistance:Int
	{
		return getStatisticInt("special resistance") ?? 0
	}
	var name:String
	{
		return getStatistic("name") as! String
	}
	var spriteName:String
	{
		return getStatistic("sprite name") as! String
	}
	var spriteColor:String
	{
		return getStatistic("color") as! String
	}
	
	
	private func getStatistic(name:String) -> NSObject?
	{
		let subtypes = Armor.subtypesFor(type)!
		return subtypes[subtype][name] as? NSObject
	}
	
	private func getStatisticInt(name:String) -> Int?
	{
		if let number = getStatistic(name) as? NSNumber
		{
			return Int(number.intValue)
		}
		return nil
	}
}