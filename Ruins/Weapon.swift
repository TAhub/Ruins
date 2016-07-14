//
//  Weapon.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class Weapon
{
	let type:String
	let subtype:Int
	let material:String
	var health:Int
	
	init(type:String, material:String, level:Int)
	{
		self.type = type
		self.material = material
		self.health = 0
		
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
		
		//fill up the health
		self.health = self.maxHealth
	}
	
	init(saveDict d:NSDictionary)
	{
		self.type = d["type"] as! String
		self.material = d["material"] as! String
		self.subtype = Int((d["subtype"] as! NSNumber).intValue)
		self.health = Int((d["health"] as! NSNumber).intValue)
	}
	
	var saveDict:NSDictionary
	{
		var d = [NSString : NSObject]()
		
		d["type"] = type
		d["material"] = material
		d["subtype"] = subtype
		d["health"] = health
		
		return d
	}
	
	private static func subtypesFor(type:String) -> [NSDictionary]?
	{
		return DataStore.getArray("Weapons", type, "subtypes") as? [NSDictionary]
	}
	
	var broken:Bool
	{
		return health == 0 && maxHealth != 0
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
	var maxHealth:Int
	{
		if let hel = DataStore.getInt("Weapons", type, "health")
		{
			return hel * DataStore.getInt("Materials", material, "health multiplier")! / 100
		}
		return 0
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
	var strongVS:String?
	{
		return DataStore.getString("Materials", material, "strong vs")
	}
	var statusInflicted:String?
	{
		return DataStore.getString("Materials", material, "status inflicted")
	}
	var spriteName:String?
	{
		return DataStore.getString("Weapons", type, "sprite")
	}
	var spriteColor:UIColor
	{
		return DataStore.getColor("Materials", material, "color") ?? UIColor.blackColor()
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
	var description:String
	{
		let flavor = DataStore.getString("Weapons", type, "flavor")!
		return "\(flavor)\n\(damage * hitDamageMultiplier / 100) damage (\(damage) graze), \(accuracy)% accuracy, \(range) range, \(weight) weight"
	}
}