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
		
		creature = Creature(enemyType: "test creature", level: 1)
    }
	
	func testLoadCreatureFromPlist()
	{
		//test to make sure all of the loaded statistics, and calculated statistics, are as expected
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
		XCTAssertEqual(creature.encumberance, 0) //the test guy should be carrying nothing with weight
		XCTAssertEqual(creature.weapon.type, "bash")
		XCTAssertEqual(creature.weapon.material, "neutral")
		XCTAssertEqual(creature.weapon.subtype, 1) //bash is no-subtype, so it should just be set to the test guy's level
	}
}