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
}

class Game
{
	var phaseOn:GamePhase = .Start
	var creatureOn:Int = -1
	var delegate:GameDelegate?
	var creatures = [Creature]()
	var movePoints:Int = 0
	var targetX:Int = 0
	var targetY:Int = 0
	
	func executePhase()
	{
		var anim:Animation?
		
		//execute the current phase
		switch(phaseOn)
		{
		case .Move:
			//TODO: move for real, instead of sliding direcly there
			
			//make the move animation
			anim = Animation()
			anim!.movePath = [(activeCreature.x, activeCreature.y), (targetX, targetY)]
			
			//actually move there
			movePoints -= abs(activeCreature.x - targetX) + abs(activeCreature.y - targetY)
			activeCreature.x = targetX
			activeCreature.y = targetY
			
		case .Attack:
			//TODO: get the target based on targetX and targetY
			let target = creatures[1]
			let damages = activeCreature.attack(target)
			
			anim = Animation()
			anim!.attackTarget = (targetX, targetY)
			anim!.attackType = "whatever" //TODO: this value isn't used yet
			anim!.damageNumbers.append((target, "\(damages.theirDamage)"))
			if damages.myDamage > 0
			{
				anim!.damageNumbers.append((activeCreature, "\(damages.myDamage)"))
			}
		case .PoisonDamage: break
		case .EndTurn: break
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
		case .PoisonDamage: phaseOn = .MakeDecision
		case .MakeDecision:
			if (false)
			{
				//TODO: if the active person is an AI, run their AI script
			}
			else
			{
				delegate?.inputDesired()
			}
			
			return
		case .Move: phaseOn = .MakeDecision
		case .Attack: phaseOn = .EndTurn
		case .EndTurn: phaseOn = .PoisonDamage; nextCreature = true
		}
		
		if nextCreature
		{
			creatureOn = (creatureOn + 1) % creatures.count
			movePoints = activeCreature.maxMovePoints
		}
		
		executePhase()
	}
}