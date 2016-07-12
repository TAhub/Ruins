//
//  MapGenerator.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/12/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation

let numStubs = 3
let endRoomSize = 6

class MapStub
{
	let flavor:String
	let theme:String
	let name:String
	init(flavor:String, theme:String, name:String)
	{
		self.flavor = flavor
		self.theme = theme
		self.name = name
	}
	init(flavor:String, theme:String)
	{
		self.flavor = flavor
		self.theme = theme
		
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
			name = possibleNames[Int(arc4random_uniform(UInt32(possibleNames.count)))]
		}
		else
		{
			//pick a possible name
			name = uniqueNames[Int(arc4random_uniform(UInt32(uniqueNames.count)))]
			
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
		
		return correctTypes
	}
}

class MapGenerator
{
	//MARK: map stub
	static func generateMapStubs() -> [MapStub]
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
			stubs.append(MapStub(flavor: flavors[i], theme: themes[i]))
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
	static func generateSolidityMap(mapStub:MapStub) -> (solidity:[Bool], width:Int, height:Int, startX:Int, startY:Int, endX:Int, endY:Int)
	{
		let width = 100
		let height = 100
		
		let startX = 50
		let startY = 90
		
		let endX = 50
		let endY = 10
		
		var solidity = [Bool]()
		for _ in 0..<(width * height)
		{
			solidity.append(true)
		}
		
		//TODO: actual random generation
		//for now, carve out a very simple map
		
		//carve the end room
		for y in 0..<endRoomSize
		{
			for x in 0..<endRoomSize
			{
				solidity[(x + endX) + (y + endY) * width] = false
			}
		}
		
		//carve a hallway down to the start position
		for y in (endY + endRoomSize)...startY
		{
			solidity[startX + y * width] = false
		}
		
		return (solidity: solidity, width: width, height: height, startX: startX, startY: startY, endX: endX, endY: endY)
	}
	
	static func pruneSolidity(oldSolidity:[Bool], width oldWidth:Int, height oldHeight:Int, startX oldStartX:Int, startY oldStartY:Int, endX oldEndX:Int, endY oldEndY:Int) -> (solidity:[Bool], width:Int, height:Int, startX:Int, startY:Int, endX:Int, endY:Int)
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
		
		//move the reference integers over too
		let startX = oldStartX - left + 1
		let startY = oldStartY - top + 1
		let endX = oldEndX - left + 1
		let endY = oldEndY - top + 1
		
		return (solidity: solidity, width: width, height: height, startX: startX, startY: startY, endX: endX, endY: endY)
	}
	
	//TODO: future idea: mega-tile structures
	//	there are a number of registered mega-tile structures, which are rectangular arrangement of tiles
	//	after making the solidity map, it "claims" rectangular areas of solidity to be mega-tile structures
	//	each structure must have at least one non-solid tile adjacent to it
	//	and structures cannot overlap
	//	suggested uses: individual buildings in the city tileset, etc
	//	all tiles that are not claimed by a mega-tile structure should be a generic wall tile
}

//TODO: move this elsewhere
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