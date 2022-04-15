//
//  AccountSearchResultsViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 30.06.19.
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
import MastodonKit

class AccountSearchResultsViewController: SearchResultsViewController<Account>
{
	@IBOutlet unowned var _tableView: NSTableView!

	private var instance: Instance!

	override var tableView: NSTableView!
	{
		return _tableView
	}

	override internal var cellIdentifier: NSUserInterfaceItemIdentifier
	{
		return NSUserInterfaceItemIdentifier("account")
	}

	override func set(results: ResultsType, instance: Instance)
	{
		self.instance = instance
		elements = results.accounts
	}

	override internal func populate(cell: NSTableCellView, for account: Account)
	{
		guard let cell = cell as? AccountResultTableCellView else { return }

		cell.set(account: account, instance: instance)

		fetchAvatar(for: account, cell: cell)
	}

	override internal func makeSelection(for account: Account) -> SearchResultSelection
	{
		return .account(account)
	}

	private func fetchAvatar(for account: Account, cell: AccountResultTableCellView)
	{
		AppDelegate.shared.avatarImageCache.fetchImage(account: account)
			{
				[weak self] result in

				switch result
				{
				case .inCache(let image):
					assert(Thread.isMainThread)
					cell.set(avatar: image)

				case .loaded(let image):
					DispatchQueue.main.async {
						self?.setLoadedAvatar(image, for: account)
					}

				case .noImage:
					self?.setLoadedAvatar(#imageLiteral(resourceName: "missing"), for: account)
				}
			}
	}

	private func setLoadedAvatar(_ avatar: NSImage, for account: Account)
	{
		DispatchQueue.main.async
			{
				(self.cellView(for: account) as? AccountResultTableCellView)?.set(avatar: avatar)
			}
	}
}

class AccountResultTableCellView: NSTableCellView
{
	private static let displayNameAttributes: [NSAttributedString.Key: AnyObject] = [
		.font: NSFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: NSColor.labelColor,
		.underlineStyle: NSNumber(value: 0)
	]

	private static let bioAttributes: [NSAttributedString.Key: AnyObject] = [
		.font: NSFont.labelFont(ofSize: 11), .foregroundColor: NSColor.labelColor,
		.underlineStyle: NSNumber(value: 0)
	]

	private static let bioLinkAttributes: [NSAttributedString.Key: AnyObject] = [
		.font: NSFont.labelFont(ofSize: 11), .foregroundColor: NSColor.labelColor,
		.underlineStyle: NSNumber(value: 1)
	]

	@IBOutlet private unowned var avatarImageView: NSImageView!
	@IBOutlet private unowned var displayNameLabel: NSTextField!
	@IBOutlet private unowned var handleLabel: NSTextField!
	@IBOutlet private unowned var bioLabel: AttributedLabel!

	override func awakeFromNib()
	{
		super.awakeFromNib()

		bioLabel.linkTextAttributes = AccountResultTableCellView.bioLinkAttributes
		bioLabel.linkHandler = nil
	}

	func set(account: Account, instance: Instance)
	{
		avatarImageView.image = #imageLiteral(resourceName: "missing")

		displayNameLabel.set(stringValue: account.bestDisplayName,
							 applyingAttributes: AccountResultTableCellView.displayNameAttributes,
							 applyingEmojis: account.cacheableEmojis)

		handleLabel.stringValue = account.uri(in: instance)

		bioLabel.set(attributedStringValue: account.attributedNote,
					 applyingAttributes: AccountResultTableCellView.bioAttributes,
					 applyingEmojis: account.cacheableEmojis)
	}

	func set(avatar: NSImage)
	{
		avatarImageView.image = avatar
	}
}
