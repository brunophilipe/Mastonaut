//
//  TagBookmarkService.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 03.10.19.
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
import CoreData

public class TagBookmarkService
{
	private var bookmarkedTags: Set<String> = []

	private let account: AuthorizedAccount

	public init(account: AuthorizedAccount)
	{
		self.account = account
	}

	public func isTagBookmarked(_ tag: String) -> Bool
	{
		return account.hasBookmarkedTag(tag)
	}

	public func bookmarkTag(_ tag: String)
	{
		account.bookmarkTag(tag)
	}

	public func unbookmarkTag(_ tag: String)
	{
		account.unbookmarkTag(tag)
	}

	public func toggleBookmarkedState(for tag: String)
	{
		if account.hasBookmarkedTag(tag)
		{
			unbookmarkTag(tag)
		}
		else
		{
			bookmarkTag(tag)
		}
	}
}
