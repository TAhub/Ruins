//
//  Trap.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/13/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation

class Trap
{
	let trapPower:Int
	let type:String
	let good:Bool
	var dead:Bool
	
	init(type:String, trapPower:Int, good:Bool)
	{
		self.type = type
		self.trapPower = trapPower
		self.good = good
		dead = false
	}
	
	func damage(trapResistance:Int) -> Int
	{
		let baseDamage = DataStore.getInt("Traps", type, "damage")!
		return baseDamage * max(100 + (trapPower - trapResistance) * damMultiplier, minMultiplier) / 100
	}
	
	func activate(creature:Creature) -> Int
	{
		self.dead = true
		
		let damage = self.damage(creature.trapRes)
		creature.health = max(0, creature.health - damage)
		
		//TODO: status effects
		if let stun = DataStore.getInt("Traps", type, "stun")
		{
			creature.stun += (creature.stun == 0 ? 1 : 0) + stun
		}
		if let shake = DataStore.getInt("Traps", type, "shake")
		{
			creature.shake += (creature.shake == 0 ? 1 : 0) + shake
		}
		if let poison = DataStore.getInt("Traps", type, "poison")
		{
			creature.poison += (creature.poison == 0 ? 1 : 0) + poison
		}
		
		return damage
	}
}