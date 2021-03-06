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
	case Special
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
	func trapCreated(trap:Trap, x:Int, y:Int)
}

class Game
{
	var player:Creature!
	var phaseOn:GamePhase = .Start
	var creatureOn:Int = -1
	var delegate:GameDelegate?
	var creatures = [Creature]()
	var movePoints:Int = 0
	var hasAction:Bool = false
	var targetX:Int = 0
	var targetY:Int = 0
	var targetSpecial:String?
	var map:Map
	
	init()
	{
		map = Map(width: 30, height: 30)
	}
	
	init(mapStub:MapStub)
	{
		player = Creature(enemyType: "fairy player", level: mapStub.level, x: 0, y: 0)
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
	
	func addTrap(trap:Trap, x:Int, y:Int)
	{
		let tile = map.tileAt(x: x, y: y)
		tile.trap = trap
		delegate?.trapCreated(trap, x: x, y: y)
	}
	
	func calculateVisibility()
	{
		map.calculateVisibility(x: player.x, y: player.y)
	}
	
	func validTarget(cr:Creature) -> Bool
	{
		//if you don't have an action, you can't attack
		if !hasAction
		{
			return false
		}
		
		//if either the attacker or the defender are on invisible tiles, no
		if !map.tileAt(x: cr.x, y: cr.y).visible || !map.tileAt(x: activeCreature.x, y: activeCreature.y).visible
		{
			return false
		}
		
		if cr.good == activeCreature.good
		{
			//they are on your side
			return false
		}
		
		if targetSpecial != nil
		{
			//specials have unlimited range
			return true
		}
		
		let distance = abs(cr.x - activeCreature.x) + abs(cr.y - activeCreature.y)
		let range = activeCreature.weapon.range
		let minRange = range == 1 ? 0 : 1
		return distance <= range && distance > minRange
	}
	
	func executePhase()
	{
		var anim:Animation?
		
		func attackMisc(damages:(myDamage: Int, theirDamage: Int), target:Creature)
		{
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
			
			if target.dead
			{
				map.tileAt(x: target.x, y: target.y).creature = nil
			}
		}
		
		//execute the current phase
		switch(phaseOn)
		{
		case .Move:
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
				let tile = map.tileAt(x: step.0, y: step.1)
				
				anim!.movePath!.append(step)
				movePoints = max(movePoints - tile.entryCost, 0)
				
//				print("  PATH MOVING TO (\(step.0), \(step.1))")
				
				print("IS THERE A TRAP ON TILE \(step.0), \(step.1)????")
				if let trap = tile.trap
				{
					print("SET OFF TRAP OF TYPE \(trap.type)!")
					
					//set off the trap
					let damage = trap.activate(activeCreature)
					tile.trap = nil
					
					//give it a trap attack animation
					anim!.attackType = "trap" //TODO: trap-specific animation
					anim!.damageNumbers.append((activeCreature, "\(damage)"))
					
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
			
		case .Special:
			let target:Creature = map.tileAt(x: targetX, y: targetY).creature!
			let damages = activeCreature.useSpecial(target, special: targetSpecial!)
			attackMisc(damages, target: target)
			targetSpecial = nil
			
		case .Attack:
			let target:Creature = map.tileAt(x: targetX, y: targetY).creature!
			let damages = activeCreature.attack(target)
			attackMisc(damages, target: target)
			
		case .PoisonDamage:
			if let damage = activeCreature.poisonTick()
			{
				anim = Animation()
				anim!.damageNumbers.append((activeCreature, "\(damage)"))
				
				if activeCreature === player
				{
					delegate?.uiUpdate()
				}
				
				print("TAKING \(damage) FROM POISON")
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
	
	func special(x x:Int, y:Int)
	{
		print("SPECIAL")
		phaseOn = .Special
		targetX = x
		targetY = y
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
		case .Move: phaseOn = hasAction ? .MakeDecision : .EndTurn
		case .Attack: phaseOn = .EndTurn
		case .Special: phaseOn = .EndTurn
		case .Stun: phaseOn = .EndTurn
		case .EndTurn: phaseOn = .PoisonDamage; nextCreature = true
		}
		
		while (nextCreature)
		{
			creatureOn = (creatureOn + 1) % creatures.count
			if creatureOn == 0
			{
				//cull the creature list
				creatures = creatures.filter() { !$0.dead }
			}
			movePoints = activeCreature.maxMovePoints
			hasAction = true
			nextCreature = activeCreature.dead
			
			if player.dead
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