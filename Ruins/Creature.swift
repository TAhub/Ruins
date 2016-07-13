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

let aiBadlyInjuredPoint:Int = 20

class Creature
{
	//MARK: position
	var x:Int
	var y:Int
	
	//MARK: identity
	var enemyType:String
	var good:Bool
	var awake:Bool
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
		return end + (armor?.meleeResistance ?? 0)
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
		return dex + (armor?.dodge ?? 0)
	}
	var maxHealthBonus:Int
	{
		return end + (armor?.maxHealthBonus ?? 0)
	}
	var trapPow:Int
	{
		return 2 * cun
	}
	var trapRes:Int
	{
		return cun + end + (armor?.trapResistance ?? 0)
	}
	var specialPow:Int
	{
		return wis
	}
	var specialRes:Int
	{
		return wis + (armor?.specialResistance ?? 0)
	}
	
	var boss:Bool
	{
		return DataStore.getBool("EnemyTypes", enemyType, "boss")
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
	var armor:Armor?
	var inventory = [Item]()
	
	//MARK: variable stats
	var shake:Int
	var poison:Int
	var stun:Int
	var health:Int
	var encumberance:Int
	{
		var wei = weapon.weight + (armor?.weight ?? 0)
		for item in inventory
		{
			wei += item.weight
		}
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
		if let armorType = DataStore.getString("EnemyTypes", enemyType, "armor")
		{
			self.armor = Armor(type: armorType, level: level)
		}
		
		//set identity
		self.enemyType = enemyType
		good = DataStore.getBool("EnemyTypes", enemyType, "good")
		awake = false
		
		//initialize variables
		health = 0
		shake = 0
		stun = 0
		poison = 0
		
		
		//TODO: if you're a boss, automatically raise your stats based on your level
		
		
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
		if let armorDict = d["armor"] as? NSDictionary
		{
			armor = Armor(saveDict: armorDict)
		}
		
		//load identity
		enemyType = d["enemyType"] as! String
		good = Creature.intFromD(d, name: "good") == 1
		awake = Creature.intFromD(d, name: "awake") == 1
		
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
		if let armor = armor
		{
			d["armor"] = armor.saveDict
		}
		
		//save identity
		d["enemyType"] = enemyType
		d["good"] = good ? 1 : 0
		d["awake"] = awake ? 1 : 0
		
		//save variables
		d["health"] = health
		d["shake"] = shake
		d["poison"] = poison
		d["stun"] = stun
		
		return d
	}
	
	//MARK: operations
	
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
		//if the AI is asleep, wake them
		target.awake = true
		
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
				print("\(status) inflicted!")
			}
		}
		
		//actually apply the damage
		health = min(max(health - myDamage, 0), maxHealth)
		target.health = min(max(target.health - theirDamage, 0), maxHealth)
		
		//degrade equip,ent
		weapon.health = max(weapon.health - 1, 0)
		if weapon.broken
		{
			//TODO: break sound effect
			weapon = Weapon(type: "unarmed", material: "neutral", level: 0)
		}
		if let armor = target.armor
		{
			armor.health = max(armor.health - 1, 0)
			if armor.broken
			{
				//TODO: break sound effect
				target.armor = nil
			}
		}
		
		return (myDamage:myDamage, theirDamage:theirDamage)
	}
	
	func AIAction(game:Game) -> Bool
	{
		if let AI = AI
		{
			//AIs won't do anything until you see them once
			if game.map.tileAt(x: x, y: y).visible
			{
				awake = true
			}
			
			if !awake
			{
				game.skipAction()
				return true
			}
			
			
			//if you can move, check to see if you want to
			if game.movePoints > 0
			{
				//get AI variables for fitness
				let inRangeFitness = DataStore.getInt("AIs", AI, "fitness gain for being in range")!
				let inRangeFitnessFlee = DataStore.getInt("AIs", AI, "fitness gain for being in range when fleeing")!
				let noMoveFitness = DataStore.getInt("AIs", AI, "fitness gain for not having to move")!
				let trapFitness = DataStore.getInt("AIs", AI, "fitness gain for trap")!
				let fitnessPerTileToPlayer = DataStore.getInt("AIs", AI, "fitness gain per tile to player")!
				let fitnessPerTileToPlayerFlee = DataStore.getInt("AIs", AI, "fitness gain per tile to player when fleeing")!
				let randomFitness = DataStore.getInt("AIs", AI, "random fitness gain")!
				
				//run away if you're really hurt, or if you were disarmed
				let flee = health * 100 < maxHealth * aiBadlyInjuredPoint || weapon.type == "unarmed"
				
				
				//figure out where you can move to
				game.map.pathfinding(self, movePoints: game.movePoints)
				
				//now examine each tile
				var bestTileFitness = -99999
				var bestTile = (x, y)
				let tilesAccessable = game.map.tilesAccessable
				let oldX = x
				let oldY = y
				for tile in tilesAccessable
				{
					//temporarily move there
					x = tile.0
					y = tile.1
					
					//get fitness for that tile
					let distance = abs(game.player.x - x) + abs(game.player.y - y)
					
					var fitness = Int(arc4random_uniform(UInt32(randomFitness)))
					if false //TODO: if there's a trap
					{
						fitness += trapFitness
					}
					fitness += (flee ? fitnessPerTileToPlayerFlee : fitnessPerTileToPlayer) * distance
					if game.validTarget(game.player)
					{
						fitness += flee ? inRangeFitnessFlee : inRangeFitness
					}
					if x == oldX && y == oldY
					{
						fitness += noMoveFitness
					}
					
					if fitness > bestTileFitness
					{
						bestTileFitness = fitness
						bestTile = tile
					}
				}
				x = oldX
				y = oldY
				
				//if the tile you want to be in isn't the one you are in, move
				if bestTile.0 != x || bestTile.1 != y
				{
					game.movePoints = 0
					game.makeMove(x: bestTile.0, y: bestTile.1)
					return true
				}
			}
			
			//if you didn't decide to move, or you did and this has now asked you for your AI action, take an action
			
			//attack if you're in range
			if weapon.type != "unarmed" && game.validTarget(game.player)
			{
				game.attack(x: game.player.x, y: game.player.y)
			}
			else
			{
				game.skipAction()
			}
			
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