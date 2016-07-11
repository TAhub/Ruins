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
	var uiUpdateCalled = 0
	var gameOverCalled = 0
	var firstCharacter:Creature!
	var secondCharacter:Creature!
	var lastAnimation:Animation?
	
    override func setUp() {
        super.setUp()
		
		game = Game()
		game.delegate = self
		inputDesiredCalled = 0
		playAnimationCalled = 0
		uiUpdateCalled = 0
		gameOverCalled = 0
		
		firstCharacter = Creature(enemyType: "test creature", level: 1, x: 1, y: 1)
		game.addPlayer(firstCharacter)
		secondCharacter = Creature(enemyType: "test creature", level: 1, x: 2, y: 1)
		game.addEnemy(secondCharacter)
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
		let desiredPath = [(1, 2)]
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
	
	func testValidTarget()
	{
		game.executePhase()
		
		firstCharacter.weapon = Weapon(type: "test melee weapon", material: "neutral", level: 0)
		
		//secondCharacter is the same side, so it should be an invalid target
		XCTAssertFalse(game.validTarget(secondCharacter))
		
		//thirdCharacter is too far away, so it should be invalid
		let thirdCharacter = Creature(enemyType: "human player", level: 0, x: 2, y: 2)
		XCTAssertFalse(game.validTarget(thirdCharacter))
		
		//...but if we move thirdCharacter one tile closer, it will be in range
		thirdCharacter.x = 1
		XCTAssertTrue(game.validTarget(thirdCharacter))
		
		//...but x2 if we switch the player back to a ranged weapon, thirdCharacter will now be inside the minimum range
		firstCharacter.weapon = Weapon(type: "test weapon", material: "neutral", level: 0)
		XCTAssertFalse(game.validTarget(thirdCharacter))
	}
	
	func testAttacking()
	{
		game.executePhase()
		
		//apply shake to make sure that the other person won't die
		firstCharacter.shake = 10
		
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
	
	func testSkipDead()
	{
		secondCharacter.health = 0
		
		game.executePhase()
		game.skipAction()
		
		XCTAssertEqual(game.creatureOn, 0)
	}
	
	func testDeadCulledWhenLooping()
	{
		game.executePhase()
		firstCharacter.health = 0
		game.skipAction()
		game.skipAction()
		
		XCTAssertEqual(game.creatureOn, 0)
		XCTAssertEqual(game.creatures.count, 1)
		XCTAssertTrue(game.creatures[0] === secondCharacter)
	}
	
	func testUIUpdate()
	{
		let thirdCharacter = Creature(enemyType: "test creature", level: 1, x: 2, y: 2)
		game.addEnemy(thirdCharacter)
		
		//make sure nobody dies from a crit
		firstCharacter.shake = 10
		secondCharacter.shake = 10
		thirdCharacter.shake = 10
		
		//the turn starts for the player, so one UI update
		
		game.executePhase()
		XCTAssertEqual(uiUpdateCalled, 1)
		
		//the UI should update when the player attacks
		XCTAssertEqual(game.creatureOn, 0)
		game.attack(x: 2, y: 1)
		game.toNextPhase()
		XCTAssertEqual(uiUpdateCalled, 2)
		
		//the UI should update when the player is attacked
		XCTAssertEqual(game.creatureOn, 1)
		game.attack(x: 1, y: 1)
		game.toNextPhase()
		XCTAssertEqual(uiUpdateCalled, 3)
		
		//the UI shouldn't update when an attack happens that doesn't involve the player
		XCTAssertEqual(game.creatureOn, 2)
		game.attack(x: 2, y: 1)
		XCTAssertEqual(uiUpdateCalled, 3)
		
		//and another turn start
		
		//the UI should update when there's a poison tick
		firstCharacter.poison = 1
		game.toNextPhase()
		XCTAssertEqual(uiUpdateCalled, 5)
		
		//the UI should update if the player moves
		XCTAssertEqual(game.creatureOn, 0)
		game.makeMove(x: 1, y: 2)
		XCTAssertEqual(uiUpdateCalled, 6)
		
		//...but when other people move, who cares?
		game.skipAction()
		XCTAssertTrue(game.activeCreature === thirdCharacter) 
		game.makeMove(x: 2, y: 3)
		XCTAssertEqual(uiUpdateCalled, 6)
	}
	
	func testGameOver()
	{
		XCTAssertEqual(gameOverCalled, 0)
		
		game.executePhase()
		
		//kill the player
		firstCharacter.health = 0
		
		//and skip turn to get to someone else, to recognize the game over
		game.skipAction()
		
		XCTAssertEqual(gameOverCalled, 1)
	}
	
	//MARK: map tests
	func testCreaturesAppearInTiles()
	{
		XCTAssertTrue((game.map.tileAt(x: 1, y: 1).creature ?? secondCharacter) === firstCharacter)
		XCTAssertTrue((game.map.tileAt(x: 2, y: 1).creature ?? firstCharacter) === secondCharacter)
	}
	
	func testMovingUpdatesTiles()
	{
		game.executePhase()
		
		XCTAssertTrue((game.map.tileAt(x: 1, y: 1).creature ?? secondCharacter) === firstCharacter)
		
		game.makeMove(x: 1, y: 2)
		
		XCTAssertNil(game.map.tileAt(x: 1, y: 1).creature)
		XCTAssertTrue((game.map.tileAt(x: 1, y: 2).creature ?? secondCharacter) === firstCharacter)
	}
	
	func testKillingEnemyWithAttackUpdatesTiles()
	{
		//TODO: remember to make similar tests for other forms of death (death due to special attacks, death due to traps, etc)
		
		game.executePhase()
		
		//ensure a crit, so it will be a one-hit kill
		firstCharacter.dex = 99999
		
		game.attack(x: 2, y: 1)
		
		XCTAssertNil(game.map.tileAt(x: 2, y: 1).creature)
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
	func uiUpdate()
	{
		uiUpdateCalled += 1
	}
	func gameOver()
	{
		gameOverCalled += 1
	}
}