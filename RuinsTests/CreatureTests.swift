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
	
	func testGetStatsFromArmor()
	{
		creature.armor = Armor(type: "sample armor", level: 0)
		XCTAssertEqual(creature.maxHealthBonus, 13)
		XCTAssertEqual(creature.dodge, 12)
		XCTAssertEqual(creature.meleeRes, 11)
		XCTAssertEqual(creature.trapRes, 24)
		XCTAssertEqual(creature.specialRes, 15)
	}
	
	func testDead()
	{
		XCTAssertFalse(creature.dead)
		XCTAssertFalse(creature.injured)
		creature.health = 1
		XCTAssertFalse(creature.dead)
		XCTAssertTrue(creature.injured)
		creature.health = 0
		XCTAssertTrue(creature.dead)
		XCTAssertTrue(creature.injured)
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
	
	func testAttackDegradesEquipment()
	{
		let target = Creature(enemyType: "test creature", level: 1, x: 0, y: 0)
		target.armor = Armor(type: "sample armor", level: 0)
		creature.armor = Armor(type: "sample armor", level: 0)
		
		creature.attack(target)
		
		XCTAssertEqual(creature.weapon.health, creature.weapon.maxHealth - 1)
		XCTAssertEqual(creature.armor!.health, creature.armor!.maxHealth)
		XCTAssertEqual(target.weapon.health, target.weapon.maxHealth)
		XCTAssertEqual(target.armor!.health, target.armor!.maxHealth - 1)
		
		target.attack(creature)
		
		XCTAssertEqual(creature.weapon.health, creature.weapon.maxHealth - 1)
		XCTAssertEqual(creature.armor!.health, creature.armor!.maxHealth - 1)
		XCTAssertEqual(target.weapon.health, target.weapon.maxHealth - 1)
		XCTAssertEqual(target.armor!.health, target.armor!.maxHealth - 1)
	}
	
	func testEquipmentBreak()
	{
		let target = Creature(enemyType: "test creature", level: 1, x: 0, y: 0)
		target.armor = Armor(type: "sample armor", level: 0)
		target.armor!.health = 1
		creature.weapon.health = 1
		
		creature.attack(target)
		
		XCTAssertEqual(creature.weapon.type, "unarmed")
		XCTAssertEqual(creature.weapon.subtype, 0)
		XCTAssertEqual(creature.weapon.material, "neutral")
		XCTAssertNil(target.armor)
	}
	
	func testWeakness()
	{
		let target = Creature(enemyType: "test creature", level: 1, x: 0, y: 0)
		let invalidTarget = Creature(enemyType: "test pzombie", level: 1, x: 0, y: 0)
		
		//ensure they always graze
		creature.shake = 10
		
		//test ranged weakness
		creature.weapon = Weapon(type: "test weapon", material: "mortal killing material", level: 0)
		XCTAssertEqual(creature.weapon.strongVS ?? "", "mortal")
		let damages = creature.attack(target)
		let oDamages = creature.attack(invalidTarget)
		XCTAssertEqual(damages.theirDamage, 140) //it gets +40% damage from ranged weakness
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
	
	func testStatus()
	{
		let target = Creature(enemyType: "test creature", level: 1, x: 0, y: 0)
		
		//TODO: note that this test is testing a random function, so there's a small chance it will fail for no apparent reason
		//specifically, a chance equal to (0.8 ^ 100)
		
		creature.weapon = Weapon(type: "test weapon", material: "mercury", level: 0)
		for _ in 0..<100
		{
			creature.attack(target)
		}
		
		XCTAssertGreaterThan(target.poison, 0)
	}
	
	func testStatusImmunity()
	{
		let target = Creature(enemyType: "test pzombie", level: 1, x: 0, y: 0)
		
		//TODO: again, this is random; there is a tiny tiny chance of a false positive
		
		creature.weapon = Weapon(type: "test weapon", material: "mercury", level: 0)
		for _ in 0..<100
		{
			creature.attack(target)
		}
		
		XCTAssertEqual(target.poison, 0)
	}
	
	func testAllEnemyTypesHaveFlavorText()
	{
		for (creature, _) in DataStore.getPlist("EnemyTypes") as! [String : NSObject]
		{
			let hasKeywords = DataStore.getArray("EnemyTypes", creature, "keywords")!.count > 0
			let isBoss = DataStore.getBool("EnemyTypes", creature, "boss")
			let isPlayer = DataStore.getBool("EnemyTypes", creature, "good")
			if !isPlayer && (isBoss || hasKeywords)
			{
				let flavorText = DataStore.getString("EnemyTypes", creature, "flavor text")
				XCTAssertNotNil(flavorText)
				if flavorText == nil
				{
					print("WARNING: CREATURE \(creature) HAS NO FLAVOR TEXT!")
				}
			}
		}
	}
	
	//TODO: other attack tests to make:
	//	test healing weapons
	
	//MARK: helpers
	func normalLoadAsserts()
	{
		//note that sample armor gives the guy a few stat bonuses
		XCTAssertEqual(creature.racialGroup, "mortal")
		XCTAssertEqual(creature.appearanceGroup, "human")
		XCTAssertNil(creature.AI)
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
		XCTAssertEqual(creature.encumberance, 100) //the test guy should be carrying his 100-weight weapon, and nothing else
		XCTAssertEqual(creature.weapon.type, "test subtype weapon")
		XCTAssertEqual(creature.weapon.material, "neutral")
		XCTAssertEqual(creature.weapon.subtype, 0)
		XCTAssertNil(creature.armor)
	}
}