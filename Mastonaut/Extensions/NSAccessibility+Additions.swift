//
//  NSAccessibility+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 02.03.19.
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

extension NSAccessibility
{
	static var shouldReduceMotion: Bool
	{
		return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
	}

	static func observeReduceMotionPreference(using block: @escaping () -> Void) -> NSObjectProtocol
	{
		let workspaceNC = NSWorkspace.shared.notificationCenter
		return workspaceNC.addObserver(forName: .accessibilityDisplayOptionsDidChange, object: nil, queue: .main)
		{
			[block] _ in block()
		}
	}
}

private extension Foundation.Notification.Name
{
	static var accessibilityDisplayOptionsDidChange: Foundation.Notification.Name
	{
		return NSWorkspace.accessibilityDisplayOptionsDidChangeNotification
	}
}
