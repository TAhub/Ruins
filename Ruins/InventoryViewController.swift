//
//  InventoryViewController.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/11/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit

class InventoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet weak var table: UITableView!
	@IBOutlet weak var label: UILabel!
	
	@IBOutlet weak var actionB1: UIButton!
	@IBOutlet weak var actionB2: UIButton!
	@IBOutlet weak var modeB: UIButton!
	
	var game:Game!
	private var mode:Int = 0
	private var item:Item?
	
    override func viewDidLoad() {
        super.viewDidLoad()

		table.dataSource = self
		table.delegate = self
		
		nameButtons()
    }
	
	private func nameButtons()
	{
		actionB1.hidden = false
		actionB2.hidden = false
		if mode == 0
		{
			if !canUse
			{
				actionB1.hidden = true
			}
			if item?.weapon != nil || item?.armor != nil
			{
				actionB1.setTitle("Equip", forState: .Normal)
			}
			else
			{
				actionB1.setTitle("Use", forState: .Normal)
			}
			actionB2.setTitle("Drop", forState: .Normal)
			modeB.setTitle("To Floor", forState: .Normal)
		}
		else
		{
			actionB1.setTitle("Pick Up", forState: .Normal)
			actionB2.hidden = true
			modeB.setTitle("To Inventory", forState: .Normal)
		}
		if let item = item
		{
			label.text = "\(item.name): DESCRIPTION"
			//TODO: description
			//it should probably include, like, stats and shit
			//and comparisons to current stats
		}
		else
		{
			label.text = ""
		}
	}
	
	//MARK: actions
	
	@IBAction func actionButton(sender: UIButton)
	{
		switch(sender.tag)
		{
		case 0:
			if mode == 0
			{
				if let armor = item?.armor
				{
					backButton()
					
					//equip the armor
					if let currentArmor = game.player.armor
					{
						game.player.inventory.append(Item(armor: currentArmor))
					}
					game.player.armor = armor
					removeItem()
					
					game.delegate?.updatePlayer()
					
					//this costs an entire action
					game.skipAction()
				}
				else if let weapon = item?.weapon
				{
					backButton()
					
					//equip the weapon
					if game.player.weapon.type != "unarmed"
					{
						game.player.inventory.append(Item(weapon: game.player.weapon))
					}
					game.player.weapon = weapon
					removeItem()
					
					game.delegate?.updatePlayer()
					
					//this doesn't cost an action, just a move point
					game.movePoints = max(game.movePoints - 1, 0)
				}
			}
			else
			{
				//TODO: pick up
			}
		case 1:
			if mode == 0
			{
				//TODO: drop
			}
		default: break
		}
	}
	
	@IBAction func modeButton()
	{
		item = nil
		mode = (mode + 1) % 2
		nameButtons()
		table.reloadData()
	}
	
	@IBAction func backButton()
	{
		self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}
	
	//MARK: delegate methods
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return 5
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if mode == 1
		{
			return 0 //TODO: should be able to pick stuff up off ground; it should all be in a single category as below though
		}
		return inventorySubarrayInCategoryNumber(self.game.player.inventory, categoryNumber: section).count
	}
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		if mode == 1
		{
			return nil
		}
		switch(section)
		{
		case 0: return "Weapons"
		case 1: return "Spell Items"
		case 2: return "Usables"
		case 3: return "Armors"
		default: return "Misc"
		}
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let item = inventorySubarrayInCategoryNumber(self.game.player.inventory, categoryNumber: indexPath.section)[indexPath.row]
		
		let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell")!
		
		cell.textLabel!.text = item.name
		
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		item = inventorySubarrayInCategoryNumber(self.game.player.inventory, categoryNumber: indexPath.section)[indexPath.row]
		nameButtons()
	}
	
	//MARK: helper functions
	
	private var canUse:Bool
	{
		if item?.weapon != nil
		{
			return game.movePoints > 0
		}
		//TODO: if it's a special power, return if you have aura
		return true
	}
	
	private func removeItem()
	{
		//remove the item from the open inventory, and de-select it
		for (i, item) in game.player.inventory.enumerate()
		{
			if item === self.item
			{
				game.player.inventory.removeAtIndex(i)
				break
			}
		}
		item = nil
		table.deselectRowAtIndexPath(table.indexPathForSelectedRow!, animated: false)
	}
	
	func inventorySubarrayInCategoryNumber(inventory:[Item], categoryNumber:Int) -> [Item]
	{
		var items = [Item]()
		for item in game.player.inventory
		{
			var catNum = 4
			if item.weapon != nil
			{
				catNum = 0
			}
			else if false //TODO: special power item
			{
				catNum = 1
			}
			else if false //TODO: usable item
			{
				catNum = 2
			}
			else if item.armor != nil
			{
				catNum = 3
			}
			
			if catNum == categoryNumber
			{
				items.append(item)
			}
		}
		
		return items
	}
}