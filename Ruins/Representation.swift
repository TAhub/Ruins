//
//  Representation.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class Representation
{
	let view:UIView
	
	init(view:UIView, superview:UIView)
	{
		//make the view to house the creature
		self.view = view
		superview.addSubview(view)
	}
	
	func updateAppearance()
	{
		//TODO: update the appearance of the view, if necessary
	}
	
	func updatePosition(toCameraPoint:CGPoint, map:Map)
	{
		//TODO: update the position of the view (for use in UIView animates during movement)
	}
	
	func updateVisibility(atCameraPoint:CGPoint, map:Map)
	{
		//TODO: change hidden depending on if you can be seen or not
	}
	
	var dead:Bool
	{
		return true
	}
	
	deinit
	{
		//TODO: I dunno if this is a good idea
		//because I think it kind of ties the presence of the view into the autorelease cycle?
		//that is, if it takes half a second or whatever to release memory, the view will go away at that point
		//which might be too slow
		//SO, if I'm seeing weird problems, handle the view removing elsewhere
		
		view.removeFromSuperview()
	}
}