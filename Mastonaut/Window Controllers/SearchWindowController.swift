//
//  SearchWindowController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 30.06.19.
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

class SearchWindowController: NSWindowController
{
	override func windowDidLoad()
	{
		super.windowDidLoad()

		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	}

	func set(client: ClientType)
	{
		(contentViewController as? SearchViewController)?.client = client
	}

	func set(instance: Instance)
	{
		(contentViewController as? SearchViewController)?.instance = instance
	}

	func set(searchDelegate: SearchViewDelegate)
	{
		(contentViewController as? SearchViewController)?.searchDelegate = searchDelegate
	}
}
