//
//  GameViewController.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/6/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

enum TargetingMode:Int
{
	case Attack
	case Examine
	case Special //TODO: attach a reference to the special
}

class Target
{
	let view:UIView
	let subject:Creature
	init(subject:Creature, view:UIView)
	{
		self.view = view
		self.subject = subject
	}
}

let damageNumberDuration:NSTimeInterval = 0.35
let damageNumberDistanceTraveled:CGFloat = 50

class GameViewController: UIViewController, GameDelegate {
	
	var game:Game!
	var input:Bool = false
	var representations = [Representation]()
	
	var animating:Bool = false
	var shouldUIUpdate:Bool = false
	var cameraPoint = CGPoint(x: 0, y: 0)
	
	var targetingMode:TargetingMode!
	var targets:[Target]?
	
	@IBOutlet weak var gameArea: TileDisplayView!
	@IBOutlet weak var creatureLayer: UIView!
	
	
	@IBOutlet weak var healthBarAuraView: UIView!
	@IBOutlet weak var healthBarContainerView: UIView!
	@IBOutlet weak var secondaryBarArea: UIView!
	@IBOutlet weak var weaponBarContainerView: UIView!
	@IBOutlet weak var armorBarContainerView: UIView!
	
	
	
	//TODO: this is a temporary function, for testing
	private var randomLevel:Int
	{
		return Int(arc4random_uniform(40)) + 1
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		//format some views
		healthBarAuraView.layer.cornerRadius = 10
		healthBarContainerView.layer.cornerRadius = 10
		weaponBarContainerView.layer.cornerRadius = 5
		armorBarContainerView.layer.cornerRadius = 5
		
		game = Game()
		game.delegate = self
		
		game.addPlayer(Creature(enemyType: "human player", level: randomLevel, x: 1, y: 5))
		game.addEnemy(Creature(enemyType: "test pzombie", level: randomLevel, x: 4, y: 5))
		game.addEnemy(Creature(enemyType: "test pzombie", level: randomLevel, x: 5, y: 7))
		
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
			if let targets = targets
			{
				//did you click on a target?
				for target in targets
				{
					if target.subject.x == x && target.subject.y == y
					{
						leaveTargetingMode()
						
						//if so, do something appropriate for the targeting mode
						switch(targetingMode!)
						{
						case .Attack:
							//attack them
							input = false
							game.attack(x: x, y: y)
						case .Examine:
							//TODO: examine them
							break
						case .Special:
							//TODO: use the special on them
							input = false
						}
						
						break
					}
				}
			}
			else if game.movePoints > 0
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
	}
	
	private func tryMove(x xChange:Int, y yChange:Int)->Bool
	{
		let x = game.activeCreature.x + xChange
		let y = game.activeCreature.y + yChange
		print("  Attempting to move to (\(x), \(y))")
		if game.map.tileAt(x: x, y: y).walkable
		{
			game.makeMove(x: x, y: y)
			return true
		}
		return false
	}

	@IBAction func attackButtonPressed()
	{
		//TODO: check to see if you have enough ammo to attack
		if input
		{
			if targets != nil
			{
				leaveTargetingMode()
				if targetingMode! == .Attack
				{
					return
				}
			}
			
			targetingMode = .Attack
			enterTargetingMode()
			{ (creature) -> Bool in
				return self.game.validTarget(creature)
			}
		}
	}
	
	@IBAction func skipButtonPressed()
	{
		if input
		{
			leaveTargetingMode()
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
		if input
		{
			if targets != nil
			{
				leaveTargetingMode()
				if targetingMode! == .Examine
				{
					return
				}
			}
			
			//switch to examine mode
			targetingMode = .Examine
			enterTargetingMode()
			{ (creature) -> Bool in
				//TODO: are they onscreen? can you see them?
				return true
			}
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
			//make damage number representations
			var damageViews = [UILabel]()
			for (creature, number) in anim.damageNumbers
			{
				let damageView = UILabel()
				damageView.text = number
				damageView.sizeToFit()
				damageView.textColor = UIColor.whiteColor()
				let startX = (CGFloat(creature.x) + 0.5) * tileSize - cameraPoint.x + self.gameArea.frame.origin.x
				let startY = (CGFloat(creature.y) + 0.5) * tileSize - cameraPoint.y + self.gameArea.frame.origin.y
				damageView.center = CGPointMake(startX, startY)
				damageViews.append(damageView)
				self.view.addSubview(damageView)
			}
			
			//animate them
			UIView.animateWithDuration(damageNumberDuration, animations:
			{
				for damageView in damageViews
				{
					damageView.center = CGPoint(x: damageView.center.x, y: damageView.center.y - damageNumberDistanceTraveled)
				}
			})
			{ (completed) in
				for damageView in damageViews
				{
					damageView.removeFromSuperview()
				}
				
				//update the appearances of the representations, in case anybody changed
				for rep in self.representations
				{
					rep.updateAppearance()
				}
				
				//and go to the end of the chain
				self.animChainOver()
			}
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
		makeBar(healthBarContainerView, color: UIColor.redColor(), percent: CGFloat(game.player.health) / CGFloat(game.player.maxHealth))
		
		for subview in secondaryBarArea.subviews
		{
			subview.removeFromSuperview()
		}
		
		//draw movement points number
		let labelM = UILabel()
		labelM.text = "\(game.movePoints)/\(game.activeCreature.maxMovePoints) MP "
		labelM.sizeToFit()
		secondaryBarArea.addSubview(labelM)
		
		//draw weight number
		let labelW = UILabel(frame: CGRect(x: 0, y: labelM.frame.height, width: 0, height: 0))
		labelW.text = "\(game.player.encumberance)/\(game.player.maxEncumberance) LBs "
		labelW.sizeToFit()
		secondaryBarArea.addSubview(labelW)
		
		//TODO: draw status effect icons
		
		//update the equipment health bars
		makeBar(weaponBarContainerView, color: UIColor.greenColor(), percent: game.player.weapon.maxHealth == 0 ? 0 : CGFloat(game.player.weapon.health) / CGFloat(game.player.weapon.maxHealth))
		makeBar(armorBarContainerView, color: UIColor.greenColor(), percent: game.player.armor == nil ? 0 : CGFloat(game.player.armor!.health) / CGFloat(game.player.armor!.maxHealth))
		
	}
	
	private func makeBar(inView:UIView, color:UIColor, percent:CGFloat)
	{
		for subview in inView.subviews
		{
			subview.removeFromSuperview()
		}
		if percent != 0
		{
			let bar = UIView(frame: CGRectMake(0, 0, inView.frame.width * percent, inView.frame.height))
			bar.backgroundColor = color
			inView.addSubview(bar)
		}
	}
	
	func gameOver()
	{
		//TODO: handle a game over
	}
	
	//MARK: helper methods
	
	private func pruneRepresentations()
	{
		representations = representations.filter() { !$0.dead }
	}
	
	private func enterTargetingMode(isValidTarget:(Creature)->Bool)
	{
		targets = [Target]()
		for creature in game.creatures
		{
			if isValidTarget(creature)
			{
				//make a reticle
				let reticleFrame = CGRectMake(tileSize * CGFloat(creature.x) - cameraPoint.x, tileSize * CGFloat(creature.y) - cameraPoint.y, tileSize, tileSize)
				let reticle = UIView(frame: reticleFrame)
				reticle.alpha = 0.5
				reticle.backgroundColor = UIColor.redColor()
				self.creatureLayer.addSubview(reticle)
				
				//and register the target
				targets!.append(Target(subject: creature, view: reticle))
			}
		}
		
		//cancel out of targeting mode if there were no targets
		if targets!.count == 0
		{
			targets = nil
		}
	}
	
	private func leaveTargetingMode()
	{
		if let targets = targets
		{
			for target in targets
			{
				target.view.removeFromSuperview()
			}
			self.targets = nil
		}
	}
}