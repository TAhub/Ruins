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
	
    override func setUp() {
        super.setUp()
		
		map = Map(width: 10, height: 10)
    }
 
	func testDefaultMapGen()
	{
		//it should have borders at all sides
		XCTAssertTrue(map.tileAt(x: 0, y: 0).solid)
		XCTAssertTrue(map.tileAt(x: 9, y: 0).solid)
		XCTAssertTrue(map.tileAt(x: 0, y: 9).solid)
		XCTAssertTrue(map.tileAt(x: 9, y: 9).solid)
		XCTAssertFalse(map.tileAt(x: 1, y: 1).solid)
	}
	
	func testWalkable()
	{
		XCTAssertFalse(map.tileAt(x: 0, y: 0).walkable)
		XCTAssertTrue(map.tileAt(x: 1, y: 1).walkable)
		map.tileAt(x: 1, y: 1).creature = Creature(enemyType: "test creature", level: 1, x: 1, y: 1)
		XCTAssertFalse(map.tileAt(x: 1, y: 1).walkable)
	}
	
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
}