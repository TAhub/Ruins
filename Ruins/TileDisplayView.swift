//
//  TileDisplayView.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

let tileSize:CGFloat = 40

class TileDisplayView: UIView {

	//TODO: remove the reference to map; instead, make a delegate protocol to feed the info I need
	//width, height, tile at, etc
	
	private var tiles = [Int : UIView]()
	private var map:Map!
	
	func initializeAtCameraPoint(cameraPoint:CGPoint, map:Map)
	{
		self.map = map
		makeTilesForCameraPoint(cameraPoint)
	}
	
	func makeTilesForCameraPoint(cameraPoint:CGPoint)
	{
		operateOnCameraPoint(cameraPoint)
		{ (x, y) in
			if self.tiles[self.map.width * y + x] == nil
			{
				//generate a new tile, appropriate for those coordinates
				let tile = UIView(frame: self.tileRectFor(x: x, y: y, atCameraPoint: cameraPoint))
				tile.backgroundColor = self.map.tileAt(x: x, y: y).solid ? UIColor.whiteColor() : UIColor.darkGrayColor()
				self.tiles[self.map.width * y + x] = tile
				self.addSubview(tile)
			}
		}
	}
	
	func adjustTilesForCameraPoint(cameraPoint:CGPoint)
	{
		operateOnCameraPoint(cameraPoint)
		{ (x, y) in
			if let tile = self.tiles[self.map.width * y + x]
			{
				tile.frame = self.tileRectFor(x: x, y: y, atCameraPoint: cameraPoint)
			}
		}
	}
	
	func cullTilesForCameraPoint(cameraPoint:CGPoint)
	{
		var newTiles = [Int : UIView]()
		operateOnCameraPoint(cameraPoint)
		{ (x, y) in
			let i = y * self.map.width + x
			newTiles[i] = self.tiles[i]
		}
		
		//remove the view of old tiles
		for entry in self.tiles
		{
			if newTiles[entry.0] == nil
			{
				entry.1.removeFromSuperview()
			}
		}
		
		tiles = newTiles
	}
	
	private func operateOnCameraPoint(cameraPoint:CGPoint, operation:(Int, Int)->())
	{
		//which tiles are needed?
		let startXRaw = Int(floor(cameraPoint.x / tileSize))
		let startYRaw = Int(floor(cameraPoint.y / tileSize))
		let endXRaw = Int(ceil((cameraPoint.x + frame.width) / tileSize))
		let endYRaw = Int(ceil((cameraPoint.y + frame.height) / tileSize))
		
		for y in max(startYRaw - 1, 0)...min(endYRaw + 1, map.height - 1)
		{
			for x in max(startXRaw - 1, 0)...min(endXRaw + 1, map.width - 1)
			{
				operation(x, y)
			}
		}
	}
	
	private func tileRectFor(x x:Int, y:Int, atCameraPoint cameraPoint:CGPoint) -> CGRect
	{
		return CGRect(x: CGFloat(x) * tileSize - cameraPoint.x, y: CGFloat(y) * tileSize - cameraPoint.y, width: tileSize, height: tileSize)
	}
}
