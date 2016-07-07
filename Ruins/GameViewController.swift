//
//  GameViewController.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, GameDelegate {
	
	var game:Game!
	var input:Bool = false
	var representations = [Representation]()
	
	var animating:Bool = false
	var shouldUIUpdate:Bool = false
	
	@IBOutlet weak var gameArea: UIView!
	
	@IBOutlet weak var healthBarAuraView: UIView!
	@IBOutlet weak var healthBarContainerView: UIView!
	
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		//format some views
		healthBarAuraView.layer.cornerRadius = 10
		healthBarContainerView.layer.cornerRadius = 10
		
		game = Game()
		game.delegate = self
		
		game.addPlayer(Creature(enemyType: "human player", level: 1, x: 1, y: 1))
		game.addEnemy(Creature(enemyType: "elf player", level: 1, x: 4, y: 5))
		game.addEnemy(Creature(enemyType: "bogeyman player", level: 1, x: 6, y: 5))
		game.addEnemy(Creature(enemyType: "fairy player", level: 1, x: 4, y: 7))
		game.addEnemy(Creature(enemyType: "zombie player", level: 1, x: 6, y: 7))
		game.addEnemy(Creature(enemyType: "skeleton player", level: 1, x: 8, y: 5))
		
		for creature in game.creatures
		{
			representations.append(CreatureRepresentation(creature: creature, superview: gameArea))
		}
		
		//TODO: all sprite tiles and such should auto-scale so that differently-sized iphones all have the same screen size
		
		//TODO: for tiles I probably want a lower-effort system than representations
		//since I have to do a lot of "all representation" operations
	
		//start the game loop with executePhase()
		game.executePhase()
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		
		uiUpdate()
	}
	
	//MARK: actions

	@IBAction func attackButtonPressed()
	{
		//TODO: check to see if you can attack (have ammo, targets exist, etc)
		if input
		{
			//TODO: switch to attack mode
			//TODO: remember to switch input back to "false" when actually doing something!
		}
	}
	
	@IBAction func skipButtonPressed()
	{
		if input
		{
			input = false
			game.skipAction()
		}
	}
	
	@IBAction func itemsButtonPressed()
	{
		if input
		{
			//TODO: open items menu
		}
	}
	
	@IBAction func examineButtonPressed()
	{
		//TODO: you are guaranteed to be able to examine, since self-examination is possible, so no need to check here
		if input
		{
			//TODO: switch to examine mode
		}
	}
	
	//MARK: delegate methods
	func inputDesired()
	{
		input = true
	}
	func playAnimation(anim: Animation)
	{
		animating = true
		playAttackAnimations(anim)
	}
	private func playAttackAnimations(anim:Animation)
	{
		if let target = anim.attackTarget, let type = anim.attackType
		{
			//TODO: play the attack animation
			//afterwards, update representation appearance
			//then call playMoveAnimations
		}
		else
		{
			playMoveAnimations(anim)
		}
	}
	private func playMoveAnimations(anim:Animation)
	{
		if let movePath = anim.movePath
		{
			//TODO: animate the move down that path
			//move the camera by updating the positions of all representations BUT the moving person
			//afterwards, update representation visibility (also, update the moving person's representation position afterwards too)
			//then call playDamageNumberAnimations
		}
		else
		{
			playDamageNumberAnimations(anim)
		}
	}
	private func playDamageNumberAnimations(anim: Animation)
	{
		if anim.damageNumbers.count > 0
		{
			//TODO: create, move, and destroy the damage numbers
			//afterwards, update representation appearance
			//then call animChainOver
		}
		else
		{
			animChainOver()
		}
	}
	private func animChainOver()
	{
		animating = false
		if shouldUIUpdate
		{
			uiUpdate()
		}
		pruneRepresentations()
		game.toNextPhase()
	}
	
	func uiUpdate()
	{
		//if you're animating, delay this until the animation finishes
		if animating
		{
			shouldUIUpdate = true
			return
		}
		shouldUIUpdate = false
		
		//TODO: switch healthBarAuraView's background color opacity between 0 and 1 depending on if the player has aura
		
		//update the health bar
		for subview in healthBarContainerView.subviews
		{
			subview.removeFromSuperview()
		}
		let percentage = CGFloat(game.player.health) / CGFloat(game.player.maxHealth)
		let bar = UIView(frame: CGRectMake(0, 0, healthBarContainerView.frame.width * percentage, healthBarContainerView.frame.height))
		bar.backgroundColor = UIColor.redColor()
		healthBarContainerView.addSubview(bar)
		
		//TODO: draw movement points number
		
		//TODO: draw status effect icons
	}
	
	//MARK: helper methods
	
	func pruneRepresentations()
	{
		representations = representations.filter() { !$0.dead }
	}
}