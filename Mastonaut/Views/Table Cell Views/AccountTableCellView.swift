//
//  AccountTableCellView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 21.02.19.
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
import CoreTootin

class AccountTableCellView: NSTableCellView
{
	@IBOutlet weak var avatarView: NSImageView!
	@IBOutlet weak var nameLabel: NSTextField!
	@IBOutlet weak var accountLabel: NSTextField!
	@IBOutlet weak var instanceLabel: NSTextField!
	@IBOutlet weak var shortcutLabel: NSTextField!
	@IBOutlet weak var issueIndicatorImageView: NSImageView!

	private static let nameLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
	]

	private(set) var displayedAccountUUID: UUID? = nil

	func setUp(with account: AuthorizedAccount, index: Int)
	{
		guard account.isFault == false else { return }

		displayedAccountUUID = account.uuid

		nameLabel.stringValue = account.bestDisplayName
		accountLabel.stringValue = "@\(account.username!)"
		instanceLabel.stringValue = account.baseDomain!
		shortcutLabel.stringValue = index < 9 ? "⌘\(index + 1)" : ""
		issueIndicatorImageView.isHidden = !account.needsAuthorization
	}

	func setAvatar(_ image: NSImage)
	{
		avatarView.image = image
	}
}
