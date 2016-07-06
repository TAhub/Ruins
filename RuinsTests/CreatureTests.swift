//
//  CreatureTests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class CreatureTests: XCTestCase {
	
	var creature:Creature!
	
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		creature = Creature(enemyType: "test creature", level: 1, x: 0, y: 0)
    }
	
	func testLoadCreatureFromPlist()
	{
		//test to make sure all of the loaded statistics, and calculated statistics, are as expected
		normalLoadAsserts()
	}
	
	func testLoadCreatureFromSaveDict()
	{
		let saveDict = creature.saveDict
		creature = Creature(saveDict:saveDict)
		normalLoadAsserts()
	}
	
	//TODO: other tests to make:
	//	test posion (AKA to see if it does the right amount of damage)
	
	//MARK: attack tests
	
	func testAttack()
	{
		let target = Creature(enemyType: "test creature", level: 1, x: 0, y: 0)
		
		//first, inflict shakiness to make sure that you own't land a crit and screw up this test
		creature.shake = 10
		
		//the basic test weapon is ranged, so the damage done should be unaffected by stats otherwise; that is, 100
		let damages = creature.attack(target)
		XCTAssertEqual(damages.theirDamage, 100)
		XCTAssertEqual(damages.myDamage, 0)
		XCTAssertEqual(target.health, 100)
		
		
		//next, switch to a melee weapon
		target.health = target.maxHealth
		creature.weapon = Weapon(type: "test melee weapon", material: "neutral", level: 0)
		let oDamages = creature.attack(target)
		XCTAssertEqual(oDamages.theirDamage, 180)
		XCTAssertEqual(oDamages.myDamage, 0)
		XCTAssertEqual(target.health, 20)
	}
	
	//TODO: other attack tests to make:
	//	test weaknesses (ranged, AKA +15% damage)
	//	test weaknesses (melee, AKA ignore melee resistance)
	//	test status effects (I guess for this one you'd want to just attack like 50 times in a row to see if they get infected)
	//	test crits (set the attacker's DEX to like 9999999 to ensure a crit)
	//	test healing weapons
	
	//MARK: helpers
	func normalLoadAsserts()
	{
		XCTAssertEqual(creature.racialGroup, "mortal")
		XCTAssertEqual(creature.appearanceGroup, "human")
		XCTAssertEqual(creature.str, 10)
		XCTAssertEqual(creature.dex, 10)
		XCTAssertEqual(creature.cun, 10)
		XCTAssertEqual(creature.wis, 10)
		XCTAssertEqual(creature.end, 10)
		XCTAssertEqual(creature.meleePow, 20)
		XCTAssertEqual(creature.meleeRes, 10)
		XCTAssertEqual(creature.accuracy, 20)
		XCTAssertEqual(creature.dodge, 10)
		XCTAssertEqual(creature.maxHealthBonus, 10)
		XCTAssertEqual(creature.encumberanceBonus, 10)
		XCTAssertEqual(creature.trapPow, 20)
		XCTAssertEqual(creature.trapRes, 20)
		XCTAssertEqual(creature.specialPow, 10)
		XCTAssertEqual(creature.specialRes, 10)
		XCTAssertEqual(creature.maxHealth, 200)
		XCTAssertEqual(creature.health, 200)
		XCTAssertEqual(creature.maxEncumberance, 200)
		XCTAssertEqual(creature.maxMovePoints, 4)
		XCTAssertEqual(creature.encumberance, 100) //the test guy should be carrying his 100-weight weapon and nothing else
		XCTAssertEqual(creature.weapon.type, "test subtype weapon")
		XCTAssertEqual(creature.weapon.material, "neutral")
		XCTAssertEqual(creature.weapon.subtype, 0)
	}
}