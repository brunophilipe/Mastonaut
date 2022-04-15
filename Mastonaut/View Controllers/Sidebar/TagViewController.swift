//
//  TagViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 13.04.19.
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

class TagViewController: TimelineViewController, SidebarPresentable
{
	let tag: String
	private let titleButtonBindable: SidebarTitleButtonStateBindable?
	private let tagBookmarkService: TagBookmarkService?

	var sidebarModelValue: SidebarModel
	{
		return SidebarMode.tag(tag)
	}

	var titleMode: SidebarTitleMode
	{
		return titleButtonBindable.map { .button($0, .title("#\(tag)")) } ?? .title("#\(tag)")
	}

	init(tag: String, tagBookmarkService: TagBookmarkService?)
	{
		self.tag = tag

		if let service = tagBookmarkService
		{
			self.titleButtonBindable = TagBookmarkButtonStateBindable(tag: tag, tagBookmarkService: service)
			self.tagBookmarkService = service
		}
		else
		{
			self.titleButtonBindable = nil
			self.tagBookmarkService = nil
		}

		super.init(source: .tag(name: tag))
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
}

private class TagBookmarkButtonStateBindable: SidebarTitleButtonStateBindable
{
	let tag: String

	unowned let tagBookmarkService: TagBookmarkService

	init(tag: String, tagBookmarkService: TagBookmarkService)
	{
		self.tag = tag
		self.tagBookmarkService = tagBookmarkService
		super.init()
		updateButton()
	}

	private func updateButton()
	{
		let isBookmarked = tagBookmarkService.isTagBookmarked(tag)
		icon = isBookmarked ? #imageLiteral(resourceName: "bookmark_active") : #imageLiteral(resourceName: "bookmark")
		accessibilityLabel = isBookmarked ? 🔠("Unbookmark Tag") : 🔠("Bookmark Tag")
	}

	override func didClickButton(_ sender: Any?)
	{
		tagBookmarkService.toggleBookmarkedState(for: tag)
		updateButton()
	}
}
