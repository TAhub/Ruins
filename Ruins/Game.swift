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
	case Stun
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
	func gameOver()
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
	var map:Map
	
	init()
	{
		map = Map(width: 30, height: 30)
	}
	
	init(mapStub:MapStub)
	{
		player = Creature(enemyType: "human player", level: mapStub.level, x: 0, y: 0)
		creatures.append(player)
		map = Map(mapStub: mapStub, player: player)
		
		//get all of the creatures from the map, and put them on the creatures list
		for y in 0..<map.height
		{
			for x in 0..<map.width
			{
				let tile = map.tileAt(x: x, y: y)
				if let cr = tile.creature
				{
					if !(cr === player)
					{
						creatures.append(cr)
					}
				}
			}
		}
	}
	
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
	
	func calculateVisibility()
	{
		map.calculateVisibility(x: player.x, y: player.y)
	}
	
	func validTarget(cr:Creature) -> Bool
	{
		//if either the attacker or the defender are on invisible tiles, no
		if !map.tileAt(x: cr.x, y: cr.y).visible || !map.tileAt(x: activeCreature.x, y: activeCreature.y).visible
		{
			return false
		}
		
		let distance = abs(cr.x - activeCreature.x) + abs(cr.y - activeCreature.y)
		let range = activeCreature.weapon.range
		let minRange = range == 1 ? 0 : 1
		return cr.good != activeCreature.good && distance <= range && distance > minRange
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
			
			//construct the path backwards
			var path = [(Int, Int)]()
			if abs(targetX - activeCreature.x) + abs(targetY - activeCreature.y) == 1
			{
				//just make a quick auto-constructed backwards path, no need to actually do pathfinding
				path.append((targetX, targetY))
			}
			else
			{
				var onX = targetX
				var onY = targetY
				repeat
				{
					path.append((onX, onY))
					
					let result = map.pathResultAt(x: onX, y: onY)!
					onX = result.backX
					onY = result.backY
				}
				while onX != activeCreature.x || onY != activeCreature.y
			}
			
			
			//make the move animation
			anim = Animation()
			anim!.movePath = [(Int, Int)]()
			
			//now follow the backwards path forwards
			for step in path.reverse()
			{
				anim!.movePath!.append(step)
				movePoints = max(movePoints - map.tileAt(x: step.0, y: step.1).entryCost, 0)
				
//				print("  PATH MOVING TO (\(step.0), \(step.1))")
				
				if false //TODO: if you stepped onto a trap
				{
					//TODO: add the trap attack anim to the animation
					//TODO: deal damage to the person who stepped on the trap
					//TODO: add damage numbers too
					//TODO: keep in mind that traps CAN kill
					
					
					//and immediately stop moving here
					targetX = step.0
					targetY = step.1
					movePoints = 0
					break
				}
			}
			
			
			//actually move there
			map.tileAt(x: activeCreature.x, y: activeCreature.y).creature = nil
			map.tileAt(x: targetX, y: targetY).creature = activeCreature
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
		case .Stun:
			//make a stun anim pop up
			anim = Animation()
			anim!.damageNumbers.append((activeCreature, "stunned"))
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
		print("SKIP")
		phaseOn = .EndTurn
		executePhase()
	}
	
	func attack(x x:Int, y:Int)
	{
		print("ATTACK")
		phaseOn = .Attack
		targetX = x
		targetY = y
		executePhase()
	}
	
	func makeMove(x x:Int, y:Int)
	{
		print("MOVE")
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
		print("TO NEXT PHASE from phase \(phaseOn)")
		
		var nextCreature = false
		switch(phaseOn)
		{
		case .Start: phaseOn = .PoisonDamage; nextCreature = true
		case .PoisonDamage: phaseOn = (activeCreature.stun > 0) ? GamePhase.Stun : GamePhase.MakeDecision
		case .MakeDecision:
			if !activeCreature.AIAction(self)
			{
				delegate?.inputDesired()
			}
			return
		case .Move: phaseOn = .MakeDecision
		case .Attack: phaseOn = .EndTurn
		case .Stun: phaseOn = .EndTurn
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
			
			if player.health == 0
			{
				delegate?.gameOver()
				return
			}
			
			if activeCreature === player
			{
				delegate?.uiUpdate()
			}
			
			print("Starting turn for creature #\(creatureOn) of type \(activeCreature.enemyType)!")
		}
		
		executePhase()
	}
}