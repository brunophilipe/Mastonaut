//
//  BaseAccountsPreferencesViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 21.08.19.
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

class BaseAccountsPreferencesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate
{
	@IBOutlet private(set) weak var tableView: NSTableView!

	internal let resourceFetcher = ResourcesFetcher(urlSession: AppDelegate.shared.resourcesUrlSession)

	internal var accounts: [AuthorizedAccount]? = nil {
		didSet {
			didSetAccounts()
			let selectedRow = tableView.selectedRow
			tableView.reloadData()
			if selectedRow >= 0, selectedRow < accounts?.count ?? 0 {
				tableView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
			}
		}
	}

	// MARK: - Bindings

	func didSetAccounts() {}

	struct CellViewIdentifiers
	{
		static let account = NSUserInterfaceItemIdentifier("account")
	}

	// MARK: - View Lifecycle

	override func viewDidLoad()
	{
		super.viewDidLoad()

		tableView.register(NSNib(nibNamed: "AccountTableCellView", bundle: .main),
						   forIdentifier: CellViewIdentifiers.account)

		accounts = AppDelegate.shared.accountsService.authorizedAccounts
	}

	// MARK: - Table View Data Source

	func numberOfRows(in tableView: NSTableView) -> Int
	{
		return accounts?.count ?? 0
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
	{
		let view = tableView.makeView(withIdentifier: CellViewIdentifiers.account, owner: nil)

		guard let cellView = view as? AccountTableCellView, let account = accounts?[row] else
		{
			return view
		}

		cellView.setUp(with: account, index: row)

		guard let avatarUrl = account.avatarURL else
		{
			return cellView
		}

		let accountUUID = account.uuid

		resourceFetcher.fetchImage(with: avatarUrl)
		{
			[weak self] result in

			if case .success(let image) = result
			{
				DispatchQueue.main.async
					{
						guard
							let accountIndex = self?.accounts?.firstIndex(where: { $0.uuid == accountUUID }),
							let view = self?.tableView.view(atColumn: 0, row: accountIndex, makeIfNecessary: false),
							let cellView = view as? AccountTableCellView
						else
						{
							return
						}

						cellView.setAvatar(image)
					}
			}
		}

		return cellView
	}
}
