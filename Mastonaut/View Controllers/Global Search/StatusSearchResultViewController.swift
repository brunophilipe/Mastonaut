//
//  StatusSearchResultViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 02.07.19.
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
import MastodonKit

class StatusSearchResultsViewController: SearchResultsViewController<Account>
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
		(cell as? AccountResultTableCellView)?.set(account: account, instance: instance)
	}

	override internal func makeSelection(for account: Account) -> SearchResultSelection
	{
		return .account(account)
	}
}

class StatusResultTableCellView: NSTableCellView
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

		bioLabel.linkTextAttributes = StatusResultTableCellView.bioLinkAttributes
		bioLabel.linkHandler = nil
	}

	func set(account: Account, instance: Instance)
	{
		displayNameLabel.set(stringValue: account.bestDisplayName,
							 applyingAttributes: StatusResultTableCellView.displayNameAttributes,
							 applyingEmojis: account.cacheableEmojis)

		handleLabel.stringValue = account.uri(in: instance)

		bioLabel.set(attributedStringValue: account.attributedNote,
					 applyingAttributes: StatusResultTableCellView.bioAttributes,
					 applyingEmojis: account.cacheableEmojis)
	}
}
