//
//  UserPopUpButtonSubcontroller+Helper.swift
//  QuickToot
//
//  Created by Bruno Philipe on 15.09.19.
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
import CoreTootin

extension UserPopUpButtonSubcontroller
{
	convenience init(display: UserPopUpButtonDisplaying, accountsService: AccountsService)
	{
		self.init(display: display, accountsService: accountsService, itemsFactory: ItemsFactoryShim())
	}
}

private struct ItemsFactoryShim: AccountMenuItemFactory
{
	func makeMenuItems(accounts: [AuthorizedAccount],
					   currentUser: UUID?,
					   action: Selector,
					   target: AnyObject,
					   emojiContainer: NSView?,
					   setKeyEquivalents: Bool) -> (menuItems: [NSMenuItem], selectedItem: NSMenuItem?)
	{
		return accounts.makeMenuItems(currentUser: currentUser,
									  action: action,
									  target: target,
									  emojiContainer: emojiContainer,
									  setKeyEquivalents: setKeyEquivalents)
	}
}

private extension Array where Element == AuthorizedAccount
{
	func makeMenuItems(currentUser: UUID?,
					   action: Selector,
					   target: AnyObject,
					   emojiContainer: NSView?,
					   setKeyEquivalents: Bool) -> (menuItems: [NSMenuItem], selectedItem: NSMenuItem?)
	{
		var menuItems = [NSMenuItem]()
		var selectedItem: NSMenuItem? = nil

		for (index, account) in enumerated()
		{
			let itemHasKeyEquivalent = setKeyEquivalents && index < 9
			let itemTitle = account.bestDisplayName
			let menuItem = NSMenuItem(title: itemTitle,
									  action: action,
									  keyEquivalent: itemHasKeyEquivalent ? "\(index + 1)" : "")

			menuItem.target = target
			menuItem.representedObject = account.uuid
			menuItem.keyEquivalentModifierMask = itemHasKeyEquivalent ? .command : []
			menuItems.append(menuItem)

			if currentUser == account.uuid
			{
				selectedItem = menuItem
				menuItem.state = .on
			}
		}

		if selectedItem == nil
		{
			let menuItem = NSMenuItem(title: 🔠("Please Select…"), action: nil, keyEquivalent: "")
			menuItem.isEnabled = false
			menuItems.insert(menuItem, at: 0)
			selectedItem = menuItem
		}

		return (menuItems, selectedItem)
	}
}
