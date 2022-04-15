//
//  Stack.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 10.10.19.
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

public struct Stack<Element>: ExpressibleByArrayLiteral
{
	public typealias ArrayLiteralElement = Element

	private var backingStorage: [Element]

	public var count: Int { return backingStorage.count }
	public var isEmpty: Bool { return backingStorage.isEmpty }
	public var allElements: [Element] { return backingStorage }

	public init(_ array: [Element])
	{
		backingStorage = array
	}

	public init(arrayLiteral elements: Element...)
	{
		backingStorage = elements
	}

	public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T]
	{
		return try backingStorage.map(transform)
	}

	public mutating func push(_ element: Element)
	{
		backingStorage.insert(element, at: 0)
	}

	public mutating func pop() -> Element
	{
		guard !backingStorage.isEmpty else {
			fatalError("Attempted to pop empty stack: \(self)")
		}

		return backingStorage.remove(at: 0)
	}

	public mutating func popIfNotEmpty() -> Element?
	{
		guard !backingStorage.isEmpty else { return nil }
		return pop()
	}
}
