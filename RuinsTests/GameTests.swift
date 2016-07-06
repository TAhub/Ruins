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
	
	//MARK: delegate methods
	
	func inputDesired()
	{
		inputDesiredCalled += 1
	}
	func playAnimation(anim: Animation)
	{
		playAnimationCalled += 1
	}
}