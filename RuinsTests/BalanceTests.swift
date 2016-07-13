//
//  BalanceTests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/12/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

let marginOfError:Float = 0.3

class BalanceTests: XCTestCase {
	
	var nameMemory:[String]!
	
	override func setUp() {
		super.setUp()
		
		//save the name memory to restore after the test
		nameMemory = MapGenerator.getNameMemory()
		MapGenerator.clearNameMemory()
	}
	
	override func tearDown() {
		super.tearDown()
		
		//restore the name memory to its previous state
		MapGenerator.loadNameMemory(nameMemory)
	}
	
	//these tests are a bit weird
	//because they aren't hard-and-fast pass-or-fail tests
	//instead, they are all just tests to make sure I don't fuck up the balance in the plists too bad
	
	func testMapStubsHaveGoodVarietyOfKeywords()
	{
		var stubs = allPossibleStubs()
		
		//pool every keyword generated by the stubs
		var keywords = [String : Int]()
		for stub in stubs
		{
			for keyword in stub.keywords
			{
				keywords[keyword] = (keywords[keyword] ?? 0) + 1
			}
		}
		
		//we ideally want every keyword to show up (number of keywords generated) / (number of distinct keywords) times
		let desiredAverage = (stubs.count * stubs[0].keywords.count) / keywords.keys.count
		
		//are we close, though?
		for (keyword, number) in keywords
		{
			print("TESTING KEYWORD BALANCE OF \(keyword): \(number) vs \(desiredAverage)")
			compare(num: number, desired: desiredAverage)
		}
	}
	
	func testArmorsHaveCorrectPointValues()
	{
		for (armor, armorPlist) in DataStore.getPlist("Armors") as! [NSString : NSDictionary]
		{
			if armor != "sample armor"
			{
				print("TESTING ARMOR \(armor):")
				let subtypes = armorPlist["subtypes"] as! [NSDictionary]
				for subtype in subtypes
				{
					let level = Int((subtype["level"] as! NSNumber).intValue)
					let meleeResistance = Int(((subtype["melee resistance"] as? NSNumber) ?? 0).intValue)
					let dodge = Int(((subtype["dodge"] as? NSNumber) ?? 0).intValue)
					let maxHealthBonus = Int(((subtype["max health bonus"] as? NSNumber) ?? 0).intValue)
					let trapResistance = Int(((subtype["trap resistance"] as? NSNumber) ?? 0).intValue)
					let specialResistance = Int(((subtype["special resistance"] as? NSNumber) ?? 0).intValue)
					
					let expectedPoints = 6 + level
					let actualPoints = 2 * (meleeResistance + dodge + maxHealthBonus + specialResistance) +
										1 * (trapResistance)
					XCTAssertEqual(expectedPoints, actualPoints)
				}
			}
		}
	}
	
	func testCreaturesHaveCorrectPointValues()
	{
		for (creature, _) in DataStore.getPlist("EnemyTypes") as! [String : NSObject]
		{
			if DataStore.getArray("EnemyTypes", creature, "keywords")!.count > 0
			{
				let level = DataStore.getInt("EnemyTypes", creature, "level")!
				let expectedPoints = 50 + level
				
				let strength = DataStore.getInt("EnemyTypes", creature, "strength")!
				let dexterity = DataStore.getInt("EnemyTypes", creature, "dexterity")!
				let cunning = DataStore.getInt("EnemyTypes", creature, "cunning")!
				let wisdom = DataStore.getInt("EnemyTypes", creature, "wisdom")!
				let endurance = DataStore.getInt("EnemyTypes", creature, "endurance")!
				
				XCTAssertEqual(expectedPoints, strength + dexterity + cunning + wisdom + endurance)
			}
		}
	}
	
	func testEveryMapStubHasValidCreatures()
	{
		for stub in allPossibleStubs()
		{
			print("CHECKING TO SEE IF STUB WITH KEYWORDS \(stub.keywords[0]) AND \(stub.keywords[1]) HAS ENEMIES:")
			XCTAssertGreaterThan(stub.enemyTypes.count, 0)
		}
	}
	
	//TODO: future balance test ideas
	//	make sure each non-gang keyword has a roughly equal number of creatures
	
	
	//MARK: helper functions
	private func compare(num num:Int, desired:Int)
	{
		XCTAssertLessThan(abs(num - desired), Int(marginOfError * Float(desired)))
	}
	private func allPossibleStubs() -> [MapStub]
	{
		var stubs = [MapStub]()
		let flavorsRaw = DataStore.getPlist("MapFlavors").keys
		let themesRaw = DataStore.getPlist("MapThemes").keys
		let flavors = [NSString](flavorsRaw) as! [String]
		let themes = [NSString](themesRaw) as! [String]
		for theme in themes
		{
			for flavor in flavors
			{
				stubs.append(MapStub(flavor: flavor, theme: theme, name: ""))
			}
		}
		return stubs
	}
}