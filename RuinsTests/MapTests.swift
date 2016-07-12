//
//  MapTests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class MapTests: XCTestCase {

	var map:Map!
	var nameMemory:[String]!
	
    override func setUp() {
        super.setUp()
		
		map = Map(width: 10, height: 10)
		
		//save the name memory to restore after the test
		nameMemory = MapGenerator.getNameMemory()
		
		MapGenerator.clearNameMemory()
    }
	
	override func tearDown() {
		super.tearDown()
		
		//restore the name memory to its previous state
		MapGenerator.loadNameMemory(nameMemory)
	}
	
	func testWalkable()
	{
		XCTAssertFalse(map.tileAt(x: 0, y: 0).walkable)
		XCTAssertTrue(map.tileAt(x: 1, y: 1).walkable)
		map.tileAt(x: 1, y: 1).creature = Creature(enemyType: "test creature", level: 1, x: 1, y: 1)
		XCTAssertFalse(map.tileAt(x: 1, y: 1).walkable)
	}
	
	
	//MARK: map gen tests
	func testDefaultMapGen()
	{
		//it should have borders at all sides
		XCTAssertTrue(map.tileAt(x: 0, y: 0).solid)
		XCTAssertTrue(map.tileAt(x: 9, y: 0).solid)
		XCTAssertTrue(map.tileAt(x: 0, y: 9).solid)
		XCTAssertTrue(map.tileAt(x: 9, y: 9).solid)
		XCTAssertFalse(map.tileAt(x: 1, y: 1).solid)
	}
	
	func testMapStubNoRepeatNames()
	{
		//generate 10 map stubs with the exact same flavor and theme and make sure there are no repeat names
		var stubs = [MapStub]()
		for _ in 0..<10
		{
			stubs.append(MapStub(flavor: "poisonous", theme: "wasteland"))
		}
		for stub in stubs
		{
			for oStub in stubs
			{
				if !(stub === oStub)
				{
					XCTAssertNotEqual(stub.name, oStub.name)
				}
			}
		}
	}
	
	func testMapStubNameStressTest()
	{
		//I don't care if it repeats or not in the stress test
		//just if it CAN generate hundreds of map stubs of the same type
		//so it's gotta have some way of noticing that it's out of unique names and going "oh fuck it" and repeating something
		for _ in 0..<1000
		{
			let _ = MapStub(flavor: "poisonous", theme: "wasteland")
		}
	}
	
	func testMapStubAttributes()
	{
		let stub = MapStub(flavor: "poisonous", theme: "wasteland")
		XCTAssertEqual(stub.keywords.count, 2)
		if stub.keywords.count == 2
		{
			XCTAssertEqual(stub.keywords[0], "criminal")
			XCTAssertEqual(stub.keywords[1], "poison")
		}
		
		//also make sure that alternate keywords work
		let stubTwo = MapStub(flavor: "battlefield", theme: "fort")
		XCTAssertEqual(stubTwo.keywords.count, 2)
		if stubTwo.keywords.count == 2
		{
			XCTAssertEqual(stubTwo.keywords[0], "military")
			XCTAssertEqual(stubTwo.keywords[1], "stun")
		}
	}
	
	func testMapStubEnemyList()
	{
		//get a map stub that will have both "military" and "criminal" in order to test the overlap
		let stub = MapStub(flavor: "lawless", theme: "fort")
		XCTAssertEqual(stub.keywords.count, 2)
		if stub.keywords.count == 2
		{
			XCTAssertEqual(stub.keywords[0], "military")
			XCTAssertEqual(stub.keywords[1], "criminal")
		}
		
		let enemies = stub.enemyTypes
		
		//this shouldn't include the sample monster, because I should have all its keywords commented out
		XCTAssertEqual(numberOfOccurencesOf(enemies, of: "sample enemy type"), 0)
		
		//this should include the hammerman twice, because the hammerman is military and criminal
		XCTAssertEqual(numberOfOccurencesOf(enemies, of: "hammerman"), 2)
		
		//this should include the bandit and fairy musketeer once, because they only match one keyword
		XCTAssertEqual(numberOfOccurencesOf(enemies, of: "bandit"), 1)
		XCTAssertEqual(numberOfOccurencesOf(enemies, of: "fairy musketeer"), 1)
	}
	
	func testMapStubGeneration()
	{
		//you are guaranteed to get no overlap between elements of map stubs
		//so generate 30 sets of them to try to confirm there's no overlap
		for _ in 0..<30
		{
			let stubs = MapGenerator.generateMapStubs()
			XCTAssertEqual(stubs.count, numStubs)
			for stub in stubs
			{
				for oStub in stubs
				{
					if !(stub === oStub)
					{
						//flavor and theme should both be different
						XCTAssertNotEqual(stub.flavor, oStub.flavor)
						XCTAssertNotEqual(stub.theme, oStub.theme)
					}
				}
			}
			
			
			//for the sake of convenience, just clear the memory between generations
			//this test isn't to determine what happens when you run out of names
			MapGenerator.clearNameMemory()
		}
	}
	
	//MARK: pathfinding tests
	func testPathfindingStraightLine()
	{
		let person = Creature(enemyType: "test pzombie", level: 1, x: 1, y: 1)
		map.tileAt(x: 1, y: 1).creature = person
		map.pathfinding(person, movePoints: 4)
		
		XCTAssertEqual(map.tilesAccessable.count, 15) //from this position, with no obstacles, it should be able to reach 15 tiles
		//P****		(the starting tile is considered accessable, so that makes 15)
		//****
		//***
		//**
		//*
		
		//these are spots you can just barely reach
		comparePathToExpected(toX: 5, toY: 1, expected: [(1, 1), (2, 1), (3, 1), (4, 1), (5, 1)])
		comparePathToExpected(toX: 1, toY: 5, expected: [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5)])
		
		//this is a spot that's too far
		XCTAssertNil(map.pathResultAt(x: 6, y: 1))
	}
	
	//TODO: future pathfinding tests:
	//	what if there's difficult terrain?
	//	what if there's walls in the way?
	//	what if there's a trap in the way? it should
	
	//MARK: helper functions
	func comparePathToExpected(toX x:Int, toY y:Int, expected:[(Int, Int)])
	{
		var expected = expected
		var x = x
		var y = y
		while expected.count > 1
		{
			if let result = map.pathResultAt(x: x, y: y)
			{
				expected.removeLast()
				XCTAssertEqual(result.backX, expected.last!.0)
				XCTAssertEqual(result.backY, expected.last!.1)
				x = result.backX
				y = result.backY
			}
			else
			{
				XCTAssertTrue(false)
			}
		}
	}
	func numberOfOccurencesOf(array:[String], of:String) -> Int
	{
		var occ = 0
		for value in array
		{
			if value == of
			{
				occ += 1
			}
		}
		return occ
	}
}