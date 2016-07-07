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
	
	init(creature:Creature, superview:UIView, atCameraPoint:CGPoint)
	{
		self.creature = creature
		let view = UIView(frame: CGRectMake(0, 0, tileSize, tileSize))
		view.backgroundColor = UIColor.blackColor()
		super.init(view: view, superview: superview)
		
		updateAppearance()
		updatePosition(atCameraPoint)
		updateVisibility(atCameraPoint)
	}
	
	override func updatePosition(toCameraPoint:CGPoint)
	{
		view.center = CGPoint(x: (0.5 + CGFloat(creature.x)) * tileSize - toCameraPoint.x, y: (0.5 + CGFloat(creature.y)) * tileSize - toCameraPoint.y)
		
		//TODO: if this new position isn't visible, also change your alpha to 0 so you'll fade out nicely
		//and the inverse too
	}
	
	override func updateAppearance()
	{
		//TODO: only update this if you have changed armor appearance, weapon appearance
		//or some other factor (tint from status effects? eh)
		
		
		for subview in view.subviews
		{
			subview.removeFromSuperview()
		}
		
		let genderSuffix = DataStore.getBool("AppearanceGroups", creature.appearanceGroup, "has gender") ? "_f" : ""
		
		let layers = DataStore.getArray("AppearanceGroups", creature.appearanceGroup, "layers") as! [NSDictionary]
		for layer in layers
		{
			let genderSuffix = layer["has gender"] != nil ? genderSuffix : ""
			let spriteName = layer["sprite name"] as! String
			
			let finalSpriteName = "\(spriteName)\(genderSuffix)"
			addImage(finalSpriteName)
			
			if let armorSuffix = layer["armor suffix"] as? String
			{
				//it's the equipment layer, so make equipment over it!
				if let armor = creature.armor
				{
					let armorSpriteName = armor.spriteName
					let finalArmorSpriteName = "\(armorSpriteName)_\(armorSuffix)\(genderSuffix)"
					addImage(finalArmorSpriteName)
				}
			}
		}
	}
	
	private func addImage(name:String)
	{
		//TODO: instead of being separate image views these should all be compacted into a single image
		
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