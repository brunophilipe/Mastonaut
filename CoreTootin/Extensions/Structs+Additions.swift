//
//  File.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 19.01.19.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2019 Bruno Philipe.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import AppKit

public extension NSSize
{
	var ratio: CGFloat
	{
		return height > 0 ? width / height : 0
	}

	var area: CGFloat
	{
		return width * height
	}

	func limit(width maxWidth: CGFloat = .greatestFiniteMagnitude,
			   height maxHeight: CGFloat = .greatestFiniteMagnitude) -> NSSize
	{
		return NSSize(width: Swift.min(width, maxWidth), height: Swift.min(height, maxHeight))
	}

	func fitting(on size: NSSize) -> NSSize
	{
		// Avoid division by zero
		let width = max(self.width, 1)
		let height = max(self.height, 1)

		if size.ratio < ratio
		{
			// Constrain by new size width
			return NSSize(width: size.width, height: round(height / width * size.width))
		}
		else
		{
			// Constrain by new size height
			return NSSize(width: round(width / height * size.height), height: size.height)
		}
	}

	func rounded() -> NSSize
	{
		return NSSize(width: round(width), height: round(height))
	}

	func multiplied(by scale: CGFloat) -> NSSize
	{
		return NSSize(width: width * scale, height: height * scale)
	}
}

public extension NSPoint
{
	func offsetting(byX dx: CGFloat = 0, byY dy: CGFloat = 0) -> NSPoint
	{
		return NSPoint(x: x + dx, y: y + dy)
	}
}

public extension TimeInterval
{
	var formattedStringValue: String
	{
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.day, .hour, .minute, .second]
		formatter.unitsStyle = .abbreviated
		formatter.maximumUnitCount = 2

		return formatter.string(from: self)!
	}
}

public extension Collection
{
	subscript(bounded index: Index) -> Element?
	{
		guard index >= startIndex, index < endIndex else { return nil }
		return self[index]
	}
}

infix operator ?==

public func ?==<T: Equatable>(_ lhs: Any?, _ rhs: T) -> Bool
{
	return (lhs as? T) == rhs
}

infix operator ?===

public func ?===<T: AnyObject>(_ lhs: AnyObject?, _ rhs: T) -> Bool
{
	return (lhs as? T) === rhs
}
