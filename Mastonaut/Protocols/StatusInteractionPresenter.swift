//
//  StatusInteractionPresenter.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 01.08.20.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2020 Bruno Philipe.
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
import CoreTootin
import MastodonKit

protocol StatusInteractionPresenter {

	var replyButton: NSButton! { get }
	var reblogButton: NSButton! { get }
	var favoriteButton: NSButton! { get }
	var warningButton: NSButton! { get }
	var sensitiveContentButton: NSButton! { get }
}

extension StatusInteractionPresenter where Self: MastonautTableCellView {

	func setUpInteractions(status: Status) {
		reblogButton?.isEnabled = status.visibility.allowsReblog
		reblogButton?.toolTip = status.visibility.reblogToolTip(didReblog: status.reblogged == true)
		reblogButton?.image = status.visibility.reblogIcon
		reblogButton?.state = status.reblogged == true ? .on : .off

		favoriteButton?.toolTip = favoriteToolTip(status)
		favoriteButton?.state = status.favourited == true ? .on : .off

		sensitiveContentButton?.isHidden = status.mediaAttachments.count == 0
		sensitiveContentButton?.state = status.sensitive == true ? .on : .off

		let buttons = [replyButton, reblogButton, favoriteButton, warningButton, sensitiveContentButton]
		setAccessibilityCustomActions(buttons.compactMap({ $0?.isHidden == false ? $0 : nil })
											 .map({ .init(actionForButton: $0) }))
	}

	private func favoriteToolTip(_ status: Status) -> String
	{
		if status.favourited == true {
			return 🔠("Unfavorite this toot")
		} else {
			return 🔠("Favorite this toot")
		}
	}
}

extension NSAccessibilityCustomAction {

	convenience init(actionForButton button: NSButton) {
		self.init(name: button.toolTip ?? "", handler: { [unowned button] in
			button.performClick(nil)
			return true
		})
	}
}
