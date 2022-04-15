//
//  AccountOrder+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 19.05.19.
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
import CoreData

public extension AccountOrder
{
	static func `default`(context: NSManagedObjectContext) -> AccountOrder
	{
		assert(Thread.isMainThread)
		let fetchRequest: NSFetchRequest<AccountOrder> = AccountOrder.fetchRequest()
		fetchRequest.returnsObjectsAsFaults = false

		guard let results = try? context.fetch(fetchRequest), let order = results.first else {
			return AccountOrder(context: context)
		}

		return order
	}

	var sortedAccounts: [AuthorizedAccount]
	{
		return (accounts!.array as! [AuthorizedAccount]).filter({ !$0.isDeleted })
	}

	func set(sortOrder: Int, for account: AuthorizedAccount)
	{
		let accounts = self.accounts!.mutableCopy() as! NSMutableOrderedSet
		let currentIndex = accounts.index(of: account)

		if currentIndex != NSNotFound
		{
			accounts.moveObjects(at: IndexSet(integer: currentIndex), to: sortOrder)
		}
		else
		{
			accounts.insert([account], at: sortOrder)
		}

		self.accounts = accounts
	}

	func appendAccount(_ account: AuthorizedAccount)
	{
		let accounts = (self.accounts?.mutableCopy() as? NSMutableOrderedSet) ?? NSMutableOrderedSet(capacity: 1)
		accounts.add(account)
		self.accounts = accounts
	}
}
