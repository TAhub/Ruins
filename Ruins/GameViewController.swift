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
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		game = Game()
		game.delegate = self
		
		game.creatures.append(Creature(enemyType: "test creature", level: 1, x: 1, y: 1))
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		
		//start the game loop with executePhase()
		game.executePhase()
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
		//TODO: play the desired series of animations
		//in the following order (if multiple are present)
		//	move (this should also move the camera at the same time, if necessary)
		//	attack anim
		//	damage numbers
		
		//TODO: after doing all the animations, run toNextPhase()
		game.toNextPhase()
	}
}