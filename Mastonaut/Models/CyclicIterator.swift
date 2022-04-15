//
//  CyclicIterator.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 28.04.19.
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

struct CyclicIterator<Base: Collection>
{
	private let collection: Base
	private var currentIndex: Base.Index

	init(_ collection: Base)
	{
		assert(collection.isEmpty == false, "A cyclic iterator can not be initialized with an empty collection!")
		self.collection = collection
		self.currentIndex = collection.startIndex
	}

	mutating func next() -> Base.Element
	{
		if currentIndex >= collection.endIndex
		{
			currentIndex = collection.startIndex
		}

		defer
		{
			currentIndex = collection.index(after: currentIndex)
		}

		return collection[currentIndex]
	}
}

extension Collection
{
	func makeCyclicIterator() -> CyclicIterator<Self>
	{
		return CyclicIterator(self)
	}
}
