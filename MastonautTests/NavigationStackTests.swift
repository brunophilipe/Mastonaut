//
//  NavigationStackTests.swift
//  MastonautTests
//
//  Created by Bruno Philipe on 06.10.19.
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

import XCTest
import CoreTootin

class NavigationStackTests: XCTestCase
{
	private var navigationStack: NavigationStack<MockItem>!

	override func setUp()
	{
		navigationStack = NavigationStack<MockItem>(currentItem: "1")
	}

	func testBasicSetup()
	{
		XCTAssertEqual(navigationStack.currentItem, "1")
	}

	func testPushingNewItems()
	{
		navigationStack.set(currentItem: "2")
		XCTAssertEqual(navigationStack.currentItem, "2")
		navigationStack.set(currentItem: "3")
		XCTAssertEqual(navigationStack.currentItem, "3")
		navigationStack.set(currentItem: "4")
		XCTAssertEqual(navigationStack.currentItem, "4")
		navigationStack.set(currentItem: "5")
		XCTAssertEqual(navigationStack.currentItem, "5")
		XCTAssertTrue(navigationStack.canGoBackward)
	}

	func testBackwardNavigation()
	{
		navigationStack.set(currentItem: "2")
		navigationStack.set(currentItem: "3")
		navigationStack.set(currentItem: "4")
		navigationStack.set(currentItem: "5")
		XCTAssertEqual(navigationStack.currentItem, "5")
		XCTAssertEqual(navigationStack.goBack(), "4")
		XCTAssertEqual(navigationStack.currentItem, "4")
		XCTAssertEqual(navigationStack.goBack(), "3")
		XCTAssertEqual(navigationStack.currentItem, "3")
		XCTAssertEqual(navigationStack.goBack(), "2")
		XCTAssertEqual(navigationStack.currentItem, "2")
		XCTAssertEqual(navigationStack.goBack(), "1")
		XCTAssertEqual(navigationStack.currentItem, "1")
		XCTAssertFalse(navigationStack.canGoBackward)
	}

	func testForwardNavigation()
	{
		navigationStack.set(currentItem: "2")
		navigationStack.set(currentItem: "3")
		navigationStack.set(currentItem: "4")
		navigationStack.set(currentItem: "5")
		_ = navigationStack.goBack()
		_ = navigationStack.goBack()
		_ = navigationStack.goBack()
		_ = navigationStack.goBack()
		XCTAssertTrue(navigationStack.canGoForward)
		XCTAssertEqual(navigationStack.goForward(), "2")
		XCTAssertEqual(navigationStack.currentItem, "2")
		XCTAssertEqual(navigationStack.goForward(), "3")
		XCTAssertEqual(navigationStack.currentItem, "3")
		XCTAssertEqual(navigationStack.goForward(), "4")
		XCTAssertEqual(navigationStack.currentItem, "4")
		XCTAssertEqual(navigationStack.goForward(), "5")
		XCTAssertEqual(navigationStack.currentItem, "5")
	}

	func testForwardAndBackwardNavigation()
	{
		navigationStack.set(currentItem: "2")
		navigationStack.set(currentItem: "3")
		navigationStack.set(currentItem: "4")
		navigationStack.set(currentItem: "5")
		XCTAssertTrue(navigationStack.canGoBackward)
		_ = navigationStack.goBack()
		XCTAssertTrue(navigationStack.canGoForward)
		navigationStack.set(currentItem: "4")
		XCTAssertFalse(navigationStack.canGoForward)
		navigationStack.set(currentItem: "6")
		XCTAssertFalse(navigationStack.canGoForward)
		XCTAssertTrue(navigationStack.canGoBackward)
		_ = navigationStack.goBack()
		XCTAssertTrue(navigationStack.canGoForward)
		XCTAssertEqual(navigationStack.currentItem, "4")
		_ = navigationStack.goForward()
		XCTAssertFalse(navigationStack.canGoForward)
		XCTAssertEqual(navigationStack.currentItem, "6")
	}
}

private struct MockItem: RawRepresentable, ExpressibleByStringLiteral, Equatable
{
	typealias RawValue = String
	typealias StringLiteralType = String

	let value: String

	var rawValue: String
	{
		return value
	}

	init?(rawValue: Self.RawValue)
	{
		self.value = rawValue
	}

	init(stringLiteral value: Self.StringLiteralType)
	{
		self.value = value
	}
}
