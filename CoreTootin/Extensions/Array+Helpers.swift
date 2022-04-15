//
//  Array+Helpers.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 17.09.19.
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

public extension Array where Element: Hashable
{
	func uniqueElements() -> [Element]
	{
		var set = Set<Element>()
		var uniqueElements = [Element]()

		for element in self
		{
			if set.contains(element) { continue }
			set.insert(element)
			uniqueElements.append(element)
		}

		return uniqueElements
	}
}
