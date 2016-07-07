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
let weakDamMult:Int = 40
let poisonDam:Int = 5
let weaponStatusChance:Int = 20
let weaponPoisonLength:Int = 5
let weaponStunLength:Int = 1
let weaponShakeLength:Int = 2

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
	var AI:String?
	{
		return DataStore.getString("EnemyTypes", enemyType, "AI")
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
	var shake:Int
	var poison:Int
	var stun:Int
	var health:Int
	var encumberance:Int
	{
		var wei = weapon.weight
		//TODO: account for armor weight too
		//TODO: tally up inventory weight I guess
		return wei
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
		shake = 0
		stun = 0
		poison = 0
		
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
		shake = Creature.intFromD(d, name: "shake")
		poison = Creature.intFromD(d, name: "poison")
		stun = Creature.intFromD(d, name: "stun")
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
		d["shake"] = shake
		d["poison"] = poison
		d["stun"] = stun
		
		return d
	}
	
	//TODO: operations
	
	func poisonTick() -> Int?
	{
		if poison > 0 && health > 1
		{
			let poisonDamage = min(maxHealth * poisonDam / 100, health - 1)
			health -= poisonDamage
			return poisonDamage
		}
		return nil
	}
	
	func endTurn()
	{
		poison = max(poison - 1, 0)
		stun = max(stun - 1, 0)
		shake = max(shake - 1, 0)
	}
	
	func attack(target:Creature) -> (myDamage:Int, theirDamage:Int)
	{
		//calculate how much damage people are taking
		let myDamage:Int
		let theirDamage:Int
		
		//are they weak to your weapon?
		let isWeak = (weapon.strongVS ?? "") == target.racialGroup
		
		//first, how much damage does your weapon do?
		var wDamage = weapon.damage
		if weapon.range == 1
		{
			wDamage = wDamage * (100 + damMultiplier * (meleePow - (isWeak ? 0 : target.meleeRes))) / 100
		}
		else if isWeak
		{
			wDamage = wDamage * (100 + weakDamMult) / 100
		}
		
		//next, find out if it's a hit or a graze
		if shake == 0
		{
			var hitChance = weapon.accuracy
			hitChance = hitChance * (100 + miscMultiplier * (accuracy - target.dodge)) / 100
			
			if Int(arc4random_uniform(100)) < hitChance
			{
				//it was a hit!
				//apply the hit damage bonus
				wDamage = wDamage * weapon.hitDamageMultiplier / 100
			}
		}
		
		//now, the wDamage is the damage you do to them
		theirDamage = wDamage
		myDamage = 0 //TODO: if the weapon is vampiric, give yourself some health (negative damage) too
		
		//apply status effects
		if let status = weapon.statusInflicted
		{
			if Int(arc4random_uniform(100)) <= weaponStatusChance && !DataStore.getBool("RacialGroups", target.racialGroup, "\(status) immunity")
			{
				switch(status)
				{
				case "stun": target.stun += weaponStunLength
				case "shake": target.shake += weaponShakeLength
				case "poison": target.poison += weaponPoisonLength
				default: break
				}
			}
		}
		
		//actually apply the damage
		health = min(max(health - myDamage, 0), maxHealth)
		target.health = min(max(target.health - theirDamage, 0), maxHealth)
		
		return (myDamage:myDamage, theirDamage:theirDamage)
	}
	
	func AIAction(game:Game) -> Bool
	{
		if let AI = AI
		{
			//TODO: pathfinding
			//	use A* over a wide-ish area (like at least a screen in radius)
			//	keep track of both weight and movepoints remaining
			//	weigh every tile using the AI values
			//		(movepoint cost of tile) * (weight per move point)
			//		if there is a world-placed trap, +(world trap weight)
			//		if there is a player-placed trap, +(player trap weight)
			//	your goal is to get to a tile you can use your weapon from
			//	so if you actually find one that you can walk into in one turn? stop the search and go there asap
			
			
			//TODO: for now, just attack position (2, 1)
			game.attack(x: 2, y: 1)
			
			return true
		}
		return false
	}
}

//TODO: move this elsewhere
postfix operator ++ {}

postfix func ++(inout x: Int) -> Int {
	x += 1
	return (x - 1)
}