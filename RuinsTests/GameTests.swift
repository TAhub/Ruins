//
//  GameTests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class GameTests: XCTestCase, GameDelegate {
	
	var game:Game!
	var inputDesiredCalled = 0
	var playAnimationCalled = 0
	var firstCharacter:Creature!
	var secondCharacter:Creature!
	var lastAnimation:Animation?
	
    override func setUp() {
        super.setUp()
		
		game = Game()
		game.delegate = self
		inputDesiredCalled = 0
		playAnimationCalled = 0
		
		firstCharacter = Creature(enemyType: "test creature", level: 1, x: 1, y: 1)
		game.creatures.append(firstCharacter)
		secondCharacter = Creature(enemyType: "test creature", level: 1, x: 2, y: 1)
		game.creatures.append(secondCharacter)
    }
	
	func testStageProgression()
	{
		XCTAssertEqual(game.phaseOn, GamePhase.Start)
		XCTAssertEqual(game.creatureOn, -1)
		XCTAssertEqual(game.movePoints, 0)
		
		//since person 1 isn't poisoned, it should skip straight through poisonDamage without displaying any anims
		game.executePhase()
		
		XCTAssertEqual(game.creatureOn, 0)
		XCTAssertEqual(inputDesiredCalled, 1)
		XCTAssertEqual(game.phaseOn, GamePhase.MakeDecision)
		XCTAssertEqual(game.movePoints, 4)
		XCTAssertEqual(firstCharacter.x, 1)
		XCTAssertEqual(firstCharacter.y, 1)
		
		//now try to move one tile down; this should cost 1 move point and try to play an animation
		game.makeMove(x: 1, y: 2)
		
		XCTAssertEqual(game.creatureOn, 0)
		XCTAssertEqual(inputDesiredCalled, 1)
		XCTAssertEqual(playAnimationCalled, 1)
		XCTAssertEqual(game.phaseOn, GamePhase.Move)
		XCTAssertEqual(game.movePoints, 3)
		XCTAssertEqual(firstCharacter.x, 1)
		XCTAssertEqual(firstCharacter.y, 2)
		
		//also check to make sure the animation has a reasonable path
		//man, comparing arrays of tuples is really annoying
		let animPath = (lastAnimation ?? Animation()).movePath ?? [(Int, Int)]()
		let desiredPath = [(1, 1), (1, 2)]
		XCTAssertEqual(animPath.count, desiredPath.count)
		for i in 0..<desiredPath.count
		{
			XCTAssertTrue(animPath[i] ?? (0, 0) == desiredPath[i])
		}
		
		//now signal that you have completed the animation, which should move you back to MakeDecision and ask for more input
		game.toNextPhase()
		
		XCTAssertEqual(game.creatureOn, 0)
		XCTAssertEqual(inputDesiredCalled, 2)
		XCTAssertEqual(playAnimationCalled, 1)
		XCTAssertEqual(game.phaseOn, GamePhase.MakeDecision)
		XCTAssertEqual(game.movePoints, 3)
		XCTAssertEqual(firstCharacter.x, 1)
		XCTAssertEqual(firstCharacter.y, 2)
		
		//now skip your action (saving acting for a different test), which should move this to the next creature and start the phases anew
		game.skipAction()
		
		XCTAssertEqual(game.creatureOn, 1)
		XCTAssertEqual(inputDesiredCalled, 3)
		XCTAssertEqual(playAnimationCalled, 1)
		XCTAssertEqual(game.phaseOn, GamePhase.MakeDecision)
		XCTAssertEqual(game.movePoints, 4)
		XCTAssertEqual(firstCharacter.x, 1)
		XCTAssertEqual(firstCharacter.y, 2)
	}
	
	func testAttacking()
	{
		game.executePhase()
		
		game.attack(x: 2, y: 1)
		
		XCTAssertEqual(inputDesiredCalled, 1)
		XCTAssertEqual(playAnimationCalled, 1)
		XCTAssertEqual(game.phaseOn, GamePhase.Attack)
		XCTAssertEqual(game.creatureOn, 0)
		XCTAssertLessThan(secondCharacter.health, 200)
		
		//make sure the animation has the right stuff inside it too
		let lA = lastAnimation ?? Animation()
		XCTAssertGreaterThan(lA.damageNumbers.count, 0)
		XCTAssertTrue(lA.attackTarget ?? (0, 0) == (2, 1))
		XCTAssertNotNil(lA.attackType)
		XCTAssertNil(lA.movePath)
		
		//and once you resume, it should go to the next guy
		game.toNextPhase()
		
		XCTAssertEqual(game.creatureOn, 1)
		XCTAssertEqual(game.phaseOn, GamePhase.MakeDecision)
	}
	
	func testPoisonTick()
	{
		firstCharacter.poison = 100
		
		game.executePhase()
		
		//poison should stop this at the poison phase, with an anim
		XCTAssertEqual(game.phaseOn, GamePhase.PoisonDamage)
		XCTAssertEqual(game.creatureOn, 0)
		XCTAssertEqual(playAnimationCalled, 1)
		XCTAssertEqual(inputDesiredCalled, 0)
		XCTAssertEqual(firstCharacter.health, 190)
		
		//make sure the animation has the right stuff inside it too
		let lA = lastAnimation ?? Animation()
		XCTAssertEqual(lA.damageNumbers.count, 1)
		if let dNum = lA.damageNumbers.first
		{
			XCTAssertTrue(dNum.0 === firstCharacter)
			XCTAssertEqual(dNum.1, "10")
		}
	}
	
	func testStunSkipsTurn()
	{
		firstCharacter.stun = 10
		game.executePhase()
		XCTAssertEqual(game.creatureOn, 1)
		XCTAssertEqual(game.phaseOn, GamePhase.MakeDecision)
		XCTAssertEqual(inputDesiredCalled, 1)
	}
	
	func testEndPhaseTicksStatuses()
	{
		game.executePhase()
		
		//apply statuses while waiting for input, to make sure they don't change the order of execution
		firstCharacter.poison = 10
		firstCharacter.stun = 9
		firstCharacter.shake = 8
		
		game.skipAction()
		
		//now, it should be the next person's turn and the statuses should have their duration down by 1
		XCTAssertEqual(game.creatureOn, 1)
		XCTAssertEqual(firstCharacter.poison, 9)
		XCTAssertEqual(firstCharacter.stun, 8)
		XCTAssertEqual(firstCharacter.shake, 7)
	}
	
	//MARK: delegate methods
	
	func inputDesired()
	{
		inputDesiredCalled += 1
	}
	func playAnimation(anim: Animation)
	{
		playAnimationCalled += 1
		lastAnimation = anim
	}
}