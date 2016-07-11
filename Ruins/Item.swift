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
	
	init(weapon:Weapon)
	{
		self.weapon = weapon
		self.armor = nil
	}
	init (armor:Armor)
	{
		self.weapon = nil
		self.armor = armor
	}
	
	init(saveDict d:NSDictionary)
	{
		if let weaponDict = d["weapon"] as? NSDictionary
		{
			self.weapon = Weapon(saveDict: weaponDict)
			self.armor = nil
		}
		else if let armorDict = d["armor"] as? NSDictionary
		{
			self.weapon = nil
			self.armor = Armor(saveDict: armorDict)
		}
		else
		{
			//TODO: load consumable
			self.weapon = nil
			self.armor = nil
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
			//TODO: save consumable
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
		return 100 //TODO: return weight of usable
	}
	
	var name:String
	{
		if let weapon = weapon
		{
			return weapon.name
		}
		if let armor = armor
		{
			return armor.name
		}
		return "TEMP" //TODO: return name of usable
	}
}