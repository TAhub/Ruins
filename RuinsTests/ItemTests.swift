//
//  ItemTests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/11/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class ItemTests: XCTestCase {
	
	var weaponItem:Item!
	var armorItem:Item!
	var usableItem:Item!
	
    override func setUp()
	{
        super.setUp()
		weaponItem = Item(weapon: Weapon(type: "test weapon", material: "neutral", level: 0))
		armorItem = Item(armor: Armor(type: "sample armor", level: 0))
		usableItem = Item(usable: "test usable")
    }
	
	func testItemOnlyContainsOneTypeOfThing()
	{
		normalLoadAsserts()
	}
	
	func testLoadItemFromSaveDict()
	{
		let wSave = weaponItem.saveDict
		let aSave = armorItem.saveDict
		let uSave = usableItem.saveDict
		weaponItem = Item(saveDict: wSave)
		armorItem = Item(saveDict: aSave)
		usableItem = Item(saveDict: uSave)
		normalLoadAsserts()
	}
	
	func testItemWeight()
	{
		XCTAssertEqual(weaponItem.weight, 100)
		XCTAssertEqual(armorItem.weight, 50)
		XCTAssertEqual(usableItem.weight, 100)
	}
	
	func testItemName()
	{
		XCTAssertEqual(weaponItem.name, "neutral test weapon  100/100")
		XCTAssertEqual(armorItem.name, "shirt  100/100")
		XCTAssertEqual(usableItem.name, "test usable")
	}
	
	func testItemDescription()
	{
		XCTAssertEqual(weaponItem.description, "SAMPLE FLAVOR.\n200 damage (100 graze), 100% accuracy, 100 range, 100 weight")
		XCTAssertEqual(armorItem.description, "SAMPLE FLAVOR.\n1 melee resistance, 2 dodge, 30% health bonus, 4 trap resistance, 5 special resistance, 50 weight")
		XCTAssertEqual(usableItem.description, "SAMPLE FLAVOR.\nHeals 100. Cures. 100 weight.")
	}
	
	func testItemNumber()
	{
		usableItem.number = 2
		XCTAssertEqual(usableItem.name, "test usable x2")
		XCTAssertEqual(usableItem.description, "SAMPLE FLAVOR.\nHeals 100. Cures. 200 total weight.")
	}
	
	func testItemTrapDescription()
	{
		let trapItem = Item(usable: "sample trap")
		XCTAssertNotNil(trapItem.trap)
		XCTAssertEqual(trapItem.description, "SAMPLE FLAVOR.\nLays a 100-damage trap that stuns, shakes, and poisons. 100 weight.")
	}
	
	//MARK: helper functions
	func normalLoadAsserts()
	{
		XCTAssertNotNil(weaponItem.weapon)
		XCTAssertNil(weaponItem.armor)
		XCTAssertFalse(weaponItem.cures)
		XCTAssertNil(weaponItem.heals)
		XCTAssertNil(weaponItem.trap)
		
		XCTAssertNil(armorItem.weapon)
		XCTAssertNotNil(armorItem.armor)
		XCTAssertFalse(armorItem.cures)
		XCTAssertNil(armorItem.heals)
		XCTAssertNil(armorItem.trap)
		
		XCTAssertNil(usableItem.weapon)
		XCTAssertNil(usableItem.armor)
		XCTAssertTrue(usableItem.cures)
		XCTAssertNotNil(usableItem.heals)
		XCTAssertNil(usableItem.trap)
	}
}