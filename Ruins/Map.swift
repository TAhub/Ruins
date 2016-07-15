//
//  Map.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

struct PathTile
{
	var backX:Int
	var backY:Int
	var distance:Int
}

let visibilityRange = 5
let numRays = 180
let rayInterval:Float = 0.5

class Map
{
	let width:Int
	let height:Int
	let mapColor:UIColor
	private var tiles:[Tile]
	
	private var pathfindingResults = [Int : PathTile]()
	
	init(width:Int, height:Int)
	{
		self.width = width
		self.height = height
		mapColor = UIColor.whiteColor()
		
		//make just a simple walled arena in the size
		tiles = [Tile]()
		for y in 0..<height
		{
			for x in 0..<width
			{
				let solid = x == 0 || y == 0 || x == width - 1 || y == height - 1
				tiles.append(Tile(type: solid ? "sample wall" : "sample floor"))
			}
		}
	}
	
	init(mapStub:MapStub, player:Creature)
	{
		let (tiles, width, height) = MapGenerator.mapGenerate(mapStub, player: player)
		self.width = width
		self.height = height
		self.tiles = tiles
		self.mapColor = DataStore.getColor("MapFlavors", mapStub.flavor, "map color") ?? UIColor.whiteColor()
	}
	
	func tileAt(x x:Int, y:Int) -> Tile
	{
		return tiles[toI(x: x, y: y)]
	}
	
	func pathResultAt(x x:Int, y:Int) -> PathTile?
	{
		return pathfindingResults[toI(x: x, y: y)]
	}
	
	var tilesAccessable: [(Int, Int)]
	{
		var construct = [(Int, Int)]()
		for (i, _) in pathfindingResults
		{
			construct.append((toX(i), toY(i)))
		}
		return construct
	}
	
	private func toI(x x:Int, y:Int) -> Int
	{
		return x + y * width
	}
	
	private func toX(i:Int) -> Int
	{
		return i % width
	}
	
	private func toY(i:Int) -> Int
	{
		return i / width
	}
	
	func calculateVisibility(x startX:Int, y startY:Int)
	{
		//make everything invisible
		for tile in tiles
		{
			tile.visible = false
		}
		
		for ray in 0..<numRays
		{
			var xOn = Float(startX)
			var yOn = Float(startY)
			
			while true
			{
				//make sure you don't leave the bounds
				let roundX = Int(round(xOn))
				let roundY = Int(round(yOn))
				if roundX < 0 || roundY < 0 || roundX >= width || roundY >= height
				{
					break
				}
				
				//make sure it doesn't get too far away
				if abs(roundX - startX) + abs(roundY - startY) > visibilityRange
				{
					break
				}
				
				//interact with tiles
				let tile = tiles[toI(x: roundX, y: roundY)]
				tile.visible = true
				if tile.solid
				{
					break
				}
				
				//move the ray forward
				let angle = Float(M_PI) * 2 * Float(ray) / Float(numRays)
				xOn += cos(angle) * rayInterval
				yOn += sin(angle) * rayInterval
			}
		}
	}
	
	func pathfinding(from:Creature, movePoints:Int, ignoreTerrainCosts:Bool)
	{
		//get AI variables
		let weightPerMovePoint = DataStore.getInt("AIs", from.AI!, "weight per move point")!
		let worldTrapWeight = DataStore.getInt("AIs", from.AI!, "world trap weight")!
		let playerTrapWeight = DataStore.getInt("AIs", from.AI!, "player trap weight")!
		
		//prepare to pathfind
		pathfindingResults.removeAll()
		pathfindingResults[toI(x: from.x, y: from.y)] = PathTile(backX: -1, backY: -1, distance: 0)
		var order = [Int]()
		order.append(toI(x: from.x, y: from.y))
		
		while order.count > 0
		{
			//find the cheapest place to explore
			var pick = 0
			for i in 1..<order.count
			{
				if pathfindingResults[order[i]]!.distance < pathfindingResults[order[pick]]!.distance
				{
					pick = i
				}
			}
			let fromX = toX(order[pick])
			let fromY = toY(order[pick])
			let fromTile = pathfindingResults[order[pick]]!
			order.removeAtIndex(pick)
			
			//explore in every direction from it
			func exploreTo(x x:Int, y:Int)
			{
				let tile = tileAt(x: x, y: y)
				if !tile.walkable
				{
					//you can't enter
					return
				}
				let i = toI(x: x, y: y)
				let cost = ignoreTerrainCosts ? 1 : tile.entryCost
				var newDistance = cost * weightPerMovePoint + fromTile.distance
				if let trap = tile.trap
				{
					newDistance += trap.good ? playerTrapWeight : worldTrapWeight
				}
				if pathfindingResults[i] == nil || pathfindingResults[i]!.distance > newDistance
				{
					pathfindingResults[i] = PathTile(backX: fromX, backY: fromY, distance: newDistance)
					if newDistance < movePoints
					{
						//only queue it up if you can actually get there
						order.append(i)
					}
				}
			}
			exploreTo(x: fromX - 1, y: fromY)
			exploreTo(x: fromX + 1, y: fromY)
			exploreTo(x: fromX, y: fromY - 1)
			exploreTo(x: fromX, y: fromY + 1)
		}
	}
}