//
//  ImageExtensions.swift
//  Ruins
//
//  Created by Theodore Abshire on 7/8/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

import UIKit
import CoreImage

extension UIImage
{
	private func solidColorImage(color:UIColor) -> UIImage
	{
		let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
		
		//get the color space and context
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
		let bitmapContext = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height), 8, 0, colorSpace, bitmapInfo.rawValue)
		
		//draw and fill it
		CGContextClipToMask(bitmapContext, rect, self.CGImage)
		CGContextSetFillColorWithColor(bitmapContext, color.CGColor)
		CGContextFillRect(bitmapContext, rect)
		
		//return a snapshot of that
		return UIImage(CGImage: CGBitmapContextCreateImage(bitmapContext)!)
	}
	
	func colorImage(color:UIColor) -> UIImage
	{
		//get the color mask image
		let colorImage = solidColorImage(color)
		
		//get other stuff
		let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
		UIGraphicsBeginImageContext(self.size)
		
		//draw the image
		self.drawInRect(rect)
		
		//draw the color mask
		colorImage.drawAtPoint(CGPointZero, blendMode: CGBlendMode.Multiply, alpha: 1.0)
		
		//get the new image
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage
	}
	
	class func combineImages(images:[UIImage], anchorAt:CGPoint) -> UIImage
	{
		var largestSize = CGSize(width: 0, height: 0)
		for image in images
		{
			largestSize.width = max(largestSize.width, image.size.width)
			largestSize.height = max(largestSize.height, image.size.height)
		}
		
		UIGraphicsBeginImageContext(largestSize)
		for image in images
		{
			//the anchorAt point is where the views should converge
			//ie 0.5, 0.5 means they should all be centered
			//0, 0 means they should all be drawn in the upper-left
			image.drawAtPoint(CGPoint(x: (largestSize.width - image.size.width) * anchorAt.x, y: (largestSize.height - image.size.height) * anchorAt.y))
		}
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage
	}
}