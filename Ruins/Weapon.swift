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
		
		if let subtypes = Weapon.subtypesFor(type)
		{
			//if its a weapon with no discrete subtypes, pick the subtype with the level closest to the desired level
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
		else
		{
			//otherwise, set the subtype to the level
			subtype = level
		}
	}
	
	init(saveDict d:NSDictionary)
	{
		self.type = d["type"] as! String
		self.material = d["material"] as! String
		self.subtype = Int((d["subtype"] as! NSNumber).intValue)
	}
	
	var saveDict:NSDictionary
	{
		var d = [NSString : NSObject]()
		
		d["type"] = type
		d["material"] = material
		d["subtype"] = subtype
		
		return d
	}
	
	private static func subtypesFor(type:String) -> [NSDictionary]?
	{
		return DataStore.getArray("Weapons", type, "subtypes") as? [NSDictionary]
	}
	
	//MARK: derived variables
	var damage:Int
	{
		var dam = DataStore.getInt("Weapons", type, "damage")!
		
		if let subtypes = Weapon.subtypesFor(type)
		{
			let subtype = subtypes[self.subtype] as! [String : NSObject]
			let dmult = Int((subtype["damage multiplier"] as! NSNumber).intValue)
			dam = dam * dmult / 100
		}
		else
		{
			dam = dam * (100 + (50 * subtype / 13)) / 100
		}
		dam = dam * DataStore.getInt("Materials", material, "damage multiplier")! / 100
		
		return dam
	}
	var weight:Int
	{
		var wei = DataStore.getInt("Weapons", type, "weight")!
		
		if let subtypes = Weapon.subtypesFor(type)
		{
			let subtype = subtypes[self.subtype] as! [String : NSObject]
			let wmult = Int((subtype["weight multiplier"] as! NSNumber).intValue)
			wei = wei * wmult / 100
		}
		
		wei = wei * DataStore.getInt("Materials", material, "weight multiplier")! / 100
		
		return wei
	}
	var hitDamageMultiplier:Int
	{
		return DataStore.getInt("Weapons", type, "hit damage multiplier")!
	}
	var accuracy:Int
	{
		return DataStore.getInt("Weapons", type, "accuracy")!
	}
	var range:Int
	{
		return DataStore.getInt("Weapons", type, "range")!
	}
	var name:String
	{
		var nm:String
		if let subtypes = Weapon.subtypesFor(type)
		{
			let subtype = subtypes[self.subtype] as! [String : NSObject]
			nm = subtype["name"] as! String
		}
		else
		{
			nm = type
		}
		return "\(material) \(nm)"
	}
}