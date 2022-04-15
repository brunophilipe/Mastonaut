//
//  Array+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 23.05.19.
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

import Foundation

extension Array
{
	/// If the array is empty, returns `startIndex`. Otherwise returns `endIndex`.
	var lastIndex: Index
	{
		return isEmpty ? startIndex : endIndex
	}

	func indices(elementIsIncluded: (Element) -> Bool) -> [Index]
	{
		return enumerated().compactMap({ elementIsIncluded($0.element) ? $0.offset : nil })
	}

	mutating func removeAllReturningIndices(where shouldBeRemoved: (Element) throws -> Bool) rethrows -> [Index]
	{
		var removedIndices: [Index] = []
		var keptElements: [Element] = []

		for (index, element) in self.enumerated()
		{
			if try shouldBeRemoved(element)
			{
				removedIndices.append(index)
			}
			else
			{
				keptElements.append(element)
			}
		}

		self = keptElements
		return removedIndices
	}

	@inlinable func compacted<T>() -> [T] where Element == Optional<T>
	{
		return compactMap({ $0 })
	}

	func segregated(using goesIntoFirstList: (Element) -> Bool) -> ([Element], [Element])
	{
		var first = [Element]()
		var second = [Element]()

		for element in self
		{
			if goesIntoFirstList(element)
			{
				first.append(element)
			}
			else
			{
				second.append(element)
			}
		}

		return (first, second)
	}
}
