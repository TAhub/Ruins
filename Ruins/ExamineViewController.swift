//
//  ExamineViewController.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/14/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class ExamineViewController: UIViewController {

	@IBOutlet weak var portraitContainer: UIView!
	@IBOutlet weak var descriptionContainer: UIView!
	@IBOutlet weak var descriptionLabel: UILabel!
	var creature:Creature!
	var game:Game!
	var rep:Representation!
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		var desc = ""
		if creature === game.player
		{
			//TODO: player name
			desc += "NAME HERE: "
		}
		else
		{
			desc += "\(creature.enemyType): "
		}
		desc += "level \(creature.level) \(creature.racialGroup)\n"
		if creature === game.player
		{
			//do the full description
			desc += "\(creature.health)/\(creature.maxHealth) health\n"
			desc += "\n"
			desc += "\(creature.str) STR, \(creature.dex) DEX, \(creature.cun) CUN, \(creature.wis) WIS, \(creature.end) END\n"
			desc += "\(creature.meleePow) melee pow, \(creature.meleeRes) melee res\n"
			desc += "\(creature.accuracy) accuracy, \(creature.dodge) dodge\n"
			desc += "\(creature.specialPow) special pow, \(creature.specialRes) special res\n"
			desc += "\(creature.trapPow) trap pow, \(creature.trapRes) trap res\n"
		}
		else
		{
			//do the partial description
			if creature.health == creature.maxHealth
			{
				desc += "untouched\n"
			}
			else if creature.injured
			{
				desc += "badly injured\n"
			}
			else
			{
				desc += "injured\n"
			}
			desc += creature.weapon.range == 1 ? "melee\n" : "ranged\n"
			desc += "\n"
			
			//TODO: get appropriate words based on gender
			let he = "she"
			let his = "her"
			let him = "her"
			
			var flavorText = DataStore.getString("EnemyTypes", creature.enemyType, "flavor text")!
			flavorText = flavorText.stringByReplacingOccurrencesOfString("*he", withString: he)
			flavorText = flavorText.stringByReplacingOccurrencesOfString("*his", withString: his)
			flavorText = flavorText.stringByReplacingOccurrencesOfString("*him", withString: him)

			desc += "\(flavorText)\n"
		}
		
		desc += "\n"
		
		//immunities
		if DataStore.getBool("RacialGroups", creature.racialGroup, "stun immunity")
		{
			desc += "immune to stun\n"
		}
		if DataStore.getBool("RacialGroups", creature.racialGroup, "shake immunity")
		{
			desc += "immune to shake\n"
		}
		if DataStore.getBool("RacialGroups", creature.racialGroup, "poison immunity")
		{
			desc += "immune to poison\n"
		}
		if let status = creature.weapon.statusInflicted
		{
			desc += "can inflict \(status)\n"
		}
		if let strongVS = creature.weapon.strongVS
		{
			desc += "does extra damage to \(strongVS)\n"
		}
		if creature.poison > 0
		{
			desc += "poisoned\n"
		}
		if creature.shake > 0
		{
			desc += "shaken\n"
		}
		if creature.stun > 0
		{
			desc += "stunned\n"
		}
		
		descriptionLabel.text = desc
		
		let cX = (CGFloat(creature.x) + 0.5) * tileSize - portraitContainer.frame.width / 2
		let cY = (CGFloat(creature.y) + 0) * tileSize - portraitContainer.frame.height / 2
		rep = CreatureRepresentation(creature: creature, superview: portraitContainer, atCameraPoint: CGPointMake(cX, cY), map: game.map)
	}
	
	
	@IBAction func backButtonPress()
	{
		self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}
}
