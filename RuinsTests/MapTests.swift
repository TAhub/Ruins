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
	
	func testCalculateVisibility()
	{
		map.calculateVisibility(x: 1, y: 1)
		for y in 1..<map.height
		{
			for x in 1..<map.width
			{
				let xDis = CGFloat(abs(x - 1))
				let yDis = CGFloat(abs(y - 1))
				let distance = sqrt(xDis * xDis + yDis * yDis)
				XCTAssertEqual(distance <= visibilityRange, map.tileAt(x: x, y: y).visible)
			}
		}
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
		XCTAssertEqual(lowLevelStub.totalEXP, 120)
		XCTAssertEqual(midLevelStub.totalEXP, 500)
		XCTAssertEqual(highLevelStub.totalEXP, 900)
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
	
	func testMapRoomCenter()
	{
		let room = MapRoom(x: 10, y: 8, width: 4, height: 6, roomClass: .Normal)
		XCTAssertEqual(room.centerX, 12)
		XCTAssertEqual(room.centerY, 11)
	}
	
	func testMapRoomContainsPoint()
	{
		let room = MapRoom(x: 10, y: 10, width: 10, height: 10, roomClass: .Normal)
		XCTAssertTrue(room.containsPoint(x: 10, y: 10))
		XCTAssertTrue(room.containsPoint(x: 15, y: 15))
		XCTAssertFalse(room.containsPoint(x: 9, y: 10))
	}
	
	func testMapRoomCollide()
	{
		let room = MapRoom(x: 10, y: 10, width: 10, height: 10, roomClass: .Normal)
		XCTAssertTrue(room.collide(MapRoom(x: 0, y: 10, width: 10, height: 10, roomClass: .Normal))) //there needs to be a gap of 1
		XCTAssertTrue(room.collide(MapRoom(x: 12, y: 12, width: 6, height: 6, roomClass: .Normal))) //inside
		XCTAssertFalse(room.collide(MapRoom(x: 0, y: 10, width: 5, height: 10, roomClass: .Normal))) //not inside
	}
	
	func testMapGeneratorRoomsAlgorithmValidity()
	{
		let (solidity, width, height, rooms) = MapGenerator.generateRoomsSolidityMap(MapStub(flavor: "lawless", theme: "city", level: 1))
		
		//firstly, there must be a start room and a boss room
		locateRoomsThenClosure(rooms)
		{ (startRoom, endRoom) in
			//secondly, run the general validity test
			self.validityGeneral(solidity, width: width, height: height, startRoom: startRoom, endRoom: endRoom)
			
			//finally, this algorithm is guaranteed to not need to be pruned
			//therefore, try to prune it and see if anything changes
			let (croppedSolidity, croppedWidth, croppedHeight) = MapGenerator.pruneSolidity(solidity, width: width, height: height)
			XCTAssertEqual(croppedWidth, width)
			XCTAssertEqual(croppedHeight, height)
			for i in 0..<min(croppedSolidity.count, solidity.count)
			{
				XCTAssertEqual(croppedSolidity[i], solidity[i])
			}
		}
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
		let newSolidity =
			[T, T, T, T, T, T, T,
			 T, T, T, T, T, F, T,
			 T, F, F, F, F, F, T,
			 T, F, F, F, T, T, T,
			 T, T, T, T, T, T, T]
		let newWidth = 7
		let newHeight = 5
		
		let (realSolidity, realWidth, realHeight) = MapGenerator.pruneSolidity(oldSolidity, width: oldWidth, height: oldHeight)
		
		XCTAssertEqual(newWidth, realWidth)
		XCTAssertEqual(newHeight, realHeight)
		XCTAssertEqual(newSolidity.count, realSolidity.count)
		for i in 0..<min(newSolidity.count, realSolidity.count)
		{
			XCTAssertEqual(newSolidity[i], realSolidity[i])
		}
	}
	
	func testPlaceTraps()
	{
		//trap placement depends heavily on other factors, so generate a functional map to place the traps in
		let player = Creature(enemyType: "human player", level: 1, x: 0, y: 0)
		let stub = MapStub(flavor: "lawless", theme: "city", level: 1)
		let (solidity, width, height, rooms) = MapGenerator.generateRoomsSolidityMap(stub)
		let tiles = MapGenerator.solidityToTiles(solidity, width: width, height: height, rooms: rooms, stub: stub)
		MapGenerator.placeCreatures(tiles, width: width, height: height, rooms: rooms, player: player, stub: stub)
		
		//now, place traps
		MapGenerator.placeTraps(tiles, width: width, height: height, stub: stub)
		
		//examine the traps placed for validity
		var numTraps = 0
		for y in 0..<height
		{
			for x in 0..<width
			{
				let tile = tiles[x + y * width]
				if let trap = tile.trap
				{
					numTraps += 1
					
					//first off, a trap cannot be in a non-walkable tile
					XCTAssertTrue(tile.walkable)
					
					//secondly, a trap cannot have a non-walkable tile or a trap in its surroundings
					for y in y-1...y+1
					{
						for x in x-1...x+1
						{
							let sTile = tiles[x + y * width]
							if !(tile === sTile)
							{
								XCTAssertTrue(sTile.walkable)
								XCTAssertNil(sTile.trap)
							}
						}
					}
					
					//fourthly, it should have an effective trap power of (15 + 2 * level)
					XCTAssertEqual(trap.trapPower, 17)
					
					//fifthly, it should be the right type for the map
					XCTAssertEqual(trap.type, "paralysis trap")
					
					//finally, all pre-generated traps must be non-good
					XCTAssertFalse(trap.good)
				}
			}
		}
		
		//make sure there are enough traps
		XCTAssertEqual(numTraps, 15)
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
				let solid = x == 0 || y == 0 || x == size - 1 || y == size - 1
				let tile = Tile(type: solid ? "sample wall" : "sample floor")
				tiles.append(tile)
			}
		}
		
		//place creatures in this rectangle
		let startRoom = MapRoom(x: 1, y: 1, width: 4, height: 4, roomClass: .Start)
		let endRoom = MapRoom(x: 5, y: 1, width: 4, height: 4, roomClass: .Boss)
		let roomOne = MapRoom(x: 15, y: 15, width: 3, height: 3, roomClass: .Normal)
		let roomTwo = MapRoom(x: 15, y: 20, width: 3, height: 3, roomClass: .Normal)
		let rooms = [startRoom, endRoom, roomOne, roomTwo]
		
		let player = Creature(enemyType: "human player", level: 1, x: 0, y: 0)
		let stub = MapStub(flavor: "lawless", theme: "city", level: 10)
		MapGenerator.placeCreatures(tiles, width: size, height: size, rooms: rooms, player: player, stub: stub)
		
		//first off, the player should now be at startX, startY
		XCTAssertEqual(player.x, 3)
		XCTAssertEqual(player.y, 3)
		XCTAssertTrue((tiles[3 + 3 * size].creature === player))
		
		//secondly, there should be a boss at the center of the end room
		let cr = tiles[7 + 3 * size].creature
		XCTAssertNotNil(cr)
		if let cr = cr
		{
			XCTAssertTrue(cr.boss)
		}
		
		//thirdly, make sure that all the non-player, non-boss enemies generated are in the possible generation list
		let enemyTypes = stub.enemyTypes
		var totalEXP = 0
		var roomOneHasEnemy = false
		var roomTwoHasEnemy = false
		for tile in tiles
		{
			if let creature = tile.creature
			{
				if !creature.good && !creature.boss
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
					
					//test to make sure it's inside roomOne or roomTwo
					let rOHE = roomOne.containsPoint(x: creature.x, y: creature.y)
					let rTHE = roomTwo.containsPoint(x: creature.x, y: creature.y)
					roomOneHasEnemy = roomOneHasEnemy || rOHE
					roomTwoHasEnemy = roomTwoHasEnemy || rTHE
					XCTAssertTrue(rOHE || rTHE)
				}
			}
		}
		
		//make sure if roomOne and roomTwo both have at least one enemy inside
		XCTAssertTrue(roomOneHasEnemy)
		XCTAssertTrue(roomTwoHasEnemy)
		
		//make sure that the enemies ENEMY TYPE levels add up to the proper amount for generation
		//a little bit under anyway, ideally
		XCTAssertLessThanOrEqual(totalEXP, stub.totalEXP)
		XCTAssertGreaterThan(totalEXP, stub.totalEXP / 2)
	}
	
	func testPlacePits()
	{
		let T = true
		let F = false
		let solidity = [T, T, T, T, T, T,
		                T, T, T, T, T, T,
		                T, T, T, T, T, T,
		                F, F, F, F, F, F,
		                F, F, F, F, F, F,
		                F, F, F, F, F, F]
		let megastructure = [T, T, T, F, F, F,
		                     T, T, T, F, F, F,
		                     T, T, T, F, F, F,
		                     T, T, T, F, F, F,
		                     T, T, T, F, F, F,
		                     T, T, T, F, F, F]
		let width = 6
		let height = 6
		
		let pit = MapGenerator.makePits(solidity, width: width, height: height, megastructure: megastructure, stub: MapStub(flavor: "lawless", theme: "cave", level: 1))
		
		XCTAssertEqual(pit.count, solidity.count)
		if pit.count == solidity.count
		{
			//I can't guarantee the number of pits, because it might try to extend the pit into an invalid area and get over-written
			//I can only guarantee there will be A pit
			var hasPit = false
			for i in 0..<solidity.count
			{
				if pit[i]
				{
					//the tile must be solid, and free of megastructures
					XCTAssertTrue(solidity[i])
					XCTAssertFalse(megastructure[i])
					hasPit = true
				}
			}
			XCTAssertTrue(hasPit)
		}
	}
	
	func testPlaceDifficultTerrain()
	{
		let T = true
		let F = false
		let solidity = [T, T, T, T, T, T,
		                T, T, T, T, T, T,
		                T, T, T, T, T, T,
		                F, F, F, F, F, F,
		                F, F, F, F, F, F,
		                F, F, F, F, F, F]
		let megastructure = [T, T, T, F, F, F,
		                     T, T, T, F, F, F,
		                     T, T, T, F, F, F,
		                     T, T, T, F, F, F,
		                     T, T, T, F, F, F,
		                     T, T, T, F, F, F]
		let width = 6
		let height = 6
		
		let difficult = MapGenerator.makeDifficultTiles(solidity, width: width, height: height, megastructure: megastructure, stub: MapStub(flavor: "lawless", theme: "cave", level: 1))
		
		XCTAssertEqual(difficult.count, solidity.count)
		if difficult.count == solidity.count
		{
			var numDifficult = 0
			for i in 0..<solidity.count
			{
				if difficult[i]
				{
					//the tile can't be solid OR home to a megastructure
					XCTAssertFalse(solidity[i])
					XCTAssertFalse(megastructure[i])
					numDifficult += 1
				}
			}
			//with the cave scheme, and with exactly 9 difficult tiles, there should be exactly 3 difficult tiles
			XCTAssertEqual(numDifficult, 3)
		}
	}
	
	func testSolidityToTiles()
	{
		let T = true
		let F = false
		let solidity = [T, T, T, T, T, T, T,
		                T, F, F, F, F, T, T,
		                T, F, T, T, F, T, T,
		                T, T, T, T, T, T, T,
		                T, T, T, T, T, T, T,
		                T, F, F, F, F, F, T,
		                T, F, F, F, F, F, T,
		                T, F, F, F, F, F, T,
		                T, F, F, F, F, F, T,
		                T, F, F, F, F, F, T,
		                T, T, T, T, T, T, T,
		                T, T, T, T, T, T, T,
		                ]
		let width = 7
		let height = 12
		let rooms = [MapRoom(x: 0, y: 4, width: endRoomSize, height: endRoomSize, roomClass: MapRoomClass.Boss)]
		let tiles = MapGenerator.solidityToTiles(solidity, width: width, height: height, rooms: rooms, stub: MapStub(flavor: "lawless", theme: "cave", level: 1))
		
		//note that the boss room megastructure will clear a 5x5 area in the 7x7 boss room
		//even if the boss room is entirely solid wall, because it's over-writing tiles
		
		//test to see if the solidity matches
		XCTAssertEqual(tiles.count, solidity.count)
		var tileTypes = Set<String>()
		for i in 0..<min(tiles.count, solidity.count)
		{
			XCTAssertEqual(solidity[i], tiles[i].solid)
			tileTypes.insert(tiles[i].type)
		}
		
		//test to see if the tiles are using the appropriate tilesets
		//including the boss room tiles
		XCTAssertTrue(tileTypes.contains("cave wall"))
		XCTAssertTrue(tileTypes.contains("cave floor"))
		XCTAssertTrue(tileTypes.contains("pit"))
		XCTAssertTrue(tileTypes.contains("rubble floor"))
		for i in 1...7
		{
			XCTAssertTrue(tileTypes.contains("throne \(i)"))
		}
		XCTAssertTrue(tileTypes.contains("warning floor"))
	}
	
	func testEnemyTypeEXPValue()
	{
		XCTAssertEqual(MapGenerator.expValueForEnemyType("bandit"), 12) //enemy with armor
		XCTAssertEqual(MapGenerator.expValueForEnemyType("rat"), 7) //enemy without armor
		XCTAssertEqual(MapGenerator.expValueForEnemyType("pixie"), 26) //enemy who ignores terrain
		XCTAssertEqual(MapGenerator.expValueForEnemyType("hoop snake"), 28) //enemy with extra movement
		XCTAssertEqual(MapGenerator.expValueForEnemyType("shambler"), 4) //enemy with less movement
		XCTAssertEqual(MapGenerator.expValueForEnemyType("scout"), 19) //enemy with magic
	}
	
	//MARK: pathfinding tests
	func testPathfindingStraightLine()
	{
		let person = Creature(enemyType: "test pzombie", level: 1, x: 1, y: 1)
		map.tileAt(x: 1, y: 1).creature = person
		map.pathfinding(person, movePoints: 4, ignoreTerrainCosts: false)
		
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
	
	func testPathfindingAvoidTrap()
	{
		//place a trap just to the right of the person
		//this should make it very hard to path to anywhere on the right
		map.tileAt(x: 2, y: 1).trap = Trap(type: "sample trap", trapPower: 10, good: true)
		
		let person = Creature(enemyType: "test pzombie", level: 1, x: 1, y: 1)
		map.tileAt(x: 1, y: 1).creature = person
		map.pathfinding(person, movePoints: 4, ignoreTerrainCosts: false)
		
		//when asked to move to x=3, you should walk over the trap because it's a player trap and just adds 1 move cost
		comparePathToExpected(toX: 3, toY: 1, expected: [(1, 1), (2, 1), (3, 1)])
		
		//you can't quite reach x=5, because of the effective extra cost
		XCTAssertNil(map.pathResultAt(x: 5, y: 1))
		
		//now replace that trap with a world trap
		//the AI should avoid this much more strictly
		map.tileAt(x: 2, y: 1).trap = Trap(type: "sample trap", trapPower: 10, good: false)
		map.pathfinding(person, movePoints: 4, ignoreTerrainCosts: false)
		
		//now when asked to move to x=3, you should walk around the trap
		comparePathToExpected(toX: 3, toY: 1, expected: [(1, 1), (1, 2), (2, 2), (3, 2), (3, 1)])
	}
	
	//TODO: future pathfinding tests:
	//	what if there's difficult terrain?
	//		furthermore, make sure "ignore terrain costs" works
	//	what if there's walls in the way?
	
	//MARK: helper functions
	func validityGeneral(solidity:[Bool], width:Int, height:Int, startRoom:MapRoom, endRoom:MapRoom)
	{
		//all non-solid tiles must be accessable
		//(number of accessable tiles will be 0 if the start is solid)
		XCTAssertEqual(self.numberOfNonSolidTiles(solidity), self.numberOfAccessableTiles(solidity, startX: startRoom.centerX, startY: startRoom.centerY, width: width, height: height))
		
		//the end area must be an (endRoomSize x endRoomSize) square of non-solid tiles, with only one non-solid tile in the border
		var innerSolid = 0
		var outerSolid = 0
		for y in -1..<endRoomSize+1
		{
			for x in -1..<endRoomSize+1
			{
				if solidity[(x + endRoom.x) + (y + endRoom.y) * width]
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
		XCTAssertEqual(outerSolid, endRoomSize * 4 + 4 - 1) //endRoomSize * 4 is the edges, + 4 is the corners, - 1 is the one tile entrance
		XCTAssertEqual(endRoom.width, endRoomSize)
		XCTAssertEqual(endRoom.height, endRoomSize)
	}
	
	func locateRoomsThenClosure(rooms:[MapRoom], closure:(startRoom:MapRoom, endRoom:MapRoom)->())
	{
		var startRoom:MapRoom?
		var endRoom:MapRoom?
		for room in rooms
		{
			switch (room.roomClass)
			{
			case .Start: startRoom = room
			case .Boss: endRoom = room
			default: break
			}
		}
		XCTAssertNotNil(startRoom)
		XCTAssertNotNil(endRoom)
		if let startRoom = startRoom, endRoom = endRoom
		{
			closure(startRoom: startRoom, endRoom: endRoom)
		}
	}
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
				if x != expected.last!.0 || y != expected.last!.1
				{
					return
				}
			}
			else
			{
				XCTAssertTrue(false)
				return
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