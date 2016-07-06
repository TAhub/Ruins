//
//  WeaponTests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class WeaponTests: XCTestCase {
	
	var weapon:Weapon!
	
    override func setUp() {
        super.setUp()
		
		weapon = Weapon(type: "test weapon", material: "neutral", level: 0)
    }
	
	func testLoadWeaponFromPlist()
	{
		//test to make sure all of the loaded statistics, and calculated statistics, are as expected
		normalLoadAsserts()
	}
	
	func testLoadWeaponFromSaveDict()
	{
		let saveDict = weapon.saveDict
		weapon = Weapon(saveDict: saveDict)
		normalLoadAsserts()
	}
	
	func testNoSubtypeDamageByLevel()
	{
		XCTAssertEqual(Weapon(type: "test weapon", material: "neutral", level: 13).damage, 150)
		XCTAssertEqual(Weapon(type: "test weapon", material: "neutral", level: 26).damage, 200)
	}
	
	func testMaterialDamage()
	{
		XCTAssertEqual(Weapon(type: "test weapon", material: "double material", level: 0).damage, 200)
	}
	
	func testMaterialWeight()
	{
		XCTAssertEqual(Weapon(type: "test weapon", material: "double material", level: 0).weight, 200)
	}
	
	func testSubtypePicking()
	{
		XCTAssertEqual(Weapon(type: "test subtype weapon", material: "neutral", level: 0).subtype, 0)
		XCTAssertEqual(Weapon(type: "test subtype weapon", material: "neutral", level: 25).subtype, 0)
		XCTAssertEqual(Weapon(type: "test subtype weapon", material: "neutral", level: 75).subtype, 1)
		XCTAssertEqual(Weapon(type: "test subtype weapon", material: "neutral", level: 100).subtype, 1)
	}
	
	func testSubtypeDamage()
	{
		XCTAssertEqual(Weapon(type: "test subtype weapon", material: "neutral", level: 0).damage, 100)
		XCTAssertEqual(Weapon(type: "test subtype weapon", material: "neutral", level: 100).damage, 200)
	}
	
	func testSubtypeName()
	{
		XCTAssertEqual(Weapon(type: "test subtype weapon", material: "neutral", level: 0).name, "neutral first subtype")
		XCTAssertEqual(Weapon(type: "test subtype weapon", material: "neutral", level: 100).name, "neutral second subtype")
	}
	
	func testSubtypeWeight()
	{
		XCTAssertEqual(Weapon(type: "test subtype weapon", material: "neutral", level: 0).weight, 100)
		XCTAssertEqual(Weapon(type: "test subtype weapon", material: "neutral", level: 100).weight, 200)
	}
	
	//MARK: helper functions
	func normalLoadAsserts()
	{
		XCTAssertEqual(weapon.damage, 100)
		XCTAssertEqual(weapon.accuracy, 100)
		XCTAssertEqual(weapon.hitDamageMultiplier, 200)
		XCTAssertEqual(weapon.weight, 100)
		XCTAssertEqual(weapon.range, 100)
		XCTAssertEqual(weapon.name, "neutral test weapon")
		XCTAssertNil(weapon.strongVS)
	}
}