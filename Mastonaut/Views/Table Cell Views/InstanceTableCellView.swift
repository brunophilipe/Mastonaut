//
//  InstanceTableCellView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 25.05.19.
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

class InstanceTableCellView: NSTableCellView
{
	@IBOutlet private unowned var nameLabel: NSTextField!
	@IBOutlet private unowned var descriptionLabel: NSTextField!

	@IBOutlet private unowned var statusCountLabel: NSTextField!
	@IBOutlet private unowned var userCountLabel: NSTextField!
	@IBOutlet private unowned var versionLabel: NSTextField!
	@IBOutlet private unowned var uptimeLabel: NSTextField!

	@IBOutlet private unowned var safeForWorkFlagView: NSView!
	@IBOutlet private unowned var adultContentFlagView: NSView!

	func set(instance: DirectoryService.Instance)
	{
		nameLabel.stringValue = instance.name
		descriptionLabel.stringValue = instance.info.shortDescription
		versionLabel.stringValue = instance.version ?? "––"
		uptimeLabel.stringValue = "\(Int(instance.uptime * 100))%"

		if let integerCount = Int(instance.statuses)
		{
			statusCountLabel.integerValue = integerCount
		}
		else
		{
			statusCountLabel.stringValue = instance.statuses
		}

		if let integerCount = Int(instance.users)
		{
			userCountLabel.integerValue = integerCount
		}
		else
		{
			userCountLabel.stringValue = instance.users
		}

		safeForWorkFlagView.isHidden = !instance.isSafeForWork
		adultContentFlagView.isHidden = !instance.isAdultCommunity
	}
}

private extension DirectoryService.Instance
{
	var isSafeForWork: Bool
	{
		return info.prohibitedContent.contains("pornography_all") && info.prohibitedContent.contains("nudity_all")
	}

	var isAdultCommunity: Bool
	{
		return info.categories.contains("adult")
	}
}
