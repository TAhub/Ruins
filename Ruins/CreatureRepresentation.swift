//
//  CreatureRepresentation.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

let ignoreTerrainFloat:CGFloat = 10

class CreatureRepresentation:Representation
{
	let creature:Creature
	
	private var lastArmorSprite = ""
	private var lastArmorColor = UIColor.blackColor()
	
	init(creature:Creature, superview:UIView, atCameraPoint:CGPoint, map:Map)
	{
		self.creature = creature
		let view = UIView(frame: CGRectMake(0, 0, tileSize, tileSize))
		view.backgroundColor = UIColor.blackColor()
		super.init(view: view, superview: superview)
		
		updateAppearance()
		updatePosition(atCameraPoint, map: map)
		updateVisibility(atCameraPoint, map: map)
	}
	
	override func updatePosition(toCameraPoint:CGPoint, map:Map)
	{
		let cX = (0.5 + CGFloat(creature.x)) * tileSize - toCameraPoint.x
		let cY = (0.5 + CGFloat(creature.y)) * tileSize - toCameraPoint.y - (creature.ignoreTerrainCosts ? ignoreTerrainFloat : 0)
		view.center = CGPoint(x: cX, y: cY)
		self.view.alpha = map.tileAt(x: creature.x, y: creature.y).visible ? 1 : 0
	}
	
	override func updateVisibility(atCameraPoint:CGPoint, map:Map)
	{
		self.view.hidden = !map.tileAt(x: creature.x, y: creature.y).visible
	}
	
	override func updateAppearance()
	{
		//calculate if I SHOULD update my appearance
		let armorSprite = creature.armor == nil ? "" : creature.armor!.spriteName
		let armorColor = creature.armor == nil ? UIColor.blueColor() : creature.armor!.spriteColor
		
		//TODO: also check for weapon
		
		if armorSprite != lastArmorSprite || armorColor != lastArmorColor
		{
			lastArmorSprite = armorSprite
			lastArmorColor = armorColor
			
			updateAppearanceInner()
		}
	}
	private func updateAppearanceInner()
	{
		for subview in view.subviews
		{
			subview.removeFromSuperview()
		}
		
		let layers = DataStore.getArray("AppearanceGroups", creature.appearanceGroup, "layers") as! [NSDictionary]
		let colorations = DataStore.getArray("AppearanceGroups", creature.appearanceGroup, "colorations") as! [[String]]
		
		//tally up the total possible variants
		
		var possibleVariants = colorations.count
		for layer in layers
		{
			if let variants = getIntFromLayer(layer, name: "variants")
			{
				possibleVariants *= variants
			}
		}
		if DataStore.getBool("AppearanceGroups", creature.appearanceGroup, "has gender")
		{
			possibleVariants *= 2
		}
		
		//TODO: get the real appearance number
		var appearanceNumber:Int = Int(arc4random_uniform(UInt32(possibleVariants)))
		
		let genderSuffix:String
		if DataStore.getBool("AppearanceGroups", creature.appearanceGroup, "has gender")
		{
			possibleVariants /= 2
			genderSuffix = appearanceNumber >= possibleVariants ? "_f" : "_m"
			appearanceNumber %= possibleVariants
		}
		else
		{
			genderSuffix = ""
		}
		
		
		//find the coloration from the appearance number
		possibleVariants /= colorations.count
		let colorationNumber = appearanceNumber / possibleVariants
		appearanceNumber %= possibleVariants
		let coloration = colorations[colorationNumber]
		
		var images = [UIImage]()
		
		for (i, layer) in layers.enumerate()
		{
			let genderSuffix = layer["has gender"] != nil ? genderSuffix : ""
			let spriteName = layer["sprite name"] as! String
			
			//TODO: calculate the actual variant if this isn't a suffix thing
			let variantSuffix:String
			if let variants = getIntFromLayer(layer, name: "variants")
			{
				possibleVariants /= variants
				let variantNumber = appearanceNumber / possibleVariants
				appearanceNumber %= possibleVariants
				variantSuffix = "_\(variantNumber+1)"
			}
			else
			{
				variantSuffix = ""
			}
			
			let finalSpriteName = "\(spriteName)\(genderSuffix)\(variantSuffix)"
			if let bodyImage = makeImage(finalSpriteName, color: DataStore.getColorByName(coloration[i]) ?? UIColor.blackColor())
			{
				images.append(bodyImage)
			}
			
			if let armorSuffix = layer["armor suffix"] as? String
			{
				//it's the equipment layer, so make equipment over it!
				if let armor = creature.armor
				{
					let armorSpriteName = armor.spriteName
					let finalArmorSpriteName = "\(armorSpriteName)_\(armorSuffix)\(genderSuffix)"
					if let armorImage = makeImage(finalArmorSpriteName, color: armor.spriteColor)
					{
						images.append(armorImage)
					}
				}
			}
		}
		
		//combine the images together
		let combinationImage = UIImage.combineImages(images, anchorAt: CGPoint(x: 0.5, y: 1))
		let imageView = UIImageView(image: combinationImage)
		self.view.addSubview(imageView)
		
		//center it properly
		imageView.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height - combinationImage.size.height / 2)
	}
	
	private func getIntFromLayer(layer:NSDictionary, name:String) -> Int?
	{
		if let int = (layer[name] as? NSNumber)?.intValue
		{
			return Int(int)
		}
		return nil
	}
	
	private func makeImage(name:String, color:UIColor) -> UIImage?
	{
		//TODO: instead of being separate image views these should all be compacted into a single image
		
		if let image = UIImage(named: name)
		{
			return image.colorImage(color)
		}
		else
		{
			print("ERROR: could not find image named \(name)!")
			return nil
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