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
		game.addEnemy(firstCharacter)
		
		//calculate visibility to let attacking happen
		game.map.calculateVisibility(x: 1, y: 1)
    }
	
	func testAISleep()
	{
		//make a goodguy for the AI to target; this one is right next to the player
		let target = Creature(enemyType: "human player", level: 1, x: 2, y: 1)
		game.addPlayer(target)
		
		//make everyone shaky to ensure no crits
		target.shake = 100
		firstCharacter.shake = 100
		
		//move the visibility elsewhere so that the AI is offscreen
		game.map.calculateVisibility(x: 20, y: 20)
		
		game.executePhase()
		
		//it should automatically switch turn to the player
		XCTAssertEqual(game.creatureOn, 1)
		XCTAssertFalse(firstCharacter.awake)
		
		//attack the AI; this should wake it up
		game.attack(x: firstCharacter.x, y: firstCharacter.y)
		XCTAssertTrue(firstCharacter.awake)
	}
	
	func testAIAttackNearby()
	{
		//make a goodguy for the AI to target; this one is right next to the player
		let target = Creature(enemyType: "human player", level: 1, x: 2, y: 1)
		game.addPlayer(target)
		
		game.executePhase()
		
		//in this position, the AI should attack
		XCTAssertEqual(game.phaseOn, GamePhase.Attack)
		XCTAssertLessThan(target.health, 200)
	}
	
	func testAIWalkToAttack()
	{
		//make a goodguy for the AI to target; this one is far enough away you'll need to walk to them
		let target = Creature(enemyType: "human player", level: 1, x: 4, y: 1)
		game.addPlayer(target)
		
		game.executePhase()
		
		XCTAssertEqual(game.phaseOn, GamePhase.Move)
		
		game.toNextPhase()
		
		XCTAssertEqual(game.phaseOn, GamePhase.Attack)
		XCTAssertLessThan(target.health, 200)
	}
	
	func testAIWalkToDistantPlayer()
	{
		//make a goodguy for the AI to target; this one is far enough away you'll need to walk to them
		let target = Creature(enemyType: "human player", level: 1, x: 9, y: 9)
		game.addPlayer(target)
		
		game.executePhase()
		
		XCTAssertEqual(game.phaseOn, GamePhase.Move)
	}
	
	func testFleeWhenHurt()
	{
		//make a goodguy for the AI to target; this one is right ABOVE the player to make the direction of fleeing obvious
		let target = Creature(enemyType: "human player", level: 1, x: 3, y: 2)
		game.addPlayer(target)
		
		firstCharacter.x = 3
		firstCharacter.y = 3
		
		//also make the AI near-death
		firstCharacter.health = 1
		
		game.executePhase()
		
		//and now the AI flees
		XCTAssertEqual(game.phaseOn, GamePhase.Move)
		let distance = abs(firstCharacter.x - target.x) + abs(firstCharacter.y - target.y)
		XCTAssertEqual(distance, 5)
	}
	
	func testFleeWhenUnarmed()
	{
		//make a goodguy for the AI to target; this one is right ABOVE the player to make the direction of fleeing obvious
		let target = Creature(enemyType: "human player", level: 1, x: 3, y: 2)
		game.addPlayer(target)
		
		firstCharacter.x = 3
		firstCharacter.y = 3
		
		//also make the AI's weapon be something that's about to break
		firstCharacter.weapon = Weapon(type: "sword", material: "neutral", level: 0)
		firstCharacter.weapon.health = 1
		
		game.executePhase()
		
		//they should attack, which breaks their weapon
		XCTAssertEqual(game.phaseOn, GamePhase.Attack)
		XCTAssertLessThan(target.health, target.maxHealth)
		XCTAssertEqual(firstCharacter.weapon.type, "unarmed")
		
		game.toNextPhase()
		
		//skip the target's turn
		game.skipAction()
		
		//and now the AI flees
		XCTAssertEqual(game.phaseOn, GamePhase.Move)
		let distance = abs(firstCharacter.x - target.x) + abs(firstCharacter.y - target.y)
		XCTAssertEqual(distance, 5)
	}
	
	func testNoAttackWhenUnarmed()
	{
		//make two goodguys to box the AI in
		let targetOne = Creature(enemyType: "human player", level: 1, x: 2, y: 1)
		game.addPlayer(targetOne)
		let targetTwo = Creature(enemyType: "human player", level: 1, x: 1, y: 2)
		game.addEnemy(targetTwo)
		
		//and disarm the AI
		firstCharacter.weapon = Weapon(type: "unarmed", material: "neutral", level: 0)
		
		//the AI can't move OR attack, so it should just skip its turn
		game.executePhase()
		
		XCTAssertEqual(game.phaseOn, GamePhase.MakeDecision)
		XCTAssertEqual(game.creatureOn, 1)
	}
	
	//TODO: more AI tests
	//	test to make sure some AIs will avoid traps and some won't
	//	test for AIs not "activating" until they become visible at least once
}