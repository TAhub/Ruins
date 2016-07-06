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
	case DoAction
	case EndTurn
}

class Animation
{
	//TODO: this should contain enough data to do the following things
	//	ONE: move a creature over a given path
	//	TWO: have one creature do a specific attack anim on another (including damage numbers over both afterwards)
	//TODO: whenever there is an animation, the top UI should update
}

class Game
{
	var phaseOn:GamePhase = .Start
	var creatureOn:Int = -1
	
	func executePhase()
	{
		var anim:Animation?
		
		//TODO: execute the current phase
		
		if let anim = anim
		{
			//TODO: run the anim, and then call toNextPhase() once it's over
		}
		else
		{
			toNextPhase()
		}
	}
	
	func toNextPhase()
	{
		var nextCreature = false
		switch(phaseOn)
		{
		case .Start: phaseOn = .PoisonDamage; nextCreature = true
		case .PoisonDamage: phaseOn = .MakeDecision
		case .MakeDecision: break //TODO: this phase is manually left, via AI decision or player input
		case .Move: phaseOn = .MakeDecision
		case .DoAction: phaseOn = .EndTurn
		case .EndTurn: phaseOn = .PoisonDamage; nextCreature = true
		}
		
		if nextCreature
		{
			//TODO: go to the next creature in order
		}
	}
}