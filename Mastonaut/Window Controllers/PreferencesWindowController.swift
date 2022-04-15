//
//  PreferencesWindowController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 03.03.19.
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
import CoreTootin

class PreferencesWindowController: NSWindowController
{
	var tabViewController: NSTabViewController?
	{
		return contentViewController as? NSTabViewController
	}

	lazy var accountsPreferencesViewController: AccountsPreferencesController? =
		{
			return tabViewController?.children.first(where: { $0 is AccountsPreferencesController }) as? AccountsPreferencesController
		}()

	func showAccountPreferences()
	{
		if let tabIndex = tabViewController?.children.firstIndex(where: { $0 is AccountsPreferencesController })
		{
			tabViewController?.selectedTabViewItemIndex = tabIndex
		}
	}
}

extension PreferencesWindowController: NSWindowDelegate
{
	func windowWillClose(_ notification: Notification)
	{
		AppDelegate.shared.detachPreferencesWindow(for: self)
	}
}

extension PreferencesWindowController: AccountAuthorizationSource
{
	var sourceWindow: NSWindow?
	{
		return window
	}

	func successfullyAuthenticatedUser(with userUUID: UUID)
	{
		accountsPreferencesViewController?.refreshAccountsListUI()
		accountsPreferencesViewController?.selectedAccountUUID = userUUID
	}

	func prepareForAuthorization()
	{
		showAccountPreferences()
	}

	func finalizeAuthorization()
	{

	}
}

extension PreferencesWindowController: AccountsMenuProvider
{
	private var accounts: [AuthorizedAccount]
	{
		return AppDelegate.shared.accountsService.authorizedAccounts
	}

	var accountsMenuItems: [NSMenuItem]
	{
		return accounts.makeMenuItems(currentUser: accountsPreferencesViewController?.selectedAccountUUID,
									  action: #selector(PreferencesWindowController.selectAccount(_:)),
									  target: self,
									  emojiContainer: nil,
									  setKeyEquivalents: true).menuItems
	}

	@objc func selectAccount(_ sender: Any?)
	{
		guard
			let uuid = (sender as? NSMenuItem)?.representedObject as? UUID,
			let accountsViewIndex = tabViewController?.children.firstIndex(where: { $0 is AccountsPreferencesController })
		else {
			return
		}

		tabViewController?.selectedTabViewItemIndex = accountsViewIndex
		accountsPreferencesViewController?.selectedAccountUUID = uuid
	}
}
