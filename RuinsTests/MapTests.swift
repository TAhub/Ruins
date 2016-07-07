//
//  MapTests.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import XCTest
@testable import Ruins

class MapTests: XCTestCase {

	var map:Map!
	
    override func setUp() {
        super.setUp()
		
		map = Map(width: 10, height: 10)
    }
 
	func testDefaultMapGen()
	{
		//it should have borders at all sides
		XCTAssertTrue(map.tileAt(x: 0, y: 0).solid)
		XCTAssertTrue(map.tileAt(x: 9, y: 0).solid)
		XCTAssertTrue(map.tileAt(x: 0, y: 9).solid)
		XCTAssertTrue(map.tileAt(x: 9, y: 9).solid)
		XCTAssertFalse(map.tileAt(x: 1, y: 1).solid)
	}
}
