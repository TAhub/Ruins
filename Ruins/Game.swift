//
//  Game.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation


enum GamePhase:Int
{
	case Start
	case PoisonDamage
	case MakeDecision
	case Move
	case Attack
	case EndTurn
}

class Animation
{
	var damageNumbers = [(Creature, String)]()
	var movePath:[(Int, Int)]?
	var attackTarget:(Int, Int)?
	var attackType:String?
}

protocol GameDelegate
{
	func playAnimation(anim:Animation)
	func inputDesired()
	func uiUpdate()
}

class Game
{
	var player:Creature!
	var phaseOn:GamePhase = .Start
	var creatureOn:Int = -1
	var delegate:GameDelegate?
	var creatures = [Creature]()
	var movePoints:Int = 0
	var targetX:Int = 0
	var targetY:Int = 0
	var map = Map(width: 30, height: 30)
	
	func addEnemy(creature:Creature)
	{
		creatures.append(creature)
		map.tileAt(x: creature.x, y: creature.y).creature = creature
	}
	
	func addPlayer(creature:Creature)
	{
		self.player = creature
		addEnemy(creature)
	}
	
	func executePhase()
	{
		var anim:Animation?
		
		//execute the current phase
		switch(phaseOn)
		{
		case .Move:
			//TODO: to get the path,
			//if it's a single tile of movement, you just make the path like I am now
			//otherwise, I should save the last pathfinding result and use the stored path from that
			
			//TODO: check for problems on the way over the path
			//IE if you walk over a trap, stop the path right there, add a "hurt by trap" anim to the animation, and a damage number
			
			//make the move animation
			anim = Animation()
			anim!.movePath = [(activeCreature.x, activeCreature.y), (targetX, targetY)]
			
			//actually move there
			map.tileAt(x: activeCreature.x, y: activeCreature.y).creature = nil
			map.tileAt(x: targetX, y: targetY).creature = activeCreature
			movePoints -= abs(activeCreature.x - targetX) + abs(activeCreature.y - targetY)
			activeCreature.x = targetX
			activeCreature.y = targetY
			
			if activeCreature === player
			{
				delegate?.uiUpdate()
			}
			
		case .Attack:
			//TODO: get the target based on the grid, rather than by going through the creature list
			var target:Creature!
			for creature in creatures
			{
				if creature.x == targetX && creature.y == targetY
				{
					target = creature
					break
				}
			}
			let damages = activeCreature.attack(target)
			
			anim = Animation()
			anim!.attackTarget = (targetX, targetY)
			anim!.attackType = "whatever" //TODO: this value isn't used yet
			anim!.damageNumbers.append((target, "\(damages.theirDamage)"))
			if damages.myDamage > 0
			{
				anim!.damageNumbers.append((activeCreature, "\(damages.myDamage)"))
			}
			
			if target === player || activeCreature === player
			{
				delegate?.uiUpdate()
			}
			
			if target.health == 0
			{
				map.tileAt(x: target.x, y: target.y).creature = nil
			}
			
		case .PoisonDamage:
			if let damage = activeCreature.poisonTick()
			{
				anim = Animation()
				anim!.damageNumbers.append((activeCreature, "\(damage)"))
				
				if activeCreature === player
				{
					delegate?.uiUpdate()
				}
			}
		case .EndTurn:
			activeCreature.endTurn()
		default: break
		}
		
		if let anim = anim
		{
			delegate?.playAnimation(anim)
		}
		else
		{
			toNextPhase()
		}
	}
	
	func skipAction()
	{
		phaseOn = .EndTurn
		executePhase()
	}
	
	func attack(x x:Int, y:Int)
	{
		phaseOn = .Attack
		targetX = x
		targetY = y
		executePhase()
	}
	
	func makeMove(x x:Int, y:Int)
	{
		phaseOn = .Move
		targetX = x
		targetY = y
		executePhase()
	}
	
	var activeCreature:Creature
	{
		return creatures[creatureOn]
	}
	
	func toNextPhase()
	{
		var nextCreature = false
		switch(phaseOn)
		{
		case .Start: phaseOn = .PoisonDamage; nextCreature = true
		case .PoisonDamage: phaseOn = (activeCreature.stun > 0) ? GamePhase.EndTurn : GamePhase.MakeDecision
		case .MakeDecision:
			if !activeCreature.AIAction(self)
			{
				delegate?.inputDesired()
			}
			return
		case .Move: phaseOn = .MakeDecision
		case .Attack: phaseOn = .EndTurn
		case .EndTurn: phaseOn = .PoisonDamage; nextCreature = true
		}
		
		while (nextCreature)
		{
			creatureOn = (creatureOn + 1) % creatures.count
			if creatureOn == 0
			{
				//cull the creature list
				creatures = creatures.filter() { $0.health > 0 }
			}
			movePoints = activeCreature.maxMovePoints
			nextCreature = activeCreature.health == 0
			
			//TODO: if the player is dead, notify game over
		}
		
		executePhase()
	}
}