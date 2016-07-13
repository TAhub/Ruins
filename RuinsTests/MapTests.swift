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
			stubs.append(MapStub(flavor: "poisonous", theme: "wasteland", level: 1))
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
			let _ = MapStub(flavor: "poisonous", theme: "wasteland", level: 1)
		}
	}
	
	func testMapStubAttributes()
	{
		let stub = MapStub(flavor: "poisonous", theme: "wasteland", level: 1)
		XCTAssertEqual(stub.keywords.count, 2)
		if stub.keywords.count == 2
		{
			XCTAssertEqual(stub.keywords[0], "criminal")
			XCTAssertEqual(stub.keywords[1], "poison")
		}
		
		//also make sure that alternate keywords work
		let stubTwo = MapStub(flavor: "battlefield", theme: "fort", level: 1)
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
		let stub = MapStub(flavor: "lawless", theme: "fort", level: 999)
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
	
	func testMapStubTotalEXP()
	{
		let lowLevelStub = MapStub(flavor: "lawless", theme: "fort", level: 1)
		let midLevelStub = MapStub(flavor: "lawless", theme: "fort", level: 20)
		let highLevelStub = MapStub(flavor: "lawless", theme: "fort", level: 40)
		//TODO: take into account map theme exp multiplier
		XCTAssertEqual(lowLevelStub.totalEXP, 60)
		XCTAssertEqual(midLevelStub.totalEXP, 250)
		XCTAssertEqual(highLevelStub.totalEXP, 450)
	}
	
	func testMapStubEnemyListMaxLevel()
	{
		let lowLevelStub = MapStub(flavor: "lawless", theme: "fort", level: 1)
		let lowLevelStubEnemies = lowLevelStub.enemyTypes
		let midLevelStub = MapStub(flavor: "lawless", theme: "fort", level: 20)
		let midLevelStubEnemies = midLevelStub.enemyTypes
		let highLevelStub = MapStub(flavor: "lawless", theme: "fort", level: 40)
		let highLevelStubEnemies = highLevelStub.enemyTypes
		XCTAssertGreaterThan(midLevelStubEnemies.count, lowLevelStubEnemies.count)
		XCTAssertGreaterThan(highLevelStubEnemies.count, midLevelStubEnemies.count)
		
		//make sure no list has any enemy higher level than expected
		func stubTestByLevel(stub:MapStub, enemies:[String]) -> Bool
		{
			for enemy in enemies
			{
				let level = DataStore.getInt("EnemyTypes", enemy, "level")!
				if level > stub.level + expLevelAdd
				{
					return false
				}
			}
			return true
		}
		XCTAssertTrue(stubTestByLevel(lowLevelStub, enemies: lowLevelStubEnemies))
		XCTAssertTrue(stubTestByLevel(midLevelStub, enemies: midLevelStubEnemies))
		XCTAssertTrue(stubTestByLevel(highLevelStub, enemies: highLevelStubEnemies))
	}
	
	func testMapStubGeneration()
	{
		//you are guaranteed to get no overlap between elements of map stubs
		//so generate 30 sets of them to try to confirm there's no overlap
		for _ in 0..<30
		{
			let stubs = MapGenerator.generateMapStubs(0)
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
						XCTAssertGreaterThanOrEqual(stub.level, 2)
						XCTAssertLessThanOrEqual(stub.level, 3)
					}
				}
			}
			
			
			//for the sake of convenience, just clear the memory between generations
			//this test isn't to determine what happens when you run out of names
			MapGenerator.clearNameMemory()
		}
	}
	
	func testMapGeneratorValidity()
	{
		let (solidity, width, height, startX, startY, endX, endY) = MapGenerator.generateSolidityMap(MapStub(flavor: "lawless", theme: "city", level: 1))
		
		//firstly, all non-solid tiles must be accessable
		//(number of accessable tiles will be 0 if the start is solid)
		XCTAssertEqual(numberOfNonSolidTiles(solidity), numberOfAccessableTiles(solidity, startX: startX, startY: startY, width: width, height: height))
		
		//secondly, the end area must be an (endRoomSize x endRoomSize) square of non-solid tiles, with only one non-solid tile in the border
		var innerSolid = 0
		var outerSolid = 0
		for y in -1..<endRoomSize+1
		{
			for x in -1..<endRoomSize+1
			{
				if solidity[(x + endX) + (y + endY) * width]
				{
					outerSolid += 1
					if !(y == -1 || x == -1 || x == endRoomSize || y == endRoomSize)
					{
						innerSolid += 1
					}
				}
			}
		}
		XCTAssertEqual(innerSolid, 0)
		XCTAssertEqual(outerSolid, endRoomSize * 4 + 4 - 1) //endRoomSize * 4 is the edges, + 4 is the corners, - 1 is the one tile enterance
	}
	
	func testMapGeneratorClip()
	{
		let T = true
		let F = false
		let oldSolidity =
			[T, T, T, T, T, T, T, T, T, T,
			 T, T, T, T, T, T, T, T, T, T,
			 T, T, T, T, T, T, T, T, T, T,
			 T, T, T, T, T, T, F, T, T, T,
			 T, T, F, F, F, F, F, T, T, T,
			 T, T, F, F, F, T, T, T, T, T]
		let oldWidth = 10
		let oldHeight = 6
		let oldStartX = 6
		let oldStartY = 3
		let oldEndX = 2
		let oldEndY = 4
		let newSolidity =
			[T, T, T, T, T, T, T,
			 T, T, T, T, T, F, T,
			 T, F, F, F, F, F, T,
			 T, F, F, F, T, T, T,
			 T, T, T, T, T, T, T]
		let newWidth = 7
		let newHeight = 5
		let newStartX = 5
		let newStartY = 1
		let newEndX = 1
		let newEndY = 2
		
		let (realSolidity, realWidth, realHeight, realStartX, realStartY, realEndX, realEndY) = MapGenerator.pruneSolidity(oldSolidity, width: oldWidth, height: oldHeight, startX: oldStartX, startY: oldStartY, endX: oldEndX, endY: oldEndY)
		
		XCTAssertEqual(newWidth, realWidth)
		XCTAssertEqual(newHeight, realHeight)
		XCTAssertEqual(newStartX, realStartX)
		XCTAssertEqual(newStartY, realStartY)
		XCTAssertEqual(newEndX, realEndX)
		XCTAssertEqual(newEndY, realEndY)
		XCTAssertEqual(newSolidity.count, realSolidity.count)
		for i in 0..<min(newSolidity.count, realSolidity.count)
		{
			XCTAssertEqual(newSolidity[i], realSolidity[i])
		}
	}
	
	func testPlaceCreatures()
	{
		//just make a big empty rectangle of tiles to place creatures in
		let size = 40
		var tiles = [Tile]()
		for y in 0..<size
		{
			for x in 0..<size
			{
				let tile = Tile(solid: x == 0 || y == 0 || x == size - 1 || y == size - 1)
				tiles.append(tile)
			}
		}
		
		//place creatures in this rectangle
		let startX = 5
		let startY = 5
		let endX = size / 2
		let endY = size / 2
		
		let player = Creature(enemyType: "human player", level: 1, x: 0, y: 0)
		let stub = MapStub(flavor: "lawless", theme: "city", level: 10)
		MapGenerator.placeCreatures(tiles, width: size, height: size, startX: startX, startY: startY, endX: endX, endY: endY, player: player, stub: stub)
		
		//first off, the player should now be at startX, startY
		XCTAssertEqual(player.x, startX)
		XCTAssertEqual(player.y, startY)
		XCTAssertTrue((tiles[startX + startY * size].creature === player))
		
		//secondly, there should be a boss at the center of the end room
		XCTAssertNotNil(tiles[endX + endRoomSize / 2 + (endY + endRoomSize / 2) * size].creature)
		//TODO: check to see if this is an actual boss
		
		//thirdly, make sure that all the non-player, non-boss enemies generated are in the possible generation list
		let enemyTypes = stub.enemyTypes
		var totalEXP = 0
		for tile in tiles
		{
			if let creature = tile.creature
			{
				if !creature.good //TODO: also if it's not a boss
				{
					totalEXP += MapGenerator.expValueForEnemyType(creature.enemyType)
					
					var isPossibleType = false
					for enemyType in enemyTypes
					{
						if creature.enemyType == enemyType
						{
							isPossibleType = true
							break
						}
					}
					XCTAssertTrue(isPossibleType)
				}
			}
		}
		
		//make sure that the enemies ENEMY TYPE levels add up to the proper amount for generation
		//a little bit under anyway, ideally
		XCTAssertLessThanOrEqual(totalEXP, stub.totalEXP)
		XCTAssertGreaterThan(totalEXP, 0)
	}
	
	func testEnemyTypeEXPValue()
	{
		XCTAssertEqual(MapGenerator.expValueForEnemyType("bandit"), 12) //enemy with armor
		XCTAssertEqual(MapGenerator.expValueForEnemyType("shambler"), 6) //enemy without armor
		//TODO: enemy with magic
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
	func numberOfNonSolidTiles(solidity:[Bool]) -> Int
	{
		var nonSolid = 0
		for solid in solidity
		{
			if !solid
			{
				nonSolid += 1
			}
		}
		return nonSolid
	}
	func numberOfAccessableTiles(solidity:[Bool], startX:Int, startY:Int, width:Int, height:Int) -> Int
	{
		var accessable = [Bool]()
		for _ in solidity
		{
			accessable.append(false)
		}
		
		func exploreAround(x x:Int, y:Int)
		{
			if x >= 0 && y >= 0 && x < width && y < height
			{
				let i = x + y * width
				if !accessable[i] && !solidity[i]
				{
					accessable[i] = true
					exploreAround(x: x - 1, y: y)
					exploreAround(x: x + 1, y: y)
					exploreAround(x: x, y: y - 1)
					exploreAround(x: x, y: y + 1)
				}
			}
		}
		exploreAround(x: startX, y: startY)
		
		var numAcc = 0
		for acc in accessable
		{
			if acc
			{
				numAcc += 1
			}
		}
		return numAcc
	}
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