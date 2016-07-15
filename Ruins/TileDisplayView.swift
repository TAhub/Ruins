//
//  TileDisplayView.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

let tileSize:CGFloat = 40
let tileLevelOff:CGFloat = 16
let mapColorPercent:CGFloat = 0.5

class TileRepresentation
{
	var upper:UIView?
	var middle:UIView?
	var lower:UIView?
	
	init(tile:Tile, mapColor:UIColor)
	{
		func loadRep(name:String?) -> UIView?
		{
			if let name = name
			{
				if let image = UIImage(named: name)
				{
					let tintedImage = image.colorImage(tile.color.colorLerp(mapColor, percent: mapColorPercent))
					let view = UIImageView(image: tintedImage)
					return view
				}
			}
			return nil
		}
		upper = loadRep(tile.upperSprite)
		middle = loadRep(tile.middleSprite)
		lower = loadRep(tile.lowerSprite)
	}
	
	func removeFromSuperview()
	{
		upper?.removeFromSuperview()
		middle?.removeFromSuperview()
		lower?.removeFromSuperview()
	}
	
	func setFrame(frame:CGRect)
	{
		upper?.frame = CGRectMake(frame.origin.x, frame.origin.y - tileLevelOff, frame.size.width, frame.size.height)
		middle?.frame = frame
		lower?.frame = CGRectMake(frame.origin.x, frame.origin.y + tileLevelOff, frame.size.width, frame.size.height)
	}
	
	func setAlpha(alpha:CGFloat)
	{
		upper?.alpha = alpha
		middle?.alpha = alpha
		lower?.alpha = alpha
	}
}

class TileDisplayView: UIView {

	//TODO: remove the reference to map; instead, make a delegate protocol to feed the info I need
	//width, height, tile at, etc
	
	private var tiles = [Int : TileRepresentation]()
	private var map:Map!
	
	private var lowerView:UIView!
	private var middleView:UIView!
	private var upperView:UIView!
	
	func initializeAtCameraPoint(cameraPoint:CGPoint, map:Map, upperView: UIView)
	{
		self.upperView = upperView
		lowerView = UIView(frame: self.bounds)
		middleView = UIView(frame: self.bounds)
		self.addSubview(lowerView)
		self.addSubview(middleView)
		self.map = map
		makeTilesForCameraPoint(cameraPoint)
	}
	
	func updateTileHidden()
	{
		for (i, rep) in tiles
		{
			let x = i % map.width
			let y = i / map.width
			let tile = map.tileAt(x: x, y: y)
			rep.setAlpha(tile.visible ? 1 : 0)
		}
	}
	
	func makeTilesForCameraPoint(cameraPoint:CGPoint)
	{
		operateOnCameraPoint(cameraPoint)
		{ (x, y) in
			if self.tiles[self.map.width * y + x] == nil
			{
				//generate a new tile, appropriate for those coordinates
				let tile = self.map.tileAt(x: x, y: y)
				let tileRect = self.tileRectFor(x: x, y: y, atCameraPoint: cameraPoint)
				
				let rep = TileRepresentation(tile: tile, mapColor: self.map.mapColor)
				rep.setFrame(tileRect)
				rep.setAlpha(tile.visible ? 1 : 0)
				self.tiles[self.map.width * y + x] = rep
				
				if let upper = rep.upper
				{
					self.upperView.addSubview(upper)
				}
				if let middle = rep.middle
				{
					self.middleView.addSubview(middle)
				}
				if let lower = rep.lower
				{
					self.lowerView.addSubview(lower)
				}
			}
		}
	}
	
	func adjustTilesForCameraPoint(cameraPoint:CGPoint)
	{
		operateOnCameraPoint(cameraPoint)
		{ (x, y) in
			if let tile = self.tiles[self.map.width * y + x]
			{
				tile.setFrame(self.tileRectFor(x: x, y: y, atCameraPoint: cameraPoint))
			}
		}
	}
	
	func cullTilesForCameraPoint(cameraPoint:CGPoint)
	{
		var newTiles = [Int : TileRepresentation]()
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
