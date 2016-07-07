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
	var cameraPoint = CGPoint(x: 0, y: 0)
	
	@IBOutlet weak var gameArea: TileDisplayView!
	@IBOutlet weak var creatureLayer: UIView!
	
	
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
		
		//make the tiles
		gameArea.initializeAtCameraPoint(cameraPoint, map: game.map)
		
		for creature in game.creatures
		{
			representations.append(CreatureRepresentation(creature: creature, superview: creatureLayer, atCameraPoint: cameraPoint))
		}
		
		//TODO: all sprite tiles and such should auto-scale so that differently-sized iphones all have the same screen size
		
		//TODO: for tiles I probably want a lower-effort system than representations
		//since I have to do a lot of "all representation" operations
	
		//start the game loop with executePhase()
		game.executePhase()
		
		
		//add a gesture recognizer for the game area
		let tappy = UITapGestureRecognizer(target: self, action: #selector(gameAreaPressed))
		creatureLayer.addGestureRecognizer(tappy)
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		
		uiUpdate()
	}
	
	//MARK: actions
	
	func gameAreaPressed(sender:UITapGestureRecognizer)
	{
		//find out the exact x and y coordinates of the tap
		let coordinates = sender.locationInView(gameArea)
		let x = Int(floor((coordinates.x + cameraPoint.x) / tileSize))
		let y = Int(floor((coordinates.y + cameraPoint.y) / tileSize))
		
		print("Tapped at (\(x), \(y))")
		
		if input
		{
			let xDif = x - game.activeCreature.x
			let yDif = y - game.activeCreature.y
			
			if xDif != 0 || yDif != 0
			{
				//you probably want to move somewhere
				let xDis = abs(xDif)
				let yDis = abs(yDif)
				let xM = xDif > 0 ? 1 : -1
				let yM = yDif > 0 ? 1 : -1
				if xDis >= yDis * 2
				{
					tryMove(x: xM, y: 0)
				}
				else if yDis >= xDis * 2
				{
					tryMove(x: 0, y: yM)
				}
				else
				{
					if xDis > yDis
					{
						if (!tryMove(x: xM, y: 0))
						{
							tryMove(x: 0, y: yM)
						}
					}
					else if (!tryMove(x: 0, y: yM))
					{
						tryMove(x: xM, y: 0)
					}
				}
			}
		}
	}
	
	private func tryMove(x xChange:Int, y yChange:Int)->Bool
	{
		let x = game.activeCreature.x + xChange
		let y = game.activeCreature.y + yChange
		print("  Attempting to move to (\(x), \(y))")
		if game.map.tileAt(x: x, y: y).walkable
		{
			//TODO: also check to see if you have enough move points
			game.makeMove(x: x, y: y)
			return true
		}
		return false
	}

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
		playMoveAnimations(anim)
	}
	private func playMoveAnimations(anim:Animation)
	{
		//this comes before attacks because if you walk over a trap, it's move -> attack -> damage
		if let movePath = anim.movePath
		{
			//TODO: animate the move down that path
			//move the camera by updating the positions of all representations BUT the moving person
			//afterwards, update representation visibility (also, update the moving person's representation position afterwards too)
			//then call playAttackAnimations
			
			let updateCamera = game.activeCreature === game.player
			
			if updateCamera
			{
				gameArea.makeTilesForCameraPoint(cameraPoint)
			}
			
			UIView.animateWithDuration(0.25, animations:
			{
				let active = self.game.activeCreature
				
				//update the moving creature's position step by step
				let realX = active.x
				let realY = active.y
				active.x = movePath.first!.0
				active.y = movePath.first!.1
				
				if updateCamera
				{
					let newX = min(max(CGFloat(active.x) * tileSize - self.gameArea.frame.width / 2, 0), CGFloat(self.game.map.width) * tileSize - self.gameArea.frame.width)
					let newY = min(max(CGFloat(active.y) * tileSize - self.gameArea.frame.height / 2, 0), CGFloat(self.game.map.height) * tileSize - self.gameArea.frame.height)
					self.cameraPoint = CGPoint(x: newX, y: newY)
					
					self.gameArea.adjustTilesForCameraPoint(self.cameraPoint)
				}
				
				for rep in self.representations
				{
					rep.updatePosition(self.cameraPoint)
				}
				
				active.x = realX
				active.y = realY
			})
			{ (completed) in
				if movePath.count == 1
				{
					//the move is over, so clean up visibility and go on
					for rep in self.representations
					{
						rep.updateVisibility(self.cameraPoint)
					}
					
					self.gameArea.cullTilesForCameraPoint(self.cameraPoint)
					
					self.playAttackAnimations(anim)
				}
				else
				{
					//pop that one move off of the array and go to the next stage of the movement
					//TODO: it'd be ideal if moves were a queue I guess, but it probably doesn't matter much
					anim.movePath!.removeFirst()
					self.playMoveAnimations(anim)
				}
			}
		}
		else
		{
			playAttackAnimations(anim)
		}
	}
	private func playAttackAnimations(anim:Animation)
	{
		if let target = anim.attackTarget, let type = anim.attackType
		{
			//TODO: play the attack animation
			//afterwards, update representation appearance
			//then call playDamageNumberAnimations
			playDamageNumberAnimations(anim)
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
			animChainOver()
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