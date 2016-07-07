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
		let view = UIView(frame: CGRectMake(40 * CGFloat(creature.x), 40 * CGFloat(creature.y), 40, 40))
		view.backgroundColor = UIColor.blackColor()
		super.init(view: view, superview: superview)
		
		updateAppearance()
		updatePosition()
		updateVisibility()
	}
	
	override func updateAppearance()
	{
		//TODO: only update this if you have changed armor appearance, weapon appearance
		//or some other factor (tint?)
		
		for subview in view.subviews
		{
			subview.removeFromSuperview()
		}
		
		let genderSuffix = DataStore.getBool("AppearanceGroups", creature.appearanceGroup, "has gender") ? "_m" : ""
		
		let layers = DataStore.getArray("AppearanceGroups", creature.appearanceGroup, "layers") as! [NSDictionary]
		for layer in layers
		{
			let spriteName = layer["sprite name"] as! String
			
			let finalSpriteName = "\(spriteName)\(genderSuffix)"
			addImage(finalSpriteName)
		}
	}
	
	private func addImage(name:String)
	{
		if let image = UIImage(named: name)
		{
			let imageView = UIImageView(image: image)
			view.addSubview(imageView)
			
			//center the image
			imageView.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height - image.size.height / 2)
		}
		else
		{
			print("ERROR: could not find image named \(name)!")
		}
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