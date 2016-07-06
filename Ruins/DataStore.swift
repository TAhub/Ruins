//
//  DataStore.swift
//  Arena
//
//  Created by Theodore Abshire on 6/7/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import Foundation

class DataStore
{
	//MARK: internal functions
	private static func getPlist(plist:String) -> [NSString : NSObject]
	{
		if let filePath = NSBundle.mainBundle().pathForResource(plist, ofType: "plist"), let dict = NSDictionary(contentsOfFile: filePath) as? [NSString : NSObject]
		{
			return dict
		}
		assertionFailure()
		return [NSString : NSObject]()
	}
	
	private static func getEntry(plist:String, _ entry:String) -> [NSString : NSObject]
	{
		let plist = getPlist(plist)
		if let entry = plist[entry] as? [NSString : NSObject]
		{
			return entry
		}
		assertionFailure()
		return [NSString : NSObject]()
	}
	
	//MARK: external accessors
	static func getInt(plist:String, _ entry:String, _ value:String) -> Int?
	{
		let entry = getEntry(plist, entry)
		if let number = entry[value] as? NSNumber
		{
			return Int(number.intValue)
		}
		return nil
	}
	
	static func getFloat(plist:String, _ entry:String, _ value:String) -> Float?
	{
		let entry = getEntry(plist, entry)
		if let number = entry[value] as? NSNumber
		{
			return number.floatValue
		}
		return nil
	}
	
	static func getString(plist:String, _ entry:String, _ value:String) -> String?
	{
		let entry = getEntry(plist, entry)
		return entry[value] as? String
	}
	
	static func getArray(plist:String, _ entry:String, _ value:String) -> [NSObject]?
	{
		let entry = getEntry(plist, entry)
		return entry[value] as? [NSObject]
	}
	
	static func getBool(plist:String, _ entry:String, _ value:String) -> Bool
	{
		let entry = getEntry(plist, entry)
		return entry[value] != nil
	}
}