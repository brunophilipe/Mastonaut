//
//  NavigationTextField.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 05.06.19.
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

import Cocoa
import Carbon

@objc protocol NavigationTextFieldDelegate: AnyObject {

	func textField(_ textField: NavigationTextField, didStartNavigationModeFrom direction: NavigationTextField.Source)
	func textFieldDidCancelNavigationMode(_ textField: NavigationTextField)
	func textFieldDidCommitNavigationMode(_ textField: NavigationTextField)
	func textField(_ textField: NavigationTextField, didNavigate direction: NavigationTextField.Direction)
}

class NavigationTextField: NSTextField, NSTextViewDelegate {

	private(set) var isNavigationModeOn: Bool = false

	func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool
	{
		switch commandSelector
		{
		case #selector(moveUp(_:)):		moveUp()
		case #selector(moveDown(_:)):	moveDown()
		case #selector(moveLeft(_:)):	moveLeft()
		case #selector(moveRight(_:)):	moveRight()
		default: return false
		}
		return true
	}

	@IBOutlet
	var navigationDelegate: NavigationTextFieldDelegate?
	{
		didSet
		{
			if navigationDelegate == nil
			{
				isNavigationModeOn = false
			}
		}
	}

	private func moveDown()
	{
		guard let delegate = navigationDelegate else
		{
			return
		}

		if isNavigationModeOn
		{
			delegate.textField(self, didNavigate: .down)
		}
		else
		{
			isNavigationModeOn = true
			delegate.textField(self, didStartNavigationModeFrom: .top)
		}
	}

	private func moveUp()
	{
		guard let delegate = navigationDelegate else
		{
			return
		}

		if isNavigationModeOn
		{
			delegate.textField(self, didNavigate: .up)
		}
		else
		{
			isNavigationModeOn = true
			delegate.textField(self, didStartNavigationModeFrom: .bottom)
		}
	}

	private func moveLeft()
	{
		guard let delegate = navigationDelegate, isNavigationModeOn else
		{
			return
		}

		delegate.textField(self, didNavigate: .left)
	}

	private func moveRight()
	{
		guard let delegate = navigationDelegate, isNavigationModeOn else
		{
			return
		}

		delegate.textField(self, didNavigate: .right)
	}

	override func textDidChange(_ notification: Notification)
	{
		if let delegate = navigationDelegate, isNavigationModeOn
		{
			isNavigationModeOn = false
			delegate.textFieldDidCancelNavigationMode(self)
		}

		super.textDidChange(notification)
	}

	override func textDidEndEditing(_ notification: Notification)
	{
		if let delegate = navigationDelegate, isNavigationModeOn
		{
			if let currentEvent = NSApp.currentEvent, currentEvent.type == .keyDown,
				currentEvent.specialKey == .carriageReturn
			{
				delegate.textFieldDidCommitNavigationMode(self)
			}
			else
			{
				delegate.textFieldDidCancelNavigationMode(self)
			}
		}

		isNavigationModeOn = false
	}

	@objc enum Direction: Int
	{
		case up, down, left, right
	}

	@objc enum Source: Int
	{
		case bottom, top
	}
}
