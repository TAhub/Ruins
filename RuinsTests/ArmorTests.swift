//
//  ArmorTests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class ArmorTests: XCTestCase {

	var armor:Armor!
	
    override func setUp() {
        super.setUp()
		
		armor = Armor(type: "sample armor", level: 0)
    }
	
	func testLoadArmorFromPlist()
	{
		//test to make sure all of the loaded statistics, and calculated statistics, are as expected
		normalLoadAsserts()
	}
	
	func testLoadArmorFromSaveDict()
	{
		let saveDict = armor.saveDict
		armor = Armor(saveDict: saveDict)
		normalLoadAsserts()
	}
	
	func testArmorBroken()
	{
		XCTAssertFalse(armor.broken)
		armor.health = 0
		XCTAssertTrue(armor.broken)
	}
	
	
	//MARK: helper functions
	func normalLoadAsserts()
	{
		XCTAssertEqual(armor.subtype, 0)
		XCTAssertEqual(armor.name, "shirt")
		XCTAssertEqual(armor.meleeResistance, 1)
		XCTAssertEqual(armor.dodge, 2)
		XCTAssertEqual(armor.maxHealthBonus, 3)
		XCTAssertEqual(armor.trapResistance, 4)
		XCTAssertEqual(armor.specialResistance, 5)
		XCTAssertEqual(armor.weight, 50)
		XCTAssertEqual(armor.spriteName, "outfit")
		XCTAssertEqual(armor.spriteColor, UIColor.blackColor())
		XCTAssertEqual(armor.maxHealth, 100)
		XCTAssertEqual(armor.health, 100)
		XCTAssertEqual(armor.description, "SAMPLE FLAVOR.\n1 melee resistance, 2 dodge, 30% health bonus, 4 trap resistance, 5 special resistance, 50 weight")
	}
}
