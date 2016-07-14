//
//  TrapTests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/13/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class TrapTests: XCTestCase {
	
	var trap:Trap!
	
    override func setUp() {
        super.setUp()
		
		trap = Trap(type: "sample trap", trapPower: 20, good: false)
    }
	
	func testTrapDamage()
	{
		XCTAssertEqual(trap.damage(20), 100)
		XCTAssertEqual(trap.damage(15), 140)
		XCTAssertEqual(trap.damage(25), 60)
		XCTAssertEqual(trap.damage(999999), 25)
	}
	
	func testActiveTrap()
	{
		let mineSweeper = Creature(enemyType: "test creature", level: 1, x: 0, y: 0)
		
		XCTAssertFalse(trap.dead)
		
		let damage = trap.activate(mineSweeper)
		XCTAssertEqual(damage, 100)
		XCTAssertEqual(mineSweeper.health, mineSweeper.maxHealth - damage)
		
		//all these statuses should be +1 from what's listed under the trap, since the turn will end immediately afterwards
		XCTAssertEqual(mineSweeper.stun, 4)
		XCTAssertEqual(mineSweeper.shake, 3)
		XCTAssertEqual(mineSweeper.poison, 2)
		
		XCTAssertTrue(trap.dead)
		
		//detonating the trap again will add the expected amount
		trap.activate(mineSweeper)
		XCTAssertEqual(mineSweeper.health, mineSweeper.maxHealth - damage * 2)
		XCTAssertEqual(mineSweeper.stun, 7)
		XCTAssertEqual(mineSweeper.shake, 5)
		XCTAssertEqual(mineSweeper.poison, 3)
	}
}
