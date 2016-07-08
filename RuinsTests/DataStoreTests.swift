//
//  DataStoreTests.swift
//  Arena
//
//  Created by Theodore Abshire on 6/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class DataStoreTests: XCTestCase {

	//all of these tests are made to read the contents of the Test plist, which are all known ahead of time
	//and are guaranteed to not change during development
	
    func testGetInt()
	{
		XCTAssertEqual(DataStore.getInt("Tests", "Entry One", "Int") ?? 0, 3)
		XCTAssertEqual(DataStore.getInt("Tests", "Entry One", "Other Int") ?? 0, 4)
	}
	
	func testGetFloat()
	{
		XCTAssertEqual(DataStore.getFloat("Tests", "Entry One", "Float") ?? 0, 1.5)
		XCTAssertEqual(DataStore.getFloat("Tests", "Entry One", "Other Float") ?? 0, 7.5)
	}
	
	func testGetString()
	{
		XCTAssertEqual(DataStore.getString("Tests", "Entry One", "String") ?? "", "Hello")
		XCTAssertEqual(DataStore.getString("Tests", "Entry One", "Other String") ?? "", "Hi")
	}
	
	func testGetColor()
	{
		XCTAssertEqual(DataStore.getColor("Tests", "Entry One", "Color") ?? UIColor.blackColor(), UIColor.redColor())
		XCTAssertEqual(DataStore.getColor("Tests", "Entry One", "Other Color") ?? UIColor.blackColor(), UIColor.blueColor())
		XCTAssertEqual(DataStore.getColorByName("red") ?? UIColor.blackColor(), UIColor.redColor())
		XCTAssertEqual(DataStore.getColorByName("blue") ?? UIColor.blackColor(), UIColor.blueColor())
	}
	
	func testGetBool()
	{
		XCTAssertTrue(DataStore.getBool("Tests", "Entry One", "True"))
		XCTAssertFalse(DataStore.getBool("Tests", "Entry One", "False"))
	}
	
	func testGetArray()
	{
		XCTAssertEqual(DataStore.getArray("Tests", "Entry One", "Array") ?? [], ["Hola"])
	}
	
	func testNonexistantValues()
	{
		XCTAssertNil(DataStore.getInt("Tests", "Entry One", "Nonexistant Int"))
		XCTAssertNil(DataStore.getFloat("Tests", "Entry One", "Nonexistant Float"))
		XCTAssertNil(DataStore.getString("Tests", "Entry One", "Nonexistant String"))
		XCTAssertNil(DataStore.getArray("Tests", "Entry One", "Nonexistant Array"))
		XCTAssertNil(DataStore.getColor("Tests", "Entry One", "Nonexistant Color"))
		XCTAssertNil(DataStore.getColor("Tests", "Entry One", "Real Color That Isn't In The Color List"))
	}

	func testMultipleEntries()
	{
		XCTAssertEqual(DataStore.getInt("Tests", "Entry Two", "EntryTwoValue") ?? 0, 999)
	}
	
	func testLoadAsWrongType()
	{
		XCTAssertNil(DataStore.getString("Tests", "Entry One", "Float"))
		XCTAssertNil(DataStore.getInt("Tests", "Entry One", "String"))
	}
}
