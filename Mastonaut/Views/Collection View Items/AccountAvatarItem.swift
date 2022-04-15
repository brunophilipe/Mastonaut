//
//  AccountAvatarItem.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 12.03.19.
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

class AccountAvatarItem: NSCollectionViewItem
{
	@IBOutlet private weak var avatarImageView: NSImageView!
	@IBOutlet private weak var shortcutLabel: NSTextField!

	func set(account: AuthorizedAccount, index: Int)
	{
		view.toolTip = account.accountWithInstance

		if index < 9
		{
			shortcutLabel.stringValue = "⌘\(index + 1)"
		}
		else
		{
			shortcutLabel.stringValue = ""
		}
	}

	func set(avatar: NSImage)
	{
		avatarImageView.image = avatar
	}

	override var highlightState: NSCollectionViewItem.HighlightState
	{
		didSet
		{
			view.animator().alphaValue = highlightState == .forSelection ? 0.66 : 1.0
		}
	}
}
