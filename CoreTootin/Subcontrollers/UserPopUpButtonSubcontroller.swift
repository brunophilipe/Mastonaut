//
//  UserPopUpButtonSubcontroller.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 20.02.19.
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

@objc
public protocol UserPopUpButtonDisplaying: AnyObject
{
	var currentUserPopUpButton: NSPopUpButton! { get }

	var currentUser: UUID? { get set }

	func shouldChangeCurrentUser(to userUUID: UUID) -> Bool
}

public protocol AccountMenuItemFactory
{
	func makeMenuItems(accounts: [AuthorizedAccount],
					   currentUser: UUID?,
					   action: Selector,
					   target: AnyObject,
					   emojiContainer: NSView?,
					   setKeyEquivalents: Bool) -> (menuItems: [NSMenuItem], selectedItem: NSMenuItem?)
}

public class UserPopUpButtonSubcontroller: NSObject
{
	private unowned let display: UserPopUpButtonDisplaying
	private unowned let accountsService: AccountsService
	private let itemsFactory: AccountMenuItemFactory

	private let accountCountObservation: NSKeyValueObservation

	private var accounts: [AuthorizedAccount]
	{
		return accountsService.authorizedAccounts
	}

	public init(display: UserPopUpButtonDisplaying,
				accountsService: AccountsService,
				itemsFactory: AccountMenuItemFactory)
	{
		self.display = display
		self.accountsService = accountsService
		self.itemsFactory = itemsFactory

		let selfPromise = WeakPromise<UserPopUpButtonSubcontroller>()
		self.accountCountObservation = accountsService.observe(\.authorizedAccountsCount)
			{
				_,_ in selfPromise.value?.updateUserPopUpButton()
			}

		super.init()

		selfPromise.value = self

		updateUserPopUpButton()
	}

	public func updateUserPopUpButton()
	{
		let accountsMenuItems = itemsFactory.makeMenuItems(accounts: accounts,
														   currentUser: display.currentUser,
														   action: #selector(UserPopUpButtonSubcontroller.selectAccount(_:)),
														   target: self,
														   emojiContainer: display.currentUserPopUpButton,
														   setKeyEquivalents: false)

		let usersMenu = NSMenu(title: "Users")
		usersMenu.setItems(accountsMenuItems.menuItems)
		display.currentUserPopUpButton.menu = usersMenu
		display.currentUserPopUpButton.select(accountsMenuItems.selectedItem)
	}

	@objc
	public func selectAccount(_ sender: NSMenuItem)
	{
		guard
			let uuid = sender.representedObject as? UUID,
			display.currentUser != uuid,
			display.shouldChangeCurrentUser(to: uuid)
			else
		{
			updateUserPopUpButton()
			return
		}

		display.currentUser = uuid
	}
}
