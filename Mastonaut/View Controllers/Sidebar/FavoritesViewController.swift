//
//  FavoritesViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 11.10.19.
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

class FavoritesViewController: TimelineViewController, SidebarPresentable
{
	var titleMode: SidebarTitleMode
	{
		return .title(🔠("Favorites"))
	}

	var sidebarModelValue: SidebarModel
	{
		return SidebarMode.favorites
	}

	init()
	{
		super.init(source: .favorites)
	}

	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override func handle(updatedStatus: Status)
	{
		guard updatedStatus.favourited != true else
		{
			super.handle(updatedStatus: updatedStatus)
			return
		}

		handle(deletedEntry: updatedStatus.id)
	}
}
