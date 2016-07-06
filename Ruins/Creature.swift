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
	var movePoints:Int
	var encumberance:Int
	{
		//TODO: tally up total weight of items
		return 0
	}
	
	//MARK: initializers
	init(enemyType:String, level:Int)
	{
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
		movePoints = 0
		
		//fill up health (this has to happen after every variable is initialized)
		health = maxHealth
	}
}