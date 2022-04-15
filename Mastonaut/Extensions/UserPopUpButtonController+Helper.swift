//
//  UserPopUpButtonSubcontroller+Helper.swift
//  Mastonaut
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

import Foundation
import CoreTootin

extension UserPopUpButtonSubcontroller
{
	convenience init(display: UserPopUpButtonDisplaying)
	{
		self.init(display: display,
				  accountsService: AppDelegate.shared.accountsService,
				  itemsFactory: ItemsFactoryShim())
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
