//
//  NSString+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 29.12.18.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2018 Bruno Philipe.
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

import Foundation
import MastodonKit

public extension NSString
{
	@objc var isEmptyString: Bool
	{
		return length == 0
	}

	func allRanges(of string: String, options: NSString.CompareOptions = []) -> [NSRange]
	{
		var allRanges = [NSRange]()
		var searchRange = NSMakeRange(0, length)
		var subrange: NSRange

		repeat
		{
			subrange = range(of: string, options: options, range: searchRange)

			if subrange.location != NSNotFound
			{
				allRanges.append(subrange)
				searchRange = NSMakeRange(subrange.upperBound, length - subrange.upperBound)
			}
		}
		while subrange.location != NSNotFound

		return allRanges
	}

	func applyingAttributes(_ attributes: [NSAttributedString.Key: AnyObject]) -> NSAttributedString
	{
		return NSAttributedString(string: self as String, attributes: attributes)
	}

	var range: NSRange
	{
		return NSMakeRange(0, length)
	}
}

public extension NSMutableString
{
	func replaceCharacters(in rangesReplacementMap: [NSRange: String])
	{
		var lengthOffset = 0

		for range in rangesReplacementMap.keys.sorted(by: { $0.location < $1.location })
		{
			let replacement = rangesReplacementMap[range]!
			replaceCharacters(in: NSMakeRange(range.location + lengthOffset, range.length), with: replacement)
			lengthOffset += (replacement as NSString).length - range.length
		}
	}
}

public extension NSAttributedString
{
	var isEmpty: Bool
	{
		return length == 0
	}
}

private extension Bool
{
	func map<U>(_ transform: () throws -> U) rethrows -> U?
	{
		if self == true
		{
			return try transform()
		}
		else
		{
			return nil
		}
	}
}
