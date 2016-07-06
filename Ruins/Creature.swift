//
//  Creature.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation

let damMultiplier:Int = 8
let miscMultiplier:Int = 10

class Creature
{
	//MARK: position
	var x:Int
	var y:Int
	
	//MARK: identity
	var enemyType:String
	var good:Bool
	var level:Int
	
	//MARK: derived identity
	var racialGroup:String
	{
		return DataStore.getString("EnemyTypes", enemyType, "racial group")!
	}
	var appearanceGroup:String
	{
		return DataStore.getString("EnemyTypes", enemyType, "appearance group")!
	}
	
	//MARK: base stats
	var str:Int
	var dex:Int
	var cun:Int
	var wis:Int
	var end:Int
	
	//MARK: primary derived stats
	var meleePow:Int
	{
		return 2 * str
	}
	var meleeRes:Int
	{
		return end
	}
	var encumberanceBonus:Int
	{
		return str
	}
	var accuracy:Int
	{
		return dex + cun
	}
	var dodge:Int
	{
		return dex
	}
	var maxHealthBonus:Int
	{
		return end
	}
	var trapPow:Int
	{
		return 2 * cun
	}
	var trapRes:Int
	{
		return cun + end
	}
	var specialPow:Int
	{
		return wis
	}
	var specialRes:Int
	{
		return wis
	}
	
	//MARK: secondary derived stats
	var maxHealth:Int
	{
		return 100 * (100 + miscMultiplier * maxHealthBonus) / 100
	}
	var maxEncumberance:Int
	{
		return 100 * (100 + miscMultiplier * encumberanceBonus) / 100
	}
	var maxMovePoints:Int
	{
		return 4
	}
	
	//MARK: equipment
	var weapon:Weapon
	
	//MARK: variable stats
	var health:Int
	var encumberance:Int
	{
		//TODO: tally up total weight of items
		return 0
	}
	
	//MARK: initializers
	init(enemyType:String, level:Int, x:Int, y:Int)
	{
		//set position
		self.x = x
		self.y = y
		
		//set stats
		str = DataStore.getInt("EnemyTypes", enemyType, "strength")!
		dex = DataStore.getInt("EnemyTypes", enemyType, "dexterity")!
		cun = DataStore.getInt("EnemyTypes", enemyType, "cunning")!
		wis = DataStore.getInt("EnemyTypes", enemyType, "wisdom")!
		end = DataStore.getInt("EnemyTypes", enemyType, "endurance")!
		self.level = level
		
		//set equipment
		let weaponType = DataStore.getString("EnemyTypes", enemyType, "weapon")!
		let weaponMaterial = DataStore.getString("EnemyTypes", enemyType, "weapon material")!
		self.weapon = Weapon(type: weaponType, material: weaponMaterial, level: level)
		
		//set identity
		self.enemyType = enemyType
		good = false
		
		//initialize variables
		health = 0
		
		//fill up health (this has to happen after every variable is initialized)
		health = maxHealth
	}
	
	init(saveDict d:NSDictionary)
	{
		//load position
		x = Creature.intFromD(d, name: "x")
		y = Creature.intFromD(d, name: "y")
		
		//load stats
		str = Creature.intFromD(d, name: "str")
		dex = Creature.intFromD(d, name: "dex")
		cun = Creature.intFromD(d, name: "cun")
		wis = Creature.intFromD(d, name: "wis")
		end = Creature.intFromD(d, name: "end")
		level = Creature.intFromD(d, name: "level")
		
		//load equipment
		weapon = Weapon(saveDict: d["weapon"] as! NSDictionary)
		
		//load identity
		enemyType = d["enemyType"] as! String
		good = Creature.intFromD(d, name: "good") == 1
		
		//load variables
		health = Creature.intFromD(d, name: "health")
	}
	
	private static func intFromD(d:NSDictionary, name:String) -> Int
	{
		return Int((d[name] as! NSNumber).intValue)
	}
	
	var saveDict:NSDictionary
	{
		var d = [NSString : NSObject]()
		
		//save position
		d["x"] = x
		d["y"] = y
		
		//save stats
		d["str"] = str
		d["dex"] = dex
		d["cun"] = cun
		d["wis"] = wis
		d["end"] = end
		d["level"] = level
		
		//save equipment
		d["weapon"] = weapon.saveDict
		
		//save identity
		d["enemyType"] = enemyType
		d["good"] = good ? 1 : 0
		
		//save variables
		d["health"] = health
		
		return d
	}
}

//TODO: move this elsewhere
postfix operator ++ {}

postfix func ++(inout x: Int) -> Int {
	x += 1
	return (x - 1)
}