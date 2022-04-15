//
//  NavigationStack.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 13.04.19.
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

public class NavigationStack<NavigationItem: RawRepresentable>: NSObject, NSCoding
{
	private var backwardStack: Stack<NavigationItem.RawValue> = []
	private var forwardStack: Stack<NavigationItem.RawValue> = []

	public private(set) var currentItem: NavigationItem

	public var canGoForward: Bool { return !forwardStack.isEmpty }
	public var canGoBackward: Bool { return !backwardStack.isEmpty }

	public init(currentItem: NavigationItem)
	{
		self.currentItem = currentItem
	}

	public required init?(coder decoder: NSCoder)
	{
		guard
			let rawCurrentItem: NavigationItem.RawValue = decoder.decodeObject(forKey: CodingKeys.currentItem),
			let currentItem = NavigationItem(rawValue: rawCurrentItem),
			let backwardStackItems: [NavigationItem.RawValue] = decoder.decodeObject(forKey: CodingKeys.backwardStack),
			let forwardStackItems: [NavigationItem.RawValue] = decoder.decodeObject(forKey: CodingKeys.forwardStack)
		else
		{
			return nil
		}

		self.currentItem = currentItem
		self.backwardStack = Stack(backwardStackItems)
		self.forwardStack = Stack(forwardStackItems)
	}

	public func encode(with encoder: NSCoder)
	{
		encoder.encode(backwardStack.allElements, forKey: CodingKeys.backwardStack)
		encoder.encode(forwardStack.allElements, forKey: CodingKeys.forwardStack)
		encoder.encode(currentItem.rawValue, forKey: CodingKeys.currentItem)
	}

	public func set(currentItem newItem: NavigationItem)
	{
		backwardStack.push(currentItem.rawValue)
		forwardStack = []
		currentItem = newItem
	}

	public func goBack() -> NavigationItem
	{
		forwardStack.push(currentItem.rawValue)
		guard let currentItem = NavigationItem(rawValue: backwardStack.pop()) else {
			fatalError("Could not parse NavigationItem from rawValue")
		}
		self.currentItem = currentItem
		return currentItem
	}

	public func goForward() -> NavigationItem
	{
		backwardStack.push(currentItem.rawValue)
		guard let currentItem = NavigationItem(rawValue: forwardStack.pop()) else {
			fatalError("Could not parse NavigationItem from rawValue")
		}
		self.currentItem = currentItem
		return currentItem
	}

	private enum CodingKeys: String
	{
		case backwardStack, forwardStack, currentItem
	}
}
