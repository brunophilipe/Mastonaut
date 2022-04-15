//
//  ShareMenuFactory.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 11.05.19.
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

enum ShareMenuFactory
{
	static func shareMenuItems(for url: URL, previewImage image: NSImage? = nil) -> [NSMenuItem]
	{
		let sharingServices = NSSharingService.sharingServices(forItems: [image ?? url])
		return sharingServices.map()
			{
				service -> NSMenuItem in

				let menuItem = NSMenuItem(title: service.menuItemTitle,
										  action: #selector(ShareServiceContext.share(_:)),
										  keyEquivalent: "")

				let shareContext = ShareServiceContext(service: service, url: url, preview: image)

				menuItem.representedObject = shareContext
				menuItem.image = service.image
				menuItem.target = shareContext

				return menuItem
			}
	}

	static func shareMenu(for url: URL, previewImage image: NSImage? = nil) -> NSMenu
	{
		let menu = NSMenu(title: "")
		menu.setItems(shareMenuItems(for: url, previewImage: image))
		return menu
	}
}

private class ShareServiceContext
{
	let service: NSSharingService
	let url: URL
	let image: NSImage?

	init(service: NSSharingService, url: URL, preview: NSImage?)
	{
		self.service = service
		self.url = url
		self.image = preview
	}

	func perform()
	{
		service.perform(withItems: [image ?? url])
	}

	@objc func share(_ sender: NSMenuItem)
	{
		perform()
	}
}
