//
//  MastodonURLResolver.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 09.04.19.
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

struct MastodonURLResolver
{
	static func resolve(url: URL, knownTags: [Tag]?, source windowController: TimelinesWindowController?)
	{
		var modeToPresent: SidebarMode? = nil

		if let annotations = (url as? AnnotatedURL)?.annotation?.split(separator: " ")
		{
			if annotations.contains("mention")
			{
				if annotations.contains("u-url")
				{
					modeToPresent = .profile(uri: url.mastodonHandleFromAccountURI)
				}
				else if annotations.contains("hashtag")
				{
					if let tag = knownTags?.first(where: { $0.url == url })
					{
						modeToPresent = .tag(tag.name)
					}
					else if let leadIndex = url.pathComponents.firstIndex(where: { $0 == "tag" || $0 == "tags" }),
						leadIndex < url.pathComponents.count
					{
						modeToPresent = .tag(url.pathComponents[leadIndex + 1])
					}
				}
			}
		}

		if let mode = modeToPresent, let windowController = windowController
		{
			windowController.presentInSidebar(mode)
		}
		else
		{
			NSWorkspace.shared.open(url)
		}
	}
}
