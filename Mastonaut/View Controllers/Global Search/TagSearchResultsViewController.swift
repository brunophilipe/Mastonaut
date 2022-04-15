//
//  TagSearchResultsViewController.swift
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
import CoreTootin

class TagSearchResultsViewController: SearchResultsViewController<Tag>
{
	@IBOutlet unowned var _tableView: NSTableView!

	override var tableView: NSTableView!
	{
		return _tableView
	}

	override internal var cellIdentifier: NSUserInterfaceItemIdentifier
	{
		return NSUserInterfaceItemIdentifier("tag")
	}

	override func set(results: ResultsType, instance: Instance)
	{
		elements = results.hashtags
	}

	override internal func populate(cell: NSTableCellView, for tag: Tag)
	{
		(cell as? TagResultTableCellView)?.set(tag: tag)
	}

	override internal func makeSelection(for tag: Tag) -> SearchResultSelection
	{
		return .tag(tag.name)
	}
}

class TagResultTableCellView: NSTableCellView
{
	@IBOutlet private unowned var tagNameLabel: NSTextField!
	@IBOutlet private unowned var tagUsageLabel: NSTextField!

	func set(tag: Tag)
	{
		tagNameLabel.stringValue = "#\(tag.name)"
		tagUsageLabel.stringValue = makeUsageInfo(tag.history ?? [])
	}

	private func makeUsageInfo(_ history: [TagStatistics]) -> String
	{
		let totalUses = history.reduce(0) { return $0 + $1.uses }

		guard totalUses > 0 else {
			return 🔠("No recent usage")
		}

		let days = history.count
		return 🔠("%@ uses in the past %@", "\(totalUses)", days == 1 ? 🔠("day") : 🔠("%@ days", "\(days)"))
	}
}
