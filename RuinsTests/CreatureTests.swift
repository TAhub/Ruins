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
	
	func testPoison()
	{
		//poisonTick should do nothing if you aren't poisoned
		XCTAssertNil(creature.poisonTick())
		XCTAssertEqual(creature.health, 200)
		
		creature.poison = 100
		
		//make sure the poison does the right damage
		XCTAssertEqual(creature.poisonTick() ?? 999, 10)
		XCTAssertEqual(creature.health, 190)
		
		//run it again to make sure it keys off your max health and not current health
		XCTAssertEqual(creature.poisonTick() ?? 999, 10)
		XCTAssertEqual(creature.health, 180)
		
		//run it again to make sure that poison can't reduce you below 1 health
		creature.health = 10
		XCTAssertEqual(creature.poisonTick() ?? 999, 9)
		XCTAssertEqual(creature.health, 1)
		
		//and run it once more to show that poisonTick does nothing if you are at 1 health
		XCTAssertNil(creature.poisonTick())
	}
	
	func testEndTurn()
	{
		creature.poison = 3
		creature.stun = 7
		creature.shake = 1
		
		creature.endTurn()
		
		XCTAssertEqual(creature.poison, 2)
		XCTAssertEqual(creature.stun, 6)
		XCTAssertEqual(creature.shake, 0)
		
		creature.endTurn()
		creature.endTurn()
		
		XCTAssertEqual(creature.poison, 0)
		XCTAssertEqual(creature.stun, 4)
		XCTAssertEqual(creature.shake, 0)
		
		creature.endTurn()
		creature.endTurn()
		creature.endTurn()
		creature.endTurn()
		
		XCTAssertEqual(creature.poison, 0)
		XCTAssertEqual(creature.stun, 0)
		XCTAssertEqual(creature.shake, 0)
	}
	
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
	
	func testWeakness()
	{
		let target = Creature(enemyType: "test creature", level: 1, x: 0, y: 0)
		let invalidTarget = Creature(enemyType: "test undead creature", level: 1, x: 0, y: 0)
		
		//ensure they always graze
		creature.shake = 10
		
		//test ranged weakness
		creature.weapon = Weapon(type: "test weapon", material: "mortal killing material", level: 0)
		XCTAssertEqual(creature.weapon.strongVS ?? "", "mortal")
		let damages = creature.attack(target)
		let oDamages = creature.attack(invalidTarget)
		XCTAssertEqual(damages.theirDamage, 130) //it gets +30% damage from ranged weakness
		XCTAssertEqual(oDamages.theirDamage, 100)
		
		//test melee weakness
		creature.weapon = Weapon(type: "test melee weapon", material: "mortal killing material", level: 0)
		let mDamages = creature.attack(target)
		let oMDamages = creature.attack(invalidTarget)
		XCTAssertEqual(mDamages.theirDamage, 260) //it ignores the -80 from their melee res from melee weakness
		XCTAssertEqual(oMDamages.theirDamage, 180)
	}
	
	func testCrit()
	{
		let target = Creature(enemyType: "test creature", level: 1, x: 0, y: 0)
		
		//set the attacker's DEX super-high to ensure a 100% critrate
		creature.dex = 999999
		XCTAssertEqual(creature.attack(target).theirDamage, 200)
		
		//apply shake to ensure that it won't crit, despite the critrate
		creature.shake = 10
		XCTAssertEqual(creature.attack(target).theirDamage, 100)
	}
	
	//TODO: other attack tests to make:
	//	test status effects (I guess for this one you'd want to just attack like 50 times in a row to see if they get infected)
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