//
//  Visibility+MenuItemCapable.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 14.09.19.
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

import AppKit
import MastodonKit

public extension Visibility
{
	private var icon: NSImage
	{
		switch self
		{
		case .public: return NSImage.CoreTootin.globe
		case .unlisted: return NSImage.CoreTootin.padlock_open
		case .private: return NSImage.CoreTootin.padlock
		case .direct: return NSImage.CoreTootin.envelope
		}
	}

	var localizedTitle: String
	{
		switch self
		{
		case .public: return 🔠("visibility.public")
		case .unlisted: return 🔠("visibility.unlisted")
		case .private: return 🔠("visibility.private")
		case .direct: return 🔠("visibility.direct")
		}
	}

	func makeMenuItem() -> NSMenuItem
	{
		let item = NSMenuItem(title: localizedTitle, action: nil, keyEquivalent: "")
		item.image = icon
		item.representedObject = self
		return item
	}

	static func make(from audience: MastonautPreferences.StatusAudience) -> Visibility
	{
		switch audience
		{
		case .public:	return .public
		case .unlisted:	return .unlisted
		case .private:	return .private
		}
	}
}
