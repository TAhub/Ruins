//
//  AITests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class AITests: XCTestCase {
	
	var game:Game!
	var firstCharacter:Creature!
	
    override func setUp() {
        super.setUp()
		
		game = Game()
		
		firstCharacter = Creature(enemyType: "test pzombie", level: 1, x: 1, y: 1)
		game.addPlayer(firstCharacter)
    }
	
	func testAIActsAutomatically()
	{
		//make a goodguy for the AI to target
		let target = Creature(enemyType: "test creature", level: 1, x: 2, y: 1)
		target.good = true
		game.addEnemy(target)
		
		game.executePhase()
		
		//in this position, the AI should attack
		XCTAssertEqual(game.phaseOn, GamePhase.Attack)
		XCTAssertLessThan(target.health, 200)
	}
}