//
//  TileTests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/15/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class TileTests: XCTestCase {
	
	var wallTile:Tile!
	var floorTile:Tile!
	var pitTile:Tile!
	
    override func setUp() {
        super.setUp()
		
		wallTile = Tile(type: "sample wall")
		floorTile = Tile(type: "sample floor")
		pitTile = Tile(type: "sample pit")
    }
    
    func testSolid()
	{
		XCTAssertTrue(wallTile.solid)
		XCTAssertFalse(floorTile.solid)
		XCTAssertTrue(pitTile.solid)
		
		XCTAssertNotNil(wallTile.upperSprite)
		if let upper = wallTile.upperSprite
		{
			XCTAssertEqual(upper, "tile_caveceil")
		}
		XCTAssertNil(floorTile.upperSprite)
		XCTAssertNil(pitTile.upperSprite)
		
		XCTAssertNotNil(wallTile.middleSprite)
		if let middle = wallTile.middleSprite
		{
			XCTAssertEqual(middle, "tile_cavewall")
		}
		XCTAssertNotNil(floorTile.middleSprite)
		if let middle = floorTile.middleSprite
		{
			XCTAssertEqual(middle, "tile_cavefloor")
		}
		XCTAssertNil(pitTile.middleSprite)
		
		XCTAssertNotNil(wallTile.lowerSprite)
		if let lower = wallTile.lowerSprite
		{
			XCTAssertEqual(lower, "tile_pitwall")
		}
		XCTAssertNotNil(floorTile.lowerSprite)
		if let lower = floorTile.lowerSprite
		{
			XCTAssertEqual(lower, "tile_pitwall")
		}
		XCTAssertNotNil(pitTile.lowerSprite)
		if let lower = pitTile.lowerSprite
		{
			XCTAssertEqual(lower, "tile_pitfloor")
		}
	}
    
}
