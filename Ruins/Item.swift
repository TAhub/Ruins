//
//  Item.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/11/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation

class Item
{
	let weapon:Weapon?
	let armor:Armor?
	let usable:String?
	var number:Int!
	
	init(weapon:Weapon)
	{
		self.weapon = weapon
		self.armor = nil
		self.usable = nil
	}
	init(armor:Armor)
	{
		self.weapon = nil
		self.armor = armor
		self.usable = nil
	}
	init(usable:String)
	{
		self.weapon = nil
		self.armor = nil
		self.usable = usable
		self.number = 1
	}
	
	init(saveDict d:NSDictionary)
	{
		if let weaponDict = d["weapon"] as? NSDictionary
		{
			self.weapon = Weapon(saveDict: weaponDict)
			self.armor = nil
			self.usable = nil
		}
		else if let armorDict = d["armor"] as? NSDictionary
		{
			self.weapon = nil
			self.armor = Armor(saveDict: armorDict)
			self.usable = nil
		}
		else
		{
			self.weapon = nil
			self.armor = nil
			self.usable = d["usable"] as? String
			self.number = Int((d["number"] as! NSNumber).intValue)
		}
	}
	
	var saveDict:NSDictionary
	{
		var d = [NSString : NSObject]()
		
		if let weapon = weapon
		{
			d["weapon"] = weapon.saveDict
		}
		else if let armor = armor
		{
			d["armor"] = armor.saveDict
		}
		else
		{
			d["usable"] = usable
			d["number"] = number
		}
		
		return d
	}
	
	//MARK: accessors
	
	var weight:Int
	{
		if let weapon = weapon
		{
			return weapon.weight
		}
		if let armor = armor
		{
			return armor.weight
		}
		return DataStore.getInt("Usables", usable!, "weight")! * number
	}
	
	var name:String
	{
		if let weapon = weapon
		{
			return "\(weapon.name)  \(weapon.health)/\(weapon.maxHealth)"
		}
		if let armor = armor
		{
			return "\(armor.name)  \(armor.health)/\(armor.maxHealth)"
		}
		return "\(usable!)\(number == 1 ? "" : " x\(number)")"
	}
	
	var description:String
	{
		if let weapon = weapon
		{
			return weapon.description
		}
		if let armor = armor
		{
			return armor.description
		}
		if let usable = usable
		{
			var stats = [String]()
			if let heals = heals
			{
				stats.append("Heals \(heals)")
			}
			if cures
			{
				stats.append("Cures")
			}
			if let trap = trap
			{
				let trapDamage = DataStore.getInt("Traps", trap, "damage")!
				let trapStun = DataStore.getBool("Traps", trap, "stun")
				let trapShake = DataStore.getBool("Traps", trap, "shake")
				let trapPoison = DataStore.getBool("Traps", trap, "poison")
				var effectDesc = ""
				if trapStun
				{
					effectDesc += "stuns"
				}
				if trapShake
				{
					if !effectDesc.isEmpty
					{
						effectDesc += ", "
						if !trapPoison
						{
							effectDesc += "and "
						}
					}
					effectDesc += "shakes"
				}
				if trapPoison
				{
					if !effectDesc.isEmpty
					{
						effectDesc += ", and "
					}
					effectDesc += "poisons"
				}
				
				stats.append("Lays a \(trapDamage)-damage trap\(effectDesc.isEmpty ? "" : " that ")\(effectDesc)")
			}
			stats.append("\(weight) \(number > 1 ? "total " : "")weight")
			let flavor = DataStore.getString("Usables", usable, "flavor")!
			let joined = stats.joinWithSeparator(". ")
			return "\(flavor)\n\(joined)."
		}
		assertionFailure()
		return "NO"
	}
	
	var cures:Bool
	{
		if let usable = usable
		{
			return DataStore.getBool("Usables", usable, "cures")
		}
		return false
	}
	
	var trap:String?
	{
		if let usable = usable
		{
			return DataStore.getString("Usables", usable, "trap")
		}
		return nil
	}
	
	var heals:Int?
	{
		if let usable = usable
		{
			return DataStore.getInt("Usables", usable, "heals")
		}
		return nil
	}
}