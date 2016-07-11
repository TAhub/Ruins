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
	
    override func setUp()
	{
        super.setUp()
		weaponItem = Item(weapon: Weapon(type: "test weapon", material: "neutral", level: 0))
		armorItem = Item(armor: Armor(type: "sample armor", level: 0))
    }
	
	func testItemOnlyContainsOneTypeOfThing()
	{
		normalLoadAsserts()
	}
	
	func testLoadItemFromSaveDict()
	{
		let wSave = weaponItem.saveDict
		let aSave = armorItem.saveDict
		weaponItem = Item(saveDict: wSave)
		armorItem = Item(saveDict: aSave)
		normalLoadAsserts()
	}
	
	func testItemWeight()
	{
		XCTAssertEqual(weaponItem.weight, 100)
		XCTAssertEqual(armorItem.weight, 50)
	}
	
	func testItemName()
	{
		XCTAssertEqual(weaponItem.name, "neutral test weapon")
		XCTAssertEqual(armorItem.name, "shirt")
	}
	
	//MARK: helper functions
	func normalLoadAsserts()
	{
		XCTAssertNotNil(weaponItem.weapon)
		XCTAssertNil(weaponItem.armor)
		XCTAssertNil(armorItem.weapon)
		XCTAssertNotNil(armorItem.armor)
	}
}
