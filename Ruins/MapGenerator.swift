//
//  MapGenerator.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/12/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation

let numStubs = 3
let endRoomSize = 7
let expBase = 5
let expMagicMult = 25
let expArmorMult = 25
let expMovePointMult = 25
let expIgnoreTerrainCostMult = 15
let levelAddMin = 2
let levelAddMax = 3
let expLevelAdd = 7 //TODO: this should probably be a smaller value, once I add more low-level filler enemies? perhaps from gangs
let mapGeneratorPickEnemiesTries = 10

enum MapRoomClass
{
	case Boss
	case Start
	case Normal
}

struct MapRoom
{
	var x:Int
	var y:Int
	var width:Int
	var height:Int
	var roomClass:MapRoomClass
	var roomEXP:Int
	init(x:Int, y:Int, width:Int, height:Int, roomClass:MapRoomClass)
	{
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.roomClass = roomClass
		roomEXP = 0
	}
	var centerX:Int
	{
		return x + width / 2
	}
	var centerY:Int
	{
		return y + height / 2
	}
	func containsPoint(x pX:Int, y pY:Int) -> Bool
	{
		return pX >= x && pY >= y && pX < x + width && pY < y + height
	}
	func collide(room:MapRoom) -> Bool
	{
		//take into account the 1-tile border
		return !(self.x - 1 > room.x + room.width - 1 || self.y - 1 > room.y + room.height - 1 ||
				self.x + self.width < room.x || self.y + self.height < room.y)
	}
}

class MapStub
{
	let level:Int
	let flavor:String
	let theme:String
	let name:String
	init(flavor:String, theme:String, name:String)
	{
		self.flavor = flavor
		self.theme = theme
		self.name = ""
		self.level = 0
	}
	init(flavor:String, theme:String, level:Int)
	{
		self.flavor = flavor
		self.theme = theme
		self.level = level
		
		//pick a unique name based on these factors
		let prefixes = DataStore.getArray("MapFlavors", flavor, "prefixes") as! [String]
		let suffixes = DataStore.getArray("MapThemes", theme, "suffixes") as! [String]
		
		
		//first, get all of the names that have been picked so far
		let existingNames = MapGenerator.getNameMemory()
		
		//convert the existing names into a dictionary for fast lookup
		var existingNameDict = [String : Bool]()
		for name in existingNames
		{
			existingNameDict[name] = true
		}
		
		//now calculate every possible name
		var possibleNames = [String]()
		var uniqueNames = [String]()
		
		//remove all existing names from the possible names list
		for prefix in prefixes
		{
			for suffix in suffixes
			{
				let name = "\(prefix) \(suffix)"
				if existingNameDict[name] == nil
				{
					uniqueNames.append(name)
				}
				possibleNames.append(name)
			}
		}
		
		if uniqueNames.count == 0
		{
			//every possible name has been picked already, so just pick a name
			name = possibleNames.randomElement!
		}
		else
		{
			//pick a possible name
			name = uniqueNames.randomElement!
			
			//and register it
			var newNames = existingNames
			newNames.append(name)
			NSUserDefaults.standardUserDefaults().setObject(newNames, forKey: "name memory")
		}
	}
	
	var keywords:[String]
	{
		let k1 = DataStore.getString("MapThemes", theme, "keyword")!
		var k2 = DataStore.getString("MapFlavors", flavor, "keyword")!
		if k1 == k2
		{
			k2 = DataStore.getString("MapFlavors", flavor, "alternate keyword")!
		}
		
		return [k1, k2]
	}
	
	var enemyTypes:[String]
	{
		let typesRaw = DataStore.getPlist("EnemyTypes").keys
		let types = [NSString](typesRaw) as! [String]
		
		var correctTypes = [String]()
		
		let keywords = self.keywords
		for type in types
		{
			let typeKeywords = DataStore.getArray("EnemyTypes", type, "keywords") as! [String]
			for keyword in typeKeywords
			{
				for myKeyword in keywords
				{
					if keyword == myKeyword
					{
						correctTypes.append(type)
						//DON'T break; if there's multi-matches I want to multi-add
					}
				}
			}
		}
		
		//finally, filter by level
		return correctTypes.filter()
		{
			DataStore.getInt("EnemyTypes", $0, "level")! <= level + expLevelAdd
		}
	}
	
	var totalEXP:Int
	{
		return DataStore.getInt("MapThemes", theme, "creature exp multiplier")! * (expBase + level)
	}
}

class MapGenerator
{
	//MARK: map stub
	static func generateMapStubs(oldLevel:Int) -> [MapStub]
	{
		var stubs = [MapStub]()
		
		//get the full list of flavors and themes
		let flavorsRaw = DataStore.getPlist("MapFlavors").keys
		let themesRaw = DataStore.getPlist("MapThemes").keys
		var flavors = [NSString](flavorsRaw) as! [String]
		var themes = [NSString](themesRaw) as! [String]
		flavors.shuffleInPlace()
		themes.shuffleInPlace()
		
		//and just take the elements in row from the shuffled arrays
		for i in 0..<numStubs
		{
			let newLevel = oldLevel + levelAddMin + Int(arc4random_uniform(UInt32(levelAddMax - levelAddMin)))
			stubs.append(MapStub(flavor: flavors[i], theme: themes[i], level: newLevel))
		}
		return stubs
	}
	
	static func clearNameMemory()
	{
		NSUserDefaults.standardUserDefaults().setObject([String](), forKey: "name memory")
	}
	
	static func getNameMemory() -> [String]
	{
		return (NSUserDefaults.standardUserDefaults().arrayForKey("name memory") as? [String]) ?? [String]()
	}
	
	static func loadNameMemory(memory:[String])
	{
		NSUserDefaults.standardUserDefaults().setObject(memory, forKey: "name memory")
	}
	
	//MARK: map generation
	
	static func mapGenerate(mapStub:MapStub, player:Creature) -> (tiles:[Tile], width:Int, height:Int)
	{
		//this is the rooms algorithm
		//remember that this one doesn't require pruning, but others might
		let (solidity, width, height, rooms) = generateRoomsSolidityMap(mapStub)
		let tiles = solidityToTiles(solidity, width: width, height: height, rooms: rooms, stub: mapStub)
		placeCreatures(tiles, width: width, height: height, rooms: rooms, player: player, stub: mapStub)
		placeTraps(tiles, width: width, height: height, stub: mapStub)
		return (tiles: tiles, width: width, height: height)
	}
	
	//MARK: map generation components
	
	//this algorithm generates the rooms and the solidity map at the same time
	//it makes a series of rectangular rooms joined by hallways
	//it is guaranteed to not need to be trimmed
	static func generateRoomsSolidityMap(mapStub:MapStub) -> (solidity:[Bool], width:Int, height:Int, rooms:[MapRoom])
	{
		var rooms = [MapRoom]()
		
		//start with the boss room
		let bossRoom = MapRoom(x: 0, y: 0, width: endRoomSize, height: endRoomSize, roomClass: .Boss)
		rooms.append(bossRoom)
		let numRooms = 10
		let roomSize = 5
		
		//place other rooms
		while rooms.count < numRooms
		{
			let branchRoom = rooms.last!
			
			//pick a size
			//TODO: randomize this a bit
			let width = roomSize
			let height = roomSize
			
			var possibilities = [MapRoom]()
			func makePossibility(xA xA:Int, yA:Int)
			{
				possibilities.append(MapRoom(x: branchRoom.x + xA, y: branchRoom.y + yA, width: width, height: height, roomClass: rooms.count == numRooms - 1 ? .Start : .Normal))
			}
			
			//get the four possibilities
			makePossibility(xA: -width - 1, yA: 0)
			makePossibility(xA: branchRoom.width + 1, yA: 0)
			makePossibility(xA: 0, yA: -height - 1)
			makePossibility(xA: 0, yA: branchRoom.height + 1)
			
			//shuffle them
			possibilities.shuffleInPlace()
			
			//try out the possibilities in order
			var pickedRoom:MapRoom?
			for possibility in possibilities
			{
				//check against other rooms to see if there's any collision
				var collision = false
				for room in rooms
				{
					if room.collide(possibility)
					{
						collision = true
						break
					}
				}
				
				if !collision
				{
					pickedRoom = possibility
					break
				}
			}
			
			if let pickedRoom = pickedRoom
			{
				//that room has been picked!
				rooms.append(pickedRoom)
			}
			else
			{
				//otherwise, you failed to generate; cancel and restart
				return generateRoomsSolidityMap(mapStub)
			}
		}
		
		//bound the rooms
		var left:Int = 99999
		var right:Int = -99999
		var top:Int = 99999
		var bottom:Int = -99999
		for room in rooms
		{
			left = min(left, room.x)
			right = max(right, room.x + room.width - 1)
			top = min(top, room.y)
			bottom = max(bottom, room.y + room.height - 1)
		}
		rooms = rooms.map() { MapRoom(x: $0.x - left + 1, y: $0.y - top + 1, width: $0.width, height: $0.height, roomClass: $0.roomClass) }
		
		let width = right - left + 3
		let height = bottom - top + 3
		
		var solidity = [Bool]()
		for _ in 0..<(width * height)
		{
			solidity.append(true)
		}
		var lastRoom:MapRoom?
		for room in rooms
		{
			func carveBounds(x1 x1:Int, y1:Int, x2:Int, y2:Int)
			{
				for y in y1...y2
				{
					for x in x1...x2
					{
						solidity[x + y * width] = false
					}
				}
			}
			
			//carve out the inside of the room
			carveBounds(x1: room.x, y1: room.y, x2: room.x + room.width - 1, y2: room.y + room.height - 1)
			
			
			if let lastRoom = lastRoom
			{
				//carve out a hallway between the two
				
				let midPointX = (room.centerX + lastRoom.centerX) / 2
				let midPointY = (room.centerY + lastRoom.centerY) / 2
				
				var x1:Int = midPointX
				var x2:Int = midPointX
				var y1:Int = midPointY
				var y2:Int = midPointY
				while true
				{
					var eitherChecked = false
					
					if x1 > 0 && x2 < width - 1
					{
						eitherChecked = true
						if (room.containsPoint(x: x1, y: midPointY) || room.containsPoint(x: x2, y: midPointY)) &&
							(lastRoom.containsPoint(x: x1, y: midPointY) || lastRoom.containsPoint(x: x2, y: midPointY))
						{
							//it's a horizontal hallway
							carveBounds(x1: x1, y1: midPointY, x2: x2, y2: midPointY)
							
							break
						}
					}
					if y1 > 0 && y2 < height - 1
					{
						eitherChecked = true
						if (room.containsPoint(x: midPointX, y: y1) || room.containsPoint(x: midPointX, y: y2)) &&
							(lastRoom.containsPoint(x: midPointX, y: y1) || lastRoom.containsPoint(x: midPointX, y: y2))
						{
							//it's a vertical hallway!
							carveBounds(x1: midPointX, y1: y1, x2: midPointX, y2: y2)
							
							break
						}
					}
					
					if !eitherChecked
					{
						//failed to make a hallway at all, somehow
						assertionFailure()
					}
					
					x1 -= 1
					x2 += 1
					y1 -= 1
					y2 += 1
				}
			}
			
			lastRoom = room
		}
		
		return (solidity: solidity, width: width, height: height, rooms: rooms)
	}
	
	static func pruneSolidity(oldSolidity:[Bool], width oldWidth:Int, height oldHeight:Int) -> (solidity:[Bool], width:Int, height:Int)
	{
		//locate the four borders of the map
		var left = oldWidth
		var right = 0
		var top = oldHeight
		var bottom = 0
		for y in 0..<oldHeight
		{
			for x in 0..<oldWidth
			{
				let i = x + y * oldWidth
				if !oldSolidity[i]
				{
					left = min(x, left)
					right = max(x, right)
					top = min(y, top)
					bottom = max(y, bottom)
				}
			}
		}
		
		//translate the old solidity array into the new context (keep in mind the 1-tile borders)
		let width = right - left + 3
		let height = bottom - top + 3
		var solidity = [Bool]()
		for _ in 0..<(width*height)
		{
			solidity.append(true)
		}
		
		for y in top...bottom
		{
			for x in left...right
			{
				let oldI = x + y * oldWidth
				let newI = (x - left + 1) + (y - top + 1) * width
				solidity[newI] = oldSolidity[oldI]
			}
		}
		
		return (solidity: solidity, width: width, height: height)
	}
	
	static func placeTraps(tiles:[Tile], width:Int, height:Int, stub:MapStub)
	{
		var numTraps = DataStore.getInt("MapThemes", stub.theme, "trap number")!
		
		func trapTileOK(x x:Int, y:Int) -> Bool
		{
			let tile = tiles[x + y * width]
			return tile.trap == nil && tile.walkable
		}
		
		while numTraps > 0
		{
			let x = Int(arc4random_uniform(UInt32(width - 2))) + 1
			let y = Int(arc4random_uniform(UInt32(height - 2))) + 1
			
			//see if it's a valid spot for a trap
			var spotOK = true
			for y in y-1...y+1
			{
				for x in x-1...x+1
				{
					if !trapTileOK(x: x, y: y)
					{
						spotOK = false
						break
					}
				}
			}
			
			if spotOK
			{
				let trapType = DataStore.getString("MapFlavors", stub.flavor, "trap type")!
				tiles[x + y * width].trap = Trap(type: trapType, trapPower: 15 + 2 * stub.level, good: false)
				numTraps -= 1
			}
		}
	}
	
	static func placeCreatures(tiles:[Tile], width:Int, height:Int, rooms:[MapRoom], player:Creature, stub:MapStub)
	{
		//locate the start and end rooms
		var startRoom:MapRoom!
		var endRoom:MapRoom!
		var encounterRooms = [MapRoom]()
		for room in rooms
		{
			switch(room.roomClass)
			{
			case .Boss: endRoom = room
			case .Start: startRoom = room
			case .Normal: encounterRooms.append(room)
			}
		}
		
		
		//place the player
		player.x = startRoom.centerX
		player.y = startRoom.centerY
		tiles[startRoom.centerX + startRoom.centerY * width].creature = player
		
//		return
		
		let enemyTypes = stub.enemyTypes
		
		//assign EXP to rooms
		//TODO: for now this is even shares; in the future it might be good to have some rooms have bigger/smaller shares
		for i in 0..<encounterRooms.count
		{
			encounterRooms[i].roomEXP = stub.totalEXP / encounterRooms.count
		}
		
		for room in encounterRooms
		{
			//come up with a group of enemies with less total EXP than the room's EXP allotment
			//try a few times to find the best one
			var enemyTypesFiltered = enemyTypes
			var lastEnemiesToPlace:[String]!
			var lastTotalEXP = 0
			for _ in 0..<mapGeneratorPickEnemiesTries
			{
				var totalEXP = 0
				var enemiesToPlace = [String]()
				
				while true
				{
					enemyTypesFiltered = enemyTypesFiltered.filter() { totalEXP + expValueForEnemyType($0) <= room.roomEXP }
					if enemyTypesFiltered.count == 0
					{
						break
					}
					let pick = enemyTypesFiltered.randomElement!
					totalEXP += expValueForEnemyType(pick)
					enemiesToPlace.append(pick)
				}
				
				if totalEXP > lastTotalEXP
				{
					lastTotalEXP = totalEXP
					lastEnemiesToPlace = enemiesToPlace
				}
			}
		
			
			//now use those enemies you picked
			
			//find all of the valid tiles for placing enemies
			var validTiles = [(Int, Int)]()
			for y in room.y..<room.y+room.height
			{
				for x in room.x..<room.x+room.width
				{
					let tile = tiles[x + y * width]
					if tile.walkable
					{
						validTiles.append((x, y))
					}
				}
			}
			
			//and now use that generated data to place enemies
			validTiles.shuffleInPlace()
			for i in 0..<min(validTiles.count, lastEnemiesToPlace.count)
			{
				let enemy = Creature(enemyType: lastEnemiesToPlace[i], level: stub.level, x: validTiles[i].0, y: validTiles[i].1)
				tiles[validTiles[i].0 + validTiles[i].1 * width].creature = enemy
			}
		}
		
		
		
		//finally, place a boss
		//TODO: place a boss appropriate to the stub, instead of just the generic boss
		let boss = Creature(enemyType: "boss", level: stub.level, x: endRoom.centerX, y: endRoom.centerY)
		tiles[endRoom.centerX + endRoom.centerY * width].creature = boss
	}
	
	static func expValueForEnemyType(enemyType:String) -> Int
	{
		let hasMagic = DataStore.getBool("EnemyTypes", enemyType, "special")
		let hasArmor = DataStore.getBool("EnemyTypes", enemyType, "armor")
		let movePoints = DataStore.getInt("EnemyTypes", enemyType, "move points")!
		let ignoreTerrainCost = DataStore.getBool("EnemyTypes", enemyType, "ignore terrain cost")
		
		let mult = (hasMagic ? expMagicMult : 0) + (hasArmor ? expArmorMult : 0) +
					(movePoints - 4) * expMovePointMult + (ignoreTerrainCost ? expIgnoreTerrainCostMult : 0)
		
		return (DataStore.getInt("EnemyTypes", enemyType, "level")! + expBase) * (100 + mult) / 100
	}
	
	static func solidityToTiles(solidity:[Bool], width:Int, height:Int, rooms:[MapRoom], stub:MapStub) -> [Tile]
	{
		var endRoom:MapRoom!
		for room in rooms
		{
			if room.roomClass == .Boss
			{
				endRoom = room
				break
			}
		}
		
		let (structures, megastructure) = makeMegastructures(solidity, width: width, height: height, bossRoom: endRoom, stub: stub)
		let pit = makePits(solidity, width: width, height: height, megastructure: megastructure, stub: stub)
		let difficult = makeDifficultTiles(solidity, width: width, height: height, megastructure: megastructure, stub: stub)
		
		
		let tileset = DataStore.getString("MapThemes", stub.theme, "tileset")!
		
		let tilesetFloor = DataStore.getString("Tilesets", tileset, "floor tile")!
		let tilesetWall = DataStore.getString("Tilesets", tileset, "wall tile")!
		let tilesetDifficult = DataStore.getString("Tilesets", tileset, "difficult tile")!
		let tilesetPit = DataStore.getString("Tilesets", tileset, "pit tile")!
		
		var tiles = [Tile]()
		for y in 0..<height
		{
			for x in 0..<width
			{
				let i = x + y * width
				let type:String
				if solidity[i]
				{
					type = pit[i] ? tilesetPit : tilesetWall
				}
				else
				{
					type = difficult[i] ? tilesetDifficult : tilesetFloor
				}
				tiles.append(Tile(type: type))
			}
		}
		//place megastructure tiles
		for ms in structures
		{
			let msWidth = DataStore.getInt("MegaStructures", ms.2, "width")!
			let msHeight = DataStore.getInt("MegaStructures", ms.2, "height")!
			let msTiles = DataStore.getArray("MegaStructures", ms.2, "tiles") as! [String]
			for y in 0..<msHeight
			{
				for x in 0..<msWidth
				{
					let i = x + y * msWidth
					let tile = msTiles[i]
					if tile != ""
					{
						let mI = (x + ms.0) + (y + ms.1) * width
						tiles[mI] = Tile(type: tile)
					}
				}
			}
		}
		return tiles
	}
	
	//MARK: solidity to tiles components
	static func makeMegastructures(solidity:[Bool], width:Int, height:Int, bossRoom:MapRoom, stub:MapStub) -> ([(Int, Int, String)], [Bool])
	{
		var megastructure = [Bool](count: width*height, repeatedValue: false)
		var structures = [(Int, Int, String)]()
		
		//TODO: get the map's actual list of megastructures
		var numStructures = DataStore.getInt("MapThemes", stub.theme, "number of megastructures")!
		
		func placeMegastructureAt(ms:String, x startX:Int, y startY:Int)
		{
			let msWidth = DataStore.getInt("MegaStructures", ms, "width")!
			let msHeight = DataStore.getInt("MegaStructures", ms, "height")!
			for y in startY..<startY+msHeight
			{
				for x in startX..<startX+msWidth
				{
					megastructure[x+y*width] = true
				}
			}
			structures.append((startX, startY, ms))
		}
		
		//place the boss room
		placeMegastructureAt("boss room", x: bossRoom.x, y: bossRoom.y)
		
		//place a lot of megastructures
		//each one should go in a position that has one corner in common with an open tile
		while numStructures > 0
		{
			let ms = "small house"
			var validSpots = [(Int, Int)]()
			let msWidth = DataStore.getInt("MegaStructures", ms, "width")!
			let msHeight = DataStore.getInt("MegaStructures", ms, "height")!
			
			func isValidSpot(x startX:Int, y startY:Int) -> Bool
			{
				func rectCheck(x startX:Int, y startY:Int, w rectWidth:Int, h rectHeight:Int, closure:(Int)->(Bool))
				{
					for y in startY..<startY+rectHeight
					{
						for x in startX..<startX+rectWidth
						{
							if x >= 0 && y >= 0 && x < width && y < height
							{
								if closure(x + y * width)
								{
									return
								}
							}
						}
					}
				}
				
				//check to make sure that every tile in the spot is wall and non-megastructure
				var allValid = true
				rectCheck(x: startX, y: startY, w: msWidth, h: msHeight)
				{ (i) in
					if megastructure[i] || !solidity[i]
					{
						allValid = false
						return true
					}
					return false
				}
				
				if !allValid
				{
					return false
				}
				
				
				//now check to make sure at least one border has a non-wall tile, so that you can SEE the megastructure
				var sideFloor = false
				rectCheck(x: startX - 1, y: startY, w: 1, h: msHeight)
				{ (i) in
					if !solidity[i]
					{
						sideFloor = true
						return true
					}
					return false
				}
				if sideFloor
				{
					return true
				}
				rectCheck(x: startX, y: startY - 1, w: msWidth, h: 1)
				{ (i) in
					if !solidity[i]
					{
						sideFloor = true
						return true
					}
					return false
				}
				if sideFloor
				{
					return true
				}
				rectCheck(x: startX + msWidth, y: startY, w: 1, h: msHeight)
				{ (i) in
					if !solidity[i]
					{
						sideFloor = true
						return true
					}
					return false
				}
				if sideFloor
				{
					return true
				}
				rectCheck(x: startX, y: startY + msHeight, w: msWidth, h: 1)
				{ (i) in
					if !solidity[i]
					{
						sideFloor = true
						return true
					}
					return false
				}
				return sideFloor
			}
			
			for y in 0..<height-msHeight
			{
				for x in 0..<width-msWidth
				{
					if isValidSpot(x: x, y: y)
					{
						validSpots.append((x, y))
					}
				}
			}
			
			if validSpots.count == 0
			{
				//you can't place this type of megastructure
				//TODO: rmeove this type of megastructure from the list; only break if there are no types left
				break
			}
			else
			{
				let spot = validSpots.randomElement!
				numStructures -= 1
				placeMegastructureAt(ms, x: spot.0, y: spot.1)
				
				if validSpots.count > 1 && numStructures > 0
				{
					//try placing a second megastructure with the same validSpots, to save some time
					let otherSpot = validSpots.randomElement!
					if isValidSpot(x: otherSpot.0, y: otherSpot.1)
					{
						placeMegastructureAt(ms, x: otherSpot.0, y: otherSpot.1)
						numStructures -= 1
					}
				}
			}
		}
		
		return (structures, megastructure)
	}
	
	static func makeDifficultTiles(solidity:[Bool], width:Int, height:Int, megastructure:[Bool], stub:MapStub) -> [Bool]
	{
		//find the tiles that can be turned into difficult WHILE initializing the difficult array
		var difficult = [Bool]()
		var applicable = [Int]()
		for i in 0..<width*height
		{
			difficult.append(false)
			if !solidity[i] && !megastructure[i]
			{
				applicable.append(i)
			}
		}
		
		let numDifficult = applicable.count * DataStore.getInt("MapThemes", stub.theme, "difficult percent")! / 100
		if numDifficult > 0
		{
			applicable.shuffleInPlace()
			for i in 0..<numDifficult
			{
				difficult[applicable[i]] = true
			}
		}
		
		return difficult
	}
	static func makePits(solidity:[Bool], width:Int, height:Int, megastructure:[Bool], stub:MapStub) -> [Bool]
	{
		var pit = [Bool](count: width*height, repeatedValue: false)
		
		let numPits = DataStore.getInt("MapThemes", stub.theme, "number of pits")!
		let pitSize = DataStore.getInt("MapThemes", stub.theme, "pit size")!
		
		for i in 0..<numPits
		{
			var possibilities = [Int]()
			for i in 0..<width*height
			{
				if solidity[i] && !megastructure[i]
				{
					possibilities.append(i)
				}
			}
			
			if possibilities.count == 0
			{
				//end immediately
				return pit
			}
			
			let centerI = possibilities.randomElement!
			
			pit[centerI] = true
			
			var tilesLeft = pitSize - 1
			var placedIs = [centerI]
			
			while tilesLeft > 0 && placedIs.count > 0
			{
				func tileIsValidToExplore(i:Int) -> Bool
				{
					let x = i % width
					let y = i / width
					let n = y > 0 && !pit[i - width]
					let s = y < height - 1 && !pit[i + width]
					let e = x < width - 1 && !pit[i + 1]
					let w = x > 0 && !pit[i - 1]
					return !pit[i] && (w || e || n || s)
				}
				
				let i = placedIs.randomElement!
				pit[i] = true
				tilesLeft -= 1
				let x = i % width
				let y = i / width
				if x > 0
				{
					placedIs.append(i - 1)
				}
				if x < width - 1
				{
					placedIs.append(i + 1)
				}
				if y > 0
				{
					placedIs.append(i - width)
				}
				if y < height - 1
				{
					placedIs.append(i + width)
				}
				
				placedIs = placedIs.filter() { tileIsValidToExplore($0) }
			}
		}
		
		//filter out all pits over invalid tiles
		for i in 0..<pit.count
		{
			pit[i] = pit[i] && solidity[i] && !megastructure[i]
		}
		
		return pit
	}
}

//TODO: move this elsewhere
extension CollectionType where Index == Int
{
	var randomElement:Self.Generator.Element?
	{
		let index = Int(arc4random_uniform(UInt32(self.count)))
		return self[index]
	}
}

extension MutableCollectionType where Index == Int
{
	mutating func shuffleInPlace()
	{
		if count >= 2
		{
			for i in 0..<count - 1
			{
				let j = Int(arc4random_uniform(UInt32(count - i))) + i
				guard i != j else { continue }
				swap(&self[i], &self[j])
			}
		}
	}
}