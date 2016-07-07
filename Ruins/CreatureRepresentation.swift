//
//  CreatureRepresentation.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class CreatureRepresentation:Representation
{
	let creature:Creature
	
	init(creature:Creature, superview:UIView)
	{
		self.creature = creature
		let view = UIView(frame: CGRectMake(30 * CGFloat(creature.x), 30 * CGFloat(creature.y), 30, 30))
		view.backgroundColor = UIColor.whiteColor()
		super.init(view: view, superview: superview)
	}
	
	override var dead:Bool
	{
		return creature.health == 0
	}
	
	deinit
	{
		view.removeFromSuperview()
	}
}