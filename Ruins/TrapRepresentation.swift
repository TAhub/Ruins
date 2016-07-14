//
//  TrapRepresentation.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/13/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class TrapRepresentation:Representation
{
	let trap:Trap
	let x:Int
	let y:Int
	
	init(trap:Trap, x:Int, y:Int, superview:UIView, atCameraPoint:CGPoint, map:Map)
	{
		self.trap = trap
		self.x = x
		self.y = y
		let view = UIView(frame: CGRectMake(0, 0, tileSize, tileSize))
		view.backgroundColor = UIColor.orangeColor()
		super.init(view: view, superview: superview)
		
		updatePosition(atCameraPoint, map: map)
		updateVisibility(atCameraPoint, map: map)
	}
	
	override func updatePosition(toCameraPoint:CGPoint, map:Map)
	{
		view.center = CGPoint(x: (0.5 + CGFloat(x)) * tileSize - toCameraPoint.x, y: (0.5 + CGFloat(y)) * tileSize - toCameraPoint.y)
		self.view.alpha = map.tileAt(x: x, y: y).visible ? 1 : 0
	}
	
	override func updateVisibility(atCameraPoint:CGPoint, map:Map)
	{
		self.view.hidden = !map.tileAt(x: x, y: y).visible
	}
	
	override var dead:Bool
	{
		return trap.dead
	}
}